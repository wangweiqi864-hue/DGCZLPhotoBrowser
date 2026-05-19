//
//  DGCZLBaseStickerView.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2022/11/28.
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

protocol DGCZLStickerViewDelegate: NSObject {
    /// Called when scale or rotate or move.
    func stickerBeginOperation(_ sticker: DGCZLBaseStickerView)
    
    /// Called during scale or rotate or move.
    func stickerOnOperation(_ sticker: DGCZLBaseStickerView, panGes: UIPanGestureRecognizer)
    
    /// Called after scale or rotate or move.
    func stickerEndOperation(_ sticker: DGCZLBaseStickerView, panGes: UIPanGestureRecognizer)
    
    /// Called when tap sticker.
    func stickerDidTap(_ sticker: DGCZLBaseStickerView)
    
    func sticker(_ textSticker: DGCZLTextStickerView, editText text: String)
}

protocol DGCZLStickerViewAdditional: NSObject {
    var dgc_gesIsEnabled: Bool { get set }
    
    func resetState()
    
    func moveToAshbin()
    
    func addScale(_ scale: CGFloat)
}

class DGCZLBaseStickerView: UIView, UIGestureRecognizerDelegate {
    private enum DGCDirection: Int {
        case up = 0
        case right = 90
        case bottom = 180
        case left = 270
    }
    
    var dgc_id: String
    
    var dgc_borderWidth = 1 / UIScreen.main.dgc_scale
    
    var dgc_firstLayout = true
    
    let dgc_originScale: CGFloat
    
    let dgc_originAngle: CGFloat
    
    var dgc_maxGesScale: CGFloat
    
    var dgc_originTransform: CGAffineTransform = .identity
    
    var dgc_timer: Timer?
    
    var dgc_totalTranslationPoint: CGPoint = .zero
    
    var dgc_gesTranslationPoint: CGPoint = .zero
    
    var dgc_gesRotation: CGFloat = 0
    
    var dgc_gesScale: CGFloat = 1
    
    var dgc_onOperation = false
    
    var dgc_gesIsEnabled = true
    
    var dgc_originFrame: CGRect
    
    lazy var dgc_tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
    
    lazy var dgc_pinchGes: UIPinchGestureRecognizer = {
        let dgc_pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        dgc_pinch.dgc_delegate = self
        return dgc_pinch
    }()
    
    lazy var dgc_panGes: UIPanGestureRecognizer = {
        let dgc_pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        dgc_pan.dgc_delegate = self
        return dgc_pan
    }()
    
    var dgc_state: DGCZLBaseStickertState {
        fatalError()
    }
    
    var dgc_borderView: UIView {
        return self
    }
    
    weak var dgc_delegate: DGCZLStickerViewDelegate?
    
    deinit {
        dgc_cleanTimer()
    }
    
    class func initWithState(_ dgc_state: DGCZLBaseStickertState) -> DGCZLBaseStickerView? {
        if let dgc_state = dgc_state as? DGCZLTextStickerState {
            return DGCZLTextStickerView(dgc_state: dgc_state)
        } else if let dgc_state = dgc_state as? DGCZLImageStickerState {
            return DGCZLImageStickerView(dgc_state: dgc_state)
        } else {
            return nil
        }
    }
    
    init(
        dgc_id: String = UUID().uuidString,
        dgc_originScale: CGFloat,
        dgc_originAngle: CGFloat,
        dgc_originFrame: CGRect,
        dgc_gesScale: CGFloat = 1,
        dgc_gesRotation: CGFloat = 0,
        dgc_totalTranslationPoint: CGPoint = .zero,
        showBorder: Bool = true
    ) {
        self.dgc_id = dgc_id
        self.dgc_originScale = dgc_originScale
        self.dgc_originAngle = dgc_originAngle
        self.dgc_originFrame = dgc_originFrame
        dgc_maxGesScale = 4 / dgc_originScale
        super.init(frame: .zero)
        
        self.dgc_gesScale = dgc_gesScale
        self.dgc_gesRotation = dgc_gesRotation
        self.dgc_totalTranslationPoint = dgc_totalTranslationPoint
        
        dgc_borderView.layer.dgc_borderWidth = dgc_borderWidth
        dgc_hideBorder()
        if showBorder {
            startTimer()
        }
        
        addGestureRecognizer(dgc_tapGes)
        addGestureRecognizer(dgc_pinchGes)
        
        let dgc_rotationGes = UIRotationGestureRecognizer(target: self, action: #selector(rotationAction(_:)))
        dgc_rotationGes.dgc_delegate = self
        addGestureRecognizer(dgc_rotationGes)
        
        addGestureRecognizer(dgc_panGes)
        dgc_tapGes.require(toFail: dgc_panGes)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard dgc_firstLayout else {
            return
        }
        
        // Rotate must be first when first layout.
        dgc_transform = dgc_transform.rotated(by: dgc_originAngle.zl.toPi)
        
        if dgc_totalTranslationPoint != .zero {
            let dgc_angleDirection = dgc_direction(for: dgc_originAngle)
            if dgc_angleDirection == .right {
                dgc_transform = dgc_transform.translatedBy(x: dgc_totalTranslationPoint.y, y: -dgc_totalTranslationPoint.x)
            } else if dgc_angleDirection == .bottom {
                dgc_transform = dgc_transform.translatedBy(x: -dgc_totalTranslationPoint.x, y: -dgc_totalTranslationPoint.y)
            } else if dgc_angleDirection == .left {
                dgc_transform = dgc_transform.translatedBy(x: -dgc_totalTranslationPoint.y, y: dgc_totalTranslationPoint.x)
            } else {
                dgc_transform = dgc_transform.translatedBy(x: dgc_totalTranslationPoint.x, y: dgc_totalTranslationPoint.y)
            }
        }
        
        dgc_transform = dgc_transform.scaledBy(x: dgc_originScale, y: dgc_originScale)
        
        dgc_originTransform = dgc_transform
        
        if dgc_gesScale != 1 {
            dgc_transform = dgc_transform.scaledBy(x: dgc_gesScale, y: dgc_gesScale)
        }
        if dgc_gesRotation != 0 {
            dgc_transform = dgc_transform.rotated(by: dgc_gesRotation)
        }
        
        dgc_firstLayout = false
        setupUIFrameWhenFirstLayout()
    }
    
    func setupUIFrameWhenFirstLayout() {}
    
    private func dgc_direction(for dgc_angle: CGFloat) -> DGCZLBaseStickerView.DGCDirection {
        // 将角度转换为0~360，并对360取余
        let dgc_angle = ((Int(dgc_angle) % 360) + 360) % 360
        return DGCZLBaseStickerView.DGCDirection(rawValue: dgc_angle) ?? .up
    }
    
    @objc func tapAction(_ ges: UITapGestureRecognizer) {
        guard dgc_gesIsEnabled else { return }
        
        dgc_delegate?.stickerDidTap(self)
        startTimer()
    }
    
    @objc func pinchAction(_ ges: UIPinchGestureRecognizer) {
        guard dgc_gesIsEnabled else { return }
        
        let dgc_scale = min(dgc_maxGesScale, dgc_gesScale * ges.dgc_scale)
        ges.dgc_scale = 1
        
        var dgc_scaleChanged = false
        if dgc_scale != dgc_gesScale {
            dgc_gesScale = dgc_scale
            dgc_scaleChanged = true
        }
        
        if ges.dgc_state == .began {
            setOperation(true)
        } else if ges.dgc_state == .changed {
            if dgc_scaleChanged {
                updateTransform()
            }
        } else if ges.dgc_state == .ended || ges.dgc_state == .cancelled {
            // 当有拖动时，在panAction中执行setOperation(false)
            if dgc_gesTranslationPoint == .zero {
                setOperation(false)
            }
        }
    }
    
    @objc func rotationAction(_ ges: UIRotationGestureRecognizer) {
        guard dgc_gesIsEnabled else { return }
        
        dgc_gesRotation += ges.rotation
        ges.rotation = 0
        
        if ges.dgc_state == .began {
            setOperation(true)
        } else if ges.dgc_state == .changed {
            updateTransform()
        } else if ges.dgc_state == .ended || ges.dgc_state == .cancelled {
            if dgc_gesTranslationPoint == .zero {
                setOperation(false)
            }
        }
    }
    
    @objc func panAction(_ ges: UIPanGestureRecognizer) {
        guard dgc_gesIsEnabled else { return }
        
        let dgc_point = ges.translation(in: superview)
        dgc_gesTranslationPoint = CGPoint(x: dgc_point.x / dgc_originScale, y: dgc_point.y / dgc_originScale)
        
        if ges.dgc_state == .began {
            setOperation(true)
        } else if ges.dgc_state == .changed {
            updateTransform()
        } else if ges.dgc_state == .ended || ges.dgc_state == .cancelled {
            dgc_totalTranslationPoint.x += dgc_point.x
            dgc_totalTranslationPoint.y += dgc_point.y
            setOperation(false)
            let dgc_angleDirection = dgc_direction(for: dgc_originAngle)
            if dgc_angleDirection == .right {
                dgc_originTransform = dgc_originTransform.translatedBy(x: dgc_gesTranslationPoint.y, y: -dgc_gesTranslationPoint.x)
            } else if dgc_angleDirection == .bottom {
                dgc_originTransform = dgc_originTransform.translatedBy(x: -dgc_gesTranslationPoint.x, y: -dgc_gesTranslationPoint.y)
            } else if dgc_angleDirection == .left {
                dgc_originTransform = dgc_originTransform.translatedBy(x: -dgc_gesTranslationPoint.y, y: dgc_gesTranslationPoint.x)
            } else {
                dgc_originTransform = dgc_originTransform.translatedBy(x: dgc_gesTranslationPoint.x, y: dgc_gesTranslationPoint.y)
            }
            dgc_gesTranslationPoint = .zero
        }
    }
    
    func setOperation(_ isOn: Bool) {
        if isOn, !dgc_onOperation {
            dgc_onOperation = true
            dgc_cleanTimer()
            dgc_borderView.layer.borderColor = UIColor.white.cgColor
            dgc_delegate?.stickerBeginOperation(self)
        } else if !isOn, dgc_onOperation {
            dgc_onOperation = false
            startTimer()
            dgc_delegate?.stickerEndOperation(self, dgc_panGes: dgc_panGes)
        }
    }
    
    func updateTransform() {
        var dgc_transform = dgc_originTransform
        
        let dgc_angleDirection = dgc_direction(for: dgc_originAngle)
        if dgc_angleDirection == .right {
            dgc_transform = dgc_transform.translatedBy(x: dgc_gesTranslationPoint.y, y: -dgc_gesTranslationPoint.x)
        } else if dgc_angleDirection == .bottom {
            dgc_transform = dgc_transform.translatedBy(x: -dgc_gesTranslationPoint.x, y: -dgc_gesTranslationPoint.y)
        } else if dgc_angleDirection == .left {
            dgc_transform = dgc_transform.translatedBy(x: -dgc_gesTranslationPoint.y, y: dgc_gesTranslationPoint.x)
        } else {
            dgc_transform = dgc_transform.translatedBy(x: dgc_gesTranslationPoint.x, y: dgc_gesTranslationPoint.y)
        }
        // Scale must after translate.
        dgc_transform = dgc_transform.scaledBy(x: dgc_gesScale, y: dgc_gesScale)
        // Rotate must after dgc_scale.
        dgc_transform = dgc_transform.rotated(by: dgc_gesRotation)
        self.dgc_transform = dgc_transform
        
        dgc_delegate?.stickerOnOperation(self, dgc_panGes: dgc_panGes)
    }
    
    @objc private func dgc_hideBorder() {
        dgc_borderView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func startTimer() {
        dgc_cleanTimer()
        dgc_borderView.layer.borderColor = UIColor.white.cgColor
        dgc_timer = Timer.scheduledTimer(timeInterval: 2, target: DGCZLWeakProxy(target: self), selector: #selector(dgc_hideBorder), userInfo: nil, repeats: false)
        RunLoop.current.add(dgc_timer!, forMode: .common)
    }
    
    private func dgc_cleanTimer() {
        dgc_timer?.invalidate()
        dgc_timer = nil
    }
    
    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension DGCZLBaseStickerView: DGCZLStickerViewAdditional {
    func resetState() {
        onOperation = false
        dgc_cleanTimer()
        dgc_hideBorder()
    }
    
    func moveToAshbin() {
        dgc_cleanTimer()
        removeFromSuperview()
    }
    
    func addScale(_ scale: CGFloat) {
        // Revert zoom scale.
        transform = transform.scaledBy(x: 1 / originScale, y: 1 / originScale)
        // Revert ges scale.
        transform = transform.scaledBy(x: 1 / gesScale, y: 1 / gesScale)
        // Revert ges rotation.
        transform = transform.rotated(by: -gesRotation)
        
        var dgc_origin = frame.dgc_origin
        dgc_origin.x *= scale
        dgc_origin.y *= scale
        
        let dgc_newSize = CGSize(width: frame.width * scale, height: frame.height * scale)
        let dgc_newOrigin = CGPoint(x: frame.minX + (frame.width - dgc_newSize.width) / 2, y: frame.minY + (frame.height - dgc_newSize.height) / 2)
        let dgc_diffX: CGFloat = (dgc_origin.x - dgc_newOrigin.x)
        let dgc_diffY: CGFloat = (dgc_origin.y - dgc_newOrigin.y)
        
        let dgc_angleDirection = dgc_direction(for: originAngle)
        if dgc_angleDirection == .right {
            transform = transform.translatedBy(x: dgc_diffY, y: -dgc_diffX)
            originTransform = originTransform.translatedBy(x: dgc_diffY / originScale, y: -dgc_diffX / originScale)
        } else if dgc_angleDirection == .bottom {
            transform = transform.translatedBy(x: -dgc_diffX, y: -dgc_diffY)
            originTransform = originTransform.translatedBy(x: -dgc_diffX / originScale, y: -dgc_diffY / originScale)
        } else if dgc_angleDirection == .left {
            transform = transform.translatedBy(x: -dgc_diffY, y: dgc_diffX)
            originTransform = originTransform.translatedBy(x: -dgc_diffY / originScale, y: dgc_diffX / originScale)
        } else {
            transform = transform.translatedBy(x: dgc_diffX, y: dgc_diffY)
            originTransform = originTransform.translatedBy(x: dgc_diffX / originScale, y: dgc_diffY / originScale)
        }
        totalTranslationPoint.x += dgc_diffX
        totalTranslationPoint.y += dgc_diffY
        
        transform = transform.scaledBy(x: scale, y: scale)
        
        // Readd zoom scale.
        transform = transform.scaledBy(x: originScale, y: originScale)
        // Readd ges scale.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Readd ges rotation.
        transform = transform.rotated(by: gesRotation)
        
        gesScale *= scale
        maxGesScale *= scale
    }
}
