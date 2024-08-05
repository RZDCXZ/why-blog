---
title: TypeScript常用内置高级类型
published: 2024-08-05
tags: ['typescript']
description: TypeScript的一些常用内置高级类型
category: '技术'
draft: false 
---

## Parameters

Parameters 用于提取函数类型的参数类型，源码如下：

```typescript
type Parameters<T extends (...args: any) => any> 
    = T extends (...args: infer P) => any 
        ? P 
        : never;

type ParamatersRes = Parameters<(name: string, age: number)=>void>
// ParamatersRes的类型即为函数参数的类型：[name: string, age: number]
```

## ReturnType

用于提取函数类型的返回值类型，源码如下：

```typescript
type ReturnType<T extends (...args: any) => any> 
    = T extends (...args: any) => infer R 
        ? R 
        : any;

type ReturnTypeRes = ReturnType<()=>string>
// ReturnTypeRes的类型即为函数返回值的类型：string
```

## ConstructorParameters

Parameters 用于提取函数参数的类型，而 ConstructorParameters 用于提取构造器参数的类型，源码如下：

```typescript
type ConstructorParameters<
    T extends abstract new (...args: any) => any
> = T extends abstract new (...args: infer P) => any 
    ? P 
    : never;

interface PersonConstructor {
    new(name: string): Person
}

type ConstructorParametersRes = ConstructorParameters<PersonConstructor>
// ConstructorParametersRes的类型为[name: string]
```

## InstanceType

提取构造器返回值的类型，源码如下：

```typescript
type InstanceType<
    T extends abstract new (...args: any) => any
> = T extends abstract new (...args: any) => infer R 
    ? R 
    : any;
```

整体和 ConstructorParameters 差不多，只不过提取的不再是参数了，而是返回值。

## Partial

索引类型可以通过映射类型的语法做修改，比如把索引变为可选：

```typescript
type Partial<T> = {
    [P in keyof T]?: T[P];
};
```

## Required

可以把索引变为可选，也同样可以去掉可选，也就是 Required 类型：

```typescript
type Required<T> = {
    [P in keyof T]-?: T[P];
};
```

## Readonly

同样的方式，也可以添加 readonly 的修饰：

```typescript
type Readonly<T> = {
    readonly [P in keyof T]: T[P];
};
```

## Pick

映射类型的语法用于构造新的索引类型，在构造的过程中可以对索引和值做一些修改或过滤：

```typescript
type Pick<T, K extends keyof T> = {
    [P in K]: T[P];
};

type PickRes = Pick<{name: string, age: number, sex: 1}, 'name' | 'age'>
// PickRes的类型为{name: string, age: number}
```

## Record

Record 用于创建索引类型，传入 key 和值的类型：

```typescript
type Record<K extends keyof any, T> = {
    [P in K]: T;
};
```

## Exclude

当想从一个联合类型中去掉一部分类型时，可以用 Exclude 类型：

```typescript
type Exclude<T, U> = T extends U ? never : T;

type ExcludeRes = Exclude<'a'|'b'|'c'|'d','a'|'b'>
// ExcludeRes的类型为'c'|'d'
```

## Extract

可以过滤掉，自然也可以保留，Exclude 反过来就是 Extract，也就是取交集：

```typescript
type Extract<T, U> = T extends U ? T : never;

type ExtractRes = Extract<'a'|'b'|'c', 'a'|'b'|'d'>
// ExtractRes的类型为'a'|'b'
```

## Omit

我们知道了 Pick 可以取出索引类型的一部分索引构造成新的索引类型，那反过来就是去掉这部分索引构造成新的索引类型：

```typescript
type Omit<T, K extends keyof any> = Pick<T, Exclude<keyof T, K>>;

type OmitRes = Omit<{name: string, age: number}, 'age'>
// OmitRes的类型为{name: string}
```

## Awaited

取 Promise 的 ValuType 的高级类型：

```typescript
type Awaited<T> =
    T extends null | undefined
        ? T 
        : T extends object & { then(onfulfilled: infer F): any }
            ? F extends ((value: infer V, ...args: any) => any)
                ? Awaited<V>
                : never 
            : T;

type AwaitedRes = Awaited<Promise<Promise<string>>>
// AwaitedRes的类型为string
```

## NonNullable

NonNullable 就是用于判断是否为非空类型，也就是不是 null 或者 undefined 的类型的：

```typescript
type NonNullable<T> = T extends null | undefined ? never : T;
```

## Uppercase、Lowercase、Capitalize、Uncapitalize

这四个类型是分别实现大写、小写、首字母大写、去掉首字母大写的。

![image-20240805111024813](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/08/05/20240805111032.png)

## 