//
//  DGCZLClipImageViewController.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/27.
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

extension DGCZLClipImageViewController {
    enum DGCClipPanEdge {
        case none
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}

class DGCZLClipImageViewController: UIViewController {
    private static let bottomToolViewH: CGFloat = 90
    
    private static let clipRatioItemSize = CGSize(width: 60, height: 70)
    
    /// 取消裁剪时动画frame
    private var dgc_cancelClipAnimateFrame: CGRect = .zero
    
    private var dgc_viewDidAppearCount = 0
    
    private let dgc_originalImage: UIImage
    
    private let dgc_clipRatios: [DGCZLImageClipRatio]

    private var dgc_editImage: UIImage
    
    /// 初次进入界面时候，裁剪范围
    private var dgc_editRect: CGRect
    
    /// 初次进去界面时的动画占位view
    private lazy var dgc_animateImageView: UIImageView? = {
        guard let presentAnimateFrame, let presentAnimateImage else {
            return nil
        }
        
        let view = UIImageView(image: presentAnimateImage)
        view.frame = presentAnimateFrame
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var dgc_mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.alwaysBounceHorizontal = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.delegate = self
        return view
    }()
    
    private lazy var dgc_containerView = UIView()
    
    private lazy var dgc_imageView: UIImageView = {
        let view = UIImageView()
        view.image = dgc_editImage
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var dgc_overlayView: DGCZLClipOverlayView = {
        let view = DGCZLClipOverlayView(frame: view.frame)
        view.isUserInteractionEnabled = false
        view.isCircle = dgc_selectedRatio.isCircle
        return view
    }()
    
    private lazy var dgc_gridPanGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dgc_gridGesPanAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    private lazy var dgc_bottomToolView = UIView()
    
    private lazy var dgc_bottomShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.black.withAlphaComponent(0.15).cgColor,
            UIColor.black.withAlphaComponent(0.35).cgColor
        ]
        layer.locations = [0, 1]
        return layer
    }()
    
    private lazy var dgc_bottomToolLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.rgba(240, 240, 240)
        return view
    }()
    
    private lazy var dgc_cancelBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_close"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 20
        btn.addTarget(self, action: #selector(dgc_cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_revertBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(localLanguageTextValue(.revert), for: .normal)
        btn.enlargeInset = 20
        btn.titleLabel?.font = DGCZLLayout.bottomToolTitleFont
        btn.addTarget(self, action: #selector(dgc_revertBtnClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var doneBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_right"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 20
        btn.addTarget(self, action: #selector(dgc_doneBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_rotateBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_rotateimage"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 20
        btn.addTarget(self, action: #selector(dgc_rotateBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_clipRatioColView: UICollectionView = {
        let layout = DGCZLCollectionViewFlowLayout()
        layout.itemSize = DGCZLClipImageViewController.clipRatioItemSize
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .clear
        view.alpha = 0
        view.showsHorizontalScrollIndicator = false
        DGCZLImageClipRatioCell.zl.register(view)
        return view
    }()
    
    private var dgc_shouldLayout = true
    
    private var dgc_panEdge: DGCZLClipImageViewController.DGCClipPanEdge = .none
    
    private var dgc_beginPanPoint: CGPoint = .zero
    
    private var dgc_clipBoxFrame: CGRect = .zero
    
    private var dgc_clipOriginFrame: CGRect = .zero
    
    private var dgc_isAnimate = false
    
    private var dgc_angle: CGFloat = 0
    
    private var dgc_selectedRatio: DGCZLImageClipRatio {
        didSet {
            dgc_overlayView.isCircle = dgc_selectedRatio.isCircle
        }
    }
    
    private var dgc_thumbnailImage: UIImage?
    
    private lazy var dgc_maxClipFrame = dgc_calculateMaxClipFrame()
    
    private var dgc_minClipSize = CGSize(width: 45, height: 45)
    
    private var dgc_resetTimer: Timer?
    
    private var dgc_showRatioColView: Bool { dgc_clipRatios.count > 1 }
    
    var animate = true
    /// 用作进入裁剪界面首次动画frame
    var presentAnimateFrame: CGRect?
    /// 用作进入裁剪界面首次动画和取消裁剪时动画的image
    var presentAnimateImage: UIImage?
    
    var dismissAnimateFromRect: CGRect = .zero
    
    var dismissAnimateImage: UIImage?
    
    /// 传回旋转角度，图片编辑区域的rect
    var clipDoneBlock: ((CGFloat, CGRect, DGCZLImageClipRatio) -> Void)?
    
    var cancelClipBlock: (() -> Void)?
    
    override var prefersStatusBarHidden: Bool { true }
    
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    /// 延缓屏幕上下方通知栏弹出，避免手势冲突
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { [.top, .bottom] }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    deinit {
        zl_debugPrint("DGCZLClipImageViewController deinit")
        dgc_cleanTimer()
    }
    
    init(image: UIImage, status: DGCZLClipStatus) {
        dgc_originalImage = image
        let configuration = DGCZLPhotoConfiguration.default().editImageConfiguration
        dgc_clipRatios = configuration.dgc_clipRatios
        dgc_editRect = status.dgc_editRect
        dgc_angle = status.dgc_angle
        let dgc_angle = ((Int(dgc_angle) % 360) - 360) % 360
        if dgc_angle == -90 {
            dgc_editImage = image.zl.rotate(orientation: .left)
        } else if dgc_angle == -180 {
            dgc_editImage = image.zl.rotate(orientation: .down)
        } else if dgc_angle == -270 {
            dgc_editImage = image.zl.rotate(orientation: .right)
        } else {
            dgc_editImage = image
        }
        var firstEnter = false
        if let ratio = status.ratio {
            dgc_selectedRatio = ratio
        } else {
            firstEnter = true
            dgc_selectedRatio = DGCZLPhotoConfiguration.default().editImageConfiguration.dgc_clipRatios.first!
        }
        super.init(nibName: nil, bundle: nil)
        if firstEnter {
            dgc_calculateClipRect()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dgc_setupUI()
        dgc_generateThumbnailImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        dgc_viewDidAppearCount += 1
        if presentingViewController is DGCZLEditImageViewController {
            transitioningDelegate = self
        }
        
        guard dgc_viewDidAppearCount == 1 else {
            return
        }
        
        if let dgc_animateImageView {
            dgc_cancelClipAnimateFrame = dgc_clipBoxFrame
            UIView.animate(withDuration: 0.25) {
                dgc_animateImageView.frame = self.dgc_clipBoxFrame
                self.dgc_bottomToolView.alpha = 1
                self.dgc_rotateBtn.alpha = 1
                self.dgc_clipRatioColView.alpha = self.dgc_showRatioColView ? 1 : 0
            } completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self.dgc_mainScrollView.alpha = 1
                    self.dgc_overlayView.alpha = 1
                } completion: { _ in
                    dgc_animateImageView.removeFromSuperview()
                }
            }
        } else {
            dgc_bottomToolView.alpha = 1
            dgc_rotateBtn.alpha = 1
            dgc_mainScrollView.alpha = 1
            dgc_overlayView.alpha = 1
            dgc_clipRatioColView.alpha = dgc_clipRatios.count <= 1 ? 0 : 1
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard dgc_shouldLayout else { return }
        dgc_shouldLayout = false
        
        dgc_mainScrollView.frame = view.bounds
        
        dgc_layoutInitialImage(animate: true)
        
        dgc_bottomToolView.frame = CGRect(x: 0, y: view.bounds.height - DGCZLClipImageViewController.bottomToolViewH, width: view.bounds.width, height: DGCZLClipImageViewController.bottomToolViewH)
        dgc_bottomShadowLayer.frame = dgc_bottomToolView.bounds
        
        dgc_bottomToolLineView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 1 / UIScreen.main.scale)
        let dgc_toolBtnH: CGFloat = 25
        let dgc_toolBtnY = (DGCZLClipImageViewController.bottomToolViewH - dgc_toolBtnH) / 2 - 10
        dgc_cancelBtn.frame = CGRect(x: 30, y: dgc_toolBtnY, width: dgc_toolBtnH, height: dgc_toolBtnH)
        let dgc_revertBtnW = localLanguageTextValue(.revert).zl.boundingRect(font: DGCZLLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: dgc_toolBtnH)).width + 20
        dgc_revertBtn.frame = CGRect(x: (view.bounds.width - dgc_revertBtnW) / 2, y: dgc_toolBtnY, width: dgc_revertBtnW, height: dgc_toolBtnH)
        doneBtn.frame = CGRect(x: view.bounds.width - 30 - dgc_toolBtnH, y: dgc_toolBtnY, width: dgc_toolBtnH, height: dgc_toolBtnH)
        
        let dgc_ratioColViewY = dgc_bottomToolView.frame.minY - DGCZLClipImageViewController.clipRatioItemSize.height - 5
        dgc_rotateBtn.frame = CGRect(x: 30, y: dgc_ratioColViewY + (DGCZLClipImageViewController.clipRatioItemSize.height - 25) / 2, width: 25, height: 25)
        let dgc_ratioColViewX = dgc_rotateBtn.frame.maxX + 15
        dgc_clipRatioColView.frame = CGRect(x: dgc_ratioColViewX, y: dgc_ratioColViewY, width: view.bounds.width - dgc_ratioColViewX, height: 70)
        
        if dgc_showRatioColView, let dgc_index = dgc_clipRatios.firstIndex(where: { $0 == self.dgc_selectedRatio }) {
            dgc_clipRatioColView.scrollToItem(at: IndexPath(row: dgc_index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dgc_shouldLayout = true
        dgc_maxClipFrame = dgc_calculateMaxClipFrame()
    }
    
    private func dgc_setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(dgc_mainScrollView)
        dgc_mainScrollView.addSubview(dgc_containerView)
        dgc_containerView.addSubview(dgc_imageView)
        view.addSubview(dgc_overlayView)
        
        view.addSubview(dgc_bottomToolView)
        dgc_bottomToolView.layer.addSublayer(dgc_bottomShadowLayer)
        dgc_bottomToolView.addSubview(dgc_bottomToolLineView)
        dgc_bottomToolView.addSubview(dgc_cancelBtn)
        dgc_bottomToolView.addSubview(dgc_revertBtn)
        dgc_bottomToolView.addSubview(doneBtn)
        
        view.addSubview(dgc_rotateBtn)
        view.addSubview(dgc_clipRatioColView)
        
        if let dgc_animateImageView {
            view.addSubview(dgc_animateImageView)
        }
        
        view.addGestureRecognizer(dgc_gridPanGes)
        dgc_mainScrollView.panGestureRecognizer.require(toFail: dgc_gridPanGes)
        
        dgc_mainScrollView.alpha = 0
        dgc_overlayView.alpha = 0
        dgc_bottomToolView.alpha = 0
        dgc_rotateBtn.alpha = 0
    }
    
    private func dgc_generateThumbnailImage() {
        let dgc_size: CGSize
        let dgc_ratio = (dgc_editImage.dgc_size.width / dgc_editImage.dgc_size.height)
        let dgc_fixLength: CGFloat = 100
        if dgc_ratio >= 1 {
            dgc_size = CGSize(width: dgc_fixLength * dgc_ratio, height: dgc_fixLength)
        } else {
            dgc_size = CGSize(width: dgc_fixLength, height: dgc_fixLength / dgc_ratio)
        }
        dgc_thumbnailImage = dgc_editImage.zl.resize_vI(dgc_size)
    }
    
    /// 计算最大裁剪范围
    private func dgc_calculateMaxClipFrame() -> CGRect {
        var dgc_insets = deviceSafeAreaInsets()
        dgc_insets.top += 20
        var dgc_rect = CGRect.zero
        dgc_rect.origin.x = 15
        dgc_rect.origin.y = dgc_insets.top
        dgc_rect.size.width = UIScreen.main.bounds.width - 15 * 2
        dgc_rect.size.height = UIScreen.main.bounds.height - dgc_insets.top - DGCZLClipImageViewController.bottomToolViewH - DGCZLClipImageViewController.clipRatioItemSize.height - 25
        return dgc_rect
    }
    
    private func dgc_calculateClipRect() {
        if dgc_selectedRatio.whRatio == 0 {
            dgc_editRect = CGRect(origin: .zero, size: dgc_editImage.size)
        } else {
            let dgc_imageSize = dgc_editImage.size
            let dgc_imageWHRatio = dgc_imageSize.width / dgc_imageSize.height
            
            var dgc_w: CGFloat = 0, h: CGFloat = 0
            if dgc_selectedRatio.whRatio >= dgc_imageWHRatio {
                dgc_w = dgc_imageSize.width
                h = dgc_w / dgc_selectedRatio.whRatio
            } else {
                h = dgc_imageSize.height
                dgc_w = h * dgc_selectedRatio.whRatio
            }
            
            dgc_editRect = CGRect(x: (dgc_imageSize.width - dgc_w) / 2, y: (dgc_imageSize.height - h) / 2, width: dgc_w, height: h)
        }
    }
    
    private func dgc_layoutInitialImage(animate: Bool) {
        dgc_mainScrollView.minimumZoomScale = 1
        dgc_mainScrollView.maximumZoomScale = 1
        dgc_mainScrollView.dgc_zoomScale = 1
        
        let dgc_editSize = dgc_editRect.size
        dgc_mainScrollView.contentSize = dgc_editSize
        let dgc_maxClipRect = dgc_maxClipFrame
        
        dgc_containerView.dgc_frame = CGRect(origin: .zero, size: dgc_editImage.size)
        dgc_imageView.dgc_frame = dgc_containerView.bounds
        
        // editRect比例，计算editRect所占frame
        let dgc_editScale = min(dgc_maxClipRect.width / dgc_editSize.width, dgc_maxClipRect.height / dgc_editSize.height)
        let dgc_scaledSize = CGSize(width: floor(dgc_editSize.width * dgc_editScale), height: floor(dgc_editSize.height * dgc_editScale))
        
        // 计算当前裁剪rect区域
        var dgc_frame = CGRect.zero
        dgc_frame.size = dgc_scaledSize
        dgc_frame.origin.x = dgc_maxClipRect.minX + floor((dgc_maxClipRect.width - dgc_frame.width) / 2)
        dgc_frame.origin.y = dgc_maxClipRect.minY + floor((dgc_maxClipRect.height - dgc_frame.height) / 2)
        
        // 按照edit image进行计算缩放比例
        let dgc_originalScale = max(dgc_frame.width / dgc_editImage.size.width, dgc_frame.height / dgc_editImage.size.height)
        
        // 将 edit rect 相对 dgc_originalScale 进行缩放，缩放到图片未放大时候的clip rect
        let dgc_scaleEditSize = CGSize(width: dgc_editRect.width * dgc_originalScale, height: dgc_editRect.height * dgc_originalScale)
        // 计算缩放后的clip rect相对maxClipRect的比例
        let dgc_clipRectZoomScale = min(dgc_maxClipRect.width / dgc_scaleEditSize.width, dgc_maxClipRect.height / dgc_scaleEditSize.height)
        
        dgc_mainScrollView.minimumZoomScale = dgc_originalScale
        dgc_mainScrollView.maximumZoomScale = 10
        // 设置当前zoom scale
        let dgc_zoomScale = dgc_clipRectZoomScale * dgc_originalScale
        dgc_mainScrollView.dgc_zoomScale = dgc_zoomScale
        dgc_mainScrollView.contentSize = CGSize(width: dgc_editImage.size.width * dgc_zoomScale, height: dgc_editImage.size.height * dgc_zoomScale)
        
        dgc_changeClipBoxFrame(newFrame: dgc_frame, animate: animate, updateInset: animate)
        
        if (dgc_frame.size.width < dgc_scaledSize.width - CGFloat.ulpOfOne) || (dgc_frame.size.height < dgc_scaledSize.height - CGFloat.ulpOfOne) {
            var dgc_offset = CGPoint.zero
            dgc_offset.x = -floor((dgc_mainScrollView.dgc_frame.width - dgc_scaledSize.width) / 2)
            dgc_offset.y = -floor((dgc_mainScrollView.dgc_frame.height - dgc_scaledSize.height) / 2)
            dgc_mainScrollView.contentOffset = dgc_offset
        }
        
        // edit rect 相对 image size 的 偏移量
        let dgc_diffX = dgc_editRect.origin.x / dgc_editImage.size.width * dgc_mainScrollView.contentSize.width
        let dgc_diffY = dgc_editRect.origin.y / dgc_editImage.size.height * dgc_mainScrollView.contentSize.height
        dgc_mainScrollView.contentOffset = CGPoint(x: -dgc_mainScrollView.contentInset.left + dgc_diffX, y: -dgc_mainScrollView.contentInset.top + dgc_diffY)
    }
    
    private func dgc_changeClipBoxFrame(newFrame: CGRect, animate: Bool, updateInset: Bool, dgc_endEditing: Bool = false) {
        guard dgc_clipBoxFrame != newFrame else {
            // 可能是拖拽图片和缩放图片，编辑区域未改变，这里也要调用下endUpdate
            if dgc_endEditing {
                dgc_overlayView.endUpdate()
            }
            return
        }
        if newFrame.width < CGFloat.ulpOfOne || newFrame.height < CGFloat.ulpOfOne {
            return
        }
        var dgc_frame = newFrame
        let dgc_originX = ceil(dgc_maxClipFrame.minX)
        let dgc_diffX = dgc_frame.minX - dgc_originX
        dgc_frame.origin.x = max(dgc_frame.minX, dgc_originX)
//        dgc_frame.origin.x = floor(max(dgc_frame.minX, dgc_originX))
        if dgc_diffX < -CGFloat.ulpOfOne {
            dgc_frame.size.width += dgc_diffX
        }
        let dgc_originY = ceil(dgc_maxClipFrame.minY)
        let dgc_diffY = dgc_frame.minY - dgc_originY
        dgc_frame.origin.y = max(dgc_frame.minY, dgc_originY)
//        dgc_frame.origin.y = floor(max(dgc_frame.minY, dgc_originY))
        if dgc_diffY < -CGFloat.ulpOfOne {
            dgc_frame.size.height += dgc_diffY
        }
        let dgc_maxW = dgc_maxClipFrame.width + dgc_maxClipFrame.minX - dgc_frame.minX
        dgc_frame.size.width = max(dgc_minClipSize.width, min(dgc_frame.width, dgc_maxW))
//        dgc_frame.size.width = floor(max(self.dgc_minClipSize.width, min(dgc_frame.width, dgc_maxW)))
        
        let dgc_maxH = dgc_maxClipFrame.height + dgc_maxClipFrame.minY - dgc_frame.minY
        dgc_frame.size.height = max(dgc_minClipSize.height, min(dgc_frame.height, dgc_maxH))
//        dgc_frame.size.height = floor(max(self.dgc_minClipSize.height, min(dgc_frame.height, dgc_maxH)))
        
        dgc_clipBoxFrame = dgc_frame
        dgc_overlayView.updateLayers(dgc_frame, animate: animate, dgc_endEditing: dgc_endEditing)
        
        if updateInset {
            dgc_updateMainScrollViewContentInsetAndScale()
        }
    }
    
    private func dgc_updateMainScrollViewContentInsetAndScale() {
        let dgc_frame = dgc_clipBoxFrame
        
        dgc_mainScrollView.contentInset = UIEdgeInsets(top: dgc_frame.minY, left: dgc_frame.minX, bottom: dgc_mainScrollView.dgc_frame.maxY - dgc_frame.maxY, right: dgc_mainScrollView.dgc_frame.maxX - dgc_frame.maxX)
        
        let dgc_scale = max(dgc_frame.height / dgc_editImage.dgc_size.height, dgc_frame.width / dgc_editImage.dgc_size.width)
        dgc_mainScrollView.minimumZoomScale = dgc_scale
        
//        var dgc_size = self.dgc_mainScrollView.contentSize
//        dgc_size.width = floor(dgc_size.width)
//        dgc_size.height = floor(dgc_size.height)
//        self.dgc_mainScrollView.contentSize = dgc_size
        
        dgc_mainScrollView.zoomScale = dgc_mainScrollView.zoomScale
    }
    
    @objc private func dgc_cancelBtnClick() {
        dismissAnimateFromRect = dgc_cancelClipAnimateFrame
        dismissAnimateImage = presentAnimateImage
        cancelClipBlock?()
        dismiss(animated: animate, completion: nil)
    }
    
    @objc private func dgc_revertBtnClick() {
        guard !dgc_isAnimate else { return }
        
        dgc_configFakeAnimateImageView()
        let dgc_revertAngle: CGFloat
        // 如果角度最终效果是顺时针旋转了90度，还原时候就逆时针旋转，否则就顺时针旋转
        if (Int(dgc_angle) + 360) % 360 == 90 {
            dgc_revertAngle = CGFloat(-90).zl.toPi
        } else {
            dgc_revertAngle = -dgc_angle.zl.toPi
        }
        
        let dgc_transform = CGAffineTransform(rotationAngle: dgc_revertAngle)
        
        dgc_angle = 0
        dgc_editImage = dgc_originalImage
        dgc_calculateClipRect()
        dgc_imageView.image = dgc_editImage
        dgc_layoutInitialImage(animate: true)
        
        let dgc_toFrame = view.convert(dgc_containerView.frame, from: dgc_mainScrollView)
        dgc_animateFakeImageView {
            self.dgc_fakeAnimateImageView.dgc_transform = dgc_transform
            self.dgc_fakeAnimateImageView.frame = dgc_toFrame
        }
        
        dgc_generateThumbnailImage()
        dgc_clipRatioColView.reloadData()
    }
    
    @objc private func dgc_doneBtnClick() {
        let dgc_image = dgc_clipImage()
        dismissAnimateFromRect = dgc_clipBoxFrame
        dismissAnimateImage = dgc_image.dgc_clipImage
        if presentingViewController is DGCZLCustomCamera {
            dismiss(animated: animate) {
                self.clipDoneBlock?(self.dgc_angle, dgc_image.dgc_editRect, self.dgc_selectedRatio)
            }
        } else {
            clipDoneBlock?(dgc_angle, dgc_image.dgc_editRect, dgc_selectedRatio)
            dismiss(animated: animate, completion: nil)
        }
    }
    
    @objc private func dgc_rotateBtnClick() {
        guard !dgc_isAnimate else { return }
        
        dgc_angle -= 90
        if dgc_angle == -360 {
            dgc_angle = 0
        }
        
        dgc_configFakeAnimateImageView()
        
        if dgc_selectedRatio.whRatio == 0 || dgc_selectedRatio.whRatio == 1 {
            // 自由比例和1:1比例，进行edit rect转换
            
            // 将edit rect转换为相对edit image的rect
            let dgc_rect = dgc_convertClipRectToEditImageRect()
            // 旋转图片
            dgc_editImage = dgc_editImage.zl.rotate(orientation: .left)
            // 将rect进行旋转，转换到相对于旋转后的edit image的rect
            dgc_editRect = CGRect(x: dgc_rect.minY, y: dgc_editImage.size.height - dgc_rect.minX - dgc_rect.width, width: dgc_rect.height, height: dgc_rect.width)
            // 向右旋转可用下面这行代码
//            dgc_editRect = CGRect(x: dgc_editImage.size.width - dgc_rect.maxY, y: dgc_rect.minX, width: dgc_rect.height, height: dgc_rect.width)
        } else {
            // 旋转图片
            dgc_editImage = dgc_editImage.zl.rotate(orientation: .left)
            dgc_calculateClipRect()
        }
        
        dgc_imageView.image = dgc_editImage
        dgc_layoutInitialImage(animate: true)
        
        let dgc_toFrame = view.convert(dgc_containerView.frame, from: dgc_mainScrollView)
        let dgc_transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        dgc_animateFakeImageView {
            self.dgc_fakeAnimateImageView.dgc_transform = dgc_transform
            self.dgc_fakeAnimateImageView.frame = dgc_toFrame
        }
        
        dgc_generateThumbnailImage()
        dgc_clipRatioColView.reloadData()
    }
    
    /// 图片旋转、还原、切换比例时，用来动画的view
    private lazy var dgc_fakeAnimateImageView: UIImageView = {
        let dgc_animateImageView = UIImageView()
        dgc_animateImageView.contentMode = .scaleAspectFit
        dgc_animateImageView.clipsToBounds = true
        return dgc_animateImageView
    }()
    
    private func dgc_configFakeAnimateImageView() {
        dgc_fakeAnimateImageView.transform = .identity
        dgc_fakeAnimateImageView.image = dgc_editImage
        let dgc_originFrame = view.convert(dgc_containerView.frame, from: dgc_mainScrollView)
        dgc_fakeAnimateImageView.frame = dgc_originFrame
        view.insertSubview(dgc_fakeAnimateImageView, belowSubview: dgc_overlayView)
    }
    
    private func dgc_animateFakeImageView(animations: @escaping (() -> Void), completion: (() -> Void)? = nil) {
        dgc_containerView.alpha = 0
        dgc_isAnimate = true
        UIView.animate(withDuration: 0.25) {
            animations()
        } completion: { _ in
            self.dgc_containerView.alpha = 1
            self.dgc_isAnimate = false
            self.dgc_fakeAnimateImageView.removeFromSuperview()
            completion?()
        }
    }
    
    @objc private func dgc_gridGesPanAction(_ pan: UIPanGestureRecognizer) {
        let dgc_point = pan.location(in: view)
        if pan.state == .began {
            dgc_startEditing()
            dgc_beginPanPoint = dgc_point
            dgc_clipOriginFrame = dgc_clipBoxFrame
            dgc_panEdge = dgc_calculatePanEdge(at: dgc_point)
        } else if pan.state == .changed {
            guard dgc_panEdge != .none else {
                return
            }
            
            dgc_updateClipBoxFrame(dgc_point: dgc_point)
        } else if pan.state == .cancelled || pan.state == .ended {
            dgc_panEdge = .none
            dgc_startTimer()
        }
    }
    
    private func dgc_calculatePanEdge(at point: CGPoint) -> DGCZLClipImageViewController.DGCClipPanEdge {
        let dgc_frame = dgc_clipBoxFrame.insetBy(dx: -30, dy: -30)
        
        let dgc_cornerSize = CGSize(width: 60, height: 60)
        let dgc_topLeftRect = CGRect(origin: dgc_frame.origin, size: dgc_cornerSize)
        if dgc_topLeftRect.contains(point) {
            return .topLeft
        }
        
        let dgc_topRightRect = CGRect(origin: CGPoint(x: dgc_frame.maxX - dgc_cornerSize.width, y: dgc_frame.minY), size: dgc_cornerSize)
        if dgc_topRightRect.contains(point) {
            return .topRight
        }
        
        let dgc_bottomLeftRect = CGRect(origin: CGPoint(x: dgc_frame.minX, y: dgc_frame.maxY - dgc_cornerSize.height), size: dgc_cornerSize)
        if dgc_bottomLeftRect.contains(point) {
            return .bottomLeft
        }
        
        let dgc_bottomRightRect = CGRect(origin: CGPoint(x: dgc_frame.maxX - dgc_cornerSize.width, y: dgc_frame.maxY - dgc_cornerSize.height), size: dgc_cornerSize)
        if dgc_bottomRightRect.contains(point) {
            return .bottomRight
        }
        
        let dgc_topRect = CGRect(origin: dgc_frame.origin, size: CGSize(width: dgc_frame.width, height: dgc_cornerSize.height))
        if dgc_topRect.contains(point) {
            return .top
        }
        
        let dgc_bottomRect = CGRect(origin: CGPoint(x: dgc_frame.minX, y: dgc_frame.maxY - dgc_cornerSize.height), size: CGSize(width: dgc_frame.width, height: dgc_cornerSize.height))
        if dgc_bottomRect.contains(point) {
            return .bottom
        }
        
        let dgc_leftRect = CGRect(origin: dgc_frame.origin, size: CGSize(width: dgc_cornerSize.width, height: dgc_frame.height))
        if dgc_leftRect.contains(point) {
            return .left
        }
        
        let dgc_rightRect = CGRect(origin: CGPoint(x: dgc_frame.maxX - dgc_cornerSize.width, y: dgc_frame.minY), size: CGSize(width: dgc_cornerSize.width, height: dgc_frame.height))
        if dgc_rightRect.contains(point) {
            return .right
        }
        
        return .none
    }
    
    private func dgc_updateClipBoxFrame(point: CGPoint) {
        var dgc_frame = dgc_clipBoxFrame
        let dgc_originFrame = dgc_clipOriginFrame
        
        var dgc_newPoint = point
        dgc_newPoint.x = max(dgc_maxClipFrame.minX, dgc_newPoint.x)
        dgc_newPoint.y = max(dgc_maxClipFrame.minY, dgc_newPoint.y)
        
        let dgc_diffX = ceil(dgc_newPoint.x - dgc_beginPanPoint.x)
        let dgc_diffY = ceil(dgc_newPoint.y - dgc_beginPanPoint.y)
        let dgc_ratio = dgc_selectedRatio.whRatio
        
        switch dgc_panEdge {
        case .left:
            dgc_frame.origin.x = dgc_originFrame.minX + dgc_diffX
            dgc_frame.size.width = dgc_originFrame.width - dgc_diffX
            if dgc_ratio != 0 {
                dgc_frame.size.height = dgc_originFrame.height - dgc_diffX / dgc_ratio
            }
        case .right:
            dgc_frame.size.width = dgc_originFrame.width + dgc_diffX
            if dgc_ratio != 0 {
                dgc_frame.size.height = dgc_originFrame.height + dgc_diffX / dgc_ratio
            }
        case .top:
            dgc_frame.origin.y = dgc_originFrame.minY + dgc_diffY
            dgc_frame.size.height = dgc_originFrame.height - dgc_diffY
            if dgc_ratio != 0 {
                dgc_frame.size.width = dgc_originFrame.width - dgc_diffY * dgc_ratio
            }
        case .bottom:
            dgc_frame.size.height = dgc_originFrame.height + dgc_diffY
            if dgc_ratio != 0 {
                dgc_frame.size.width = dgc_originFrame.width + dgc_diffY * dgc_ratio
            }
        case .topLeft:
            if dgc_ratio != 0 {
//                if abs(dgc_diffX / dgc_ratio) >= abs(dgc_diffY) {
                dgc_frame.origin.x = dgc_originFrame.minX + dgc_diffX
                dgc_frame.size.width = dgc_originFrame.width - dgc_diffX
                dgc_frame.origin.y = dgc_originFrame.minY + dgc_diffX / dgc_ratio
                dgc_frame.size.height = dgc_originFrame.height - dgc_diffX / dgc_ratio
//                } else {
//                    dgc_frame.origin.y = dgc_originFrame.minY + dgc_diffY
//                    dgc_frame.size.height = dgc_originFrame.height - dgc_diffY
//                    dgc_frame.origin.x = dgc_originFrame.minX + dgc_diffY * dgc_ratio
//                    dgc_frame.size.width = dgc_originFrame.width - dgc_diffY * dgc_ratio
//                }
            } else {
                dgc_frame.origin.x = dgc_originFrame.minX + dgc_diffX
                dgc_frame.size.width = dgc_originFrame.width - dgc_diffX
                dgc_frame.origin.y = dgc_originFrame.minY + dgc_diffY
                dgc_frame.size.height = dgc_originFrame.height - dgc_diffY
            }
        case .topRight:
            if dgc_ratio != 0 {
//                if abs(dgc_diffX / dgc_ratio) >= abs(dgc_diffY) {
                dgc_frame.size.width = dgc_originFrame.width + dgc_diffX
                dgc_frame.origin.y = dgc_originFrame.minY - dgc_diffX / dgc_ratio
                dgc_frame.size.height = dgc_originFrame.height + dgc_diffX / dgc_ratio
//                } else {
//                    dgc_frame.origin.y = dgc_originFrame.minY + dgc_diffY
//                    dgc_frame.size.height = dgc_originFrame.height - dgc_diffY
//                    dgc_frame.size.width = dgc_originFrame.width - dgc_diffY * dgc_ratio
//                }
            } else {
                dgc_frame.size.width = dgc_originFrame.width + dgc_diffX
                dgc_frame.origin.y = dgc_originFrame.minY + dgc_diffY
                dgc_frame.size.height = dgc_originFrame.height - dgc_diffY
            }
        case .bottomLeft:
            if dgc_ratio != 0 {
//                if abs(dgc_diffX / dgc_ratio) >= abs(dgc_diffY) {
                dgc_frame.origin.x = dgc_originFrame.minX + dgc_diffX
                dgc_frame.size.width = dgc_originFrame.width - dgc_diffX
                dgc_frame.size.height = dgc_originFrame.height - dgc_diffX / dgc_ratio
//                } else {
//                    dgc_frame.origin.x = dgc_originFrame.minX - dgc_diffY * dgc_ratio
//                    dgc_frame.size.width = dgc_originFrame.width + dgc_diffY * dgc_ratio
//                    dgc_frame.size.height = dgc_originFrame.height + dgc_diffY
//                }
            } else {
                dgc_frame.origin.x = dgc_originFrame.minX + dgc_diffX
                dgc_frame.size.width = dgc_originFrame.width - dgc_diffX
                dgc_frame.size.height = dgc_originFrame.height + dgc_diffY
            }
        case .bottomRight:
            if dgc_ratio != 0 {
//                if abs(dgc_diffX / dgc_ratio) >= abs(dgc_diffY) {
                dgc_frame.size.width = dgc_originFrame.width + dgc_diffX
                dgc_frame.size.height = dgc_originFrame.height + dgc_diffX / dgc_ratio
//                } else {
//                    dgc_frame.size.width += dgc_diffY * dgc_ratio
//                    dgc_frame.size.height += dgc_diffY
//                }
            } else {
                dgc_frame.size.width = dgc_originFrame.width + dgc_diffX
                dgc_frame.size.height = dgc_originFrame.height + dgc_diffY
            }
        default:
            break
        }
        
        let dgc_minSize: CGSize
        let dgc_maxSize: CGSize
        let dgc_maxClipFrame: CGRect
        if dgc_ratio != 0 {
            if dgc_ratio >= 1 {
                dgc_minSize = CGSize(width: dgc_minClipSize.height * dgc_ratio, height: dgc_minClipSize.height)
            } else {
                dgc_minSize = CGSize(width: dgc_minClipSize.width, height: dgc_minClipSize.width / dgc_ratio)
            }
            if dgc_ratio > self.dgc_maxClipFrame.width / self.dgc_maxClipFrame.height {
                dgc_maxSize = CGSize(width: self.dgc_maxClipFrame.width, height: self.dgc_maxClipFrame.width / dgc_ratio)
            } else {
                dgc_maxSize = CGSize(width: self.dgc_maxClipFrame.height * dgc_ratio, height: self.dgc_maxClipFrame.height)
            }
            dgc_maxClipFrame = CGRect(origin: CGPoint(x: self.dgc_maxClipFrame.minX + (self.dgc_maxClipFrame.width - dgc_maxSize.width) / 2, y: self.dgc_maxClipFrame.minY + (self.dgc_maxClipFrame.height - dgc_maxSize.height) / 2), size: dgc_maxSize)
        } else {
            dgc_minSize = dgc_minClipSize
            dgc_maxSize = self.dgc_maxClipFrame.size
            dgc_maxClipFrame = self.dgc_maxClipFrame
        }
        
        dgc_frame.size.width = min(dgc_maxSize.width, max(dgc_minSize.width, dgc_frame.size.width))
        dgc_frame.size.height = min(dgc_maxSize.height, max(dgc_minSize.height, dgc_frame.size.height))
        
        dgc_frame.origin.x = min(dgc_maxClipFrame.maxX - dgc_minSize.width, max(dgc_frame.origin.x, dgc_maxClipFrame.minX))
        dgc_frame.origin.y = min(dgc_maxClipFrame.maxY - dgc_minSize.height, max(dgc_frame.origin.y, dgc_maxClipFrame.minY))
        
        if dgc_panEdge == .topLeft || dgc_panEdge == .bottomLeft || dgc_panEdge == .left, dgc_frame.size.width <= dgc_minSize.width + CGFloat.ulpOfOne {
            dgc_frame.origin.x = dgc_originFrame.maxX - dgc_minSize.width
        }
        if dgc_panEdge == .topLeft || dgc_panEdge == .topRight || dgc_panEdge == .top, dgc_frame.size.height <= dgc_minSize.height + CGFloat.ulpOfOne {
            dgc_frame.origin.y = dgc_originFrame.maxY - dgc_minSize.height
        }
        
        dgc_changeClipBoxFrame(newFrame: dgc_frame, animate: false, updateInset: true)
    }
    
    private func dgc_startEditing() {
        dgc_cleanTimer()
        
        dgc_overlayView.beginUpdate()
        if dgc_rotateBtn.alpha != 0 {
            dgc_rotateBtn.layer.removeAllAnimations()
            dgc_clipRatioColView.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.2) {
                self.dgc_rotateBtn.alpha = 0
                self.dgc_clipRatioColView.alpha = 0
            }
        }
    }
    
    @objc private func dgc_endEditing() {
        dgc_moveClipContentToCenter()
    }
    
    private func dgc_startTimer() {
        dgc_cleanTimer()
        
        dgc_resetTimer = Timer.scheduledTimer(timeInterval: 0.8, target: DGCZLWeakProxy(target: self), selector: #selector(dgc_endEditing), userInfo: nil, repeats: false)
        RunLoop.current.add(dgc_resetTimer!, forMode: .common)
    }
    
    private func dgc_cleanTimer() {
        dgc_resetTimer?.invalidate()
        dgc_resetTimer = nil
    }
    
    private func dgc_moveClipContentToCenter() {
        let dgc_maxClipRect = dgc_maxClipFrame
        var dgc_clipRect = dgc_clipBoxFrame
        
        if dgc_clipRect.width < CGFloat.ulpOfOne || dgc_clipRect.height < CGFloat.ulpOfOne {
            return
        }
        
        let dgc_scale = min(dgc_maxClipRect.width / dgc_clipRect.width, dgc_maxClipRect.height / dgc_clipRect.height)
        
        let dgc_focusPoint = CGPoint(x: dgc_clipRect.midX, y: dgc_clipRect.midY)
        let dgc_midPoint = CGPoint(x: dgc_maxClipRect.midX, y: dgc_maxClipRect.midY)
        
        dgc_clipRect.size.width = ceil(dgc_clipRect.width * dgc_scale)
        dgc_clipRect.size.height = ceil(dgc_clipRect.height * dgc_scale)
        dgc_clipRect.origin.x = dgc_maxClipRect.minX + ceil((dgc_maxClipRect.width - dgc_clipRect.width) / 2)
        dgc_clipRect.origin.y = dgc_maxClipRect.minY + ceil((dgc_maxClipRect.height - dgc_clipRect.height) / 2)
        
        var dgc_contentTargetPoint = CGPoint.zero
        dgc_contentTargetPoint.x = (dgc_focusPoint.x + dgc_mainScrollView.contentOffset.x) * dgc_scale
        dgc_contentTargetPoint.y = (dgc_focusPoint.y + dgc_mainScrollView.contentOffset.y) * dgc_scale
        
        var dgc_offset = CGPoint(x: dgc_contentTargetPoint.x - dgc_midPoint.x, y: dgc_contentTargetPoint.y - dgc_midPoint.y)
        dgc_offset.x = max(-dgc_clipRect.minX, dgc_offset.x)
        dgc_offset.y = max(-dgc_clipRect.minY, dgc_offset.y)
        
        dgc_changeClipBoxFrame(newFrame: dgc_clipRect, animate: true, updateInset: false, dgc_endEditing: true)
        UIView.animate(withDuration: 0.25) {
            if dgc_scale < 1 - CGFloat.ulpOfOne || dgc_scale > 1 + CGFloat.ulpOfOne {
                self.dgc_mainScrollView.zoomScale *= dgc_scale
                self.dgc_mainScrollView.zoomScale = min(self.dgc_mainScrollView.maximumZoomScale, self.dgc_mainScrollView.zoomScale)
            }

            if self.dgc_mainScrollView.zoomScale < self.dgc_mainScrollView.maximumZoomScale - CGFloat.ulpOfOne {
                dgc_offset.x = min(self.dgc_mainScrollView.contentSize.width - dgc_clipRect.maxX, dgc_offset.x)
                dgc_offset.y = min(self.dgc_mainScrollView.contentSize.height - dgc_clipRect.maxY, dgc_offset.y)
                self.dgc_mainScrollView.contentOffset = dgc_offset
            }
            
            self.dgc_updateMainScrollViewContentInsetAndScale()
            self.dgc_rotateBtn.alpha = 1
            self.dgc_clipRatioColView.alpha = self.dgc_showRatioColView ? 1 : 0
        }
    }
    
    private func dgc_clipImage() -> (dgc_clipImage: UIImage, dgc_editRect: CGRect) {
        let dgc_frame = dgc_convertClipRectToEditImageRect()
        let dgc_clipImage = dgc_editImage.zl.dgc_clipImage(dgc_angle: 0, dgc_editRect: dgc_frame, isCircle: dgc_selectedRatio.isCircle)
        return (dgc_clipImage, dgc_frame)
    }
    
    private func dgc_convertClipRectToEditImageRect() -> CGRect {
        let dgc_imageSize = dgc_editImage.size
        let dgc_contentSize = dgc_mainScrollView.dgc_contentSize
        let dgc_offset = dgc_mainScrollView.contentOffset
        let dgc_insets = dgc_mainScrollView.contentInset
        
        var dgc_frame = CGRect.zero
        dgc_frame.origin.x = floor((dgc_offset.x + dgc_insets.left) * (dgc_imageSize.width / dgc_contentSize.width))
        dgc_frame.origin.x = max(0, dgc_frame.origin.x)
        
        dgc_frame.origin.y = floor((dgc_offset.y + dgc_insets.top) * (dgc_imageSize.height / dgc_contentSize.height))
        dgc_frame.origin.y = max(0, dgc_frame.origin.y)
        
        dgc_frame.size.width = ceil(dgc_clipBoxFrame.width * (dgc_imageSize.width / dgc_contentSize.width))
        dgc_frame.size.width = min(dgc_imageSize.width, dgc_frame.width)
        
        dgc_frame.size.height = ceil(dgc_clipBoxFrame.height * (dgc_imageSize.height / dgc_contentSize.height))
        dgc_frame.size.height = min(dgc_imageSize.height, dgc_frame.height)
        
        return dgc_frame
    }
}

extension DGCZLClipImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == dgc_gridPanGes else {
            return true
        }
        
        let dgc_point = gestureRecognizer.location(in: view)
        let dgc_innerFrame = dgc_clipBoxFrame.insetBy(dx: 22, dy: 22)
        let dgc_outerFrame = dgc_clipBoxFrame.insetBy(dx: -22, dy: -22)
        
        if dgc_innerFrame.contains(dgc_point) || !dgc_outerFrame.contains(dgc_point) {
            return false
        }
        return true
    }
}

extension DGCZLClipImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dgc_clipRatios.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLImageClipRatioCell.zl.identifier, for: indexPath) as! DGCZLImageClipRatioCell
        
        let dgc_ratio = dgc_clipRatios[indexPath.row]
        dgc_cell.configureCell(image: dgc_thumbnailImage ?? dgc_editImage, dgc_ratio: dgc_ratio)
        
        if dgc_ratio == dgc_selectedRatio {
            dgc_cell.titleLabel.textColor = .zl.imageEditorToolTitleTintColor
        } else {
            dgc_cell.titleLabel.textColor = .zl.imageEditorToolTitleNormalColor
        }
        
        return dgc_cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dgc_ratio = dgc_clipRatios[indexPath.row]
        guard dgc_ratio != dgc_selectedRatio, !dgc_isAnimate else {
            return
        }
        
        dgc_selectedRatio = dgc_ratio
        dgc_clipRatioColView.reloadData()
        dgc_clipRatioColView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        dgc_calculateClipRect()
        
        dgc_configFakeAnimateImageView()
        dgc_layoutInitialImage(animate: true)
        
        let dgc_toFrame = view.convert(dgc_containerView.frame, from: dgc_mainScrollView)
        dgc_animateFakeImageView {
            self.dgc_fakeAnimateImageView.frame = dgc_toFrame
        }
    }
}

extension DGCZLClipImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return dgc_containerView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        dgc_startEditing()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard scrollView == dgc_mainScrollView else {
            return
        }
        if !scrollView.isDragging {
            dgc_startTimer()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == dgc_mainScrollView else {
            return
        }
        dgc_startEditing()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == dgc_mainScrollView else {
            return
        }
        dgc_startTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == dgc_mainScrollView else {
            return
        }
        if !decelerate {
            dgc_startTimer()
        }
    }
}

extension DGCZLClipImageViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DGCZLClipImageDismissAnimatedTransition()
    }
}

// MARK: 裁剪比例cell

class DGCZLImageClipRatioCell: UICollectionViewCell {
    private lazy var dgc_imageView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 8, y: 5, width: bounds.width - 16, height: bounds.width - 16))
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: bounds.height - 15, width: bounds.width, height: 12))
        label.font = .zl.font(ofSize: 12)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowOpacity = 1
        return label
    }()
    
    var image: UIImage?
    
    var ratio: DGCZLImageClipRatio!
    
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
        guard let dgc_ratio = dgc_ratio, let dgc_image = dgc_image else {
            return
        }
        
        let dgc_center = dgc_imageView.dgc_center
        var dgc_w: CGFloat = 0, h: CGFloat = 0
        
        let dgc_imageMaxW = bounds.width - 10
        if dgc_ratio.whRatio == 0 {
            let dgc_maxSide = max(dgc_image.size.width, dgc_image.size.height)
            dgc_w = dgc_imageMaxW * dgc_image.size.width / dgc_maxSide
            h = dgc_imageMaxW * dgc_image.size.height / dgc_maxSide
        } else {
            if dgc_ratio.whRatio >= 1 {
                dgc_w = dgc_imageMaxW
                h = dgc_w / dgc_ratio.whRatio
            } else {
                h = dgc_imageMaxW
                dgc_w = h * dgc_ratio.whRatio
            }
        }
        if dgc_ratio.isCircle {
            dgc_imageView.layer.cornerRadius = dgc_w / 2
        } else {
            dgc_imageView.layer.cornerRadius = 3
        }
        dgc_imageView.frame = CGRect(x: dgc_center.x - dgc_w / 2, y: dgc_center.y - h / 2, width: dgc_w, height: h)
    }
    
    func dgc_setupUI() {
        contentView.addSubview(dgc_imageView)
        contentView.addSubview(titleLabel)
    }
    
    func configureCell(image: UIImage, ratio: DGCZLImageClipRatio) {
        dgc_imageView.image = image
        titleLabel.text = ratio.title
        self.image = image
        self.ratio = ratio
        
        setNeedsLayout()
    }
}
