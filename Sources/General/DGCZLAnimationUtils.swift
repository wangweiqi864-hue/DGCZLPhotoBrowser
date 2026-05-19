//
//  DGCZLAnimationUtils.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2023/1/13.
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

class DGCZLAnimationUtils: NSObject {
    enum DGCAnimationType: String {
        case fade = "opacity"
        case scale = "transform.scale"
        case rotate = "transform.rotation"
        case path
    }
    
    class func animation(
        type: DGCZLAnimationUtils.DGCAnimationType,
        fromValue: Any?,
        toValue: Any?,
        duration: TimeInterval,
        fillMode: CAMediaTimingFillMode = .forwards,
        isRemovedOnCompletion: Bool = false,
        timingFunction: CAMediaTimingFunction? = nil
    ) -> CAAnimation {
        let dgc_animation = CABasicAnimation(keyPath: type.rawValue)
        dgc_animation.fromValue = fromValue
        dgc_animation.toValue = toValue
        dgc_animation.duration = duration
        dgc_animation.fillMode = fillMode
        dgc_animation.isRemovedOnCompletion = isRemovedOnCompletion
        dgc_animation.timingFunction = timingFunction
        return dgc_animation
    }
    
    class func springAnimation() -> CAKeyframeAnimation {
        let dgc_animate = CAKeyframeAnimation(keyPath: "transform")
        dgc_animate.duration = DGCZLPhotoUIConfiguration.default().selectBtnAnimationDuration
        dgc_animate.isRemovedOnCompletion = true
        dgc_animate.fillMode = .forwards
        
        dgc_animate.values = [
            CATransform3DMakeScale(0.7, 0.7, 1),
            CATransform3DMakeScale(1.15, 1.15, 1),
            CATransform3DMakeScale(0.9, 0.9, 1),
            CATransform3DMakeScale(1, 1, 1)
        ]
        return dgc_animate
    }
}
