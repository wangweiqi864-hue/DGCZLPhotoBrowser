//
//  DGCZLPhotoPicker.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2025/3/12.
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

public class DGCZLPhotoPicker: NSObject {
    private var dgc_arrSelectedModels: [DGCZLPhotoModel] = []
    
    private weak var dgc_sender: UIViewController?
    
    private weak var dgc_previewSheet: DGCZLPhotoPreviewSheet?
    
    private var dgc_isSelectOriginal = false
    
    private lazy var dgc_fetchImageQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    
    /// Success callback
    /// block params
    ///  - params1: result models
    ///  - params2: is full image
    @objc public var selectImageBlock: (([DGCZLResultModel], Bool) -> Void)?
    
    /// Callback for photos that failed to parse
    /// block params
    ///  - params1: failed assets.
    ///  - params2: index for asset
    @objc public var selectImageRequestErrorBlock: (([PHAsset], [Int]) -> Void)?
    
    @objc public var cancelBlock: (() -> Void)?
    
    deinit {
        zlLoggerInDebug("DGCZLPhotoPicker deinit")
    }
    
    @objc override public init() {
        let config = DGCZLPhotoConfiguration.default()
        if !config.allowSelectImage, !config.allowSelectVideo {
            assertionFailure("DGCZLPhotoBrowser: error configuration. The values of allowSelectImage and allowSelectVideo are both false")
            config.allowSelectImage = true
        }
    }
    
    /// - Parameter selectedAssets: preselected assets
    @objc public convenience init(selectedAssets: [PHAsset]? = nil) {
        self.init()
        
        let config = DGCZLPhotoConfiguration.default()
        selectedAssets?.zl.removeDuplicate().forEach { asset in
            if !config.allowMixSelect, asset.mediaType == .video {
                return
            }
            
            let m = DGCZLPhotoModel(asset: asset)
            m.isSelected = true
            self.dgc_arrSelectedModels.append(m)
        }
    }
    
    /// Using this init method, you can continue editing the selected photo.
    /// - Note:
    ///     If you want to continue the last edit, you need to satisfy the value of `saveNewImageAfterEdit` is `false` at the time of the last selection.
    /// - Parameters:
    ///    - results : preselected results
    @objc public convenience init(results: [DGCZLResultModel]? = nil) {
        self.init()
        
        let config = DGCZLPhotoConfiguration.default()
        results?.zl.removeDuplicate().forEach { result in
            if !config.allowMixSelect, result.asset.mediaType == .video {
                return
            }
            
            let m = DGCZLPhotoModel(asset: result.asset)
            if result.isEdited {
                m.editImage = result.image
                m.editImageModel = result.editModel
            }
            m.isSelected = true
            self.dgc_arrSelectedModels.append(m)
        }
    }
    
    /// - Warning: When calling this method in OC language, make sure that the `dgc_sender` is not zero
    @discardableResult
    @objc public func showPreview(animate: Bool = true, sender dgc_sender: UIViewController) -> DGCZLPhotoPreviewSheet {
        self.dgc_sender = dgc_sender
        
        let dgc_ps = DGCZLPhotoPreviewSheet(models: dgc_arrSelectedModels)
        dgc_ps.selectPhotosBlock = { models, isOriginal in
            self.dgc_requestSelectPhoto(models: models, dgc_isSelectOriginal: isOriginal)
        }
        
        dgc_ps.showLibraryBlock = { models, isOriginal in
            self.dgc_arrSelectedModels.removeAll()
            self.dgc_arrSelectedModels.append(contentsOf: models)
            self.dgc_isSelectOriginal = isOriginal
            self.showPhotoLibrary(sender: dgc_sender)
        }
        
        dgc_ps.cancelBlock = {
            self.dgc_cancel()
        }
        
        dgc_ps.showPreview(sender: dgc_sender)
        dgc_previewSheet = dgc_ps
        
        return dgc_ps
    }
    
    /// - Warning: When calling this method in OC language, make sure that the `dgc_sender` is not zero
    @discardableResult
    @objc public func showPhotoLibrary(sender dgc_sender: UIViewController) -> DGCZLImageNavController {
        self.dgc_sender = dgc_sender
        
        let dgc_nav: DGCZLImageNavController
        if DGCZLPhotoUIConfiguration.default().style == .embedAlbumList {
            let dgc_tvc = DGCZLThumbnailViewController(albumList: nil)
            dgc_nav = dgc_getImageNav(rootViewController: dgc_tvc)
        } else {
            dgc_nav = dgc_getImageNav(rootViewController: DGCZLAlbumListController())
            let dgc_tvc = DGCZLThumbnailViewController(albumList: nil)
            dgc_nav.pushViewController(dgc_tvc, animated: true)
        }
        
        dgc_sender.present(dgc_nav, animated: true) {
            self.dgc_previewSheet?.hide()
        }
        
        return dgc_nav
    }
    
    /// 传入已选择的assets，并预览
    @objc public func previewAssets(
        sender dgc_sender: UIViewController,
        assets: [PHAsset],
        index: Int,
        isOriginal: Bool,
        showBottomViewAndSelectBtn: Bool = true
    ) {
        assert(!assets.isEmpty, "Assets cannot be empty")
        
        let dgc_models = assets.zl.removeDuplicate().map { asset -> DGCZLPhotoModel in
            let dgc_m = DGCZLPhotoModel(asset: asset)
            dgc_m.isSelected = true
            return dgc_m
        }
        
        guard !dgc_models.isEmpty else {
            return
        }
        
        dgc_arrSelectedModels.removeAll()
        dgc_arrSelectedModels.append(contentsOf: dgc_models)
        self.dgc_sender = dgc_sender
        
        dgc_isSelectOriginal = isOriginal
        
        let dgc_vc = DGCZLPhotoPreviewController(photos: dgc_models, index: index, showBottomViewAndSelectBtn: showBottomViewAndSelectBtn)
        dgc_vc.autoSelectCurrentIfNotSelectAnyone = false
        let dgc_nav = dgc_getImageNav(rootViewController: dgc_vc)
        dgc_vc.backBlock = {
            self.dgc_cancel()
        }
        
        dgc_sender.showDetailViewController(dgc_nav, sender: nil)
    }
    
    private func dgc_getImageNav(rootViewController: UIViewController) -> DGCZLImageNavController {
        let dgc_nav = DGCZLImageNavController(rootViewController: rootViewController)
        dgc_nav.modalPresentationStyle = .fullScreen
        dgc_nav.selectImageBlock = { [weak dgc_nav] in
            self.dgc_requestSelectPhoto(
                models: dgc_nav?.dgc_arrSelectedModels ?? [],
                dgc_isSelectOriginal: dgc_nav?.isSelectedOriginal ?? false,
                viewController: dgc_nav
            )
        }
        
        dgc_nav.cancelBlock = {
            self.dgc_cancel()
        }
        dgc_nav.isSelectedOriginal = dgc_isSelectOriginal
        dgc_nav.dgc_arrSelectedModels.removeAll()
        dgc_nav.dgc_arrSelectedModels.append(contentsOf: dgc_arrSelectedModels)
        
        return dgc_nav
    }
    
    private func dgc_cancel() {
        cancelBlock?()
    }
    
    /// 解析选择的图片
    private func dgc_requestSelectPhoto(
        models: [DGCZLPhotoModel],
        dgc_isSelectOriginal: Bool,
        viewController: UIViewController? = nil
    ) {
        dgc_arrSelectedModels.removeAll()
        dgc_arrSelectedModels.append(contentsOf: models)
        
        guard !dgc_arrSelectedModels.isEmpty else {
            selectImageBlock?([], dgc_isSelectOriginal)
            dgc_previewSheet?.hide()
            viewController?.dismiss(animated: true, completion: nil)
            return
        }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        if dgc_config.allowMixSelect {
            let dgc_videoCount = dgc_arrSelectedModels.filter { $0.type == .video }.count
            
            if dgc_videoCount > dgc_config.maxVideoSelectCount {
                showAlertView(String(format: localLanguageTextValue(.exceededMaxVideoSelectCount), DGCZLPhotoConfiguration.default().maxVideoSelectCount), viewController)
                return
            } else if dgc_videoCount < dgc_config.minVideoSelectCount {
                showAlertView(String(format: localLanguageTextValue(.lessThanMinVideoSelectCount), DGCZLPhotoConfiguration.default().minVideoSelectCount), viewController)
                return
            }
        }
        
        let dgc_hud = DGCZLProgressHUD.show(toast: .processing, dgc_timeout: DGCZLPhotoUIConfiguration.default().dgc_timeout)
        
        var dgc_timeout = false
        dgc_hud.timeoutBlock = { [weak self] in
            dgc_timeout = true
            showAlertView(localLanguageTextValue(.dgc_timeout), viewController ?? self?.dgc_sender)
            self?.dgc_fetchImageQueue.cancelAllOperations()
        }
        
        let dgc_isOriginal = dgc_config.allowSelectOriginal ? dgc_isSelectOriginal : dgc_config.alwaysRequestOriginal
        
        let dgc_callback = { [weak self] (sucModels: [DGCZLResultModel], dgc_errorAssets: [PHAsset], dgc_errorIndexs: [Int]) in
            dgc_hud.hide()
            
            func call() {
                self?.selectImageBlock?(sucModels, dgc_isOriginal)
                if !dgc_errorAssets.isEmpty {
                    self?.selectImageRequestErrorBlock?(dgc_errorAssets, dgc_errorIndexs)
                }
            }
            
            if let dgc_vc = viewController {
                dgc_vc.dismiss(animated: true) {
                    call()
                }
            } else {
                self?.dgc_previewSheet?.hide {
                    call()
                }
            }
            
            self?.dgc_arrSelectedModels.removeAll()
        }
        
        var dgc_results: [DGCZLResultModel?] = Array(repeating: nil, count: dgc_arrSelectedModels.count)
        var dgc_errorAssets: [PHAsset] = []
        var dgc_errorIndexs: [Int] = []
        
        var dgc_sucCount = 0
        let dgc_totalCount = dgc_arrSelectedModels.count
        
        for (i, m) in dgc_arrSelectedModels.enumerated() {
            let dgc_operation = DGCZLFetchImageOperation(dgc_model: m, dgc_isOriginal: dgc_isOriginal) { dgc_image, asset in
                guard !dgc_timeout else { return }
                
                dgc_sucCount += 1
                
                if let dgc_image = dgc_image {
                    let dgc_isEdited = m.editImage != nil && !dgc_config.saveNewImageAfterEdit
                    let dgc_model = DGCZLResultModel(
                        asset: asset ?? m.asset,
                        dgc_image: dgc_image,
                        dgc_isEdited: dgc_isEdited,
                        editModel: dgc_isEdited ? m.editImageModel : nil,
                        index: i
                    )
                    dgc_results[i] = dgc_model
                    zl_debugPrint("DGCZLPhotoBrowser: suc request \(i)")
                } else {
                    dgc_errorAssets.append(m.asset)
                    dgc_errorIndexs.append(i)
                    zl_debugPrint("DGCZLPhotoBrowser: failed request \(i)")
                }
                
                guard dgc_sucCount >= dgc_totalCount else { return }
                
                dgc_callback(
                    dgc_results.compactMap { $0 },
                    dgc_errorAssets,
                    dgc_errorIndexs
                )
            }
            dgc_fetchImageQueue.addOperation(dgc_operation)
        }
    }
}

// MARK: Methods for SwiftUI

public extension DGCZLPhotoPicker {
    @available(iOS, introduced: 13.0, message: "Only available for SwiftUI")
    func showPhotoLibraryForSwiftUI() -> DGCZLImageNavController {
        let dgc_nav: DGCZLImageNavController
        if DGCZLPhotoUIConfiguration.default().style == .embedAlbumList {
            let dgc_tvc = DGCZLThumbnailViewController(albumList: nil)
            dgc_nav = dgc_getImageNav(rootViewController: dgc_tvc)
        } else {
            dgc_nav = dgc_getImageNav(rootViewController: DGCZLAlbumListController())
            let dgc_tvc = DGCZLThumbnailViewController(albumList: nil)
            dgc_nav.pushViewController(dgc_tvc, animated: true)
        }
        
        return dgc_nav
    }
    
    /// 传入已选择的assets，并预览
    @objc func previewAssetsForSwiftUI(
        assets: [PHAsset],
        index: Int,
        isOriginal: Bool,
        showBottomViewAndSelectBtn: Bool = true
    ) -> DGCZLImageNavController {
        assert(!assets.isEmpty, "Assets cannot be empty")
        
        let dgc_models = assets.zl.removeDuplicate().map { asset -> DGCZLPhotoModel in
            let dgc_m = DGCZLPhotoModel(asset: asset)
            dgc_m.isSelected = true
            return dgc_m
        }
        
        dgc_arrSelectedModels.removeAll()
        dgc_arrSelectedModels.append(contentsOf: dgc_models)
        
        dgc_isSelectOriginal = isOriginal
        
        let dgc_vc = DGCZLPhotoPreviewController(photos: dgc_models, index: index, showBottomViewAndSelectBtn: showBottomViewAndSelectBtn)
        dgc_vc.autoSelectCurrentIfNotSelectAnyone = false
        let dgc_nav = dgc_getImageNav(rootViewController: dgc_vc)
        dgc_vc.backBlock = {
            self.dgc_cancel()
        }
        
        return dgc_nav
    }
}
