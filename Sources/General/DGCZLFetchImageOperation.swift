//
//  DGCZLFetchImageOperation.swift
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
import Photos

class DGCZLFetchImageOperation: Operation, @unchecked Sendable {
    private let dgc_model: DGCZLPhotoModel
    
    private let dgc_isOriginal: Bool
    
    private let dgc_progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)?
    
    private let dgc_completion: (UIImage?, PHAsset?) -> Void
    
    private var dgc_pri_isExecuting = false {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
        }
        didSet {
            self.didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return dgc_pri_isExecuting
    }
    
    private var dgc_pri_isFinished = false {
        willSet {
            self.willChangeValue(forKey: "isFinished")
        }
        didSet {
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return dgc_pri_isFinished
    }
    
    private var dgc_pri_isCancelled = false {
        willSet {
            willChangeValue(forKey: "isCancelled")
        }
        didSet {
            didChangeValue(forKey: "isCancelled")
        }
    }
    
    private var dgc_requestImageID = PHInvalidImageRequestID
    
    override var isCancelled: Bool {
        return dgc_pri_isCancelled
    }
    
    init(
        dgc_model: DGCZLPhotoModel,
        dgc_isOriginal: Bool,
        dgc_progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil,
        dgc_completion: @escaping ((UIImage?, PHAsset?) -> Void)
    ) {
        self.dgc_model = dgc_model
        self.dgc_isOriginal = dgc_isOriginal
        self.dgc_progress = dgc_progress
        self.dgc_completion = dgc_completion
        super.init()
    }
    
    override func start() {
        if isCancelled {
            dgc_fetchFinish()
            return
        }
        zl_debugPrint("---- start fetch")
        dgc_pri_isExecuting = true
        
        // 存在编辑的图片
        if let dgc_editImage = dgc_model.dgc_editImage {
            if DGCZLPhotoConfiguration.default().saveNewImageAfterEdit {
                DGCZLPhotoManager.saveImageToAlbum(dgc_image: dgc_editImage) { [weak self] _, asset in
                    self?.dgc_completion(dgc_editImage, asset)
                    self?.dgc_fetchFinish()
                }
            } else {
                ZLMainAsync {
                    self.dgc_completion(dgc_editImage, nil)
                    self.dgc_fetchFinish()
                }
            }
            return
        }
        
        if DGCZLPhotoConfiguration.default().allowSelectGif, dgc_model.type == .gif {
            dgc_requestImageID = DGCZLPhotoManager.fetchOriginalImageData(for: dgc_model.asset) { [weak self] data, _, isDegraded in
                if !isDegraded {
                    let dgc_image = UIImage.zl.animateGifImage(data: data)
                    self?.dgc_completion(dgc_image, nil)
                    self?.dgc_fetchFinish()
                }
            }
            return
        }
        
        if dgc_isOriginal {
            dgc_requestImageID = DGCZLPhotoManager.fetchOriginalImage(for: dgc_model.asset, dgc_progress: dgc_progress) { [weak self] dgc_image, isDegraded in
                if !isDegraded {
                    zl_debugPrint("---- 原图加载完成 \(String(describing: self?.isCancelled))")
                    self?.dgc_completion(dgc_image?.zl.fixOrientation(), nil)
                    self?.dgc_fetchFinish()
                }
            }
        } else {
            dgc_requestImageID = DGCZLPhotoManager.fetchImage(for: dgc_model.asset, size: dgc_model.previewSize, dgc_progress: dgc_progress) { [weak self] dgc_image, isDegraded in
                if !isDegraded {
                    zl_debugPrint("---- 加载完成 isCancelled: \(String(describing: self?.isCancelled))")
                    self?.dgc_completion(self?.dgc_scaleImage(dgc_image?.zl.fixOrientation()), nil)
                    self?.dgc_fetchFinish()
                }
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        zl_debugPrint("---- cancel \(isExecuting) \(dgc_requestImageID)")
        PHImageManager.default().cancelImageRequest(dgc_requestImageID)
        dgc_pri_isCancelled = true
        if isExecuting {
            dgc_fetchFinish()
        }
    }
    
    private func dgc_scaleImage(_ image: UIImage?) -> UIImage? {
        guard let dgc_i = image else {
            return nil
        }
        guard let dgc_data = dgc_i.jpegData(compressionQuality: 1) else {
            return dgc_i
        }
        let dgc_mUnit: CGFloat = 1024 * 1024
        
        if dgc_data.count < Int(0.2 * dgc_mUnit) {
            return dgc_i
        }
        let dgc_scale: CGFloat = (dgc_data.count > Int(dgc_mUnit) ? 0.6 : 0.8)
        
        guard let dgc_d = dgc_i.jpegData(compressionQuality: dgc_scale) else {
            return dgc_i
        }
        return UIImage(dgc_data: dgc_d)
    }
    
    private func dgc_fetchFinish() {
        dgc_pri_isExecuting = false
        dgc_pri_isFinished = true
    }
}
