---
title: Nginx常用用法
published: 2024-06-10
tags: ['nginx']
description: Nginx静态资源托管、反向代理、灰度系统
category: '技术'
draft: false 
---

## 常用

1. 主配置文件在 /etc/nginx/nginx.conf，子配置文件在 /etc/nginx/conf.d 目录下。

2. location匹配规则

   location = /aaa 是精确匹配 /aaa 的路由。

   location /bbb 是前缀匹配 /bbb 的路由。

   location ~ /ccc.*.html 是正则匹配。可以再加个 * 表示不区分大小写 location ~* /ccc.*.html

   location ^~ /ddd 是前缀匹配，但是优先级更高。

   这 4 种语法的优先级是这样的：

   **精确匹配（=） > 高优先级前缀匹配（^~） > 正则匹配（～ ~\*） > 普通前缀匹配**

   实例：

   ```nginx
   location = /111/ {
       default_type text/plain;
       return 200 "111 success";
   }
   
   location /222 {
       default_type text/plain;
       return 200 $uri;
   }
   
   location ~ ^/333/bbb.*\.html$ {
       default_type text/plain;
       return 200 $uri;
   }
   
   location ~* ^/444/AAA.*\.html$ {
       default_type text/plain;
       return 200 $uri;
   }
   ```

3. root和alias区别

   ```nginx
   location /222 {
       alias /dddd;
   }
   
   location /222 {
       root /dddd;
   }
   ```

   同样是 /222/xxx/yyy.html，如果是用 root 的配置，会把整个 uri 作为路径拼接在后面。

   也就是会查找 /dddd/222/xxx/yyy.html 文件。

   如果是 alias 配置，它会把去掉 /222 之后的部分路径拼接在后面。

   也就是会查找 /dddd/xxx/yyy.html 文件。

   也就是 我们 **root 和 alias 的区别就是拼接路径时是否包含匹配条件的路径。**

## 反向代理

* 更改nginx配置文件

  ```nginx
  location ^~ /api {
      proxy_pass http://192.168.1.6:3000;
  }
  ```

  代表将/api开头的请求代理到nest服务的地址，^~ 是提高优先级用的。

* 反向代理服务器可以透明的修改请求、响应，例如修改请求头：

  ```nginx
  location ^~ /api {
      proxy_set_header name why;
      proxy_pass http://192.168.1.6:3000;
  }
  ```

## 负载均衡

比如这里启动了两个nest实例一个运行在3001端口一个运行在3002端口。

更改nginx配置文件

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/12/20240612160455.webp)

在 upstream 里配置它代理的目标服务器的所有实例。

下面 proxy_pass 通过 upstream 的名字来指定。

负载均衡的规则默认是轮询的方式。

一共有 4 种负载均衡策略：

- 轮询：默认方式。
- weight：在轮询基础上增加权重，也就是轮询到的几率不同。
- ip_hash：按照 ip 的 hash 分配，保证每个访客的请求固定访问一个服务器，解决 session 问题。
- fair：按照响应时间来分配，这个需要安装 nginx-upstream-fair 插件。

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/12/20240612160513.webp)

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/12/20240612160523.webp)

## 实现灰度系统

软件开发一般不会上来就是最终版本，而是会一个版本一个版本的迭代。

新版本上线前都会经过测试，但就算这样，也不能保证上线了不出问题。

所以，在公司里上线新版本代码一般都是通过灰度系统。

灰度系统可以把流量划分成多份，一份走新版本代码，一份走老版本代码。

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/12/20240612162037.webp)

而且灰度系统支持设置流量的比例，比如可以把走新版本代码的流程设置为 5%，没啥问题再放到 10%，50%，最后放到 100% 全量。

这样可以把出现问题的影响降到最低。

这里启动2个nest服务分别运行在3000和3001端口。

* 修改nginx配置文件

```nginx
location ^~ /api {
    rewrite ^/api/(.*)$ /$1 break;
    proxy_pass http://192.168.1.6:3001;
}
```

用 rewrite 把 url 重写了，比如 /api/xxx 变成了 /xxx。

* 现在需要有多组 upstream：

```nginx
upstream version1.0_server {
    server 192.168.1.6:3000;
}
 
upstream version2.0_server {
    server 192.168.1.6:3001;
}

upstream default {
    server 192.168.1.6:3000;
}
```

有版本 1.0 的、版本 2.0 的，默认的 server 列表。

然后需要根据某个条件来区分转发给哪个服务。

我们这里根据 cookie 来区分：

```nginx
set $group "default";
if ($http_cookie ~* "version=1.0"){
    set $group version1.0_server;
}

if ($http_cookie ~* "version=2.0"){
    set $group version2.0_server;
}

location ^~ /api {
    rewrite ^/api/(.*)$ /$1 break;
    proxy_pass http://$group;
}
```

如果包含 version=1.0 的 cookie，那就走 version1.0_server 的服务，有 version=2.0 的 cookie 就走 version2.0_server 的服务，否则，走默认的。

![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/12/20240612162427.webp)

这样就实现了流量的划分，也就是灰度的功能。

* 但现在还有一个问题：

  什么时候设置的这个 cookie 呢？

  比如我想实现 80% 的流量走版本 1.0，20% 的流量走版本 2.0

  其实公司内部一般都有灰度配置系统，可以配置不同的版本的比例，然后流量经过这个系统之后，就会返回 Set-Cookie 的 header，里面按照比例来分别设置不同的 cookie。

  比如随机数载 0 到 0.2 之间，就设置 version=2.0 的 cookie，否则，设置 version=1.0 的 cookie。

  这也叫做流量染色。

  ![img](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/06/12/20240612162617.webp)

  第一次请求的时候，会按照设定的比例随机对流量染色，也就是设置不同 cookie。

  再次访问的时候会根据 cookie 来走到不同版本的代码。

  其中，后端代码会根据 cookie 标识来请求不同的服务（或者同一个服务走不同的 if else），前端代码可以根据 cookie 判断走哪段逻辑。

  这就实现了灰度功能，可以用来做 5% 10% 50% 100% 这样逐步上线的灰度上线机制。