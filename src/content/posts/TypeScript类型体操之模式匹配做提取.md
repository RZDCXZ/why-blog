---
title: TypeScript类型体操之模式匹配做提取
published: 2024-07-23
tags: ['typescript']
description: TypeScript类型做模式匹配
category: '技术'
draft: false 
---

## 模式匹配

示例：提取一个Promise的值的类型

```typescript
type GetPromiseValueType<P> = P extends Promise<infer Value> ? Value : never
// 传入的泛型P为Promise的类型吗？是的话就返回它的值的类型，否则返回never类型

type GetValueResult = GetPromiseValueType<Promise<'why'>>
// 由于传入的泛型是Promise<'why'>，符合匹配规则，所以GetValueResult就是'why'的类型也就是string
```

**Typescript 类型的模式匹配是通过 extends 对类型参数做匹配，结果保存到通过 infer 声明的局部类型变量里，如果匹配就能从该局部变量里拿到提取出的类型。**

## 数组类型

### First

提取数组的第一个元素的类型：

```typescript
type GetFirst<T extends unknown[]> = T extends [infer First, ...unknown[]] ? First : never
// 限制传入的泛型T是一个数组，用infer声明局部变量，如果T是一个数组则返回数组第一个元素First的类型，否则返回never

type GetFirstResult1 = GetFirst<[string,2,'3']>
// 此时GetFirstResult1的类型则为数组中第一个元素的类型，也就是string

type GetFirstResult2 = GetFirst<[]>
// GetFirstResult2的类型为never
```

### Last

提取数组的最后一个元素的类型：

```typescript
type GetLast<T extends unknown[]> = T extends [...unknown[], infer Last] ? Last : never;
// 同理于提取数组第一个元素的类型
```

### PopArr

分别取了首尾元素，当然也可以取剩余的数组，比如取去掉了最后一个元素的数组：

```typescript
type PopArr<T extends unknown[]> = T extends [...infer Rest, unknown] ? Rest : never
// 传入的泛型是数组吗？是则返回去掉了最后一个元素的数组，不是则返回never类型

type PopResult = PopArr<[1,2,3]>
// 此时PopResult的类型为[1,2]
```

### ShiftArr

同理可得 ShiftArr 的实现，去掉了第一个元素的数组：

```typescript
type ShiftArr<T extends unknown[]> = T extends [unknown, ...infer Rest] ? Rest : never
// 传入的泛型是数组吗？是则返回去掉了最后一个元素的数组，不是则返回never类型

type ShiftResult = PopArr<[1,2,3]>
// 此时PopResult的类型为[2,3]
```

## 字符串类型

### StartsWith

判断字符串是否以某个前缀开头，也是通过模式匹配：

```typescript
type StartsWith<Str extends string, Prefix extends string> = Str extends `${Prefix}${string}` ? true : false
// 传入两个字符串泛型，如果Str字符串是以Prefix字符串开头的则返回true，否则返回false

type StartsWithResult = StartsWith<'wanghaoyu', 'wang'>
// 'wanghaoyu'是以'wang'开头的，所以StartsWithResult类型为true
```

### Replace

字符串可以匹配一个模式类型，提取想要的部分，也可以用这些再构成一个新的类型。

比如实现字符串替换：

```typescript
type ReplaceStr<
    Str extends string, // 原始字符串
    From extends string, // 需要被替换的字符串
    To extends string // 替换成的字符串
> = Str extends `${infer Prefix}${From}${infer Suffix}` ? `${Prefix}${To}${Suffix}` : Str
// 传入三个泛型字符串，如符合替换规则则用传入的To字符串替换From字符串，不符合规则则返回原Str字符串
```

### Trim

能够匹配和替换字符串，那也就能实现去掉空白字符的 Trim：

不过因为我们不知道有多少个空白字符，所以只能一个个匹配和去掉，需要递归。

先实现 TrimRight:

```typescript
type TrimStrRight<Str extends string> = 
    Str extends `${infer Rest}${' ' | '\n' | '\t'}` 
        ? TrimStrRight<Rest> : Str;

type TrimStrRightResult = TrimStrRight<'why      '>
// TrimStrRightResult的类型是'why'
```

类型参数 Str 是要 Trim 的字符串。

如果 Str 匹配字符串 + 空白字符 (空格、换行、制表符)，那就把字符串放到 infer 声明的局部变量 Rest 里。

把 Rest 作为类型参数递归 TrimRight，直到不匹配，这时的类型参数 Str 就是处理结果。

同理可得 TrimLeft：

```typescript
type TrimStrLeft<Str extends string> = 
    Str extends `${' ' | '\n' | '\t'}${infer Rest}` 
        ? TrimStrLeft<Rest> : Str;
```

TrimRight 和 TrimLeft 结合就是 Trim：

```typescript
type TrimStr<Str extends string> =TrimStrRight<TrimStrLeft<Str>>;
```

## 函数

### GetParameters

函数类型可以通过模式匹配来提取参数的类型：

```typescript
type GetParameters<Func extends Function> = Func extends (...args: infer Args) => unknown ? Args : never
// 传入一个泛型函数，若符合规则则返回他的参数类型

type ParametersResult = GetParameters<(name: string, password: string) => string>
// ParametersResult的类型为[name: string, password: string]
```

### GetReturnType

能提取参数类型，同样也可以提取返回值类型：

```typescript
type GetReturnType<Func extends Function> = 
    Func extends (...args: any[]) => infer ReturnType 
        ? ReturnType : never;
// 传入一个泛型函数，符合规则则返回它的返回值类型，否则返回never

type ReturnTypeResult = GetReturnType<()=>string>
// ReturnTypeResult的类型为string
```

## 索引类型

### GetRefProps

我们同样通过模式匹配的方式提取 ref 的值的类型：

```typescript
type GetRefProps<Props> = 'ref' extends keyof Props ?
    Props extends {ref?: infer Vallue | undefine} ? Value : never : never
    
type GetRefPropsResult = GetRefProps<{ref?:string,name: 'dog'}>
// GetRefPropsResult的类型为string
```

通过 keyof Props 取出 Props 的所有索引构成的联合类型，判断下 ref 是否在其中，也就是 'ref' extends keyof Props。

如果有 ref 这个索引的话，就通过 infer 提取 Value 的类型返回，否则返回 never。

## 总结

就像字符串可以匹配一个模式串提取子组一样，TypeScript 类型也可以匹配一个模式类型提取某个部分的类型。

**TypeScript 类型的模式匹配是通过类型 extends 一个模式类型，把需要提取的部分放到通过 infer 声明的局部变量里，后面可以从这个局部变量拿到类型做各种后续处理。**