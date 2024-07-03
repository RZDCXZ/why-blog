---
title: Nestjs中Exception Filter的使用
published: 2024-07-03
tags: ['nest']
description: nest中自定义exception捕获异常并响应
category: '技术'
draft: false 
---

*Exception Filter 是在 Nest 应用抛异常的时候，捕获它并返回一个对应的响应。*

## 自定义exception filter:

`nest g filter hello --flat --no-spec`

--flat 是不生成 hello 目录，--no-spec 是不生成测试文件。

@Catch 指定要捕获的异常，这里指定 BadRequestException。

```typescript
import { ArgumentsHost, BadRequestException, Catch, ExceptionFilter } from '@nestjs/common';

@Catch(BadRequestException) // 捕获BadRequestException类型的异常
export class HelloFilter implements ExceptionFilter {
  catch(exception: BadRequestException, host: ArgumentsHost) {
  }
}
```

如果想局部启用，可以加在 handler 或者 controller 上：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/03/20240703162419.webp)

然后在代码里写入对异常的响应即可：

```typescript
import { ArgumentsHost, BadRequestException, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import { Response } from 'express';

@Catch(BadRequestException)
export class HelloFilter implements ExceptionFilter {
  catch(exception: BadRequestException, host: ArgumentsHost) {
    const http = host.switchToHttp();
    const response = http.getResponse<Response>();

    const statusCode = exception.getStatus();

    response.status(statusCode).json({
       code: statusCode, // 响应状态码
       message: exception.message, // 响应信息
       error: 'Bad Request', // 错误类型
       xxx: 111 // 自定义数据
    })
  }
}
```

最后，需要在main.ts里全局启用:

`app.useGlobalFilters(new HelloFilter())`

这样，抛异常时返回的响应就是自定义的了：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/03/20240703162622.webp)

但我们只是 @Catch 了 BadRequestException，如果抛的是其他异常，依然是原来的格式。

想要捕获所有的http错误类型只要 @Catch 指定 HttpException 就行了，因为 BadRequestExeption、BadGateWayException 等都是它的子类。

```typescript
import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
} from '@nestjs/common'
import { Response } from 'express'

@Catch(HttpException)
export class HelloFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const http = host.switchToHttp()
    const response = http.getResponse<Response>()

    const statusCode = exception.getStatus()

    const res = exception.getResponse() as { message: string[]; error: string }

    response.status(statusCode).json({
      code: statusCode,
      message: res.message,
      error: res.error,
      xxx: 111,
    })
  }
}
```

## 兼容ValidationPipe的错误

当我们用了 ValidationPipe 的时候，有多个错误时message返回的是数组，我们自定义的 exception filter 会拦截所有 HttpException，但是没有对这种情况做支持。

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/03/20240703163933.webp)

最终代码如下：

```typescript
import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
} from '@nestjs/common'
import { Response } from 'express'

@Catch(HttpException)
export class HelloFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const http = host.switchToHttp()
    const response = http.getResponse<Response>()

    const statusCode = exception.getStatus()

    const res = exception.getResponse() as { message: string[]; error: string }

    response.status(statusCode).json({
      code: statusCode,
      message: res.message?.join ? res.message.join(',') : exception.message, // 如果是数组则用,拼接,字符串直接返回
      error: res.error,
      xxx: 111,
    })
  }
}
```

## 在 Filter 里注入 AppService 

这时就不用 useGlobalFilters 注册了，而是在 AppModule 里注册一个 token 为 APP_FILTER 的 provider：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/03/20240703164935.webp)

这样注册的好处就是可以注入其他 provider 了

比如我注入了 AppService，然后调用它的 getHello 方法：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/03/20240703164948.webp)

## 自定义 Exception 

自己实现一个异常然后捕获该异常

```typescript
import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus } from '@nestjs/common';
import { Response } from 'express';

export class UnLoginException{
  message: string;

  constructor(message?){
    this.message = message;
  }
}

@Catch(UnLoginException)
export class UnloginFilter implements ExceptionFilter {
  catch(exception: UnLoginException, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();

    response.status(HttpStatus.UNAUTHORIZED).json({
      code: HttpStatus.UNAUTHORIZED,
      message: 'fail',
      data: exception.message || '用户未登录'
    }).end();
  }
}
```

我们创建了一个 UnloginException 的异常。

然后在 ExceptionFilter 里 @Catch 了它。

在 AppModule 里注册这个全局 Filter：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/03/20240703165116.webp)

之后在 AppController 里抛出这个异常即可：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/03/20240703165136.webp)

## 总结

通过 @Catch 指定要捕获的异常，然后在 catch 方法里拿到异常信息，返回对应的响应。

如果捕获的是 HttpException，要注意兼容下 ValidationPipe 的错误格式的处理。

filter 可以通过 @UseFilters 加在 handler 或者 controller 上，也可以在 main.ts 用 app.useGlobalFilters 全局启用。

如果 filter 要注入其他 provider，就要通过 AppModule 里注册一个 token 为 APP_FILTER 的 provider 的方式。

此外，捕获的 Exception 也是可以自定义的。

这样，就可以自定义异常和异常返回的响应格式了。