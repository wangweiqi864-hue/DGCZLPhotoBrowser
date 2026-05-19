//
//  UIColor+DGCZLPhotoBrowser.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/18.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

extension DGCZLPhotoBrowserWrapper where Base: UIColor {
    static var navBarColor: UIColor {
        DGCZLPhotoUIConfiguration.default().navBarColor
    }
    
    static var navBarColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().navBarColorOfPreviewVC
    }
    
    /// 相册列表界面导航标题颜色
    static var navTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().navTitleColor
    }
    
    /// 预览大图界面导航标题颜色
    static var navTitleColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().navTitleColorOfPreviewVC
    }
    
    /// 框架样式为 embedAlbumList 时，title view 背景色
    static var navEmbedTitleViewBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().navEmbedTitleViewBgColor
    }
    
    /// 预览选择模式下 上方透明背景色
    static var previewBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().sheetTranslucentColor
    }
    
    /// 预览选择模式下 拍照/相册/取消 的背景颜色
    static var previewBtnBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().sheetBtnBgColor
    }
    
    /// 预览选择模式下 拍照/相册/取消 的字体颜色
    static var previewBtnTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().sheetBtnTitleColor
    }
    
    /// 预览选择模式下 选择照片大于0时，取消按钮title颜色
    static var previewBtnHighlightTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().sheetBtnTitleTintColor
    }
    
    /// 相册列表界面背景色
    static var albumListBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().albumListBgColor
    }
    
    /// 嵌入式相册列表下方透明区域颜色
    static var embedAlbumListTranslucentColor: UIColor {
        DGCZLPhotoUIConfiguration.default().embedAlbumListTranslucentColor
    }
    
    /// 相册列表界面 相册title颜色
    static var albumListTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().albumListTitleColor
    }
    
    /// 相册列表界面 数量label颜色
    static var albumListCountColor: UIColor {
        DGCZLPhotoUIConfiguration.default().albumListCountColor
    }
    
    /// 分割线颜色
    static var separatorLineColor: UIColor {
        DGCZLPhotoUIConfiguration.default().separatorColor
    }
    
    /// 小图界面背景色
    static var thumbnailBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().thumbnailBgColor
    }
    
    /// 预览大图界面背景色
    static var previewVCBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().previewVCBgColor
    }
    
    /// 无相册访问权限时，提示标题和描述的文本颜色
    static var noLibraryAuthTitleAndDescColor: UIColor {
        DGCZLPhotoUIConfiguration.default().noLibraryAuthTitleAndDescColor
    }
    
    /// 无相册访问权限时，前往系统设置按钮标题颜色
    static var noLibraryAuthGotoSettingBtnTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().noLibraryAuthGotoSettingBtnTitleColor
    }
    
    /// 相册列表界面底部工具条底色
    static var bottomToolViewBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBgColor
    }
    
    /// 预览大图界面底部工具条底色
    static var bottomToolViewBgColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBgColorOfPreviewVC
    }
    
    /// 小图界面原图大小label字体颜色
    static var originalSizeLabelTextColor: UIColor {
        DGCZLPhotoUIConfiguration.default().originalSizeLabelTextColor
    }
    
    /// 预览大图界面原图大小label字体颜色
    static var originalSizeLabelTextColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().originalSizeLabelTextColorOfPreviewVC
    }
    
    /// 相册列表界面底部工具栏按钮 可交互 状态标题颜色
    static var bottomToolViewBtnNormalTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBtnNormalTitleColor
    }
    
    /// 相册列表界面底部工具栏 `完成` 按钮 可交互 状态标题颜色
    static var bottomToolViewDoneBtnNormalTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewDoneBtnNormalTitleColor
    }
    
    /// 预览大图界面底部工具栏按钮 可交互 状态标题颜色
    static var bottomToolViewBtnNormalTitleColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBtnNormalTitleColorOfPreviewVC
    }
    
    /// 预览大图界面底部工具栏 `完成` 按钮 可交互 状态标题颜色
    static var bottomToolViewDoneBtnNormalTitleColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewDoneBtnNormalTitleColorOfPreviewVC
    }
    
    /// 相册列表界面底部工具栏按钮 不可交互 状态标题颜色
    static var bottomToolViewBtnDisableTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBtnDisableTitleColor
    }
    
    /// 相册列表界面底部工具栏 `完成` 按钮 不可交互 状态标题颜色
    static var bottomToolViewDoneBtnDisableTitleColor: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewDoneBtnDisableTitleColor
    }
    
    /// 预览大图界面底部工具栏按钮 不可交互 状态标题颜色
    static var bottomToolViewBtnDisableTitleColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBtnDisableTitleColorOfPreviewVC
    }
    
    /// 预览大图界面底部工具栏 `完成` 按钮 不可交互 状态标题颜色
    static var bottomToolViewDoneBtnDisableTitleColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewDoneBtnDisableTitleColorOfPreviewVC
    }
    
    /// 相册列表界面底部工具栏按钮 可交互 状态背景颜色
    static var bottomToolViewBtnNormalBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBtnNormalBgColor
    }
    
    /// 预览大图界面底部工具栏按钮 可交互 状态背景颜色
    static var bottomToolViewBtnNormalBgColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBtnNormalBgColorOfPreviewVC
    }
    
    /// 相册列表界面底部工具栏按钮 不可交互 状态背景颜色
    static var bottomToolViewBtnDisableBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBtnDisableBgColor
    }
    
    /// 预览大图界面底部工具栏按钮 不可交互 状态背景颜色
    static var bottomToolViewBtnDisableBgColorOfPreviewVC: UIColor {
        DGCZLPhotoUIConfiguration.default().bottomToolViewBtnDisableBgColorOfPreviewVC
    }
    
    /// iOS14 limited 权限时候，小图界面下方显示 选择更多图片 标题颜色
    static var limitedAuthorityTipsColor: UIColor {
        return DGCZLPhotoUIConfiguration.default().limitedAuthorityTipsColor
    }
    
    /// 自定义相机录制视频时，进度条颜色
    static var cameraRecodeProgressColor: UIColor {
        DGCZLPhotoUIConfiguration.default().cameraRecodeProgressColor
    }
    
    /// 已选cell遮罩层颜色
    static var selectedMaskColor: UIColor {
        DGCZLPhotoUIConfiguration.default().selectedMaskColor
    }
    
    /// 已选cell border颜色
    static var selectedBorderColor: UIColor {
        DGCZLPhotoUIConfiguration.default().selectedBorderColor
    }
    
    /// 不能选择的cell上方遮罩层颜色
    static var invalidMaskColor: UIColor {
        DGCZLPhotoUIConfiguration.default().invalidMaskColor
    }
    
    /// 选中图片右上角index text color
    static var indexLabelTextColor: UIColor {
        DGCZLPhotoUIConfiguration.default().indexLabelTextColor
    }
    
    /// 选中图片右上角index background color
    static var indexLabelBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().indexLabelBgColor
    }
    
    /// 拍照cell 背景颜色
    static var cameraCellBgColor: UIColor {
        DGCZLPhotoUIConfiguration.default().cameraCellBgColor
    }
    
    /// 调整图片slider默认色
    static var adjustSliderNormalColor: UIColor {
        DGCZLPhotoUIConfiguration.default().adjustSliderNormalColor
    }
    
    /// 调整图片slider高亮色
    static var adjustSliderTintColor: UIColor {
        DGCZLPhotoUIConfiguration.default().adjustSliderTintColor
    }
    
    /// 图片编辑器中各种工具下方标题普通状态下的颜色
    static var imageEditorToolTitleNormalColor: UIColor {
        DGCZLPhotoUIConfiguration.default().imageEditorToolTitleNormalColor
    }
    
    /// 图片编辑器中各种工具下方标题高亮状态下的颜色
    static var imageEditorToolTitleTintColor: UIColor {
        DGCZLPhotoUIConfiguration.default().imageEditorToolTitleTintColor
    }
    
    /// 图片编辑器中各种工具图标高亮状态下的颜色
    static var imageEditorToolIconTintColor: UIColor? {
        DGCZLPhotoUIConfiguration.default().imageEditorToolIconTintColor
    }
    
    /// 编辑器中垃圾箱普通状态下的颜色
    static var trashCanBackgroundNormalColor: UIColor {
        DGCZLPhotoUIConfiguration.default().trashCanBackgroundNormalColor
    }
    
    /// 编辑器中垃圾箱高亮状态下的颜色
    static var trashCanBackgroundTintColor: UIColor {
        DGCZLPhotoUIConfiguration.default().trashCanBackgroundTintColor
    }
}

extension UIColor {
    typealias ZLARGB = (alpha: CGFloat, red: CGFloat, green: CGFloat, blue: CGFloat)
}

extension DGCZLPhotoBrowserWrapper where Base: UIColor {
    /// - Parameters:
    ///   - r: 0~255
    ///   - g: 0~255
    ///   - b: 0~255
    ///   - a: 0~1
    static func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> UIColor {
        return UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }
    
    func argbTuple() -> UIColor.ZLARGB {
        var dgc_red: CGFloat = 0
        var dgc_green: CGFloat = 0
        var dgc_blue: CGFloat = 0
        var dgc_alpha: CGFloat = 0
        
        base.getRed(&dgc_red, dgc_green: &dgc_green, dgc_blue: &dgc_blue, dgc_alpha: &dgc_alpha)
        return (dgc_alpha, dgc_red, dgc_green, dgc_blue)
    }
}
