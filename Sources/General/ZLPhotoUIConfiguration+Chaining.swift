//
//  DGCZLPhotoUIConfiguration+Chaining.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2022/4/19.
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

// MARK: chaining

public extension DGCZLPhotoUIConfiguration {
    @discardableResult
    func sortAscending(_ ascending: Bool) -> DGCZLPhotoUIConfiguration {
        sortAscending = ascending
        return self
    }
    
    @discardableResult
    func style(_ style: DGCZLPhotoBrowserStyle) -> DGCZLPhotoUIConfiguration {
        self.style = style
        return self
    }
    
    @discardableResult
    func statusBarStyle(_ statusBarStyle: UIStatusBarStyle) -> DGCZLPhotoUIConfiguration {
        self.statusBarStyle = statusBarStyle
        return self
    }
    
    @discardableResult
    func navCancelButtonStyle(_ style: DGCZLPhotoUIConfiguration.DGCCancelButtonStyle) -> DGCZLPhotoUIConfiguration {
        navCancelButtonStyle = style
        return self
    }
    
    @discardableResult
    func showStatusBarInPreviewInterface(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showStatusBarInPreviewInterface = value
        return self
    }
    
    @discardableResult
    func hudStyle(_ style: DGCZLProgressHUD.DGCStyle) -> DGCZLPhotoUIConfiguration {
        hudStyle = style
        return self
    }
    
    @discardableResult
    func adjustSliderType(_ type: DGCZLAdjustSliderType) -> DGCZLPhotoUIConfiguration {
        adjustSliderType = type
        return self
    }
    
    @discardableResult
    func cellCornerRadio(_ cornerRadio: CGFloat) -> DGCZLPhotoUIConfiguration {
        cellCornerRadio = cornerRadio
        return self
    }
    
    @discardableResult
    func customAlertClass(_ alertClass: DGCZLCustomAlertProtocol.Type?) -> DGCZLPhotoUIConfiguration {
        customAlertClass = alertClass
        return self
    }
    
    /// - Note: This property is ignored when using columnCountBlock.
    @discardableResult
    func columnCount(_ count: Int) -> DGCZLPhotoUIConfiguration {
        columnCount = count
        return self
    }
    
    @discardableResult
    func columnCountBlock(_ block: ((_ collectionViewWidth: CGFloat) -> Int)?) -> DGCZLPhotoUIConfiguration {
        columnCountBlock = block
        return self
    }
    
    @discardableResult
    func minimumInteritemSpacing(_ value: CGFloat) -> DGCZLPhotoUIConfiguration {
        minimumInteritemSpacing = value
        return self
    }
    
    @discardableResult
    func minimumLineSpacing(_ value: CGFloat) -> DGCZLPhotoUIConfiguration {
        minimumLineSpacing = value
        return self
    }
    
    @discardableResult
    func animateSelectBtnWhenSelectInThumbVC(_ animate: Bool) -> DGCZLPhotoUIConfiguration {
        animateSelectBtnWhenSelectInThumbVC = animate
        return self
    }
    
    @discardableResult
    func animateSelectBtnWhenSelectInPreviewVC(_ animate: Bool) -> DGCZLPhotoUIConfiguration {
        animateSelectBtnWhenSelectInPreviewVC = animate
        return self
    }
    
    @discardableResult
    func selectBtnAnimationDuration(_ duration: CFTimeInterval) -> DGCZLPhotoUIConfiguration {
        selectBtnAnimationDuration = duration
        return self
    }
    
    @discardableResult
    func showIndexOnSelectBtn(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showIndexOnSelectBtn = value
        return self
    }
    
    @discardableResult
    func showScrollToBottomBtn(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showScrollToBottomBtn = value
        return self
    }
    
    @discardableResult
    func showCaptureImageOnTakePhotoBtn(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showCaptureImageOnTakePhotoBtn = value
        return self
    }
    
    @discardableResult
    func showSelectedMask(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showSelectedMask = value
        return self
    }
    
    @discardableResult
    func showSelectedBorder(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showSelectedBorder = value
        return self
    }
    
    @discardableResult
    func showInvalidMask(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showInvalidMask = value
        return self
    }
    
    @discardableResult
    func showSelectedPhotoPreview(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showSelectedPhotoPreview = value
        return self
    }
    
    @discardableResult
    func showAddPhotoButton(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showAddPhotoButton = value
        return self
    }
    
    @discardableResult
    func showEnterSettingTips(_ value: Bool) -> DGCZLPhotoUIConfiguration {
        showEnterSettingTips = value
        return self
    }
    
    @discardableResult
    func timeout(_ timeout: TimeInterval) -> DGCZLPhotoUIConfiguration {
        self.timeout = timeout
        return self
    }
    
    @discardableResult
    func navViewBlurEffectOfAlbumList(_ effect: UIBlurEffect?) -> DGCZLPhotoUIConfiguration {
        navViewBlurEffectOfAlbumList = effect
        return self
    }
    
    @discardableResult
    func navViewBlurEffectOfPreview(_ effect: UIBlurEffect?) -> DGCZLPhotoUIConfiguration {
        navViewBlurEffectOfPreview = effect
        return self
    }
    
    @discardableResult
    func bottomViewBlurEffectOfAlbumList(_ effect: UIBlurEffect?) -> DGCZLPhotoUIConfiguration {
        bottomViewBlurEffectOfAlbumList = effect
        return self
    }
    
    @discardableResult
    func bottomViewBlurEffectOfPreview(_ effect: UIBlurEffect?) -> DGCZLPhotoUIConfiguration {
        bottomViewBlurEffectOfPreview = effect
        return self
    }
    
    @discardableResult
    func customImageNames(_ names: [String]) -> DGCZLPhotoUIConfiguration {
        customImageNames = names
        return self
    }
    
    @discardableResult
    func customImageForKey(_ map: [String: UIImage?]) -> DGCZLPhotoUIConfiguration {
        customImageForKey = map
        return self
    }
    
    @discardableResult
    func languageType(_ type: DGCZLLanguageType) -> DGCZLPhotoUIConfiguration {
        languageType = type
        return self
    }
    
    @discardableResult
    func customLanguageKeyValue(_ map: [DGCZLLocalLanguageKey: String]) -> DGCZLPhotoUIConfiguration {
        customLanguageKeyValue = map
        return self
    }
    
    @discardableResult
    func themeFontName(_ name: String) -> DGCZLPhotoUIConfiguration {
        themeFontName = name
        return self
    }
    
    @discardableResult
    func themeColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        themeColor = color
        return self
    }
    
    @discardableResult
    func sheetTranslucentColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        sheetTranslucentColor = color
        return self
    }
    
    @discardableResult
    func sheetBtnBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        sheetBtnBgColor = color
        return self
    }
    
    @discardableResult
    func sheetBtnTitleColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        sheetBtnTitleColor = color
        return self
    }
    
    @discardableResult
    func sheetBtnTitleTintColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        sheetBtnTitleTintColor = color
        return self
    }
    
    @discardableResult
    func navBarColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        navBarColor = color
        return self
    }
    
    @discardableResult
    func navBarColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        navBarColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func navTitleColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        navTitleColor = color
        return self
    }
    
    @discardableResult
    func navTitleColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        navTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func navEmbedTitleViewBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        navEmbedTitleViewBgColor = color
        return self
    }
    
    @discardableResult
    func albumListBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        albumListBgColor = color
        return self
    }
    
    @discardableResult
    func embedAlbumListTranslucentColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        embedAlbumListTranslucentColor = color
        return self
    }
    
    @discardableResult
    func albumListTitleColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        albumListTitleColor = color
        return self
    }
    
    @discardableResult
    func albumListCountColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        albumListCountColor = color
        return self
    }
    
    @discardableResult
    func separatorColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        separatorColor = color
        return self
    }
    
    @discardableResult
    func thumbnailBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        thumbnailBgColor = color
        return self
    }
    
    @discardableResult
    func previewVCBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        previewVCBgColor = color
        return self
    }
    
    @discardableResult
    func noLibraryAuthTitleAndDescColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        noLibraryAuthTitleAndDescColor = color
        return self
    }
    
    @discardableResult
    func noLibraryAuthGotoSettingBtnTitleColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        noLibraryAuthGotoSettingBtnTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBgColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBgColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBgColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func originalSizeLabelTextColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        originalSizeLabelTextColor = color
        return self
    }
    
    @discardableResult
    func originalSizeLabelTextColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        originalSizeLabelTextColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnNormalTitleColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBtnNormalTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewDoneBtnNormalTitleColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewDoneBtnNormalTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnNormalTitleColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBtnNormalTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewDoneBtnNormalTitleColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewDoneBtnNormalTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnDisableTitleColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBtnDisableTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewDoneBtnDisableTitleColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewDoneBtnDisableTitleColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnDisableTitleColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBtnDisableTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewDoneBtnDisableTitleColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewDoneBtnDisableTitleColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnNormalBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBtnNormalBgColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnNormalBgColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBtnNormalBgColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnDisableBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBtnDisableBgColor = color
        return self
    }
    
    @discardableResult
    func bottomToolViewBtnDisableBgColorOfPreviewVC(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        bottomToolViewBtnDisableBgColorOfPreviewVC = color
        return self
    }
    
    @discardableResult
    func limitedAuthorityTipsColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        limitedAuthorityTipsColor = color
        return self
    }
    
    @discardableResult
    func cameraRecodeProgressColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        cameraRecodeProgressColor = color
        return self
    }
    
    @discardableResult
    func selectedMaskColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        selectedMaskColor = color
        return self
    }
    
    @discardableResult
    func selectedBorderColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        selectedBorderColor = color
        return self
    }
    
    @discardableResult
    func invalidMaskColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        invalidMaskColor = color
        return self
    }
    
    @discardableResult
    func indexLabelTextColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        indexLabelTextColor = color
        return self
    }
    
    @discardableResult
    func indexLabelBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        indexLabelBgColor = color
        return self
    }
    
    @discardableResult
    func cameraCellBgColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        cameraCellBgColor = color
        return self
    }
    
    @discardableResult
    func adjustSliderNormalColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        adjustSliderNormalColor = color
        return self
    }
    
    @discardableResult
    func adjustSliderTintColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        adjustSliderTintColor = color
        return self
    }
    
    @discardableResult
    func imageEditorToolTitleNormalColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        imageEditorToolTitleNormalColor = color
        return self
    }
    
    @discardableResult
    func imageEditorToolTitleTintColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        imageEditorToolTitleTintColor = color
        return self
    }
    
    @discardableResult
    func imageEditorToolIconTintColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        imageEditorToolIconTintColor = color
        return self
    }
    
    @discardableResult
    func trashCanBackgroundNormalColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        trashCanBackgroundNormalColor = color
        return self
    }
    
    @discardableResult
    func trashCanBackgroundTintColor(_ color: UIColor) -> DGCZLPhotoUIConfiguration {
        trashCanBackgroundTintColor = color
        return self
    }
}
