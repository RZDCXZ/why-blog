---
title: Nestjs中使用TypeORM保存tree格式数据
published: 2024-07-12
tags: ['nest']
description: nest中使用tyeporm保存和获取tree数据的方法
category: '技术'
draft: false 
---

## 创建表结构

1. 在一个nest项目下创建一个CRUD模块`nest g resource city --no-spec`

2. 安装typeorm相关依赖`npm install --save @nestjs/typeorm typeorm mysql2`

3. 在app.module.ts中引入TypeOrmModule连接到mysql数据库:

   ```typescript
   import { Module } from '@nestjs/common'
   import { AppController } from './app.controller'
   import { AppService } from './app.service'
   import { CityModule } from './city/city.module'
   import { TypeOrmModule } from '@nestjs/typeorm'
   import { City } from './city/entities/city.entity'
   
   @Module({
     imports: [
       CityModule,
       TypeOrmModule.forRoot({
         host: 'localhost',
         type: 'mysql',
         port: 3306,
         username: 'root',
         password: 'root',
         database: 'tree_test',
         synchronize: true,
         logging: true,
         entities: [City],
       }),
     ],
     controllers: [AppController],
     providers: [AppService],
   })
   export class AppModule {}
   ```

   *记得先在mysql中创建相应的数据库，如这里是tree_test，`create database tree_test charset=utf8mb4;`*

4. 然后更改一下相关表结构city.entity.ts:

   ```typescript
   import {
     Column,
     CreateDateColumn,
     Entity,
     PrimaryGeneratedColumn,
     Tree,
     TreeChildren,
     TreeParent,
     UpdateDateColumn,
   } from 'typeorm'
   
   @Entity()
   @Tree('closure-table') // 常用的有closure-table(存到两张表)和materialized-path(存到一张表)
   export class City {
     @PrimaryGeneratedColumn()
     id: number
   
     @Column({ default: 0 })
     status: number
   
     @CreateDateColumn()
     createDate: Date
   
     @UpdateDateColumn()
     updateDate: Date
   
     @Column()
     name: string
   
     @TreeChildren()
     children: City[] // 存储着它的 children 节点
   
     @TreeParent()
     parent: City // 存储着它的 parent 节点
   }
   ```

5. 由于TypeOrmModule里synchronize设置为true所以运行项目即可在数据库里创建表，表结构如下图:

   ![image-20240712101045057](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712101052.png)

   

## tree相关api操作

1. 插入数据示例：

   ```typescript
   @InjectEntityManager()
   entityManager: EntityManager;
   
   async findAll() {
       const city = new City();
       city.name = '华北';
       await this.entityManager.save(city);
   
       const cityChild = new City()
       cityChild.name = '山东'
       const parent = await this.entityManager.findOne(City, {
         where: {
           name: '华北'
         }
       });
       if(parent){
         cityChild.parent = parent
       }
       await this.entityManager.save(City, cityChild)
   
       return this.entityManager.getTreeRepository(City).findTrees(); // 返回表里所有的tree数据
   }
   ```

   这里创建了两个 city 的 entity，第二个的 parent 指定为第一个。

   用 save 保存。

   然后再 getTreeRepository 调用 findTrees 把数据查出来。

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712101411.webp)

   可以看到数据插入成功了，并且返回了树形结构的结果。

   将之前插入数据的代码注释掉然后重新插入一些数据:

   ```typescript
   async findAll() {
       const city = new City();
       city.name = '华南';
       await this.entityManager.save(city);
   
       const cityChild1 = new City()
       cityChild1.name = '云南'
       const parent = await this.entityManager.findOne(City, {
         where: {
           name: '华南'
         }
       });
       if(parent){
         cityChild1.parent = parent
       }
       await this.entityManager.save(City, cityChild1)
   
       const cityChild2 = new City()
       cityChild2.name = '昆明'
   
       const parent2 = await this.entityManager.findOne(City, {
         where: {
           name: '云南'
         }
       });
       if(parent){
         cityChild2.parent = parent2
       }
       await this.entityManager.save(City, cityChild2)
   
   return this.entityManager.getTreeRepository(City).findTrees();
   }
   ```

   跑一下：

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712101638.webp)

   可以看到，二层和三层的关系都可以正常的存储和查询。

2. findRoots 查询的是所有根节点：

   ```typescript
   async findAll() {
       return this.entityManager.getTreeRepository(City).findRoots() // 只查询所有根节点
   }
   ```

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712101749.webp)

3. findDescendantsTree 是查询某个节点的所有后代节点:

   ```typescript
   async findAll() {
       const parent = await this.entityManager.findOne(City, {
         where: {
           name: '云南'
         }
       });
       return this.entityManager.getTreeRepository(City).findDescendantsTree(parent) //查询该节点的所有后代节点
   }
   ```

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712101833.webp)

4. findAncestorsTree 是查询某个节点的所有祖先节点:

   ```typescript
   async findAll() {
       const parent = await this.entityManager.findOne(City, {
         where: {
           name: '云南'
         }
       });
       return this.entityManager.getTreeRepository(City).findAncestorsTree(parent) // 查询该节点的所有祖先节点
   }
   ```

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712101923.webp)

5. 换成 findAncestors、findDescendants 就是用扁平结构返回：

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712102006.webp)

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712102013.webp)

6. findTrees 换成 find 也是会返回扁平的结构：

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712102032.webp)

7. 可以调用 countAncestors 和 countDescendants 来计数：

   ```typescript
   async findAll() {
       const parent = await this.entityManager.findOne(City, {
         where: {
           name: '云南'
         }
       });
       return this.entityManager.getTreeRepository(City).countAncestors(parent) // 返回数量
   }
   ```

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/12/20240712102119.webp)

## 总结

在 entity 上使用 @Tree 标识，然后通过 @TreeParent 和 @TreeChildren 标识存储父子节点的属性。

之后可以用 getTreeRepository 的 find、findTrees、findRoots、findAncestorsTree、findAncestors、findDescendantsTree、findDescendants、countDescendants、countAncestors 等 api 来实现各种关系的查询。

存储方式可以指定 closure-table 或者 materialized-path，这两种方式一个用单表存储，一个用两个表，但实现的效果是一样的。