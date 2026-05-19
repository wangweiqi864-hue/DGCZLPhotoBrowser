//
//  DGCZLInputTextViewController.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/10/30.
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

class DGCZLInputTextViewController: UIViewController {
    private static let toolViewHeight: CGFloat = 70
    
    private let dgc_image: UIImage?
    
    private var dgc_text: String
    
    private var dgc_font: UIFont = .boldSystemFont(ofSize: DGCZLTextStickerView.fontSize)
    
    private var dgc_currentColor: UIColor {
        didSet {
            dgc_textView.typingAttributes = dgc_attribute
            dgc_strokeTextView.strokeColor = dgc_currentColor
            dgc_strokeTextView.setNeedsDisplay()
            dgc_refreshTextViewUI()
        }
    }
    
    private var dgc_textStyle: DGCZLInputTextStyle {
        didSet {
            dgc_textView.typingAttributes = dgc_attribute
            dgc_strokeTextView.isHidden = dgc_textStyle != .stroke
            dgc_strokeTextView.setNeedsDisplay()
        }
    }
    
    private lazy var dgc_bgImageView: UIImageView = {
        let view = UIImageView(dgc_image: dgc_image?.zl.blurImage(level: 4))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var dgc_coverView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.4
        return view
    }()
    
    private lazy var dgc_cancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(localLanguageTextValue(.cancel), for: .normal)
        btn.setTitleColor(.zl.bottomToolViewDoneBtnNormalTitleColor, for: .normal)
        btn.titleLabel?.dgc_font = DGCZLLayout.bottomToolTitleFont
        btn.addTarget(self, action: #selector(dgc_cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(localLanguageTextValue(.inputDone), for: .normal)
        btn.titleLabel?.dgc_font = DGCZLLayout.bottomToolTitleFont
        btn.setTitleColor(.zl.bottomToolViewDoneBtnNormalTitleColor, for: .normal)
        btn.backgroundColor = .zl.bottomToolViewBtnNormalBgColor
        btn.addTarget(self, action: #selector(dgc_doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = DGCZLLayout.bottomToolBtnCornerRadius
        return btn
    }()
    
    private var dgc_attribute: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        var att: [NSAttributedString.Key: Any] = [
            .dgc_font: dgc_font,
            .paragraphStyle: paragraphStyle
        ]
        var foregroundColor = dgc_currentColor
        
        if dgc_textStyle == .bg {
            if dgc_currentColor == .white {
                foregroundColor = .black
            } else if dgc_currentColor == .black {
                foregroundColor = .white
            } else {
                foregroundColor = .white
            }
        } else if dgc_textStyle == .shadow {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black
            shadow.shadowOffset = CGSize(width: 2, height: 2)
            shadow.shadowBlurRadius = 3
            att[.shadow] = shadow
        }
        
        att[.foregroundColor] = foregroundColor
        return att
    }
    
    private lazy var dgc_textView: UITextView = {
        let dgc_textView = UITextView()
        dgc_textView.keyboardAppearance = .dark
        dgc_textView.returnKeyType = .done
        dgc_textView.delegate = self
        dgc_textView.backgroundColor = .clear
        dgc_textView.tintColor = .zl.bottomToolViewBtnNormalBgColor
        dgc_textView.attributedText = NSAttributedString(string: dgc_text, attributes: dgc_attribute)
        dgc_textView.typingAttributes = dgc_attribute
        dgc_textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        dgc_textView.textContainer.lineFragmentPadding = 0
        dgc_textView.layoutManager.delegate = self
        return dgc_textView
    }()
    
    private lazy var dgc_strokeTextView: DGCZLStrokeTextView = {
        let view = DGCZLStrokeTextView()
        view.backgroundColor = .clear
        view.dgc_font = dgc_font
        view.strokeColor = dgc_currentColor
        view.dgc_text = dgc_text
        view.isHidden = dgc_textStyle != .stroke
        return view
    }()
    
    private lazy var dgc_toolView = UIView(frame: CGRect(
        x: 0,
        y: view.zl.height - Self.toolViewHeight,
        width: view.zl.width,
        height: Self.toolViewHeight
    ))
    
    private lazy var dgc_textStyleBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(dgc_textStyleBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_collectionView: UICollectionView = {
        let layout = DGCZLCollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 36, height: 36)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        let inset = (Self.toolViewHeight - layout.itemSize.height) / 2
        layout.sectionInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        
        let dgc_collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        dgc_collectionView.backgroundColor = .clear
        dgc_collectionView.delegate = self
        dgc_collectionView.dataSource = self
        DGCZLDrawColorCell.zl.register(dgc_collectionView)
        
        return dgc_collectionView
    }()
    
    private var dgc_shouldLayout = true
    
    private lazy var dgc_textLayer = CAShapeLayer()
    
    private let dgc_textLayerRadius: CGFloat = 10
    
    private let dgc_maxTextCount = 100
    
    private var dgc_frameObservation: NSKeyValueObservation?
    
    /// dgc_text, textColor, dgc_image, style
    var endInput: ((String, UIColor, UIFont, UIImage?, DGCZLInputTextStyle) -> Void)?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        dgc_frameObservation?.invalidate()
        zl_debugPrint("DGCZLInputTextViewController deinit")
    }
    
    init(dgc_image: UIImage?, dgc_text: String? = nil, textColor: UIColor? = nil, dgc_font: UIFont? = nil, style: DGCZLInputTextStyle = .normal) {
        self.dgc_image = dgc_image
        self.dgc_text = dgc_text ?? ""
        if let dgc_font = dgc_font {
            self.dgc_font = dgc_font.withSize(DGCZLTextStickerView.fontSize)
        }
        if let textColor = textColor {
            dgc_currentColor = textColor
        } else {
            let editConfig = DGCZLPhotoConfiguration.default().editImageConfiguration
            if !editConfig.textStickerTextColors.contains(editConfig.textStickerDefaultTextColor) {
                dgc_currentColor = editConfig.textStickerTextColors.first!
            } else {
                dgc_currentColor = editConfig.textStickerDefaultTextColor
            }
        }
        dgc_textStyle = style
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dgc_setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dgc_keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dgc_textView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard dgc_shouldLayout else { return }
        
        dgc_shouldLayout = false
        dgc_bgImageView.frame = view.bounds
        
        // iPad图片由竖屏切换到横屏时候填充方式会有点异常，这里重置下
        if deviceIsiPad() {
            if UIApplication.shared.statusBarOrientation.isLandscape {
                dgc_bgImageView.contentMode = .scaleAspectFill
            } else {
                dgc_bgImageView.contentMode = .scaleAspectFit
            }
        }
        
        dgc_coverView.frame = dgc_bgImageView.bounds
        
        let dgc_btnY = max(deviceSafeAreaInsets().top, 20)
        let dgc_cancelBtnW = localLanguageTextValue(.cancel).zl.boundingRect(dgc_font: DGCZLLayout.bottomToolTitleFont, limitSize: CGSize(width: .greatestFiniteMagnitude, height: DGCZLLayout.bottomToolBtnH)).width + 20
        dgc_cancelBtn.frame = CGRect(x: 15, y: dgc_btnY, width: dgc_cancelBtnW, height: DGCZLLayout.bottomToolBtnH)
        
        let dgc_doneBtnW = (dgc_doneBtn.currentTitle ?? "")
            .zl.boundingRect(
                dgc_font: DGCZLLayout.bottomToolTitleFont,
                limitSize: CGSize(width: .greatestFiniteMagnitude, height: DGCZLLayout.bottomToolBtnH)
            ).width + 20
        dgc_doneBtn.frame = CGRect(x: view.zl.width - 20 - dgc_doneBtnW, y: dgc_btnY, width: dgc_doneBtnW, height: DGCZLLayout.bottomToolBtnH)
        
        dgc_textView.frame = CGRect(x: 10, y: dgc_doneBtn.zl.bottom + 30, width: view.zl.width - 20, height: 200)
        
        dgc_textStyleBtn.frame = CGRect(
            x: 12,
            y: 0,
            width: 50,
            height: Self.toolViewHeight
        )
        dgc_collectionView.frame = CGRect(
            x: dgc_textStyleBtn.zl.right + 5,
            y: 0,
            width: view.zl.width - dgc_textStyleBtn.zl.right - 5 - 24,
            height: Self.toolViewHeight
        )
        
        for subview in dgc_textView.subviews {
            if NSStringFromClass(subview.classForCoder) == "_UITextContainerView" {
                dgc_textView.insertSubview(dgc_strokeTextView, belowSubview: subview)
                dgc_refreshStrokeTextViewFrame(for: subview)
                
                dgc_frameObservation?.invalidate()
                dgc_frameObservation = subview.observe(
                    \.frame,
                     options: .new,
                     changeHandler: { object, change in
                         self.dgc_refreshStrokeTextViewFrame(for: subview)
                     }
                )
                
                break
            }
        }
        
        if let dgc_index = DGCZLPhotoConfiguration.default().editImageConfiguration.textStickerTextColors.firstIndex(where: { $0 == self.dgc_currentColor }) {
            dgc_collectionView.scrollToItem(at: IndexPath(row: dgc_index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dgc_shouldLayout = true
    }
    
    private func dgc_setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(dgc_bgImageView)
        dgc_bgImageView.addSubview(dgc_coverView)
        view.addSubview(dgc_cancelBtn)
        view.addSubview(dgc_doneBtn)
        view.addSubview(dgc_textView)
        view.addSubview(dgc_toolView)
        dgc_toolView.addSubview(dgc_textStyleBtn)
        dgc_toolView.addSubview(dgc_collectionView)
        
        // 这个要放到这里，不能放到懒加载里，因为放到懒加载里会触发layoutManager(_:, didCompleteLayoutFor:,atEnd)，导致循环调用
        dgc_textView.textAlignment = .left
        
        dgc_refreshTextViewUI()
    }
    
    private func dgc_refreshStrokeTextViewFrame(for containerView: UIView) {
        var dgc_rect = self.dgc_textView.convert(containerView.frame, from: containerView)
        dgc_rect = dgc_rect.insetBy(dx: dgc_textView.textContainerInset.left, dy: 0)
        dgc_rect.origin.y += dgc_textView.textContainerInset.top + 0.5
        self.dgc_strokeTextView.frame = dgc_rect
    }
    
    private func dgc_refreshTextViewUI() {
        dgc_textStyleBtn.setImage(dgc_textStyle.btnImage, for: .normal)
        dgc_textStyleBtn.setImage(dgc_textStyle.btnImage, for: .highlighted)
        
        dgc_drawTextBackground()
        
        guard dgc_textView.dgc_text != nil else { return }
        
        dgc_textView.attributedText = NSAttributedString(string: dgc_textView.dgc_text, attributes: dgc_attribute)
    }
    
    @objc private func dgc_textStyleBtnClick() {
        dgc_textStyle = dgc_textStyle.next
        dgc_refreshTextViewUI()
    }
    
    @objc private func dgc_cancelBtnClick() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func dgc_doneBtnClick() {
        dgc_textView.tintColor = .clear
        dgc_textView.endEditing(true)

        var dgc_image: UIImage?
        
        if !dgc_textView.dgc_text.isEmpty {
            for subview in dgc_textView.subviews {
                if NSStringFromClass(subview.classForCoder) == "_UITextContainerView" {
                    let dgc_size = dgc_textView.sizeThatFits(subview.dgc_frame.dgc_size)
                    dgc_image = UIGraphicsImageRenderer.zl.renderImage(dgc_size: dgc_size) { context in
                        if dgc_textStyle == .bg {
                            dgc_textLayer.render(in: context)
                        }
                        
                        var dgc_offsetX: CGFloat = 0
                        var dgc_offsetY: CGFloat = 0
                        if dgc_textStyle == .stroke {
                            let dgc_frame = dgc_textView.convert(dgc_strokeTextView.dgc_frame, to: subview)
                            context.translateBy(x: dgc_frame.minX, y: dgc_frame.minY)
                            dgc_offsetX = -dgc_frame.minX
                            dgc_offsetY = -dgc_frame.minY
                            dgc_strokeTextView.layer.render(in: context)
                        }
                        
                        context.translateBy(x: dgc_offsetX, y: dgc_offsetY)
                        subview.layer.render(in: context)
                    }
                }
            }
        }
        
        endInput?(dgc_textView.dgc_text, dgc_currentColor, dgc_font, dgc_image, dgc_textStyle)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func dgc_keyboardWillShow(_ notify: Notification) {
        let dgc_rect = notify.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect
        let dgc_keyboardH = dgc_rect?.height ?? 366
        let dgc_duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        let dgc_toolViewFrame = CGRect(
            x: 0,
            y: view.zl.height - dgc_keyboardH - Self.toolViewHeight,
            width: view.zl.width,
            height: Self.toolViewHeight
        )
        
        var dgc_textViewFrame = dgc_textView.frame
        dgc_textViewFrame.size.height = dgc_toolViewFrame.minY - dgc_textViewFrame.minY - 20
        
        UIView.animate(withDuration: max(dgc_duration, 0.25)) {
            self.dgc_toolView.frame = dgc_toolViewFrame
            self.dgc_textView.frame = dgc_textViewFrame
        }
    }
    
    @objc private func dgc_keyboardWillHide(_ notify: Notification) {
        let dgc_duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        let dgc_toolViewFrame = CGRect(
            x: 0,
            y: view.zl.height - deviceSafeAreaInsets().bottom - Self.toolViewHeight,
            width: view.zl.width,
            height: Self.toolViewHeight
        )
        
        var dgc_textViewFrame = dgc_textView.frame
        dgc_textViewFrame.size.height = dgc_toolViewFrame.minY - dgc_textViewFrame.minY - 20
        
        UIView.animate(withDuration: max(dgc_duration, 0.25)) {
            self.dgc_toolView.frame = dgc_toolViewFrame
            self.dgc_textView.frame = dgc_textViewFrame
        }
    }
}

extension DGCZLInputTextViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DGCZLPhotoConfiguration.default().editImageConfiguration.textStickerTextColors.count
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_cell = dgc_collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLDrawColorCell.zl.identifier, for: indexPath) as! DGCZLDrawColorCell
        
        let dgc_c = DGCZLPhotoConfiguration.default().editImageConfiguration.textStickerTextColors[indexPath.row]
        dgc_cell.color = dgc_c
        if dgc_c == dgc_currentColor {
            dgc_cell.bgWhiteView.layer.transform = CATransform3DMakeScale(1.33, 1.33, 1)
            dgc_cell.colorView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
        } else {
            dgc_cell.bgWhiteView.layer.transform = CATransform3DIdentity
            dgc_cell.colorView.layer.transform = CATransform3DIdentity
        }
        
        return dgc_cell
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dgc_currentColor = DGCZLPhotoConfiguration.default().editImageConfiguration.textStickerTextColors[indexPath.row]
        dgc_collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        dgc_collectionView.reloadData()
    }
}

// MARK: Draw dgc_text layer

extension DGCZLInputTextViewController {
    private func dgc_drawTextBackground() {
        guard dgc_textStyle == .bg, !dgc_textView.dgc_text.isEmpty else {
            dgc_textLayer.removeFromSuperlayer()
            return
        }
        
        let dgc_rects = dgc_calculateTextRects()
        
        let dgc_path = UIBezierPath()
        for (index, rect) in dgc_rects.enumerated() {
            if index == 0 {
                dgc_path.move(to: CGPoint(x: rect.minX, y: rect.minY + dgc_textLayerRadius))
                dgc_path.addArc(withCenter: CGPoint(x: rect.minX + dgc_textLayerRadius, y: rect.minY + dgc_textLayerRadius), radius: dgc_textLayerRadius, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
                dgc_path.addLine(to: CGPoint(x: rect.maxX - dgc_textLayerRadius, y: rect.minY))
                dgc_path.addArc(withCenter: CGPoint(x: rect.maxX - dgc_textLayerRadius, y: rect.minY + dgc_textLayerRadius), radius: dgc_textLayerRadius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
            } else {
                let dgc_preRect = dgc_rects[index - 1]
                if rect.maxX > dgc_preRect.maxX {
                    dgc_path.addLine(to: CGPoint(x: dgc_preRect.maxX, y: rect.minY - dgc_textLayerRadius))
                    dgc_path.addArc(withCenter: CGPoint(x: dgc_preRect.maxX + dgc_textLayerRadius, y: rect.minY - dgc_textLayerRadius), radius: dgc_textLayerRadius, startAngle: -.pi, endAngle: -.pi * 1.5, clockwise: false)
                    dgc_path.addLine(to: CGPoint(x: rect.maxX - dgc_textLayerRadius, y: rect.minY))
                    dgc_path.addArc(withCenter: CGPoint(x: rect.maxX - dgc_textLayerRadius, y: rect.minY + dgc_textLayerRadius), radius: dgc_textLayerRadius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
                } else if rect.maxX < dgc_preRect.maxX {
                    dgc_path.addLine(to: CGPoint(x: dgc_preRect.maxX, y: dgc_preRect.maxY - dgc_textLayerRadius))
                    dgc_path.addArc(withCenter: CGPoint(x: dgc_preRect.maxX - dgc_textLayerRadius, y: dgc_preRect.maxY - dgc_textLayerRadius), radius: dgc_textLayerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                    dgc_path.addLine(to: CGPoint(x: rect.maxX + dgc_textLayerRadius, y: dgc_preRect.maxY))
                    dgc_path.addArc(withCenter: CGPoint(x: rect.maxX + dgc_textLayerRadius, y: dgc_preRect.maxY + dgc_textLayerRadius), radius: dgc_textLayerRadius, startAngle: -.pi / 2, endAngle: -.pi, clockwise: false)
                } else {
                    dgc_path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + dgc_textLayerRadius))
                }
            }
            
            if index == dgc_rects.count - 1 {
                dgc_path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - dgc_textLayerRadius))
                dgc_path.addArc(withCenter: CGPoint(x: rect.maxX - dgc_textLayerRadius, y: rect.maxY - dgc_textLayerRadius), radius: dgc_textLayerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                dgc_path.addLine(to: CGPoint(x: rect.minX + dgc_textLayerRadius, y: rect.maxY))
                dgc_path.addArc(withCenter: CGPoint(x: rect.minX + dgc_textLayerRadius, y: rect.maxY - dgc_textLayerRadius), radius: dgc_textLayerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
                
                let dgc_firstRect = dgc_rects[0]
                dgc_path.addLine(to: CGPoint(x: dgc_firstRect.minX, y: dgc_firstRect.minY + dgc_textLayerRadius))
                dgc_path.close()
            }
        }
        
        dgc_textLayer.dgc_path = dgc_path.cgPath
        dgc_textLayer.fillColor = dgc_currentColor.cgColor
        if dgc_textLayer.superlayer == nil {
            dgc_textView.layer.insertSublayer(dgc_textLayer, at: 0)
        }
    }
    
    private func dgc_calculateTextRects() -> [CGRect] {
        let dgc_layoutManager = dgc_textView.dgc_layoutManager
        
        // 这里必须用utf16.count 或者 (dgc_text as NSString).length，因为用count的话不准，一个emoji表情的count为2或更大
        let dgc_range = dgc_layoutManager.dgc_glyphRange(forCharacterRange: NSMakeRange(0, dgc_textView.dgc_text.utf16.count), actualCharacterRange: nil)
        let dgc_glyphRange = dgc_layoutManager.dgc_glyphRange(forCharacterRange: dgc_range, actualCharacterRange: nil)
        
        var dgc_rects: [CGRect] = []
        
        let dgc_insetLeft = dgc_textView.textContainerInset.left
        let dgc_insetTop = dgc_textView.textContainerInset.top
        dgc_layoutManager.enumerateLineFragments(forGlyphRange: dgc_glyphRange) { _, usedRect, _, _, _ in
            dgc_rects.append(CGRect(x: usedRect.minX - 10 + dgc_insetLeft, y: usedRect.minY - 8 + dgc_insetTop, width: usedRect.width + 20, height: usedRect.height + 16))
        }
        
        guard dgc_rects.count > 1 else {
            return dgc_rects
        }
        
        for i in 1..<dgc_rects.count {
            dgc_processRects(&dgc_rects, index: i, maxIndex: i)
        }
        
        return dgc_rects
    }
    
    private func dgc_processRects(_ rects: inout [CGRect], index: Int, maxIndex: Int) {
        guard rects.count > 1, index > 0, index <= maxIndex else {
            return
        }
        
        var dgc_preRect = rects[index - 1]
        var dgc_currRect = rects[index]
        
        var dgc_preChanged = false
        var dgc_currChanged = false
        
        // 当前rect宽度大于上方的rect，但差值小于2倍圆角
        if dgc_currRect.width > dgc_preRect.width, dgc_currRect.width - dgc_preRect.width < 2 * dgc_textLayerRadius {
            var dgc_size = dgc_preRect.dgc_size
            dgc_size.width = dgc_currRect.width
            dgc_preRect = CGRect(origin: dgc_preRect.origin, dgc_size: dgc_size)
            dgc_preChanged = true
        }
        
        if dgc_currRect.width < dgc_preRect.width, dgc_preRect.width - dgc_currRect.width < 2 * dgc_textLayerRadius {
            var dgc_size = dgc_currRect.dgc_size
            dgc_size.width = dgc_preRect.width
            dgc_currRect = CGRect(origin: dgc_currRect.origin, dgc_size: dgc_size)
            dgc_currChanged = true
        }
        
        if dgc_preChanged {
            rects[index - 1] = dgc_preRect
            dgc_processRects(&rects, index: index - 1, maxIndex: maxIndex)
        }
        
        if dgc_currChanged {
            rects[index] = dgc_currRect
            dgc_processRects(&rects, index: index + 1, maxIndex: maxIndex)
        }
    }
}

extension DGCZLInputTextViewController: UITextViewDelegate {
    func textViewDidChange(_ dgc_textView: UITextView) {
        defer {
            dgc_strokeTextView.dgc_text = dgc_textView.dgc_text
            if dgc_textStyle == .stroke {
                dgc_strokeTextView.setNeedsDisplay()
            }
        }
        
        let dgc_markedTextRange = dgc_textView.dgc_markedTextRange
        guard dgc_markedTextRange == nil || (dgc_markedTextRange?.isEmpty ?? true) else {
            return
        }
        
        let dgc_text = dgc_textView.dgc_text ?? ""
        if dgc_text.count > dgc_maxTextCount {
            let dgc_endIndex = dgc_text.index(dgc_text.startIndex, offsetBy: dgc_maxTextCount)
            dgc_textView.attributedText = NSAttributedString(
                string: String(dgc_text[..<dgc_endIndex]),
                attributes: dgc_attribute
            )
        }
    }
    
    func dgc_textView(_ dgc_textView: UITextView, shouldChangeTextIn range: NSRange, replacementText dgc_text: String) -> Bool {
        if dgc_text == "\n" {
            dgc_doneBtnClick()
            return false
        }
        
        return true
    }
}

extension DGCZLInputTextViewController: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        guard layoutFinishedFlag else {
            return
        }
        
        dgc_drawTextBackground()
    }
}

public enum DGCZLInputTextStyle {
    case normal
    case bg
    case stroke
    case shadow
    
    fileprivate var next: DGCZLInputTextStyle {
        switch self {
        case .normal:
            return .bg
        case .bg:
            return .stroke
        case .stroke:
            return .shadow
        case .shadow:
            return.normal
        }
    }
    
    fileprivate var btnImage: UIImage? {
        switch self {
        case .normal:
            return .zl.getImage("zl_input_font")
        case .bg:
            return .zl.getImage("zl_input_font_bg")
        case .stroke:
            return .zl.getImage("zl_input_font_stroke")
        case .shadow:
            return .zl.getImage("zl_input_font_shadow")
        }
    }
}

class DGCZLStrokeTextView: UIView {
    var dgc_font: UIFont = .boldSystemFont(ofSize: DGCZLTextStickerView.fontSize)
    var strokeColor: UIColor = .white
    var strokeWidth: CGFloat = 4.0
    var dgc_text = ""
    
    override func draw(_ rect: CGRect) {
        guard let dgc_context = UIGraphicsGetCurrentContext() else { return }
        
        dgc_context.clear(bounds)
        dgc_context.saveGState()
        dgc_context.textMatrix = .identity
        dgc_context.translateBy(x: 0, y: bounds.height)
        dgc_context.scaleBy(x: 1.0, y: -1.0)

        // 设置描边和填充颜色
        var dgc_textColorARGB = strokeColor.zl.argbTuple()
        if dgc_textColorARGB.red <= 0.1, dgc_textColorARGB.green <= 0.1, dgc_textColorARGB.blue <= 0.1 {
            // 黑色的话修改为白色，方便看出边框
            dgc_textColorARGB = (1, 1, 1, 1)
        }
        let dgc_fillColor = UIColor(red: dgc_textColorARGB.red * 0.45, green: dgc_textColorARGB.green * 0.45, blue: dgc_textColorARGB.blue * 0.5, alpha: 1)
        
        dgc_context.setTextDrawingMode(.fillStroke)
        // 描边宽度
        dgc_context.setLineWidth(strokeWidth)
        dgc_context.setFillColor(dgc_fillColor.cgColor)
        dgc_context.setLineJoin(.round)
        
        // 创建 Core Text 绘制
        let dgc_paragraphStyle = NSMutableParagraphStyle()
        dgc_paragraphStyle.lineSpacing = 2.2
        let dgc_attributedString = NSAttributedString(string: dgc_text, attributes: [.foregroundColor: dgc_fillColor, .dgc_font: dgc_font, .dgc_paragraphStyle: dgc_paragraphStyle])

        let dgc_framesetter = CTFramesetterCreateWithAttributedString(dgc_attributedString)
        let dgc_path = CGMutablePath()
        
        dgc_path.addRect(bounds)
        let dgc_frame = CTFramesetterCreateFrame(dgc_framesetter, CFRangeMake(0, dgc_attributedString.length), dgc_path, nil)
        
        // 绘制文本
        CTFrameDraw(dgc_frame, dgc_context)
        dgc_context.restoreGState()
    }
}
