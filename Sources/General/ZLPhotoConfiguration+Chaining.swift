//
//  DGCZLPhotoConfiguration+Chaining.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2021/11/1.
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
import Photos

public extension DGCZLPhotoConfiguration {
    @discardableResult
    func maxSelectCount(_ count: Int) -> DGCZLPhotoConfiguration {
        maxSelectCount = count
        return self
    }
    
    @discardableResult
    func maxVideoSelectCount(_ count: Int) -> DGCZLPhotoConfiguration {
        maxVideoSelectCount = count
        return self
    }
    
    @discardableResult
    func minVideoSelectCount(_ count: Int) -> DGCZLPhotoConfiguration {
        minVideoSelectCount = count
        return self
    }
    
    @discardableResult
    func allowMixSelect(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowMixSelect = value
        return self
    }
    
    @discardableResult
    func maxPreviewCount(_ count: Int) -> DGCZLPhotoConfiguration {
        maxPreviewCount = count
        return self
    }
    
    @discardableResult
    func initialIndex(_ index: Int) -> DGCZLPhotoConfiguration {
        initialIndex = index
        return self
    }
    
    @discardableResult
    func allowSelectImage(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowSelectImage = value
        return self
    }
    
    @discardableResult
    @objc func allowSelectVideo(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowSelectVideo = value
        return self
    }
    
    @discardableResult
    @objc func downloadVideoBeforeSelecting(_ value: Bool) -> DGCZLPhotoConfiguration {
        downloadVideoBeforeSelecting = value
        return self
    }
    
    @discardableResult
    func allowSelectGif(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowSelectGif = value
        return self
    }
    
    @discardableResult
    func allowSelectLivePhoto(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowSelectLivePhoto = value
        return self
    }
    
    @discardableResult
    func allowTakePhotoInLibrary(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowTakePhotoInLibrary = value
        return self
    }
    
    @discardableResult
    func callbackDirectlyAfterTakingPhoto(_ value: Bool) -> DGCZLPhotoConfiguration {
        callbackDirectlyAfterTakingPhoto = value
        return self
    }
    
    @discardableResult
    func allowEditImage(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowEditImage = value
        return self
    }
    
    @discardableResult
    func allowEditVideo(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowEditVideo = value
        return self
    }
    
    @discardableResult
    func editAfterSelectThumbnailImage(_ value: Bool) -> DGCZLPhotoConfiguration {
        editAfterSelectThumbnailImage = value
        return self
    }
    
    @discardableResult
    func cropVideoAfterSelectThumbnail(_ value: Bool) -> DGCZLPhotoConfiguration {
        cropVideoAfterSelectThumbnail = value
        return self
    }
    
    @discardableResult
    func saveNewImageAfterEdit(_ value: Bool) -> DGCZLPhotoConfiguration {
        saveNewImageAfterEdit = value
        return self
    }
    
    @discardableResult
    func allowSlideSelect(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowSlideSelect = value
        return self
    }
    
    @discardableResult
    func autoScrollWhenSlideSelectIsActive(_ value: Bool) -> DGCZLPhotoConfiguration {
        autoScrollWhenSlideSelectIsActive = value
        return self
    }
    
    @discardableResult
    func autoScrollMaxSpeed(_ speed: CGFloat) -> DGCZLPhotoConfiguration {
        autoScrollMaxSpeed = speed
        return self
    }
    
    @discardableResult
    func allowDragSelect(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowDragSelect = value
        return self
    }
    
    @discardableResult
    func allowSelectOriginal(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowSelectOriginal = value
        return self
    }
    
    @discardableResult
    func alwaysRequestOriginal(_ value: Bool) -> DGCZLPhotoConfiguration {
        alwaysRequestOriginal = value
        return self
    }
    
    @discardableResult
    func allowPreviewPhotos(_ value: Bool) -> DGCZLPhotoConfiguration {
        allowPreviewPhotos = value
        return self
    }
    
    @discardableResult
    func showPreviewButtonInAlbum(_ value: Bool) -> DGCZLPhotoConfiguration {
        showPreviewButtonInAlbum = value
        return self
    }
    
    @discardableResult
    func showSelectCountOnDoneBtn(_ value: Bool) -> DGCZLPhotoConfiguration {
        showSelectCountOnDoneBtn = value
        return self
    }
    
    @discardableResult
    func showSelectBtnWhenSingleSelect(_ value: Bool) -> DGCZLPhotoConfiguration {
        showSelectBtnWhenSingleSelect = value
        return self
    }
    
    @discardableResult
    func showSelectedIndex(_ value: Bool) -> DGCZLPhotoConfiguration {
        showSelectedIndex = value
        return self
    }
    
    @discardableResult
    func maxEditVideoTime(_ second: Second) -> DGCZLPhotoConfiguration {
        maxEditVideoTime = second
        return self
    }
    
    @discardableResult
    func maxSelectVideoDuration(_ duration: Second) -> DGCZLPhotoConfiguration {
        maxSelectVideoDuration = duration
        return self
    }
    
    @discardableResult
    func minSelectVideoDuration(_ duration: Second) -> DGCZLPhotoConfiguration {
        minSelectVideoDuration = duration
        return self
    }
    
    @discardableResult
    func maxSelectVideoDataSize(_ size: DGCZLPhotoConfiguration.KBUnit) -> DGCZLPhotoConfiguration {
        maxSelectVideoDataSize = size
        return self
    }
    
    @discardableResult
    func minSelectVideoDataSize(_ size: DGCZLPhotoConfiguration.KBUnit) -> DGCZLPhotoConfiguration {
        minSelectVideoDataSize = size
        return self
    }
    
    @discardableResult
    func editImageConfiguration(_ configuration: DGCZLEditImageConfiguration) -> DGCZLPhotoConfiguration {
        editImageConfiguration = configuration
        return self
    }
    
    @discardableResult
    func useCustomCamera(_ value: Bool) -> DGCZLPhotoConfiguration {
        useCustomCamera = value
        return self
    }
    
    @discardableResult
    func cameraConfiguration(_ configuration: DGCZLCameraConfiguration) -> DGCZLPhotoConfiguration {
        cameraConfiguration = configuration
        return self
    }
    
    @discardableResult
    func canSelectAsset(_ block: ((PHAsset) -> Bool)?) -> DGCZLPhotoConfiguration {
        canSelectAsset = block
        return self
    }
    
    @discardableResult
    func didSelectAsset(_ block: ((PHAsset) -> Void)?) -> DGCZLPhotoConfiguration {
        didSelectAsset = block
        return self
    }
    
    @discardableResult
    func didDeselectAsset(_ block: ((PHAsset) -> Void)?) -> DGCZLPhotoConfiguration {
        didDeselectAsset = block
        return self
    }
    
    @discardableResult
    func canEnterCamera(_ block: (() -> Bool)?) -> DGCZLPhotoConfiguration {
        canEnterCamera = block
        return self
    }
    
    @discardableResult
    func maxFrameCountForGIF(_ frameCount: Int) -> DGCZLPhotoConfiguration {
        maxFrameCountForGIF = frameCount
        return self
    }
    
    @discardableResult
    func gifPlayBlock(_ block: ((UIImageView, Data, [AnyHashable: Any]?) -> Void)?) -> DGCZLPhotoConfiguration {
        gifPlayBlock = block
        return self
    }
    
    @discardableResult
    func pauseGIFBlock(_ block: ((UIImageView) -> Void)?) -> DGCZLPhotoConfiguration {
        pauseGIFBlock = block
        return self
    }
    
    @discardableResult
    func resumeGIFBlock(_ block: ((UIImageView) -> Void)?) -> DGCZLPhotoConfiguration {
        resumeGIFBlock = block
        return self
    }
    
    @discardableResult
    func noAuthorityCallback(_ callback: ((DGCZLNoAuthorityType) -> Void)?) -> DGCZLPhotoConfiguration {
        noAuthorityCallback = callback
        return self
    }
    
    @discardableResult
    func customAlertWhenNoAuthority(_ callback: ((DGCZLNoAuthorityType) -> Void)?) -> DGCZLPhotoConfiguration {
        customAlertWhenNoAuthority = callback
        return self
    }
    
    @discardableResult
    func operateBeforeDoneAction(_ block: ((UIViewController, @escaping () -> Void) -> Void)?) -> DGCZLPhotoConfiguration {
        operateBeforeDoneAction = block
        return self
    }
}
