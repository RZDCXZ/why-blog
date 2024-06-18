---
title: Axios双token实现无感登录
published: 2024-06-05
tags: ['nest']
category: '技术'
draft: false 
---

## 后端

1. 首先写接口，运行命令`nest new access_token_and_refresh_token -p npm`创建项目。

2. 添加user模块`nest g resource user --no-spec`并安装依赖`npm install --save @nestjs/typeorm typeorm mysql2 @nest`。

3. docker启动mysql，并在 AppModule 引入 TypeOrmModule：

   ```typescript
   import { Module } from '@nestjs/common';
   import { TypeOrmModule } from '@nestjs/typeorm';
   import { AppController } from './app.controller';
   import { AppService } from './app.service';
   
   @Module({
       imports: [ 
           TypeOrmModule.forRoot({
               type: "mysql", // 连接的数据库类型
               host: "localhost", // 地址
               port: 3306, // 端口
               username: "root", //登录mysql的用户名
               password: "9527", // 登录mysql的密码
               database: "refresh_token_test", // 要连接的数据库名称
               synchronize: true, // 同步表(生产一定要关掉)
               logging: true, // 在控制台打印执行的日志
               entities: [], // 使用到的entity(表)
               poolSize: 10,
               connectorPackage: 'mysql2',
               extra: {
                   authPlugin: 'sha256_password',
               }
           }),
       ],
       controllers: [AppController],
       providers: [AppService],
   })
   export class AppModule {}
   ```

   然后创建数据库`CREATE DATABASE refresh_token_test DEFAULT CHARACTER SET utf8mb4;`。

4. 创建User的entity并在TypeOrmModule里引入：

   ```typescript
   import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";
   
   @Entity()
   export class User {
       @PrimaryGeneratedColumn()
       id: number;
   
       @Column({
           length: 50
       })
       username: string;
   
       @Column({
           length: 50
       })
       password: string;
   }
   ```

5. 下载jwt相关依赖`npm i @nestjs/jwt`并在AppModule里引入

   ```typescript
   JwtModule.register({
       global: true, // 声明为全局模块
       signOptions: {
           expiresIn: '30m' // token默认过期时间30分钟
       },
       secret: 'why' // 密钥
   })
   ```

6. 执行命令`nest g guard login --flat --no-spec`创建守卫，实现LoginGuard做登录鉴权

   ```typescript
   import {
       CanActivate,
       ExecutionContext,
       Inject,
       Injectable,
       UnauthorizedException,
   } from '@nestjs/common'
   import { Observable } from 'rxjs'
   import { JwtService } from '@nestjs/jwt'
   import { Request } from 'express'
   
   @Injectable()
   export class LoginGuard implements CanActivate {
       @Inject(JwtService)
       private readonly jwtService: JwtService
   
       canActivate(
       context: ExecutionContext,
       ): boolean | Promise<boolean> | Observable<boolean> {
           const request: Request = context.switchToHttp().getRequest()
   
           const authorization = request.headers.authorization
   
           if (!authorization) {
               throw new UnauthorizedException('请先登录')
           }
   
           try {
               const token = authorization.split(' ')[1]
               this.jwtService.verify(token)
               return true
           } catch (e) {
               throw new UnauthorizedException('token失效,请重新登录')
           }
       }
   }
   ```

7. 在UserController.ts中编写接口：

   ```typescript
   @Controller('user')
   export class UserController {
       constructor(private readonly userService: UserService) {}
   
       // 注入jwtService
       @Inject(JwtService)
       private readonly jwtService: JwtService
   
       @InjectEntityManager()
       private readonly entityManager: EntityManager
   
       // 登录接口
       @Post('login')
       async login(@Body() loginUserDto: LoginUserDto) {
           const foundUser = await this.entityManager.findOne(User, {
               where: {
                   username: loginUserDto.username,
               },
           })
   
           if (!foundUser) {
               throw new BadRequestException('用户不存在')
           }
   
           if (foundUser.password !== loginUserDto.password) {
               throw new BadRequestException('用户名或密码错误')
           }
   
           const accessToken = this.jwtService.sign({
               username: foundUser.username,
               id: foundUser.id,
           })
   
           const refreshToken = this.jwtService.sign(
               {
                   id: foundUser.id,
               },
               {
                   expiresIn: '7d', // refreshToken过期时间要长一些设置为7天
               },
           )
   
           return {
               accessToken,
               refreshToken,
           }
       }
   
       // 刷新token的接口 入参需要传入refreshToken
       @Get('refresh')
       async refresh(@Query('token') token: string) {
           try {
               const { id } = await this.jwtService.verify(token)
   
               const foundUser = await this.entityManager.findOne(User, {
                   where: {
                       id,
                   },
               })
   
               const accessToken = this.jwtService.sign({
                   username: foundUser.username,
                   id: foundUser.id,
               })
   
               const refreshToken = this.jwtService.sign(
                   {
                       id: foundUser.id,
                   },
                   {
                       expiresIn: '7d', // refreshToken过期时间要长一些设置为7天
                   },
               )
   
               return {
                   accessToken,
                   refreshToken,
               }
           } catch (e) {
               throw new BadRequestException('token失效,请重新登录')
           }
       }
   
       // 测试接口 没有token会报错
       @Get('test')
       @UseGuards(LoginGuard) // 登录守卫，由于判断是否登录
       test() {
           return 'test success!'
       }
   }
   ```

## 前端

前端主要是在请求拦截器里进行判断，如果accessToken失效则携带refreshToken请求refresh的接口获取新的token并保存下来就能实现无感刷新，但这样还不完美，比如当并发多个请求的时候，如果都失效了，会调用refresh接口多次，完美的解决方案是加一个 refreshing 的标记，如果在刷新，那就返回一个 promise，并且把它的 resolve 方法还有 config 加到队列里。当 refresh 成功之后，修改 refreshing 的值，重新发送队列中的请求，并且把结果通过 resolve 返回，完整代码如下：

```typescript
import axios, { AxiosRequestConfig } from 'axios'

interface PendingTask {
  config: AxiosRequestConfig
  resolve: Function
}

const instance = axios.create({
  baseURL: 'http://127.0.0.1:3000',
  timeout: 3000,
})

// 是否正在调用refresh接口
let refreshing = false
// axios的任务队列
const queue: PendingTask[] = []

instance.interceptors.request.use(function (config) {
  const accessToken = localStorage.getItem('accessToken')

  if (accessToken) {
    config.headers.authorization = 'Bearer ' + accessToken
  }
  return config
})

instance.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    let { data, config } = error.response

    // 如果正在refresh则将请求放到任务队列里，等refresh完毕后在拿出来调用
    if (refreshing) {
      return new Promise((resolve) => {
        queue.push({
          config,
          resolve,
        })
      })
    }

    if (data.statusCode === 401 && !config.url.includes('/refresh')) {
      refreshing = true
      // 调用refresh接口刷新过期的token
      const res = await refresh()

      refreshing = false

      if (res.status === 200) {
        // 将保存在任务队列里的任务拿出来调用
        queue.forEach(({ config, resolve }) => {
          resolve(instance(config))
        })

        return instance(config) // 重新发起请求实现无感刷新
      } else {
        alert(data || '登录过期，请重新登录')
      }
    } else {
      return error.response
    }
  },
)

export const userLogin = async (username: string, password: string) => {
  return await instance.post('/login', {
    username,
    password,
  })
}

export const test = async () => {
  return await instance.get('/test')
}

export const refresh = async () => {
  const res = await instance.get('/refresh', {
    params: {
      token: localStorage.getItem('refreshToken'),
    },
  })

  localStorage.setItem('accessToken', res.data.accessToken)
  localStorage.setItem('refreshToken', res.data.refreshToken)
  return res
}
```

## 总结

access_token 用于身份认证，refresh_token 用于刷新 token，也就是续签。

在登录接口里同时返回 access_token 和 refresh_token，access_token 设置较短的过期时间，比如 30 分钟，refresh_token 设置较长的过期时间，比如 7 天。

当 access_token 失效的时候，可以用 refresh_token 去刷新，服务端会根据其中的 userId 查询用户数据，返回新 token。

在前端代码里，可以在登录之后，把 token 放在 localstorage 里。

然后用 axios 的 interceptors.request 给请求时自动带上 authorization 的 header。

用 intercetpors.response 在响应是 401 的时候，自动访问 refreshToken 接口拿到新 token，然后再次访问失败的接口。

我们还支持了并发请求时，如果 token 过期，会把请求放到队列里，只刷新一次，刷新完批量重发请求。

这就是 token 无感刷新的前后端实现，是用的特别多的一种方案。