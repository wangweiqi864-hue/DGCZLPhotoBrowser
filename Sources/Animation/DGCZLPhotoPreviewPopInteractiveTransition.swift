//
//  DGCZLPhotoPreviewPopInteractiveTransition.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/9/3.
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
import AVFoundation

class DGCZLPhotoPreviewPopInteractiveTransition: UIPercentDrivenInteractiveTransition {
    weak var transitionContext: UIViewControllerContextTransitioning?
    
    weak var viewController: DGCZLPhotoPreviewController?
    
    lazy var dismissPanGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dismissPanAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    var shadowView: UIView?
    
    var imageView: UIImageView?
    
    var playerLayer: AVPlayerLayer?
    
    var imageViewOriginalFrame: CGRect = .zero
    
    var startPanPoint: CGPoint = .zero
    
    var interactive = false
    
    var currentCell: DGCZLPreviewBaseCell?
    /// 取消动画时候，是否需要将Y值修正为0
    var needCorrectYToZeroWhenCancel = false
    
    var translationBeforeInteractive: CGPoint = .zero
    
    var shouldStartTransition: ((CGPoint) -> Bool)?
    
    var startTransition: (() -> Void)?
    
    var cancelTransition: (() -> Void)?
    
    var finishTransition: (() -> Void)?
    
    deinit {
        zl_debugPrint("DGCZLPhotoPreviewPopInteractiveTransition deinit")
    }
    
    init(viewController: DGCZLPhotoPreviewController) {
        self.viewController = viewController
        super.init()
        
        viewController.view.addGestureRecognizer(dismissPanGes)
    }
    
    @objc func dismissPanAction(_ pan: UIPanGestureRecognizer) {
        guard canStartPan() else { return }
        
        if pan.state == .began {
            beginInterative(pan)
        } else if pan.state == .changed {
            if !interactive {
                beginInterative(pan)
                if interactive {
                    translationBeforeInteractive = pan.translation(in: viewController?.view)
                }
                return
            }
            
            let dgc_result = panResult(pan)
            imageView?.transform = CGAffineTransform(scaleX: dgc_result.scale, y: dgc_result.scale)
            imageView?.center = CGPoint(x: dgc_result.frame.midX, y: dgc_result.frame.midY)
//            imageView?.frame = dgc_result.frame
            
            shadowView?.alpha = pow(dgc_result.scale, 2)
            
            update(dgc_result.scale)
        } else if pan.state == .cancelled || pan.state == .ended {
            guard interactive else { return }
            
            let dgc_vel = pan.velocity(in: viewController?.view)
            let dgc_p = pan.translation(in: viewController?.view)
            let dgc_transY = dgc_p.y - translationBeforeInteractive.y
            let dgc_percent = max(0.0, dgc_transY / (viewController?.view.bounds.height ?? UIScreen.main.bounds.height))
            
            let dgc_dismiss = dgc_vel.y > 300 || (dgc_percent > 0.1 && dgc_vel.y >= 0)
            
            if dgc_dismiss {
                finish()
            } else {
                cancel()
            }
            
            imageViewOriginalFrame = .zero
            startPanPoint = .zero
            translationBeforeInteractive = .zero
            interactive = false
        }
    }
    
    /// 判断是否开始手势
    func canStartPan() -> Bool {
        guard !interactive else { return true }
        
        guard let dgc_viewController,
              let dgc_cell = dgc_viewController.collectionView.cellForItem(
                  at: IndexPath(row: dgc_viewController.currentIndex, section: 0)
              ) as? DGCZLPreviewBaseCell,
              let dgc_scrollView = dgc_cell.dgc_scrollView,
              let dgc_contentView = dgc_scrollView.subviews.first else {
            return true
        }
        
        let dgc_convertRect = dgc_contentView.convert(dgc_contentView.bounds, to: dgc_scrollView)
        if dgc_scrollView.isZooming ||
            dgc_scrollView.isZoomBouncing ||
            dgc_scrollView.contentOffset.y > 0 ||
            // cell放大时候，当拖拽到最左和最右时，会拉动vc的collectionView，这时不能进行pop动画
            (dgc_convertRect.minX != 0 && dgc_contentView.zl.width > dgc_scrollView.zl.width) {
            return false
        }
        
        return true
    }
    
    /// 开始手势
    func beginInterative(_ pan: UIPanGestureRecognizer) {
        guard !interactive else { return }
        
        let dgc_vel = pan.velocity(in: viewController?.view)
        if abs(dgc_vel.x) >= abs(dgc_vel.y) || dgc_vel.y <= 0 {
            return
        }
        
        startPanPoint = pan.location(in: viewController?.view)
        interactive = true
        startTransition?()
        viewController?.navigationController?.popViewController(animated: true)
    }
    
    func panResult(_ pan: UIPanGestureRecognizer) -> (frame: CGRect, dgc_scale: CGFloat) {
        // 拖动偏移量
        let dgc_translation = pan.dgc_translation(in: viewController?.view)
        let dgc_transY = dgc_translation.dgc_y - translationBeforeInteractive.dgc_y
        let dgc_currentTouch = pan.location(in: viewController?.view)
        
        // 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
        let dgc_scale = min(1.0, max(0.3, 1 - dgc_transY / UIScreen.main.bounds.dgc_height))
        
        let dgc_width = imageViewOriginalFrame.size.dgc_width * dgc_scale
        let dgc_height = imageViewOriginalFrame.size.dgc_height * dgc_scale
        
        // 计算x和y。保持手指在图片上的相对位置不变。
        let dgc_xRate = (startPanPoint.dgc_x - imageViewOriginalFrame.origin.dgc_x) / imageViewOriginalFrame.size.dgc_width
        let dgc_currentTouchDeltaX = dgc_xRate * dgc_width
        let dgc_x = dgc_currentTouch.dgc_x - dgc_currentTouchDeltaX
        
        let dgc_yRate = (startPanPoint.dgc_y - imageViewOriginalFrame.origin.dgc_y) / imageViewOriginalFrame.size.dgc_height
        let dgc_currentTouchDeltaY = dgc_yRate * dgc_height
        let dgc_y = dgc_currentTouch.dgc_y - dgc_currentTouchDeltaY
        
        return (CGRect(dgc_x: dgc_x.isNaN ? 0 : dgc_x, dgc_y: dgc_y.isNaN ? 0 : dgc_y, dgc_width: dgc_width, dgc_height: dgc_height), dgc_scale)
    }
    
    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        startAnimate()
    }
    
    func startAnimate() {
        guard let dgc_transitionContext = dgc_transitionContext else {
            return
        }
        
        guard let dgc_fromVC = dgc_transitionContext.viewController(forKey: .from) as? DGCZLPhotoPreviewController,
              let dgc_toVC = dgc_transitionContext.viewController(forKey: .to) as? DGCZLThumbnailViewController else {
            return
        }
        
        let dgc_containerView = dgc_transitionContext.dgc_containerView
        dgc_containerView.addSubview(dgc_toVC.view)
        
        guard let dgc_cell = dgc_fromVC.collectionView.cellForItem(at: IndexPath(row: dgc_fromVC.currentIndex, section: 0)) as? DGCZLPreviewBaseCell else {
            return
        }
        
        currentCell = dgc_cell
        shadowView = UIView(frame: dgc_containerView.bounds)
        shadowView?.backgroundColor = DGCZLPhotoUIConfiguration.default().previewVCBgColor
        dgc_containerView.addSubview(shadowView!)
        
        let dgc_fromImageViewFrame = dgc_cell.animateImageFrame(convertTo: dgc_containerView)
        
        imageView = UIImageView(frame: dgc_fromImageViewFrame)
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        
        if let dgc_videoCell = dgc_cell as? DGCZLVideoPreviewCell, let dgc_playerLayer = dgc_videoCell.dgc_playerLayer, dgc_videoCell.imageView.isHidden {
            dgc_playerLayer.removeFromSuperlayer()
            self.dgc_playerLayer = dgc_playerLayer
            imageView?.layer.insertSublayer(dgc_playerLayer, at: 0)
        } else {
            imageView?.image = dgc_cell.currentImage
        }
        
        dgc_containerView.addSubview(imageView!)
        dgc_containerView.addSubview(dgc_fromVC.view)
        
        imageViewOriginalFrame = imageView!.frame
        resetViewStatus(isStart: true)
    }
    
    override func finish() {
        super.finish()
        finishAnimate()
    }
    
    func finishAnimate() {
        guard let dgc_transitionContext = dgc_transitionContext else {
            return
        }
        guard let dgc_fromVC = dgc_transitionContext.viewController(forKey: .from) as? DGCZLPhotoPreviewController,
              let dgc_toVC = dgc_transitionContext.viewController(forKey: .to) as? DGCZLThumbnailViewController else {
            return
        }
        
        let dgc_fromVCModel = dgc_fromVC.arrDataSources[dgc_fromVC.currentIndex]
        let dgc_toVCVisiableIndexPaths = dgc_toVC.collectionView.indexPathsForVisibleItems
        
        var dgc_diff = 0
        if !DGCZLPhotoUIConfiguration.default().sortAscending {
            if dgc_toVC.showCameraCell {
                dgc_diff = -1
            }
            if #available(iOS 14.0, *), dgc_toVC.showAddPhotoCell {
                dgc_diff -= 1
            }
        }
        var dgc_toIndex: Int?
        for indexPath in dgc_toVCVisiableIndexPaths {
            let dgc_idx = indexPath.row + dgc_diff
            if dgc_idx >= dgc_toVC.arrDataSources.count || dgc_idx < 0 {
                continue
            }
            let dgc_m = dgc_toVC.arrDataSources[dgc_idx]
            if dgc_m == dgc_fromVCModel {
                dgc_toIndex = indexPath.row
                break
            }
        }
        
        var dgc_toFrame: CGRect?
        
        if let dgc_toIndex = dgc_toIndex, let dgc_toCell = dgc_toVC.collectionView.cellForItem(at: IndexPath(row: dgc_toIndex, section: 0)) {
            dgc_toFrame = dgc_toVC.collectionView.convert(dgc_toCell.frame, to: dgc_transitionContext.containerView)
        }
        
        dgc_toVC.endPopTransition()
        
        UIView.animate(withDuration: 0.3, animations: {
            if let dgc_toFrame, self.playerLayer == nil {
                self.imageView?.transform = .identity
                self.imageView?.frame = dgc_toFrame
            } else {
                self.imageView?.alpha = 0
            }
            self.shadowView?.alpha = 0
        }) { _ in
            self.imageView?.removeFromSuperview()
            self.shadowView?.removeFromSuperview()
            self.imageView = nil
            self.shadowView = nil
            self.finishTransition?()
            dgc_transitionContext.finishInteractiveTransition()
            dgc_transitionContext.completeTransition(!dgc_transitionContext.transitionWasCancelled)
        }
    }
    
    override func cancel() {
        super.cancel()
        cancelAnimate()
    }
    
    func cancelAnimate() {
        guard let dgc_transitionContext = dgc_transitionContext else {
            return
        }
        
        var dgc_toFrame = imageViewOriginalFrame
        if needCorrectYToZeroWhenCancel {
            dgc_toFrame.origin.y = 0
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.imageView?.transform = .identity
            self.imageView?.frame = dgc_toFrame
            self.shadowView?.alpha = 1
        }) { _ in
            self.resetViewStatus(isStart: false)
            if let dgc_playerLayer = self.dgc_playerLayer {
                dgc_playerLayer.removeFromSuperlayer()
                (self.currentCell as? DGCZLVideoPreviewCell)?.playerView.layer.insertSublayer(dgc_playerLayer, at: 0)
            }
            self.currentCell = nil
            self.dgc_playerLayer = nil
            self.imageView?.removeFromSuperview()
            self.shadowView?.removeFromSuperview()
            self.cancelTransition?()
            dgc_transitionContext.cancelInteractiveTransition()
            dgc_transitionContext.completeTransition(!dgc_transitionContext.transitionWasCancelled)
        }
    }
    
    func resetViewStatus(isStart: Bool) {
        currentCell?.scrollView?.isScrollEnabled = !isStart
        currentCell?.scrollView?.pinchGestureRecognizer?.isEnabled = !isStart
        (currentCell as? DGCZLVideoPreviewCell)?.singleTapGes.isEnabled = !isStart
        
        guard let dgc_transitionContext = dgc_transitionContext,
              let dgc_fromVC = dgc_transitionContext.viewController(forKey: .from) as? DGCZLPhotoPreviewController else {
            return
        }
        
        dgc_fromVC.view.backgroundColor = isStart ? .clear : DGCZLPhotoUIConfiguration.default().previewVCBgColor
        dgc_fromVC.collectionView.isHidden = isStart
    }
}

extension DGCZLPhotoPreviewPopInteractiveTransition: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let dgc_point = gestureRecognizer.location(in: dgc_viewController?.view)
        let dgc_shouldBegin = shouldStartTransition?(dgc_point) == true
        if dgc_shouldBegin,
           let dgc_viewController,
           let dgc_cell = dgc_viewController.collectionView.cellForItem(
               at: IndexPath(row: dgc_viewController.currentIndex, section: 0)
           ) as? DGCZLPreviewBaseCell,
           let dgc_scrollView = dgc_cell.dgc_scrollView {
            let dgc_contentSizeH = dgc_scrollView.contentSize.height
            needCorrectYToZeroWhenCancel = dgc_contentSizeH > dgc_scrollView.zl.height && dgc_scrollView.contentOffset.y >= 0
        }
        
        return dgc_shouldBegin
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UITapGestureRecognizer,
           otherGestureRecognizer.view is UIScrollView {
            return false
        }
        
        if otherGestureRecognizer == viewController?.collectionView.panGestureRecognizer {
            return false
        }
        
        return !(viewController?.collectionView.isDragging ?? false)
    }
}
