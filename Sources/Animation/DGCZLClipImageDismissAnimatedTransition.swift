//
//  DGCZLClipImageDismissAnimatedTransition.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/9/8.
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

class DGCZLClipImageDismissAnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let dgc_fromVC = transitionContext.viewController(forKey: .from) as? DGCZLClipImageViewController, let dgc_toVC = transitionContext.viewController(forKey: .to) as? DGCZLEditImageViewController else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        
        let dgc_containerView = transitionContext.dgc_containerView
        dgc_containerView.addSubview(dgc_toVC.view)
        
        let dgc_imageView = UIImageView(frame: dgc_fromVC.dismissAnimateFromRect)
        dgc_imageView.contentMode = .scaleAspectFill
        dgc_imageView.clipsToBounds = true
        dgc_imageView.image = dgc_fromVC.dismissAnimateImage
        dgc_containerView.addSubview(dgc_imageView)
        
        UIView.animate(withDuration: 0.3, animations: {
            dgc_imageView.frame = dgc_toVC.originalFrame
        }) { _ in
            dgc_toVC.finishClipDismissAnimate()
            dgc_imageView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
