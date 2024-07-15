---
title: Nestjs中使用TypeORM的migration迁移功能
published: 2024-07-15
tags: ['nest']
description: nest中typeorm的migration实现数据迁移
category: '技术'
draft: false 
---

在开发环境下，我们会开启 syncronize，自动同步 entities 到数据库表。

包括 create table 和后续的 alter table。

但是在生产环境下，我们会把它关闭，用 migration 把表结构的变动、数据初始化管理起来。

## 初始化项目

1. 创建一个nest项目然后安装相关依赖typeorm`npm install --save @nestjs/typeorm typeorm mysql2`

2. 在 AppModule 引入下：

   ```typescript
   TypeOrmModule.forRoot({
     type: "mysql",
     host: "localhost",
     port: 3306,
     username: "username",
     password: "password",
     database: "nest_migration_test",
     synchronize: true,
     logging: true,
     entities: [],
     poolSize: 10,
     connectorPackage: 'mysql2',
     extra: {
         authPlugin: 'sha256_password',
     }
   }),
   ```

3. 然后创建个 article 模块`nest g resource article`，改下 article.entity.ts:

   ```typescript
   import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";
   
   @Entity()
   export class Article {
       @PrimaryGeneratedColumn()
       id: number;
   
       @Column({
           length: 30
       })
       title: string;
   
       @Column({
           type: 'text'
       })
       content: string;
   
       @CreateDateColumn()
       createTime: Date;
   
       @UpdateDateColumn()
       updateTime: Date;
   }
   ```

   最后在typeormModule里引入这个表，再在mysql中创建该nest_migration_test数据库，因为synchronize设置为true，所以将项目跑起来即可自动连接到数据库并创建article表。

## 初始化数据

在articleService中写下初始化数据的方法initData，然后在articleController里调用:

```typescript
@InjectEntityManager()
entityManager: EntityManager;

async initData() {
    const a1 = new Article();
    a1.title = "夏日经济“热力”十足 “点燃”文旅消费新活力";
    a1.content = "人民网北京6月17日电 （高清扬）高考结束、暑期将至，各地文旅市场持续火热，暑期出游迎来热潮。热气腾腾的“夏日经济”成为消费活力升级的缩影，展示出我国文旅产业的持续发展势头。";

    const a2 = new Article();
    a2.title = "科学把握全面深化改革的方法要求";
    a2.content = "科学的方法是做好一切工作的重要保证。全面深化改革是一场复杂而深刻的社会变革，必须运用科学方法才能取得成功。";

    await this.entityManager.save(Article, a1);
    await this.entityManager.save(Article, a2);
}
```

```typescript
@Get('init-data')
async initData() {
    await this.articleService.initData();
    return '初始化数据完成';
}
```

然后浏览器访问下数据插入即可成功。

## migration

如果这个 article 的数据是要在生产环境里用的，而生产环境会关掉 syncronize，就需要用migration来创建表和初始化数据了。

1. 首先需要创建 src/data-source.ts：

   ```typescript
   import { DataSource } from "typeorm";
   import { Article } from "./article/entities/article.entity";
   
   export default new DataSource({
       type: "mysql",
       host: "localhost",
       port: 3306,
       username: "username",
       password: "password",
       database: "nest-migration-test",
       synchronize: false, // 关闭自动同步
       logging: true,
       entities: [Article],
       poolSize: 10,
       migrations: ['src/migrations/**.ts'], // migration存放位置
       connectorPackage: 'mysql2',
       extra: {
           authPlugin: 'sha256_password',
       }
   });
   ```

   注意，这里 synchronize 是 false，顺便也把 AppModule 里的那个 synchronize 也改为 false。

2. 为了方便操作，添加几个 npm scripts：

   ```json
   {
       ...
       "typeorm": "ts-node ./node_modules/typeorm/cli",
       "migration:create": "npm run typeorm -- migration:create",
       "migration:generate": "npm run typeorm -- migration:generate -d ./src/data-source.ts",
       "migration:run": "npm run typeorm -- migration:run -d ./src/data-source.ts",
       "migration:revert": "npm run typeorm -- migration:revert -d ./src/data-source.ts"
   
   }
   ```

3. 现在要模拟生产环境的操作，先在数据库里里删掉所有表，然后执行 migration:generate 命令`npm run migration:generate src/migrations/init`，它会对比 entity 和数据表的差异，生成迁移 sql：

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/15/20240715111814.webp)

   可以看到，生成的 migration 类里包含了 create table 的 sql。

   跑下`npm run migration:run`，可以看到，执行了两条 create table 语句，创建了migrations和article表。

   migrations 表里记录了执行过的 migration，已经执行过的不会再执行。

   article 表就是我们需要在生产环境创建的表。

4. 再创建个 migration 来初始化数据`npm run migration:create src/migrations/data`。

   **migration:generate 只会根据表结构变动生成迁移 sql，而数据的插入的 sql 需要我们自己添加。**

   严格来说数据初始化不能叫 migration，而应该叫 seed，也就是种子数据。

   不过我们都是通过 migration 来管理。

   在生成的迁移 class 里填入 insert into 的 sql 即可：

   ```typescript
   public async up(queryRunner: QueryRunner): Promise<void> {
       await queryRunner.query("INSERT INTO `article` VALUES (1,'夏日经济“热力”十足 “点燃”文旅消费新活力','人民网北京6月17日电 （高清扬）高考结束、暑期将至，各地文旅市场持续火热，暑期出游迎来热潮。热气腾腾的“夏日经济”成为消费活力升级的缩影，展示出我国文旅产业的持续发展势头。','2024-06-18 08:56:21.306445','2024-06-18 08:56:21.306445'),(2,'科学把握全面深化改革的方法要求','科学的方法是做好一切工作的重要保证。全面深化改革是一场复杂而深刻的社会变革，必须运用科学方法才能取得成功。','2024-06-18 08:56:21.325168','2024-06-18 08:56:21.325168');")
   }
   ```

   如果你要支持 revert，那 down 方法里应该补上 delete 语句，这里我们就不写了。

   然后使用`npm run migration:run`即可插入数据。

   可以看到，在 article 表插入了两条记录。

   然后在 migrations 表里插入了一条记录。

   为啥上次的 migration 就没执行了呢？

   因为 migrations 表里记录过了，记录过的就不会再执行。

5. 表结构的修改。

   同理，在entity中修改了表结构后执行 migration:generate 命令`npm run migration:generate src/migrations/add-tag-column`，然后执行下这个 migration `npm run migraion:run`，一条 alter table 的 sql，一条 insert 的 sql。

   可以看到，article 表多了 tags 列，migrations 表也插入了一条执行记录。

   这样，如何在生产环境通过 migration 创建表、修改表、初始化数据我们就都清楚了。

## 总结

生产环境是通过 migration 来创建表、更新表结构、初始化数据的。

这节我们在 nest 项目里实现了下迁移。

大概有这几步：

- 创建 data-source.ts 供 migration 用
- 把 synchronize 关掉
- 用 migration:generate 生成创建表的 migration
- 用 migration:run 执行
- 用 migration:create 创建 migration，然后填入数据库导出的 sql 里的 insert into 语句
- 用 migration:run 执行
- 用 migration:generate 生成修改表的 migration
- 用 migration:run 执行

在生产环境下，我们就是这样创建表、更新表、初始化数据的。