---
title: Nestjs中pipe的使用
published: 2024-06-18
tags: ['nest']
description: nest中使用内置pipe和自定义pipe实现参数检验
category: '技术'
draft: false 
---

*Pipe 是在参数传给 handler 之前对参数做一些验证和转换的 class，作用：校验和转化参数*。

## 内置pipe和自定义pipe

内置pipe有：

* ValidationPipe
* ParseIntPipe
* ParseBoolPipe
* ParseArrayPipe
* ParseUUIDPipe
* DefaultValuePipe
* ParseEnumPipe
* ParseFloatPipe
* ParseFilePipe

基本用法示例：

```typescript
import { Controller, Get, ParseIntPipe, Query } from '@nestjs/common'
import { AppService } from './app.service'

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(@Query('aaa', ParseIntPipe) aaa: number): number {
    return aaa + 1
  }
}
```

ParseIntPipe将参数转化为整数，当传入的参数不能 parse 为 int 时，会使用内置报错。

报错是可以修改的，示例如下：

```typescript
import {
  Controller,
  Get,
  HttpStatus,
  ParseIntPipe,
  Query,
} from '@nestjs/common'

@Controller()
export class AppController {
  constructor() {}

  @Get()
  getHello(
    @Query(
      'aaa',
      new ParseIntPipe({
        errorHttpStatusCode: HttpStatus.BAD_REQUEST,
      }),
    )
    aaa: number,
  ): number {
    return aaa + 1
  }
}
```

也可以自己抛一个异常出来，然后让 exception filter 处理：

```typescript
import {
  Controller,
  Get,
  HttpException,
  HttpStatus,
  ParseIntPipe,
  Query,
} from '@nestjs/common'

@Controller()
export class AppController {
  constructor() {}

  @Get()
  getHello(
    @Query(
      'aaa',
      new ParseIntPipe({
        exceptionFactory(msg) {
          throw new HttpException('xxx ' + msg, HttpStatus.NOT_IMPLEMENTED)
        },
      }),
    )
    aaa: number,
  ): number {
    return aaa + 1
  }
}
```

使用ParseArrayPipe时需要安装相关依赖`npm install class-validator class-transformer`

使用ParseArrayPipe将参数转化为数组并将数组的每一项转化为整数的示例：

```typescript
import { Controller, Get, ParseArrayPipe, Query } from '@nestjs/common'

@Controller()
export class AppController {
  constructor() {}

  @Get()
  getHello(
    @Query(
      'aaa',
      new ParseArrayPipe({
        items: Number, // 将数组的每一项转化为整数
        optional: true, // 将参数设置为可选
        separator: ',', // 指定分隔符，这样写就是将入参 ?aaa=1,2,3转化为[1,2,3]
      }),
    )
    aaa: Array<number>,
  ): number {
    return aaa.reduce((total, item) => total + item, 0)
  }
}
```

ParseEnumPipe参数必须为enum中的指定项：

```typescript
import { Controller, Get, ParseEnumPipe, Query } from '@nestjs/common'

enum Ggg {
  AAA = '111',
  BBB = '222',
  CCC = '333',
}

@Controller()
export class AppController {
  constructor() {}

  @Get()
  getHello(
    @Query('enum', new ParseEnumPipe(Ggg))
    aaa: Ggg,
  ): Ggg {
    return aaa
  }
}
```

DefaultValuePipe用于设置默认值，当没传参数值使用默认值：

```typescript
import { Controller, DefaultValuePipe, Get, Query } from '@nestjs/common'

@Controller()
export class AppController {
  constructor() {}

  @Get()
  getHello(
    @Query('bbb', new DefaultValuePipe('bbb'))
    bbb: string,
  ): string {
    return bbb
  }
}
```

## 自定义pipe

一个基本的自定义pipe示例：

```typescript
import { ArgumentMetadata, Injectable, PipeTransform } from '@nestjs/common'

@Injectable()
export class AaaPipe implements PipeTransform {
  transform(value: any, metadata: ArgumentMetadata) {
    // value为参数的值 在这里对value进行自定义检验或转化然后return即可
    return value
  }
}
```

然后即可使用：

```typescript
import { Controller, Get, Param, Query } from '@nestjs/common'
import { AaaPipe } from './aaa.pipe'

@Controller()
export class AppController {
  constructor() {}

  @Get()
  getHello(
    @Query('aaa', AaaPipe)
    aaa: string,
    @Param('bbb', AaaPipe) bbb: string,
  ): string {
    return aaa + bbb
  }
}
```

## 使用ValidatePipe验证post请求参数

需要两个依赖包`npm install class-validator class-transformer`

1. 编写body参数的dto

   ```typescript
   import { IsEmail, IsEnum, IsFQDN, IsInt, Length, Min } from 'class-validator'
   
   enum Gender {
     man,
     women,
   }
   
   export class AaaDto {
     @Length(10, 20)
     username: string
   
     @IsInt() // 只能为整数
     @Min(0, {
       message: '年龄不能小于0', // 自定义报错信息
     })
     age: number
   
     @IsEnum(Gender)
     gender: boolean
   
     hobbies: Array<string>
   
     @IsFQDN() // 是否为域名
     site: string
   
     @IsEmail()
     email: string
   }
   ```

2. 全局启用ValidationPipe：

   ```typescript
   import { NestFactory } from '@nestjs/core'
   import { AppModule } from './app.module'
   import { ValidationPipe } from '@nestjs/common'
   
   async function bootstrap() {
     const app = await NestFactory.create(AppModule)
     app.useGlobalPipes(new ValidationPipe()) // ValidationPipe
     await app.listen(3000)
   }
   
   bootstrap()
   ```

   