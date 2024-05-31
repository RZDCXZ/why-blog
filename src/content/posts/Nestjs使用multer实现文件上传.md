---
title: Nestjs使用multer实现文件上传
published: 2024-05-30
description: '使用nestjs的各种接收上传文件的方法'
tags: ['nest', 'typescript']
category: '技术'
draft: false 
---

## 创建项目

1. 使用nest命令行创建项目`nest new nest-multer-upload -p npm`。

2. 安装multer的ts类型的包`npm i -D @types/multer`。

3. 在main.ts中开启允许跨域

   ```typescript
   const app = await NestFactory.create(AppModule, {
       cors: true, // 增加这个配置来允许跨域
   })
   ```

   

## 文件上传

1. 在AppController.ts中添加这样一个handler：

   ```typescript
   @Post('aaa')
   @UseInterceptors(FileInterceptor('aaa', {
       dest: 'uploads' // 保存的文件夹名称
   }))
   uploadFile(@UploadedFile() file: Express.Multer.File, @Body() body) {
       console.log('body', body);
       console.log('file', file);
   }
   ```

   使用FileInterceptor来提取aaa字段，然后通过通过UploadedFile装饰器把它作文参数传入

   用`npm run start:dev`把服务跑起来，可以看到uploads目录被创建了，上传的文件会保存到这个文件夹里面。

2. 写前端代码，先创建一个test.html文件然后写入一下代码：

   ```html
   <!DOCTYPE html>
   <html lang="en">
   <head>
       <meta charset="UTF-8">
       <meta http-equiv="X-UA-Compatible" content="IE=edge">
       <meta name="viewport" content="width=device-width, initial-scale=1.0">
       <title>Document</title>
       <script src="https://unpkg.com/axios@0.24.0/dist/axios.min.js"></script>
   </head>
   <body>
       <input id="fileInput" type="file" multiple/>
       <script>
           const fileInput = document.querySelector('#fileInput');
   
           async function formData() {
               const data = new FormData();
               data.set('name','why');
               data.set('age', 24);
               data.set('aaa', fileInput.files[0]);
   
               const res = await axios.post('http://localhost:3000/aaa', data);
               console.log(res);
           }
   
           fileInput.onchange = formData;
       </script>
   </body>
   </html>
   ```

   用浏览器打开运行这个文件然后就可以上传文件了，上传后可以看到后端的uploads文件夹下就保存了上传的文件。

## 多文件上传

1. 再在AppController.ts文件中增加以下handler：

   ```typescript
   @Post('bbb')
   @UseInterceptors(FilesInterceptor('bbb', 3, { // 3代表单次最大支持上传数量
       dest: 'uploads'
   }))
   uploadFiles(@UploadedFiles() files: Array<Express.Multer.File>, @Body() body) {
       console.log('body', body);
       console.log('files', files);
   }
   ```

   把 FileInterceptor 换成 FilesInterceptor，把 UploadedFile 换成 UploadedFiles，都是多加一个 s。

2. 然后是前端代码，在test.html中增加以下代码：

   ```javascript
   async function formData2() {
       const data = new FormData();
       data.set('name','why');
       data.set('age', 24);
       [...fileInput.files].forEach(item => {
           data.append('bbb', item)
       })
   
       const res = await axios.post('http://localhost:3000/bbb', data, {
           headers: { 'content-type': 'multipart/form-data' }
       });
       console.log(res);
   }
   ```

   这样就可以上传多文件了。

## 多文件多字段上传

1. 和 multer 里类似，使用这种方式来指定：

   ```typescript
   @Post('ccc')
   @UseInterceptors(FileFieldsInterceptor([
       { name: 'aaa', maxCount: 2 },
       { name: 'bbb', maxCount: 3 },
   ], {
       dest: 'uploads'
   }))
   uploadFileFields(@UploadedFiles() files: { aaa?: Express.Multer.File[], bbb?: Express.Multer.File[] }, @Body() body) {
       console.log('body', body);
       console.log('files', files);
   }
   
   ```

2. 前端代码：

   ```javascript
   async function formData3() {
       const data = new FormData();
       data.set('name','why');
       data.set('age', 24);
       data.append('aaa', fileInput.files[0]);
       data.append('aaa', fileInput.files[1]);
       data.append('bbb', fileInput.files[2]);
       data.append('bbb', fileInput.files[3]);
   
       const res = await axios.post('http://localhost:3000/ccc', data);
       console.log(res);
   }
   ```

   这里应该用两个 file input 来分别上传 aaa 和 bbb 对应的文件，这里为了测试方便就简化了下。

## 不知道哪些字段是file的上传

1. 可以用AnyFileInterceptor：

   ```typescript
   @Post('ddd')
   @UseInterceptors(AnyFilesInterceptor({
       dest: 'uploads'
   }))
   uploadAnyFiles(@UploadedFiles() files: Array<Express.Multer.File>, @Body() body) {
       console.log('body', body);
       console.log('files', files);
   }
   ```

2. 前端代码：

   ```javascript
   async function formData4() {
       const data = new FormData();
       data.set('name','why');
       data.set('age', 24);
       data.set('aaa', fileInput.files[0]);
       data.set('bbb', fileInput.files[1]);
       data.set('ccc', fileInput.files[2]);
       data.set('ddd', fileInput.files[3]);
   
       const res = await axios.post('http://localhost:3000/ddd', data);
       console.log(res);
   }
   
   ```

   同样会识别出了所有 file 字段。

## 自定义storage上传

1. 新建一个ts文件然后写入一下代码：

   ```typescript
   import * as multer from 'multer'
   import * as fs from 'fs'
   import * as path from 'path'
   
   const storage = multer.diskStorage({
     // 自定义上传文件目录位置
     destination: function (req, file, cb) {
       try {
         fs.mkdirSync(path.join(process.cwd(), 'my-uploads'))
       } catch (e) {}
   
       cb(null, path.join(process.cwd(), 'my-uploads'))
     },
     // 自定义上传文件的文件名
     filename: function (req, file, cb) {
       const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9) + '-' + file.originalname
       cb(null, file.fieldname + '-' + uniqueSuffix)
     },
   })
   
   export { storage }
   
   ```

2. AppController.ts中把这个 storage 拿过来，在 controller 里用一下：

   ```typescript
   @Post('ddd')
   @UseInterceptors(
       AnyFilesInterceptor({
           // dest: 'uploads',
           storage: storage, // 使用我们写的storage
       }),
   )
   uploadAnyFiles(
       @UploadedFiles() files: Array<Express.Multer.File>,
       @Body() body: any,
       ) {
           console.log('body', body)
           console.log('files', files)
       }
   ```

   此时保存文件使用的规则就是我们storage里写的规则了，可以自定义存放的文件夹名称以及上传的文件的命名规则等等。

## 自定义函数限制上传的文件大小

1. 使用命令生成一个pipe，`nest g pipe file-size-validation-pipe --no-spec --flat`。

2. 在生成的文件中写入如下代码：

   ```typescript
   import { PipeTransform, Injectable, ArgumentMetadata, HttpException, HttpStatus } from '@nestjs/common';
   
   @Injectable()
   export class FileSizeValidationPipe implements PipeTransform {
     transform(value: Express.Multer.File, metadata: ArgumentMetadata) {
       if(value.size > 10 * 1024) {
         throw new HttpException('文件大于 10k', HttpStatus.BAD_REQUEST);
       }
       return value;
     }
   }
   ```

   大于 10k 就抛出异常，返回 400 的响应。

3. 把他加入UploadedFile的参数里：

   ```typescript
   @Post('eee')
   @UseInterceptors(
       FileInterceptor('eee', {
           dest: 'uploads',
       }),
   )
   uploadFilee2(
       @UploadedFile(FileSizeValidationPipePipe) file: Express.Multer.File,
       @Body() body: any,
       ) {
           console.log('body===>', body)
           console.log('file===>', file)
       }
   ```

   此时上传文件大于10kb就会报400错误实现校验了。

## 使用nest内置的方法实现文件上传校验

1. 像文件大小、类型的校验这种逻辑太过常见，Nest 给封装好了，可以直接用：

   ```typescript
   @Post('fff')
   @UseInterceptors(FileInterceptor('aaa', {
       dest: 'uploads'
   }))
   uploadFile3(@UploadedFile(new ParseFilePipe({
       validators: [
         new MaxFileSizeValidator({ maxSize: 1000 }), // 限制文件大小
         new FileTypeValidator({ fileType: 'image/jpeg' }), // 限制文件类型
       ],
   })) file: Express.Multer.File, @Body() body) {
       console.log('body', body);
       console.log('file', file);
   }
   ```

   此时上传文件可以看到，返回的也是 400 响应，并且 message 说明了具体的错误信息，而且这个错误信息可以自己修改：

   ```typescript
   @Post('fff')
   @UseInterceptors(FileInterceptor('aaa', {
       dest: 'uploads'
   }))
   uploadFile3(@UploadedFile(new ParseFilePipe({
       exceptionFactory: err => {
         throw new HttpException('xxx' + err, 404)   // 修改错误信息、修改返回状态码为404
       },
       validators: [
         new MaxFileSizeValidator({ maxSize: 1000 }), // 限制文件大小
         new FileTypeValidator({ fileType: 'image/jpeg' }), // 限制文件类型
       ],
   })) file: Express.Multer.File, @Body() body) {
       console.log('body', body);
       console.log('file', file);
   }
   ```

## 自定义validator校验

1. 我们也可以自己实现这样的 validator，只要继承 FileValidator 就可以：

   ```typescript
   import { FileValidator } from '@nestjs/common'
   
   export class MyFileValidator extends FileValidator {
     constructor(options: Record<string, any>) {
       super(options)
     }
   
     // 在这个函数里可以写自定义校验的各种逻辑代码
     isValid(file: Express.Multer.File): boolean | Promise<boolean> {
       if (file.size > 10000) {
         return false
       }
       return true
     }
     buildErrorMessage(file: Express.Multer.File): string {
       return `文件 ${file.originalname} 大小超出 10k`
     }
   }
   
   ```

2. 然后在AppController里用一下：

   ```typescript
     // 自定义文件validator
     @Post('ggg')
     @UseInterceptors(
       FileInterceptor('ggg', {
         dest: 'uploads',
       }),
     )
     uploadFile4(
       @UploadedFile(
         new ParseFilePipe({
           validators: [new MyFileValidator({})],
         }),
       )
       file: Express.Multer.File,
       @Body() body: any,
     ) {
       console.log('body===>', body)
       console.log('file===>', file)
     }
   }
   ```

   

## 总结

至此，以上列举了nest实现文件上传的各种方法，具体义务中灵活选择使用即可。