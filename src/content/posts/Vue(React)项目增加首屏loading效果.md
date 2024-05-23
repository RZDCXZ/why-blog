---
title: 'Vue(React)项目增加首屏loading效果'
published: 2024-05-23
tags: ['vue', 'react']
category: 技术
draft: false
---

当项目比较大时，在首次进入项目的时候由于需要耗时加载文件，首屏会出现白屏的现象影响用户体验，所以在加载的过程中引入加载动画就很有必要了。

## 创建项目

这里以`vue`项目为例，首先使用`vite`初始化一个项目`npm init vite@latest`。

## 编写HTML

项目的根目录下有index.html文件，在id为app（react项目是id为root）的div标签中写入html

```html
<div class="root-loading">
    <div class="root-loading-wrap">
        <div id="root-loading-animation">
            <span></span>
            <span></span>
            <span></span>
            <span></span>
            <span></span>
        </div>
    </div>
</div>
```

## 编写CSS样式

同样在index.html中的style标签中写入加载的`css`样式，如下实例，若想要不同的加载动画，只需要更改html和css样式即可

```css
<style>
.root-loading {
    display: flex;
    width: 100%;
    height: 100%;
    justify-content: center;
    align-items: center;
    flex-direction: column;
    background: #f4f7f9;
}

.root-loading .root-loading-wrap {
    position: absolute;
    top: 50%;
    left: 50%;
    display: flex;
    -webkit-transform: translate3d(-50%, -50%, 0);
    transform: translate3d(-50%, -50%, 0);
    justify-content: center;
    align-items: center;
    flex-direction: column;
}

.root-loading .root-loading-title {
    display: flex;
    width: 100px;
    margin-top: 40px;
    font-size: 30px;
    color: rgba(0, 0, 0, 0.85);
    justify-content: center;
    align-items: center;
}

#root-loading-animation {
    position: relative;
    width: 100%;
}

#root-loading-animation span {
    position: absolute;
    width: 20px;
    height: 20px;
    background: #0c89ff;
    border-radius: 20px;
    opacity: 0.5;
    animation: app-loading-animation 1s infinite ease-in-out;
}

#root-loading-animation span:nth-child(2) {
    left: 20px;
    animation-delay: 0.2s;
}

#root-loading-animation span:nth-child(3) {
    left: 40px;
    animation-delay: 0.4s;
}

#root-loading-animation span:nth-child(4) {
    left: 60px;
    animation-delay: 0.6s;
}

#root-loading-animation span:nth-child(5) {
    left: 80px;
    animation-delay: 0.8s;
}
@keyframes app-loading-animation {
    0% {
        opacity: 0.3;
        transform: translateY(0);
        box-shadow: 0 0 3px rgba(0, 0, 0, 0.1);
    }

    50% {
        background: #688cfd;
        opacity: 1;
        transform: translateY(-10px);
        box-shadow: 0 20px 3px rgba(0, 0, 0, 0.05);
    }

    100% {
        opacity: 0.3;
        transform: translateY(0);
        box-shadow: 0 0 3px rgba(0, 0, 0, 0.1);
    }
}
</style>
```

## 总结

由于加载代码是直接写在index.html文件中的，所以当用户打开项目时首先看到的就是加载动画，然后由于main.js程序的主文件中会将页面mount到#app（react项目为#root）的标签下，所以页面就将loading替换掉了，这样就实现了加载效果。