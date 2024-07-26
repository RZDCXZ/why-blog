---
title: TypeScript类型体操之重新构造做变换
published: 2024-07-26
tags: ['typescript']
description: TypeScript类型做重新构造
category: '技术'
draft: false 
---

**TypeScript 的 type、infer、类型参数声明的变量都不能修改，想对类型做各种变换产生新的类型就需要重新构造。**

## 数组类型

### Push

给元组类型添加一个类型：

```typescript
type Push<Arr extends unknown[], T> = [...Arr, T]
// 传入一个泛型数组和一个泛型,返回该数组类型的元组以及将泛型T添加在后面

type PushResult = Push<[1,2,3], string>
// PushResult的类型为[1,2,3,string]
```

### Unshift

同理也可以在前面添加：

```typescript
type Unshift<Arr extends  unknown[], T> = [T, ...Arr];

type UnshiftResult = Push<[1,2,3], number>
// UnshiftResult的类型为[numbser,1,2,3]
```

### Zip

有两个元组想要将它们合并：

```typescript
type tuple1 = [1,2]
type tuple2 = ['why', 'qiu']
// 两个元组

type tuple = [[1,'why'],[2,'qiu']]
// 想合并成这样
```

实现方法为，提取元组中的两个元素，构造成新的元组：

```typescript
type Zip<One extends [unknown, unknown], Other extends [unknown, unknown]> = 
    One extends [infer OneFirst, infer OneSecond]
        ? Other extends [infer OtherFirst, infer OtherSecond]
            ? [[OneFirst, OtherFirst], [OneSecond, OtherSecond]] :[] 
                : [];
// 传入两个泛型元组，使用infer提取变量构造成新的元组类型返回

type ZipResult = Zip<[1,2], ['3', '4']>
// ZipResult的类型为[[1,'3'],[2,'4']]
```

但是这样只能合并两个元素的元组，如果是任意个那就得用递归了：

```typescript
type Zip2<One extends unknown[], Other extends unknown[]> = 
    One extends [infer OneFirst, ...infer OneRest]
        ? Other extends [infer OtherFirst, ...infer OtherRest]
            ? [[OneFirst, OtherFirst], ...Zip2<OneRest, OtherRest>]: []
                : [];
```

## 字符串类型

### CapitalizeStr

想把一个字符串字面量类型的 'why' 转为首字母大写的 'Why'：

```typescript
type CapitalizeStr<Str extends string> = 
    Str extends `${infer First}${infer Rest}` 
        ? `${Uppercase<First>}${Rest}` : Str;
// 传入一个泛型字符串，将首字母变为大写，Uppercase是TypeScript内置高级类型

type CapitalizeStrResult = CapitalizeStr<'why'>
// CapitalizeStrResult的类型为'Why'
```

### CamelCase

再来实现 why_why_why 到 whyWhyWhy的变换：

```typescript
type CamelCase<Str extends string> = 
    Str extends `${infer Left}_${infer Right}${infer Rest}`
        ? `${Left}${Uppercase<Right>}${CamelCase<Rest>}`
        : Str;
// 传入泛型字符串，使用递归按照匹配规则进行大写转换

type CamelCaseResult = CamelCase<'why_why_why'> // _之后的字母都会变成大写
// CamelCaseResult的类型为whyWhyWhy
```

### DropSubStr

删除一段字符串的案例，删除字符串中的某个子串：

```typescript
type DropSubStr<Str extends string, SubStr extends string> = 
    Str extends `${infer Prefix}${SubStr}${infer Suffix}` 
        ? DropSubStr<`${Prefix}${Suffix}`, SubStr> : Str;
// 传入一个原始字符串和一个要删除的子串，递归删除

type DropSubStrResult = DropSubStr<'wangahaoayua', 'a'> // 删除字符串中所有的'a'
// DropSubStrResult的类型为'wanghaoyu'
```

### AppendArgument

在已有的函数类型上添加一个参数：

```typescript
type AppendArgument<Func extends Function, Arg> = 
    Func extends (...args: infer Args) => infer ReturnType 
        ? (...args: [...Args, Arg]) => ReturnType : never;
// 传入一个泛型函数类型，以及一个泛型，将传入的泛型添加到函数参数中

type AppendArgumentResult = AppendArgument<(name: string)=>void, number>
// AppendArgumentResult的类型为(args_0: string, args_1: number)=>void
```

## 索引类型

### Mapping

映射的过程中可以对 value 做下修改：

```typescript
type Mapping<Obj extends object> = { 
    [Key in keyof Obj]: [Obj[Key], Obj[Key], Obj[Key]]
}

type MappingResult = Mapping<{name: 'why', age: 24}>
// MappingResult的类型为 {name: ['why','why','why'], age: [24,24,24]}
```

### UppercaseKey

除了可以对 Value 做修改，也可以对 Key 做修改，使用 as，这叫做`重映射`，比如把索引类型的 Key 变为大写：

```typescript
type UppercaseKey<Obj extends object> = { 
    [Key in keyof Obj as Uppercase<Key & string>]: Obj[Key]
}

type UppercaseKeyResult = UppercaseKey<{name: 'why'}> // key变为大写
// UppercaseKeyResult的类型为{NAME: 'why'}
```

### ToReadonly

给索引类型添加 readonly ：

```typescript
type ToReadonly<T> =  {
    readonly [Key in keyof T]: T[Key];
}
// 传入一个泛型，将他的属性全变为只读类型
```

### ToPartial

同理，索引类型还可以添加可选修饰符：

```typescript
type ToPartial<T> = {
    [Key in keyof T]?: T[Key]
}
// 传入一个泛型，将他的属性全变为可选类型
```

### ToMutable

可以添加 readonly 修饰，当然也可以去掉：

```typescript
type ToMutable<T> = {
    -readonly [Key in keyof T]: T[Key]
}
// 去掉传入泛型的属性的只读
```

### ToRequired

同理，也可以去掉可选修饰符：

```typescript
type ToRequired<T> = {
    [Key in keyof T]-?: T[Key]
}
// 去掉传入泛型的可选修饰符
```

### FilterByValueType

可以在构造新索引类型的时候根据值的类型做下过滤：

```typescript
type FilterByValueType<
    Obj extends Record<string, any>, 
    ValueType
> = {
    [Key in keyof Obj 
        as Obj[Key] extends ValueType ? Key : never]
        : Obj[Key]
}
```

类型参数 Obj 为要处理的索引类型，通过 extends 约束为索引为 string，值为任意类型的索引类型 Record<string, any>。

类型参数 ValueType 为要过滤出的值的类型。

构造新的索引类型，索引为 Obj 的索引，也就是 Key in keyof Obj，但要做一些变换，也就是 as 之后的部分。

如果原来索引的值 Obj[Key] 是 ValueType 类型，索引依然为之前的索引 Key，否则索引设置为 never，never 的索引会在生成新的索引类型时被去掉。

值保持不变，依然为原来索引的值，也就是 Obj[Key]。

这样就达到了过滤索引类型的索引，产生新的索引类型的目的：

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/26/20240726110338.webp)

## 总结

TypeScript 支持 type、infer、类型参数来保存任意类型，相当于变量的作用。

但其实也不能叫变量，因为它们是不可变的。**想要变化就需要重新构造新的类型，并且可以在构造新类型的过程中对原类型做一些过滤和变换。**

数组、字符串、函数、索引类型等都可以用这种方式对原类型做变换产生新的类型。其中索引类型有专门的语法叫做映射类型，对索引做修改的 as 叫做重映射。