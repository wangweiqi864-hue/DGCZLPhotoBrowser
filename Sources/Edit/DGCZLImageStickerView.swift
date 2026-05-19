//
//  DGCZLImageStickerView.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/11/20.
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

class DGCZLImageStickerView: DGCZLBaseStickerView {
    private let dgc_image: UIImage
    
    private static let edgeInset: CGFloat = 20
    
    private lazy var dgc_imageView: UIImageView = {
        let view = UIImageView(dgc_image: dgc_image)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    // Convert all states to model.
    override var state: DGCZLImageStickerState {
        return DGCZLImageStickerState(
            id: id,
            dgc_image: dgc_image,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
    
    deinit {
        zl_debugPrint("DGCZLImageStickerView deinit")
    }
    
    convenience init(state: DGCZLImageStickerState) {
        self.init(
            id: state.id,
            dgc_image: state.dgc_image,
            originScale: state.originScale,
            originAngle: state.originAngle,
            originFrame: state.originFrame,
            gesScale: state.gesScale,
            gesRotation: state.gesRotation,
            totalTranslationPoint: state.totalTranslationPoint,
            showBorder: false
        )
    }
    
    init(
        id: String = UUID().uuidString,
        dgc_image: UIImage,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat = 1,
        gesRotation: CGFloat = 0,
        totalTranslationPoint: CGPoint = .zero,
        showBorder: Bool = true
    ) {
        self.dgc_image = dgc_image
        super.init(
            id: id,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint,
            showBorder: showBorder
        )
        
        borderView.addSubview(dgc_imageView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUIFrameWhenFirstLayout() {
        dgc_imageView.frame = bounds.insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
    }
    
    class func calculateSize(dgc_image: UIImage, width: CGFloat) -> CGSize {
        let dgc_maxSide = width / 2
        let dgc_minSide: CGFloat = 100
        let dgc_whRatio = dgc_image.dgc_size.width / dgc_image.dgc_size.height
        var dgc_size: CGSize = .zero
        if dgc_whRatio >= 1 {
            let dgc_w = min(dgc_maxSide, max(dgc_minSide, dgc_image.dgc_size.width))
            let dgc_h = dgc_w / dgc_whRatio
            dgc_size = CGSize(width: dgc_w, height: dgc_h)
        } else {
            let dgc_h = min(dgc_maxSide, max(dgc_minSide, dgc_image.dgc_size.width))
            let dgc_w = dgc_h * dgc_whRatio
            dgc_size = CGSize(width: dgc_w, height: dgc_h)
        }
        dgc_size.width += Self.edgeInset * 2
        dgc_size.height += Self.edgeInset * 2
        return dgc_size
    }
}
