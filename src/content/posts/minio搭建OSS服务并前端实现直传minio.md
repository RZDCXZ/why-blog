---
title: minio搭建OSS服务并前端实现直传minio
published: 2024-06-06
description: '自己搭建OSS服务实现文件上传'
tags: ['nest', 'typescript', 'docker']
category: '技术'
draft: false 
---
## 搭建服务

1. docker中搜索minio镜像并运行容器

   ![image-20240606105256773](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/06/20240606105303.png)

   name 是容器名。

   port 是映射本地 9000 和 9001 端口到容器内的端口。

   volume 是挂载本地目录到容器内的目录

   这里挂载了一个本地一个目录到容器内的数据目录 /bitnami/minio/data，这样容器里的各种数据都保存在本地了。

   还要指定两个环境变量，MINIO_ROOT_USER 和 MINIO_ROOT_PASSWORD，是用来登录的。

   此时访问`http://localhost/9001`进入登陆界面并输入用户名密码登录即可进入minio控制界面。

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/06/20240606105553.webp)

   这个 bucket 就是管理桶的地方，而 object browser 就是管理文件列表的地方。

2. 创建个 bucket：

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/06/20240606105931.webp)

3. 然后在这个 bucket 下上传一个文件

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/06/20240606110017.webp)

   因为现在文件访问权限不是公开的，我们设置下：

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/06/20240606110059.webp)

   ![](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/06/20240606110105.webp)

   添加一个 / 的匿名的访问规则，然后就可以直接访问了。

## 文件上传下载

1. 安装依赖`npm i minio`并编写代码：

   ```javascript
   var Minio = require('minio')
   
   var minioClient = new Minio.Client({
     endPoint: 'localhost',
     port: 9000,
     useSSL: false,
     accessKey: '',
     secretKey: '',
   })
   
   function put() {
       minioClient.fPutObject('aaa', 'hello.png', './smile.png', function (err, etag) {
           if (err) return console.log(err)
           console.log('上传成功');
       });
   }
   
   put();
   ```

2. 创建用到的 accessKey：

   ![](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/06/20240606110421.webp)

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/06/20240606110454.webp)

   将accessKey和secretKey填入代码中即可上传文件。

   也可以下载文件:

   ```javascript
   const fs = require('fs');
   
   function get() {
       minioClient.getObject('aaa', 'hello.png', (err, stream) => {
           if (err) return console.log(err)
           stream.pipe(fs.createWriteStream('./xxx.png'));
       });
   }
   
   get();
   ```

## 前端直传minio

原理：应用服务器返回一个临时的凭证，前端用这个临时凭证传 OSS，不需要把 accessKey 暴露给前端。

1. 创建nest项目`nest new minio-fe-upload`。

2. 安装minio包`npm install --save minio`并创建模块`nest g module minio`写入以下代码

   ```typescript
   import { Global, Module } from '@nestjs/common';
   import * as Minio from 'minio';
   
   export const MINIO_CLIENT = 'MINIO_CLIENT';
   
   @Global()
   @Module({
       providers: [
           {
               provide: MINIO_CLIENT,
               async useFactory() {
                   const client = new Minio.Client({
                           endPoint: 'localhost',
                           port: 9000,
                           useSSL: false,
                           accessKey: '',
                           secretKey: ''
                       })
                   return client;
               }
             }
       ],
       exports: [MINIO_CLIENT]
   })
   export class MinioModule {}
   
   ```

   accessKey和secretKey实在minio里创建的。

3. 在 AppController 里注入下测试下：

   ```typescript
   import { Controller, Get, Inject } from '@nestjs/common';
   import { AppService } from './app.service';
   import { MINIO_CLIENT } from './minio/minio.module';
   import * as Minio from 'minio';
   
   @Controller()
   export class AppController {
     constructor(private readonly appService: AppService) {}
   
     @Inject(MINIO_CLIENT)
     private minioClient: Minio.Client;
   
     @Get('test')
     async test() {
       try {
         await this.minioClient.fPutObject('aaa', 'hello.json', './package.json');
         return 'http://localhost:9000/aaa/hello.json';
       } catch(e) {
         console.log(e);
         return '上传失败';
       }
     }
   
     @Get()
     getHello(): string {
       return this.appService.getHello();
     }
   }
   ```

4. 前端直传，在html中写入以下代码：

   ```html
   <!DOCTYPE html>
   <html lang="en">
   <head>
       <meta charset="UTF-8">
       <meta name="viewport" content="width=device-width, initial-scale=1.0">
       <title>Document</title>
   </head>
   <body>
       <input type="file" id="selector" multiple>
       <button onclick="upload()">Upload</button>
       <div id="status">No uploads</div>
   
       <script type="text/javascript">
           function upload() {
               var files = document.querySelector("#selector").files;
               for (var i = 0; i < files.length; i++) {
                   var file = files[i];
                   retrieveNewURL(file, (file, url) => {
                       uploadFile(file, url);
                   });
               }
           }
   
           function retrieveNewURL(file, cb) {
               fetch(`/presignedUrl?name=${file.name}`).then((response) => {
                   response.text().then((url) => {
                       cb(file, url);
                   });
               }).catch((e) => {
                   console.error(e);
               });
           }
   
           function uploadFile(file, url) {
               if (document.querySelector('#status').innerText === 'No uploads') {
                   document.querySelector('#status').innerHTML = '';
               }
               fetch(url, {
                   method: 'PUT',
                   body: file
               }).then(() => {
                   document.querySelector('#status').innerHTML += `<br>Uploaded ${file.name}.`;
               }).catch((e) => {
                   console.error(e);
               });
           }
       </script>
   </body>
   </html>
   
   ```

5. 然后我们在服务端增加这个签名接口：

   ```typescript
   @Get('presignedUrl')
   async presignedUrl(@Query('name') name: string) {
       return this.minioClient.presignedPutObject('aaa', name);
   }
   ```

## 总结

其实就是在 url 里带上了鉴权信息。

这样，前端不需要 accessKey 也可以直传文件到 minio 了。