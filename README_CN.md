[![Version](https://img.shields.io/github/v/tag/longitachi/DGCZLPhotoBrowser.svg?color=blue&include_prereleases=&sort=semver)](https://cocoapods.org/pods/DGCZLPhotoBrowser)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SPM supported](https://img.shields.io/badge/SwiftPM-supported-E57141.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-black)](https://raw.githubusercontent.com/longitachi/DGCZLPhotoBrowser/master/LICENSE)
[![Platform](https://img.shields.io/badge/Platforms-iOS-blue?style=flat)](https://img.shields.io/badge/Platforms-iOS-blue?style=flat)
![Language](https://img.shields.io/badge/Language-%20Swift%20-E57141.svg)
[![Usage](https://img.shields.io/badge/Usage-Doc-yarn?style=flat)](https://github.com/longitachi/DGCZLPhotoBrowser/wiki/How-to-use-(Swift))

![image](https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/preview_with_title.png)

----------------------------------------

[English](https://github.com/longitachi/DGCZLPhotoBrowser/blob/master/README.md) | 简体中文

DGCZLPhotoBrowser是一款微信样式的图片选择器，支持预览/相册内拍照及录视频、拖拽/滑动选择，编辑图片/视频，支持多语言国际化等功能。

## 重要说明
* 框架自 `4.0.0` 版本起，升级为纯`Swift`编写框架，支持最低版本由 `iOS8` 升级到了 `iOS10`
* 添加并增强了一些实用功能（例如图片编辑、预览界面下方小视图显示及拖拽排序等等）
具体使用请下载demo查看

> `Swift` 版本兼容 `oc` app调用；  如需使用之前的`oc`版本（`oc`版本不再维护），请点[这里](https://github.com/longitachi/DGCZLPhotoBrowser-objc)

### 目录
* [功能介绍](#功能介绍)
* [框架支持](#框架支持)
* [使用示例](#使用示例)
* [更新日志](#更新日志)
* [国际化语言](#国际化语言)
* [安装方法(支持Cocoapods/Carthage/SPM安装)](#安装方法)
* [支持](#支持)
* [效果图](#效果图)

`Swift`及`OC`详细使用方法请查看[Wiki](https://github.com/longitachi/DGCZLPhotoBrowser/wiki)

如果你仅想使用图片编辑功能，请移步[ZLImageEditor](https://github.com/longitachi/ZLImageEditor)

### 功能介绍
你想要的应有尽有，部分功能如下，更多功能请查看 `DGCZLPhotoConfiguration` 中的参数定义（没有的话欢迎提 issue ，功能建议好的话会采纳并着手开发）
- [x] 支持SwiftUI
- [x] 支持横竖屏
- [x] 自选框架样式
- [x] 预览快速选择（支持拖拽选择，效果参照QQ）
- [x] 相册内部选择（支持滑动选择）
- [x] 图片/Gif/LivePhoto/Video 混合选择
- [x] 自定义最大预览数/选择数/视频最大最小可选时长，控制可否选择原图
- [x] 自定义每行显示列数
- [x] 图片编辑（涂鸦/裁剪/图片贴纸/文字贴纸/马赛克/滤镜/色值调整(亮度、对比度和饱和度)）（图片编辑可编辑多张；涂鸦/文字颜色可自定义；裁剪比例可自定义；滤镜效果可自定义；编辑工具可根据需要自行选择）
- [x] 视频编辑（自定义最大裁剪时长）（效果参照微信视频编辑；支持编辑本地视频）
- [x] 自定义相机（效果参照微信拍照，点击拍照、长按拍摄；上滑调整焦距；可设置最大/最小录制时间及视频分辨率；可设置闪光灯模式及视频导出格式；可根据自己需要控制是否使用自定义相机）
- [x] 多语言国际化支持（中文简/繁，英文，日文，开发者可选根据系统或自己指定，多语言文案可自定义）
- [x] 已选择照片index
- [x] 已选/不可选 状态下mask阴影遮罩
- [x] 大图界面下方显示已选择照片，可拖拽排序（可根据自己需要控制是否显示）
- [x] 大图界面下拉返回
- [x] 相机内部拍照cell实时显示相机俘获画面
- [x] 可自定义框架字体
- [x] 框架各个部位颜色均可自定义（传入dynamic color即可支持 light/dark mode）
- [x] 框架内图片资源可自定义

> 如果你在使用中有好的需求及建议，或者遇到什么bug，欢迎随时issue，我会及时的回复
 
### 框架支持
 * iOS 10.0
 * Swift 5.x
 * Xcode 12.x
 
### 使用示例
 - 快速选择
 ```
 let ps = DGCZLPhotoPreviewSheet()
 ps.selectImageBlock = { [weak self] results, isOriginal in
     // your code
 }
 ps.showPreview(animate: true, sender: self)
 ```
 
 - 直接进入相册选择
 ```
 let ps = DGCZLPhotoPreviewSheet()
 ps.selectImageBlock = { [weak self] results, isOriginal in
     // your code
 }
 ps.showPhotoLibrary(sender: self)
 ```
 
 - 需要注意的地方，你需要在你app的 `Info.plist` 中添加如下键值对
 ```
 // 如果不添加该键值对，则不支持多语言，相册名称默认为英文
 Localized resources can be mixed YES
 //或者右键plist文件Open As->DGCSource Code 添加
 CFBundleAllowMixedLocalizations
 
 // 相册使用权限描述
 Privacy - Photo Library Usage Description
 // 相机使用权限描述
 Privacy - Camera Usage Description
 // 麦克风使用权限描述
 Privacy - Microphone Usage Description
 ```
 
 
### 更新日志
> [更多更新日志](https://github.com/longitachi/DGCZLPhotoBrowser/blob/master/CHANGELOG.md)
```
● 4.6.0.1
  Add:
    支持SwiftUI。
    自定义相机支持锁定相机拍照/录制的方向。
    优化相册中视频播放体验。
    自定义相机新增播放前回调（will-capture-block），支持用户在拍照前做一些操作。
    使用ZLPhotoPicker平替ZLPhotoPreviewSheet，ZLPhotoPreviewSheet的权限将在后续版本修改为Private。
    增强图片编辑中文字贴纸的功能，新增描边和阴影效果。
  Fix:
    修复自定义相机中单击录制视频时，自动停止录制的时间计算不准确的bug。
    修复预览网络视频时宽高计算不正确的bug。
● 4.5.8
  Add:
    自定义相机支持开启防抖模式。
  Fix:
    修复自定义相机广角模式闪光灯无法开启的bug。
    修复预览网络视频时卡顿的问题。
    修复图片编辑器界面内存泄漏的问题。
    无相册权限时，再次点击相册不再显示引导开启权限弹窗（苹果审核政策要求）。
    修复图片裁剪后，涂鸦橡皮擦工具在涂抹时，UI显示错位的bug。
● 4.5.7
  Add:
    自定义相机支持点击后保持录像模式。
    自定义相机在iOS13以上系统支持广角摄像头。
    自定义相机支持添加自定义遮罩层。
    视频编辑控制器添加取消编辑的回调block。
    新增ZLImagePreviewControllerDelegate协议，接收ZLImagePreviewController中的事件回调。
...
```

### 国际化语言
🇨🇳 中文简/繁, 🇺🇸 英语, 🇯🇵 日语, 🇫🇷 法语, 🇩🇪 德语, 🇷🇺 俄语, 🇻🇳 越南语, 🇰🇷 韩语, 🇲🇾 马来语, 🇮🇹 意大利语, 🇮🇩 印度尼西亚语, 🇪🇸 西班牙语, 🇵🇹 葡萄牙语, 🇹🇷 土耳其语, 🇸🇦 阿拉伯语.

### 安装方法

* Manually 
  * 1.直接把`Sources`文件夹拖入到你的工程中
  
* Cocoapods
  * 1.在Podfile 中添加 `pod 'DGCZLPhotoBrowser'`
  * 2.执行 `pod install`
  > 如找不到最新版本，可首先执行`pod repo update`
  
* Carthage
  * 1.在Cartfile 中添加 `github "longitachi/DGCZLPhotoBrowser" ~> 4.0.0`
  * 2.执行 `$ carthage update`
  > 如果执行时遇到`Building universal frameworks with common architectures is not possible. The device and simulator slices for "DGCZLPhotoBrowser" both build for: arm64
  Rebuild with --use-xcframeworks to create an xcframework bundle instead.`这个错误，点击[这里](https://github.com/Carthage/Carthage/blob/master/Documentation/Xcode12Workaround.md)
  
* Swift Package Manager (该方式集成暂时有问题，图片及多语言资源无法读取，请暂时先用其他方式)
  * 1. 选择 File > Swift Packages > Add Package Dependency，输入 `https://github.com/longitachi/DGCZLPhotoBrowser.git`
  * 2. 输入对应版本号（SPM 最低版本为 `4.0.9`）
  * 3. 等Xcode下载完成后确定即可

### 支持
* 给个[**★ Star**](#)
* 请喝☕️ <img src="https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/ap.png" width = "100" height = "125" /> or <img src="https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/wp.png" width = "100" height = "125" />  or <img src="https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/pp.png" width = "150" height = "125" />

### 效果图
- 选择
![image](https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/%E5%BF%AB%E9%80%9F%E9%80%89%E6%8B%A9.gif)
![image](https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/%E7%9B%B8%E5%86%8C%E5%86%85%E9%83%A8%E9%80%89%E6%8B%A9.gif)
![image](https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/%E9%A2%84%E8%A7%88%E5%A4%A7%E5%9B%BE.gif)

- 编辑图片

![image](https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/editImage.gif)

- 编辑视频

![image](https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/editVideo.gif)

- 多语言

![image](https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/%E5%A4%9A%E8%AF%AD%E8%A8%80.gif)

- 自定义相机介绍

![image](https://github.com/longitachi/ImageFolder/blob/master/DGCZLPhotoBrowser/introduce.png)


