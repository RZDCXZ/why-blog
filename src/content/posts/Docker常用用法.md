---
title: Docker常用用法
published: 2024-06-10
tags: ['nest', 'docker']
description: Docker的一些常用指令以及dockerfile和docker-compose的用法
category: '技术'
draft: false 
---

## 常用指令

* `docker search [name]`   搜索镜像

* `docker pull [name]`   拉取镜像

* `docker ps`   查看容器

* `docker run --name nginx-test2 -p 80:80 -v /tmp/aaa:/usr/share/nginx/html -e KEY1=VALUE1 -d nginx:latest `

  -p 是端口映射

  -v 是指定数据卷挂载目录

  -e 是指定环境变量

  -d 是后台运行

* `docker exex -it [容器hash] /bin/bash`   在容器中打开命令行

  -i 是 terminal 交互的方式运行

  -t 是 tty 终端类型

  输入exit退出

* `docker start [name]`   启动一个已停止的容器

* `docker rm [name]`   删除容器

* `docker stop [name]`   关闭运行的容器

* `docker build -t [imageName]:[tagName] .`   构建镜像（.指代Dockerfile文件位置）

* `docker run --restart=always`   

  指定重启策略，always为总是重启

  on-failure 是只有在非正常退出的时候才重启，而且 on-failure 还可以指定最多重启几次，比如 on-failure:3 是最多重启三次。

  unless-stopped 是除非手动停止，否则总是会重启。

* `docker cp  ~/home/ubuntu/nginx-html [container-name]:/usr/share/nginx/html-xxx`   将宿主机的文件复制到容器里，反过来就是将容器里的文件复制到宿主机里。

## Dockerfile编写

1. 常用.dockerignore文件内容

   ```
   *.md
   !README.md
   node_modules/
   [a-c].txt
   .git/
   .DS_Store
   .vscode/
   .dockerignore
   .eslintignore
   .eslintrc
   .prettierrc
   .prettierignore
   ```

2. 一个使用多阶段构建的nest项目dockerfile实例

   ```dockerfile
   FROM node:18.0-alpine3.14 as build-stage
   
   WORKDIR /app
   
   COPY package.json .
   
   RUN npm config set registry https://registry.npmmirror.com/
   
   RUN npm install
   
   COPY . .
   
   RUN npm run build
   
   # production stage
   FROM node:18.0-alpine3.14 as production-stage
   
   COPY --from=build-stage /app/dist /app
   COPY --from=build-stage /app/package.json /app/package.json
   
   WORKDIR /app
   
   RUN npm config set registry https://registry.npmmirror.com/
   
   RUN npm install --production
   
   EXPOSE 3000
   
   CMD ["node", "/app/main.js"]
   ```

   使用多阶段构建的理由是：

   * docker 是分层存储的，dockerfile 里的每一行指令是一层，会做缓存。

     每次 docker build 的时候，只会从变化的层开始重新构建，没变的层会直接复用。

     也就说现在这种写法，如果 package.json 没变，那么就不会执行 npm install，直接复用之前的。

   * 源码和很多构建的依赖是不需要的，都不需要保存在镜像里。

     实际上我们只需要构建出来的 ./dist 目录下的文件还有运行时的依赖。

## docker-compose编写

1. 一个部署nest+mysql+redis的docker-compose.yml文件示例

   ```yaml
   services:
     nest-app:
       build:
         context: ./
         dockerfile: ./Dockerfile
       depends_on:
         - mysql-container
         - redis-container
       ports:
         - '3000:3000'
     mysql-container:
       image: mysql
       ports:
         - '3306:3306'
       volumes:
         - /home/ubuntu/mysql-data:/var/lib/mysql
       environment:
         MYSQL_DATABASE: aaa
         MYSQL_ROOT_PASSWORD: guang
     redis-container:
       image: redis
       ports:
         - '6379:6379'
       volumes:
         - /home/ubuntu/aaa:/data
   ```

   使用`docker-compose up`命令运行

2. 使用桥接网络

   docker-compose默认会开启桥接，此时只需将host改为相应的container名字即可

   ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/12/20240612145601.webp)