---
title: 项目案例：uniappx-community社区交友平台
published: 2024-08-14
tags: ['uniappx']
description: 使用uniappx打包安卓apk社区交友平台
category: '项目案例'
draft: false 
---

## 项目介绍

uniappx目前只能稳定打包安卓apk，该项目实现了安卓app的登录注册、发帖评论、点赞关注、socket私信等功能。

项目图片：

![image-20240814154155171](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/08/14/20240814154155.png)

![image-20240814154142978](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/08/14/20240814154143.png)

![image-20240814154206305](https://raw.githubusercontent.com/RZDCXZ/blog-img/main/2024/08/14/20240814154206.png)

## 实现细节

### 话题详情页渐变式导航栏

话题详情页头部有一张背景图，导航栏会会随着页面向下滚动而吸顶，并且随着背景图高度的滚动成比例的改变颜色透明度，从而实现渐变式的导航视觉效果，增加用户体验，实现代码如下：

```javascript
handleScroll(e:UniScrollEvent){
				const scrollTop = e.detail.scrollTop // 获取滚动的高度
				this.currentScrollTop = scrollTop
				// 渐变导航栏初始透明度
				const colorStart = 0.8
				const colorEnd = 0
				
				// 第一个渐变色透明度变化
				let colorStartChange = 1 - (1-colorStart)/this.$headerHeight * (this.$headerHeight - scrollTop)
				if(colorStartChange > 1){
					colorStartChange = 1
				}
				
				// 第二个渐变色透明度变化
				let colorEndChange = 1 - (1-colorEnd)/this.$headerHeight * (this.$headerHeight - scrollTop)
				if(colorEndChange > 1){
					colorEndChange = 1
				}
				
				// 控制导航栏渐变色变化
				this.$navbarView?.style?.setProperty("background-image",`linear-gradient(to bottom,rgba(255,255,255,${colorStartChange}),rgba(255,255,255,${colorEndChange}))`)
				
				// 控制标题显示
				this.$navbarTitle?.style?.setProperty("opacity",colorEndChange == 1 ? 1 : 0)
				
			}
```

### 多页面缓存数据同步

为了实现在一个页面点赞一个帖子，其他涉及到展示该帖子的页面也自动同步点赞，使用全局总线通知，`uni.$emit`方法会发起全局总线通知，当用户操作后可调用此方法，第一个参数传用户操作的key用来区分进行了什么操作，第二个参数为携带的数据，然后在想要同步的页面使用`uni.$on`方法监听`uni.$emit`的通知，从而实现同步操作。

### 绘制骨架屏

页面展示中为了防止页面加载慢白屏会使用骨架屏，涉及到页面优化，由于使用dom绘制骨架屏会增加dom数量印象性能，所以这里使用画布的方式展示骨架屏，实现代码如下：

```javascript
draw(ctx: DrawableContext , start: number) {
				// 屏幕宽度
				const screenWidth = this.screenWidth
				// 左右间隔
				const p = uni.rpx2px(30)
				// 骨架屏颜色
				ctx.fillStyle = "#f0f0f0"
				
				// 头像
				// 创建空白路径
				ctx.beginPath()
				// 绘制一段弧线
				ctx.arc(p + 20, start + 35, 20, 0,2*Math.PI, false)
				// 填充
				ctx.fill()
				
				// 昵称
				// 设置线条宽度
				ctx.lineWidth = 15
				// 线条末端圆角
				ctx.lineCap = "round"
				// 创建空白路径
				ctx.beginPath()
				// 移动到(x,y)坐标
				ctx.moveTo(p + 60,start + 35)
				// 将路径最后一点连接到（x,y）坐标
				ctx.lineTo(p + 110,start + 35)
				// 填充
				ctx.stroke()
				
				// 关注
				ctx.beginPath()
				// 移动到(x,y)坐标
				ctx.moveTo(p + screenWidth - 16 - 50 ,start + 35)
				// 将路径最后一点连接到（x,y）坐标
				ctx.lineTo(p + screenWidth - 16 - 25 ,start + 35)
				// 填充
				ctx.stroke()
				
				// 标题
				ctx.beginPath()
				// 移动到(x,y)坐标
				ctx.moveTo(p + 10 ,start + 80)
				// 将路径最后一点连接到（x,y）坐标
				ctx.lineTo(screenWidth - 2*p + 10 ,start + 80)
				// 填充
				ctx.stroke()
				
				// 图片
				// 绘制一个实心矩形
				ctx.fillRect(0,start + 100, screenWidth,290)
				
				// 描述
				ctx.beginPath()
				// 移动到(x,y)坐标
				ctx.moveTo(p + 10 ,start + 410)
				// 将路径最后一点连接到（x,y）坐标
				ctx.lineTo(screenWidth - 2*p + 10 ,start + 410)
				// 填充
				ctx.stroke()

				ctx.beginPath()
				// 移动到(x,y)坐标
				ctx.moveTo(p + 10 ,start + 435)
				// 将路径最后一点连接到（x,y）坐标
				ctx.lineTo(screenWidth - 2*p + 10 ,start + 435)
				// 填充
				ctx.stroke()
				
				ctx.beginPath()
				// 移动到(x,y)坐标
				ctx.moveTo(p + 10 ,start + 460)
				// 将路径最后一点连接到（x,y）坐标
				ctx.lineTo(screenWidth - 100 ,start + 460)
				// 填充
				ctx.stroke()
				
				// 分割线
				ctx.lineWidth = 10
				ctx.lineCap = "butt"
				ctx.beginPath()
				// 移动到(x,y)坐标
				ctx.moveTo(0 ,start + 485)
				// 将路径最后一点连接到（x,y）坐标
				ctx.lineTo(screenWidth,start + 485)
				// 填充
				ctx.stroke()
			}
```

## 总结

app已打包上传到服务器，访问该链接下载安装包：`https://why-blog.cn/download/uniappx-community.apk`

请使用安卓手机安装体验。