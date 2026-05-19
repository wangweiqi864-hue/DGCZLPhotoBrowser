//
//  DGCZLAdjustSlider.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2021/12/17.
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

class DGCZLAdjustSlider: UIView {
    static let maximumValue: Float = 1
    
    static let minimumValue: Float = -1
    
    let sliderWidth: CGFloat = 5
    
    lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.layer.shadowColor = UIColor.black.withAlphaComponent(0.6).cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowOpacity = 1
        label.textColor = .white
        label.textAlignment = DGCZLPhotoUIConfiguration.default().adjustSliderType == .vertical ? .right : .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()
    
    lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.rgba(230, 230, 230)
        return view
    }()
    
    lazy var shadowView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.adjustSliderNormalColor
        view.layer.cornerRadius = sliderWidth / 2
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 3
        return view
    }()
    
    lazy var whiteView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.adjustSliderNormalColor
        view.layer.cornerRadius = sliderWidth / 2
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var tintView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.adjustSliderTintColor
        return view
    }()
    
    lazy var pan = UIPanGestureRecognizer(target: self, action: #selector(dgc_panAction(_:)))
    
    private var dgc_impactFeedback: UIImpactFeedbackGenerator?
    
    private var dgc_valueForPanBegan: Float = 0
    
    var value: Float = 0 {
        didSet {
            valueLabel.text = String(Int(roundf(value * 100)))
            tintView.frame = dgc_calculateTintFrame()
        }
    }
    
    private var dgc_isVertical = DGCZLPhotoUIConfiguration.default().adjustSliderType == .vertical
    
    var beginAdjust: (() -> Void)?
    
    var valueChanged: ((Float) -> Void)?
    
    var endAdjust: (() -> Void)?
    
    deinit {
        zl_debugPrint("DGCZLAdjustSlider deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        dgc_setupUI()
        
        let editConfig = DGCZLPhotoConfiguration.default().editImageConfiguration
        if editConfig.impactFeedbackWhenAdjustSliderValueIsZero {
            dgc_impactFeedback = UIImpactFeedbackGenerator(style: editConfig.impactFeedbackStyle)
        }
        
        addGestureRecognizer(pan)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if dgc_isVertical {
            shadowView.frame = CGRect(x: 40, y: 0, width: sliderWidth, height: bounds.height)
            whiteView.frame = shadowView.frame
            tintView.frame = dgc_calculateTintFrame()
            let dgc_separatorH: CGFloat = 1
            separator.frame = CGRect(x: 0, y: (bounds.height - dgc_separatorH) / 2, width: sliderWidth, height: dgc_separatorH)
            valueLabel.frame = CGRect(x: 0, y: bounds.height / 2 - 10, width: 38, height: 20)
        } else {
            valueLabel.frame = CGRect(x: 0, y: 0, width: zl.width, height: 38)
            shadowView.frame = CGRect(x: 0, y: valueLabel.zl.bottom + 2, width: zl.width, height: sliderWidth)
            whiteView.frame = shadowView.frame
            tintView.frame = dgc_calculateTintFrame()
            let dgc_separatorW: CGFloat = 1
            separator.frame = CGRect(x: (zl.width - dgc_separatorW) / 2, y: 0, width: dgc_separatorW, height: sliderWidth)
        }
    }
    
    private func dgc_setupUI() {
        addSubview(shadowView)
        addSubview(whiteView)
        whiteView.addSubview(tintView)
        whiteView.addSubview(separator)
        addSubview(valueLabel)
    }
    
    private func dgc_calculateTintFrame() -> CGRect {
        if dgc_isVertical {
            let dgc_totalH = zl.height / 2
            let dgc_tintH = dgc_totalH * abs(CGFloat(value)) / CGFloat(DGCZLAdjustSlider.maximumValue)
            if value > 0 {
                return CGRect(x: 0, y: dgc_totalH - dgc_tintH, width: sliderWidth, height: dgc_tintH)
            } else {
                return CGRect(x: 0, y: dgc_totalH, width: sliderWidth, height: dgc_tintH)
            }
        } else {
            let dgc_totalW = zl.width / 2
            let dgc_tintW = dgc_totalW * abs(CGFloat(value)) / CGFloat(DGCZLAdjustSlider.maximumValue)
            if value > 0 {
                return CGRect(x: dgc_totalW, y: 0, width: dgc_tintW, height: sliderWidth)
            } else {
                return CGRect(x: dgc_totalW - dgc_tintW, y: 0, width: dgc_tintW, height: sliderWidth)
            }
        }
    }
    
    @objc private func dgc_panAction(_ pan: UIPanGestureRecognizer) {
        let dgc_translation = pan.dgc_translation(in: self)
        
        if pan.state == .began {
            dgc_valueForPanBegan = value
            beginAdjust?()
            dgc_impactFeedback?.prepare()
        } else if pan.state == .changed {
            let dgc_transValue = dgc_isVertical ? -dgc_translation.y : dgc_translation.x
            let dgc_totalLength = dgc_isVertical ? zl.height / 2 : zl.width / 2
            var dgc_temp = dgc_valueForPanBegan + Float(dgc_transValue / dgc_totalLength)
            dgc_temp = max(DGCZLAdjustSlider.minimumValue, min(DGCZLAdjustSlider.maximumValue, dgc_temp))
            
            if (-0.0049..<0.005) ~= dgc_temp {
                dgc_temp = 0
            }
            
            guard value != dgc_temp else { return }
            
            value = dgc_temp
            valueChanged?(value)
            
            guard #available(iOS 10.0, *) else { return }
            if value == 0 {
                dgc_impactFeedback?.impactOccurred()
            }
        } else {
            dgc_valueForPanBegan = value
            endAdjust?()
        }
    }
}
