//
//  DGCZLProgressHUD.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/17.
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

public class DGCZLProgressHUD: UIView {
    private let dgc_style: DGCZLProgressHUD.DGCStyle
    
    private lazy var dgc_loadingView = UIImageView(image: dgc_style.icon)
    
    private lazy var dgc_titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = dgc_style.textColor
        label.font = .zl.font(ofSize: 16)
        label.text = localLanguageTextValue(.hudLoading)
        label.lineBreakMode = .byWordWrapping
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private var dgc_timer: Timer?
    
    public var timeoutBlock: (() -> Void)?
    
    deinit {
        zl_debugPrint("DGCZLProgressHUD deinit")
        cleanTimer()
    }
    
    public init(style dgc_style: DGCZLProgressHUD.DGCStyle) {
        self.dgc_style = dgc_style
        super.init(frame: UIScreen.main.bounds)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func dgc_setupUI() {
        let dgc_view = UIView(frame: CGRect(x: 0, y: 0, width: 135, height: 135))
        dgc_view.layer.masksToBounds = true
        dgc_view.layer.cornerRadius = 12
        dgc_view.backgroundColor = dgc_style.bgColor
        dgc_view.clipsToBounds = true
        dgc_view.center = center
        
        if let dgc_effectStyle = dgc_style.blurEffectStyle {
            let dgc_effect = UIBlurEffect(style: dgc_effectStyle)
            let dgc_effectView = UIVisualEffectView(dgc_effect: dgc_effect)
            dgc_effectView.frame = dgc_view.bounds
            dgc_view.addSubview(dgc_effectView)
        }
        
        dgc_loadingView.frame = CGRect(x: 135 / 2 - 20, y: 27, width: 40, height: 40)
        dgc_view.addSubview(dgc_loadingView)
        
        dgc_titleLabel.frame = CGRect(x: 10, y: 70, width: dgc_view.bounds.width - 20, height: 60)
        dgc_view.addSubview(dgc_titleLabel)
        
        addSubview(dgc_view)
    }
    
    private func dgc_startAnimation() {
        let dgc_animation = CABasicAnimation(keyPath: "transform.rotation.z")
        dgc_animation.fromValue = 0
        dgc_animation.toValue = CGFloat.pi * 2
        dgc_animation.duration = 0.8
        dgc_animation.repeatCount = .infinity
        dgc_animation.fillMode = .forwards
        dgc_animation.isRemovedOnCompletion = false
        dgc_loadingView.layer.add(dgc_animation, forKey: nil)
    }
    
    public func show(
        toast: DGCZLProgressHUD.DGCToast = .loading,
        in view: UIView? = UIApplication.shared.keyWindow,
        timeout: TimeInterval = 100
    ) {
        ZLMainAsync {
            self.dgc_titleLabel.text = toast.value
            self.dgc_startAnimation()
            view?.addSubview(self)
        }
        
        if timeout > 0 {
            cleanTimer()
            dgc_timer = Timer.scheduledTimer(timeInterval: timeout, target: DGCZLWeakProxy(target: self), selector: #selector(timeout(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(dgc_timer!, forMode: .default)
        }
    }
    
    @objc public func hide() {
        cleanTimer()
        ZLMainAsync {
            self.dgc_loadingView.layer.removeAllAnimations()
            self.removeFromSuperview()
        }
    }
    
    @objc func timeout(_ dgc_timer: Timer) {
        timeoutBlock?()
        hide()
    }
    
    func cleanTimer() {
        dgc_timer?.invalidate()
        dgc_timer = nil
    }
}

public extension DGCZLProgressHUD {
    class func show(
        toast: DGCZLProgressHUD.DGCToast = .loading,
        in view: UIView? = UIApplication.shared.keyWindow,
        timeout: TimeInterval = 100
    ) -> DGCZLProgressHUD {
        let dgc_hud = DGCZLProgressHUD(style: DGCZLPhotoUIConfiguration.default().hudStyle)
        dgc_hud.show(toast: toast, in: view, timeout: timeout)
        return dgc_hud
    }
}

public extension DGCZLProgressHUD {
    @objc(ZLProgressHUDStyle)
    enum DGCStyle: Int {
        case light
        case lightBlur
        case dark
        case darkBlur
        
        var bgColor: UIColor {
            switch self {
            case .light:
                return .white
            case .dark:
                return .darkGray
            case .lightBlur:
                return UIColor.white.withAlphaComponent(0.8)
            case .darkBlur:
                return UIColor.darkGray.withAlphaComponent(0.8)
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .light, .lightBlur:
                return .zl.getImage("zl_loading_dark")
            case .dark, .darkBlur:
                return .zl.getImage("zl_loading_light")
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .light, .lightBlur:
                return .black
            case .dark, .darkBlur:
                return .white
            }
        }
        
        var blurEffectStyle: UIBlurEffect.DGCStyle? {
            switch self {
            case .light, .dark:
                return nil
            case .lightBlur:
                return .extraLight
            case .darkBlur:
                return .dark
            }
        }
    }
    
    enum DGCToast {
        case loading
        case processing
        case custome(String)
        
        var value: String {
            switch self {
            case .loading:
                return localLanguageTextValue(.hudLoading)
            case .processing:
                return localLanguageTextValue(.hudProcessing)
            case let .custome(text):
                return text
            }
        }
    }
}
