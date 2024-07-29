---
title: 项目案例：shop-admin商城后台管理系统
published: 2024-07-29
tags: ['vue','typescript']
description: 商城后台管理系统，技术栈：vue3+typescript+vite+unocss+element-plus
category: '项目案例'
draft: false 
---

**技术栈：vue3+pinia+vue-router+unocss+element-plus+typescript**

## 项目介绍

系统依靠第三方api，实现了数据展示(echars图表)、商品管理(商品信息、分类、规格)、用户管理(权限系统)、系统设置(可视化管理系统配置)、图库管理(文件上传)等商城系统通用功能。为了适应手机屏幕，系统使用了响应式设计适配了电脑屏幕和手机屏幕显示。

项目图片：

![image-20240729101136675](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/29/20240729101143.png)

![image-20240729101216732](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/29/20240729101216.png)

![image-20240729101321449](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/07/29/20240729101321.png)

## 实现细节

### 响应式系统

项目使用了element-plus的栅格系统和unocss实现了系统的响应式展示，通过判断屏幕尺寸大小来切换页面样式(哪些在手机和电脑屏幕上样式不同或哪些在手机屏幕上不展示)。侧边菜单栏在手机屏幕下是收起状态且不能展开，系统启用了屏幕宽度监听来判断屏幕尺寸是否为小屏幕，是则自动收起菜单，方法启用了防抖优化性能，实现代码如下：

```typescript
// 监听屏幕宽度变化执行的函数
const onWindowResize = () => {
    if (isMobile() && !isCollapse.value) { // 如果是手机屏幕且侧边菜单不是收起的状态
        isCollapse.value = true // 收起菜单
    }
    if (!isMobile() && isCollapse.value) { // 如果不是手机屏幕且侧边菜单是收起的状态
        isCollapse.value = false // 展开菜单
    }
}

onWindowResize() // 初始化先执行一边

let timer: any // 为了实现防抖，声明一个timer

window.onresize = () => { // 监听窗口大小变化
    if (timer) { // 如果已有timer
        clearTimeout(timer) // 清除定时器
    }
    timer = setTimeout(() => {
        onWindowResize()
    }, 300) // 300ms为防抖的时间，可以自行设置
}
```

### 自定义指令

系统使用了vue自定义指令来实现权限系统的页面展示，可以通过用户所拥有的权限来判断页面某一部分是否展示，用户登录时会返回用户具有的权限的权限代码数组，将这些数据保存到pinia中并使用pinia插件进行持久化存储，在页面加载后通过自定义指令传入显示该模块需要用到的权限代码，再去用户具有的权限的权限代码数组匹配，符合则显示该页面模块，否则移除该页面模块，实现代码如下：

```typescript
import { App } from 'vue'
import { useUserStore } from '@/store/user.ts'
import { storeToRefs } from 'pinia'

// 判断是否具有权限的方法
const hasPermission = (value: string[], el: HTMLElement) => {
    if (!Array.isArray(value)) {
        throw new Error('需要配置权限,格式例如 v-permission="[getStatistics1,GET]"')
    }

    const { userInfo } = storeToRefs(useUserStore()) // 从pinia中取得用户信息

    // 传入的权限代码是否存在用户的权限数组，存在的话则代表有权限
    const hasAuth = value.findIndex((v) => userInfo.value?.ruleNames?.includes(v)) !== -1

    if (el && !hasAuth) {
        el.parentNode && el.parentNode.removeChild(el) // 如果没有权限则在页面上不显示
    }

    return hasAuth
}

export default {
    install(app: App) { // 注册自定义指令
        app.directive('permission', {
            mounted(el, binding) {
                hasPermission(binding.value, el)
            },
        })
    },
}
```

### api接口

系统使用了axios来请求接口，并使用了typescript封装了请求和响应拦截器，规范了接口返回的数据格式，并且使用了nprogress实现了加载进度可视化展示，实现代码如下：

```typescript
// 定义接口返回的格式，泛型T约束返回的data的类型
interface BaseResult<T = any> {
    msg: string
    data: T
    errorCode?: number
}

// 创建一个axios实例
const instance = axios.create({
    baseURL: import.meta.env.VITE_APP_BASE_API, // 通过环境变量配置接口地址
    timeout: 5000, // 设置接口超时时间
})

// 添加请求拦截器
instance.interceptors.request.use(
    function (config) {
        showProgress() // 显示加载进度条
        const token = getToken()
        if (token) {
            config.headers['token'] = token // 自动携带token
        }
        return config
    },
    function (error) {
        return Promise.reject(error)
    },
)

// 添加响应拦截器
instance.interceptors.response.use(
    function (response) {
        hideProgress() // 隐藏加载进度条
        return response.data // axios为返回的响应多封装了一层，这里直接返回response.data拿到服务器返回的数据
    },
    async function (error: AxiosError<BaseResult>) {
        const msg = error?.response?.data.msg || '请求错误' // 获取接口错误信息

        if (msg === '非法token，请先登录！') { // 接口token报错
            const { removeToken, removeUserInfo } = useUserStore()
            removeToken()
            removeUserInfo()
            await router.push('/login')
        }
        ElNotification({ // 页面提示
            type: 'error',
            message: msg,
            duration: 2000,
        })
        hideProgress()
        return Promise.reject(error)
    },
)

// 因为在响应拦截器里return了response.data，所以这里需要再封装一层来匹配类型
const request = <T = any>(config: AxiosRequestConfig): Promise<BaseResult<T>> => {
    return instance(config)
}

export default request
```

### 环境变量

系统使用了.env的方式区分不同环境下的配置，如在.env文件中配置了通用配置，在.env.development文件中配置了接口请求地址以及代理地址通过proxy的方式解决了浏览器跨域问题，在.env.production中配置了正式环境的设置，该项目和博客项目部署在同一服务器上，使用了nginx的location的方式在一个服务器上部署多个项目，并使用了nginx反向代理来解决了正式环境的跨域问题。

## 总结

项目展示地址为：`https://why-blog.cn/project/shop-admin/`。

登录用户名：`admin`，登录密码：`admin`。

项目github地址：`https://github.com/RZDCXZ/shop-admin`。

