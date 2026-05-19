//
//  DGCZLClipOverlayView.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2024/6/28.
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

// MARK: 裁剪网格视图

class DGCZLClipOverlayView: UIView {
    static let cornerLineWidth: CGFloat = 3
    
    private lazy var dgc_shadowView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.7)
        view.layer.mask = dgc_shadowMaskLayer
        return view
    }()
    
    private lazy var dgc_shadowMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        return layer
    }()
    
    private lazy var dgc_cornerLinesView: UIView = {
        let view = UIView()
        view.layer.addSublayer(dgc_cornerLinesLayer)
        return view
    }()
    
    private lazy var dgc_cornerLinesLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = DGCZLClipOverlayView.cornerLineWidth
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    
    private lazy var dgc_frameBorderView: UIView = {
        let view = UIView()
        view.layer.addSublayer(dgc_frameBorderLayer)
        return view
    }()
    
    private lazy var dgc_frameBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1.2
        layer.contentsScale = UIScreen.main.scale
        layer.shadowOffset = CGSize.zero
        layer.shadowOpacity = 1
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.withAlphaComponent(0.7).cgColor
        return layer
    }()
    
    private lazy var dgc_gridLinesView: UIView = {
        let view = UIView()
        view.layer.addSublayer(dgc_gridLinesLayer)
        view.alpha = 0
        return view
    }()
    
    private lazy var dgc_gridLinesLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 0.5
        layer.contentsScale = UIScreen.main.scale
        return layer
    }()
    
    var cropRect: CGRect = .zero
    
    var isCircle = false {
        didSet {
            guard oldValue != isCircle else {
                return
            }
            
            dgc_shadowMaskLayer.path = dgc_getShadowMaskLayerPath().cgPath
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dgc_updateSubviewsFrame()
    }
    
    private func dgc_setupUI() {
        addSubview(dgc_shadowView)
        addSubview(dgc_frameBorderView)
        addSubview(dgc_cornerLinesView)
        addSubview(dgc_gridLinesView)
        
        dgc_updateSubviewsFrame()
    }
    
    private func dgc_updateSubviewsFrame() {
        dgc_shadowView.frame = bounds
        dgc_shadowMaskLayer.frame = dgc_shadowView.bounds
        dgc_frameBorderView.frame = bounds
        dgc_frameBorderLayer.frame = dgc_frameBorderView.bounds
        dgc_cornerLinesView.frame = bounds
        dgc_cornerLinesLayer.frame = dgc_cornerLinesView.bounds
        dgc_gridLinesView.frame = bounds
        dgc_gridLinesLayer.frame = dgc_gridLinesView.bounds
    }
    
    private func dgc_getShadowMaskLayerPath() -> UIBezierPath {
        let dgc_path = UIBezierPath(rect: dgc_shadowView.frame)
        let dgc_transparentPath: UIBezierPath
        if isCircle {
            dgc_transparentPath = UIBezierPath(roundedRect: cropRect, cornerRadius: cropRect.width / 2)
        } else {
            dgc_transparentPath = UIBezierPath(rect: cropRect)
        }
        dgc_path.append(dgc_transparentPath.reversing())
        return dgc_path
    }
    
    private func dgc_getCornerLinesLayerPath() -> UIBezierPath {
        let dgc_rect = cropRect.insetBy(dx: -Self.cornerLineWidth / 2, dy: -Self.cornerLineWidth / 2)
        let dgc_path = UIBezierPath()
        let dgc_length: CGFloat = 20
        
        // 左上
        dgc_path.move(to: CGPoint(x: dgc_rect.minX + dgc_length, y: dgc_rect.minY))
        dgc_path.addLine(to: CGPoint(x: dgc_rect.minX, y: dgc_rect.minY))
        dgc_path.addLine(to: CGPoint(x: dgc_rect.minX, y: dgc_rect.minY + dgc_length))

        // 右上
        dgc_path.move(to: CGPoint(x: dgc_rect.maxX - dgc_length, y: dgc_rect.minY))
        dgc_path.addLine(to: CGPoint(x: dgc_rect.maxX, y: dgc_rect.minY))
        dgc_path.addLine(to: CGPoint(x: dgc_rect.maxX, y: dgc_rect.minY + dgc_length))

        // 左下
        dgc_path.move(to: CGPoint(x: dgc_rect.minX, y: dgc_rect.maxY - dgc_length))
        dgc_path.addLine(to: CGPoint(x: dgc_rect.minX, y: dgc_rect.maxY))
        dgc_path.addLine(to: CGPoint(x: dgc_rect.minX + dgc_length, y: dgc_rect.maxY))
        
        // 右下
        dgc_path.move(to: CGPoint(x: dgc_rect.maxX - dgc_length, y: dgc_rect.maxY))
        dgc_path.addLine(to: CGPoint(x: dgc_rect.maxX, y: dgc_rect.maxY))
        dgc_path.addLine(to: CGPoint(x: dgc_rect.maxX, y: dgc_rect.maxY - dgc_length))
        
        return dgc_path
    }
    
    private func dgc_getGridLinesLayerPath() -> UIBezierPath {
        let dgc_path = UIBezierPath()
        
        let dgc_r = cropRect.width / 2
        var dgc_diff: CGFloat = 0
        if isCircle && DGCZLPhotoConfiguration.default().editImageConfiguration.dimClippedAreaDuringAdjustments {
            dgc_diff = dgc_r - sqrt(pow(dgc_r, 2) - pow(dgc_r / 3, 2))
        }
        // 画竖线
        let dgc_dw = cropRect.width / 3
        for i in 1...2 {
            let dgc_x = CGFloat(i) * dgc_dw + cropRect.minX
            dgc_path.move(to: CGPoint(dgc_x: dgc_x, dgc_y: cropRect.minY + dgc_diff))
            dgc_path.addLine(to: CGPoint(dgc_x: dgc_x, dgc_y: cropRect.maxY - dgc_diff))
        }
        
        // 画横线
        let dgc_dh = cropRect.height / 3
        for i in 1...2 {
            let dgc_y = CGFloat(i) * dgc_dh + cropRect.minY
            dgc_path.move(to: CGPoint(dgc_x: cropRect.minX + dgc_diff, dgc_y: dgc_y))
            dgc_path.addLine(to: CGPoint(dgc_x: cropRect.maxX - dgc_diff, dgc_y: dgc_y))
        }
        
        return dgc_path
    }
    
    func beginUpdate() {
        let dgc_config = DGCZLPhotoConfiguration.default().editImageConfiguration
        dgc_shadowView.alpha = dgc_config.dimClippedAreaDuringAdjustments ? 1 : 0
        dgc_gridLinesView.alpha = 1
    }
    
    func endUpdate(delay: TimeInterval = 0) {
        UIView.animate(withDuration: 0.15, delay: delay) {
            if !DGCZLPhotoConfiguration.default().editImageConfiguration.dimClippedAreaDuringAdjustments {
                self.dgc_shadowView.alpha = 1
            }
            self.dgc_gridLinesView.alpha = 0
        }
    }
    
    func updateLayers(_ rect: CGRect, animate: Bool, endEditing: Bool) {
        cropRect = rect
        
        let dgc_shadowMaskPath = dgc_getShadowMaskLayerPath()
        let dgc_frameBorderPath = UIBezierPath(rect: rect)
        let dgc_cornerLinesPath = dgc_getCornerLinesLayerPath()
        let dgc_gridLinesPath = dgc_getGridLinesLayerPath()
        
        let dgc_duration: TimeInterval = 0.25
        func animateShadowMaskLayer() {
            dgc_shadowMaskLayer.removeAnimation(forKey: "shadowMaskAnimation")
            let dgc_animation = DGCZLAnimationUtils.dgc_animation(
                type: .path,
                fromValue: dgc_shadowMaskLayer.path,
                toValue: dgc_shadowMaskPath.cgPath,
                dgc_duration: dgc_duration,
                isRemovedOnCompletion: true,
                timingFunction: CAMediaTimingFunction(name: .easeInEaseOut)
            )
            dgc_shadowMaskLayer.add(dgc_animation, forKey: "shadowMaskAnimation")
        }
        
        func animateFrameBorderLayer() {
            dgc_frameBorderLayer.removeAnimation(forKey: "frameBorderAnimation")
            let dgc_animation = DGCZLAnimationUtils.dgc_animation(
                type: .path,
                fromValue: dgc_frameBorderLayer.path,
                toValue: dgc_frameBorderPath.cgPath,
                dgc_duration: dgc_duration,
                isRemovedOnCompletion: true,
                timingFunction: CAMediaTimingFunction(name: .easeInEaseOut)
            )
            dgc_frameBorderLayer.add(dgc_animation, forKey: "frameBorderAnimation")
        }
        
        func animateCornerLinesLayer() {
            dgc_cornerLinesLayer.removeAnimation(forKey: "cornerLinesAnimation")
            let dgc_animation = DGCZLAnimationUtils.dgc_animation(
                type: .path,
                fromValue: dgc_cornerLinesLayer.path,
                toValue: dgc_cornerLinesPath.cgPath,
                dgc_duration: dgc_duration,
                isRemovedOnCompletion: true,
                timingFunction: CAMediaTimingFunction(name: .easeInEaseOut)
            )
            dgc_cornerLinesLayer.add(dgc_animation, forKey: "cornerLinesAnimation")
        }
        
        func animateGridLinesLayer() {
            dgc_gridLinesLayer.removeAnimation(forKey: "gridLinesAnimation")
            let dgc_animation = DGCZLAnimationUtils.dgc_animation(
                type: .path,
                fromValue: dgc_gridLinesLayer.path,
                toValue: dgc_gridLinesPath.cgPath,
                dgc_duration: dgc_duration,
                isRemovedOnCompletion: true,
                timingFunction: CAMediaTimingFunction(name: .easeInEaseOut)
            )
            dgc_gridLinesLayer.add(dgc_animation, forKey: "gridLinesAnimation")
        }
        
        if animate {
            animateShadowMaskLayer()
            animateFrameBorderLayer()
            animateCornerLinesLayer()
            animateGridLinesLayer()
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        dgc_shadowMaskLayer.path = dgc_shadowMaskPath.cgPath
        dgc_frameBorderLayer.path = dgc_frameBorderPath.cgPath
        dgc_cornerLinesLayer.path = dgc_cornerLinesPath.cgPath
        dgc_gridLinesLayer.path = dgc_gridLinesPath.cgPath
        
        CATransaction.commit()
        
        if animate, endEditing {
            endUpdate(delay: dgc_duration)
        }
    }
}
