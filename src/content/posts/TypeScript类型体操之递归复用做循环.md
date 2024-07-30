---
title: TypeScript类型体操之递归复用做循环
published: 2024-07-30
tags: ['typescript']
description: TypeScript类型做递归复用
category: '技术'
draft: false 
---

**递归是把问题分解为一系列相似的小问题，通过函数不断调用自身来解决这一个个小问题，直到满足结束条件，就完成了问题的求解。**

## Promise 的递归复用

### DeepPromiseValueType

实现一个提取不确定层数的 Promise 中的 value 类型的高级类型：

```typescript
type DeepPromiseValueType<T> = T extends Promise<infer ValueType> ? ValueType extends Promise<unknown>
                                ? DeepPromiseValueType<ValueType> : ValueType : never
// 传入一个泛型，如果泛型是Promise类型则取出它的ValueType，若ValueType也是Promise类型则递归调用直至取到value的类型返回
                                                 
type DeepPromiseResult = DeepPromiseValueType<Promise<Promise<Promise<string>>>>
// DeepPromiseResult的类型为string
```

## 数组类型的递归

### ReverseArr

反转数组：

```typescript
type ReverseArr<Arr extends unknown[]> = Arr extends [infer First, ...infer Rest] ? 
    [...ReverseArr<Rest>, First] : Arr
// 传入一个泛型数组，提取出第一个类型然后递归放到数组最后

type ReverseArrResult = ReverseArr<[1,2,3]>
// ReverseArrResult的类型为[3,2,1]
```

### Includes

从长度不固定的数组中查找某个元素，有就返回true，否则返回false：

```typescript
type Includes<Arr extends unknown[], FindItem> = 
    Arr extends [infer First, ...infer Rest]
        ? IsEqual<First, FindItem> extends true
            ? true
            : Includes<Rest, FindItem>
        : false;

type IsEqual<A, B> = (A extends B ? true : false) & (B extends A ? true : false);
// 判断两个泛型是否相等

type IncludesResult = Includes<[1,2,3], 2>
// IncludesResult的类型为true
```

### RemoveItem

从数组中删除某个元素：

```typescript
type RemoveItem<
    Arr extends unknown[], 
    Item, 
    Result extends unknown[] = []
> = Arr extends [infer First, ...infer Rest]
        ? IsEqual<First, Item> extends true
            ? RemoveItem<Rest, Item, Result>
            : RemoveItem<Rest, Item, [...Result, First]>
        : Result;
        
type IsEqual<A, B> = (A extends B ? true : false) & (B extends A ? true : false);
// 判断两个泛型是否相等

type RemoveItemResult = RemoveItem<[1,2,2,3], 2>
// RemoveItemResult的类型为[1,3]
```

类型参数 Arr 是待处理的数组，元素类型任意，也就是 unknown[]。类型参数 Item 为待查找的元素类型。类型参数 Result 是构造出的新数组，默认值是 []。

通过模式匹配提取数组中的一个元素的类型，如果是 Item 类型的话就删除，也就是不放入构造的新数组，直接返回之前的 Result。

否则放入构造的新数组，也就是再构造一个新的数组 [...Result, First]。

直到模式匹配不再满足，也就是处理完了所有的元素，返回这时候的 Result。

### BuildArray

传入 5 和元素类型，构造一个长度为 5 的该元素类型构成的数组：

```typescript
type BuildArray<
    Length extends number, 
    Ele = unknown, 
    Arr extends unknown[] = []
> = Arr['length'] extends Length 
        ? Arr 
        : BuildArray<Length, Ele, [...Arr, Ele]>;

type BuildArrayResult = BuildArray<5>
// BuildArrayResult的类型为[unknown,unknown,unknown,unknown,unknown]
```

类型参数 Length 为数组长度，约束为 number。类型参数 Ele 为元素类型，默认值为 unknown。类型参数 Arr 为构造出的数组，默认值是 []。

每次判断下 Arr 的长度是否到了 Length，是的话就返回 Arr，否则在 Arr 上加一个元素，然后递归构造。

## 字符串类型的递归

### ReplaceAll

递归把一个字符串中的某个字符替换成另一个：

```typescript
type ReplaceAll<
    Str extends string, 
    From extends string, 
    To extends string
> = Str extends `${infer Left}${From}${infer Right}`
        ? `${Left}${To}${ReplaceAll<Right, From, To>}`
        : Str;
type ReplaceAllResult = ReplaceAll<'why why why','why','qui'>
// ReplaceAllResult的类型为'qui qui qui'
```

### StringToUnion

我把字符串字面量类型的每个字符都提取出来组成联合类型，例如把 'why' 转为 'w' | 'h' | 'y'：

```typescript
type StringToUnion<Str extends string> = 
    Str extends `${infer First}${infer Rest}`
        ? First | StringToUnion<Rest>
        : never;

type StringToUnionResult = StringToUnion<'why'>
// StringToUnionResult的类型为'w' | 'h' | 'y'
```

### ReverseStr

同理数组反转，字符串反转：

```typescript
type ReverseStr<
    Str extends string, 
    Result extends string = ''
> = Str extends `${infer First}${infer Rest}` 
    ? ReverseStr<Rest, `${First}${Result}`> 
    : Result;
```

类型参数 Str 为待处理的字符串。类型参数 Result 为构造出的字符，默认值是空串。

通过模式匹配提取第一个字符到 infer 声明的局部变量 First，其余字符放到 Rest。

用 First 和之前的 Result 构造成新的字符串，把 First 放到前面，因为递归是从左到右处理，那么不断往前插就是把右边的放到了左边，完成了反转的效果。

直到模式匹配不满足，就处理完了所有的字符。

## 对象类型的递归

### DeepReadonly

数量（层数）不确定:

```typescript
type DeepReadonly<Obj extends Record<string, any>> =
    Obj extends any // 触发计算
        ? {
            readonly [Key in keyof Obj]:
                Obj[Key] extends object
                    ? Obj[Key] extends Function
                        ? Obj[Key] 
                        : DeepReadonly<Obj[Key]>
                    : Obj[Key]
        }
        : never;
```

 ts 的类型只有被用到的时候才会做计算。

所以可以在前面加上一段 Obj extends never ? never 或者 Obj extends any 等，从而触发计算

## 总结

递归是把问题分解成一个个子问题，通过解决一个个子问题来解决整个问题。形式是不断的调用函数自身，直到满足结束条件。

在 TypeScript 类型系统中的高级类型也同样支持递归，**在类型体操中，遇到数量不确定的问题，要条件反射的想到递归。** 比如数组长度不确定、字符串长度不确定、索引类型层数不确定等。

