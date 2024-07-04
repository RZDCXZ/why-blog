---
title: Nestjs中搭配rxjs使用interceptor拦截器
published: 2024-07-04
tags: ['nest']
description: nest中使用interceptor的常用场景
category: '技术'
draft: false 
---

`nest g interceptor map-test --flat --no-spec`生成生成一个 interceptor。

局部引用：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/04/20240704161429.webp)

全局启用：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/04/20240704161457.webp)

## 修改返回数据

使用 map operator 来对 controller 返回的数据做一些修改：

```typescript
import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { map, Observable } from 'rxjs';

@Injectable()
export class MapTestInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(map(data => {
      return {
        code: 200,
        message: 'success',
        data
      }
    }))
  }
}
```

现在返回的数据就变成了这样:

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/04/20240704161754.webp)

## 添加一些日志、缓存等逻辑

```typescript
import { AppService } from './app.service';
import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';

@Injectable()
export class TapTestInterceptor implements NestInterceptor {
  constructor(private appService: AppService) {}

  private readonly logger = new Logger(TapTestInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(tap((data) => {
      
      // 这里是更新缓存的操作，这里模拟下
      this.appService.getHello();

      this.logger.log(`log something`, data);
    }))
  }
}
```

日志记录用的 nest 内置的 Logger，在 controller 返回响应的时候记录一些东西。

## catchError

controller 里很可能会抛出错误，这些错误会被 exception filter 处理，返回不同的响应，但在那之前，我们可以在 interceptor 里先处理下:

```typescript
import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { catchError, Observable, throwError } from 'rxjs';

@Injectable()
export class CatchErrorTestInterceptor implements NestInterceptor {
  private readonly logger = new Logger(CatchErrorTestInterceptor.name)

  intercept (context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(catchError(err => {
      this.logger.error(err.message, err.stack)
      return throwError(() => err)
    }))
  }
}
```

这里就是日志记录了一下，当然也可以改成另一种错误，重新 throwError。

## timeout

接口如果长时间没返回，要给用户一个接口超时的响应，这时候就可以用 timeout operator:

```typescript
import { CallHandler, ExecutionContext, Injectable, NestInterceptor, RequestTimeoutException } from '@nestjs/common';
import { catchError, Observable, throwError, timeout, TimeoutError } from 'rxjs';

@Injectable()
export class TimeoutInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      timeout(3000),
      catchError(err => {
        if(err instanceof TimeoutError) {
          console.log(err);
          return throwError(() => new RequestTimeoutException());
        }
        return throwError(() => err);
      })
    )
  }
}
```

timeout 操作符会在 3s 没收到消息的时候抛一个 TimeoutError。

然后用 catchError 操作符处理下，如果是 TimeoutError，就返回 RequestTimeoutException，这个有内置的 exception filter 会处理成对应的响应格式。

其余错误就直接 throwError 抛出去。

浏览器访问，3s 后返回 408 响应。

## 依赖注入

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/04/20240704163456.webp)

这种是手动 new 的，没法注入依赖。

但很多情况下我们是需要全局 interceptor 的，而且还用到一些 provider，怎么办呢？

nest 提供了一个 token，用这个 token 在 AppModule 里声明的 interceptor，Nest 会把它作为全局 interceptor：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/04/20240704163523.webp)

在这个 interceptor 里我们注入了 appService：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/04/20240704163540.webp)

## 总结

nest 的 interceptor 就用了 rxjs 来处理响应，但常用的 operator 也就这么几个：

- tap: 不修改响应数据，执行一些额外逻辑，比如记录日志、更新缓存等
- map：对响应数据做修改，一般都是改成 {code, data, message} 的格式
- catchError：在 exception filter 之前处理抛出的异常，可以记录或者抛出别的异常
- timeout：处理响应超时的情况，抛出一个 TimeoutError，配合 catchErrror 可以返回超时的响应

此外，interceptor 也是可以注入依赖的，你可以通过注入模块内的各种 provider。

全局 interceptor 可以通过 APP_INTERCEPTOR 的 token 声明，这种能注入依赖，比 app.useGlobalInterceptors 更好。