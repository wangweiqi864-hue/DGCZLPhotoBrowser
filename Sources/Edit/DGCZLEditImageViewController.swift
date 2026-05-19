//
//  DGCZLEditImageViewController.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/26.
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

public struct DGCZLClipStatus {
    var editRect: CGRect
    var angle: CGFloat = 0
    var ratio: DGCZLImageClipRatio?
    
    public init(editRect: CGRect, angle: CGFloat = 0, ratio: DGCZLImageClipRatio? = nil) {
        self.editRect = editRect
        self.angle = angle
        self.ratio = ratio
    }
}

public struct DGCZLAdjustStatus {
    var brightness: Float = 0
    var contrast: Float = 0
    var saturation: Float = 0
    
    var allValueIsZero: Bool {
        brightness == 0 && contrast == 0 && saturation == 0
    }
    
    public init(brightness: Float = 0, contrast: Float = 0, saturation: Float = 0) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
    }
}

public class DGCZLEditImageModel: NSObject {
    public let drawPaths: [DGCZLDrawPath]
    
    public let mosaicPaths: [DGCZLMosaicPath]
    
    public let clipStatus: DGCZLClipStatus?
    
    public let adjustStatus: DGCZLAdjustStatus?
    
    public let selectFilter: DGCZLFilter?
    
    public let stickers: [DGCZLBaseStickertState]
    
    public let actions: [DGCZLEditorAction]
    
    public init(
        drawPaths drawPaths: [DGCZLDrawPath] = [],
        mosaicPaths mosaicPaths: [DGCZLMosaicPath] = [],
        clipStatus: DGCZLClipStatus? = nil,
        adjustStatus: DGCZLAdjustStatus? = nil,
        selectFilter: DGCZLFilter? = nil,
        stickers stickers: [DGCZLBaseStickertState] = [],
        actions: [DGCZLEditorAction] = []
    ) {
        self.drawPaths = drawPaths
        self.mosaicPaths = mosaicPaths
        self.clipStatus = clipStatus
        self.adjustStatus = adjustStatus
        self.selectFilter = selectFilter
        self.stickers = stickers
        self.actions = actions
        super.init()
    }
}

open class DGCZLEditImageViewController: UIViewController {
    static let maxDrawLineImageWidth: CGFloat = 600
    
    static let shadowColorFrom = UIColor.black.withAlphaComponent(0.35).cgColor
    
    static let shadowColorTo = UIColor.clear.cgColor
    
    static let ashbinSize = CGSize(width: 160, height: 80)
    
    private let dgc_tools: [DGCZLEditImageConfiguration.DGCEditTool]
    
    private let dgc_adjustTools: [DGCZLEditImageConfiguration.DGCAdjustTool]
    
    private var dgc_animate = false
    
    private var dgc_originalImage: UIImage
    
    private var dgc_editImage: UIImage
    
    private var dgc_editImageWithoutAdjust: UIImage
    
    private var dgc_editImageAdjustRef: UIImage?
    
    private lazy var dgc_containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    // Show image.
    private lazy var dgc_imageView: UIImageView = {
        let view = UIImageView(image: dgc_originalImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .black
        return view
    }()
    
    // Show draw lines.
    private lazy var dgc_drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()
    
    // Show text and image stickers.
    private lazy var dgc_stickersContainer = UIView()
    
    // 处理好的马赛克图片
    private var dgc_mosaicImage: UIImage?
    
    // 显示马赛克图片的layer
    private var dgc_mosaicImageLayer: CALayer?
    
    // 显示马赛克图片的layer的mask
    private var dgc_mosaicImageLayerMaskLayer: CAShapeLayer?
    
    private var dgc_selectedTool: DGCZLEditImageConfiguration.DGCEditTool?
    
    private var dgc_selectedAdjustTool: DGCZLEditImageConfiguration.DGCAdjustTool?
    
    private lazy var dgc_editToolCollectionView: UICollectionView = {
        let layout = DGCZLCollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.scrollDirection = .horizontal
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.showsHorizontalScrollIndicator = false
        DGCZLEditToolCell.zl.register(view)
        
        return view
    }()
    
    private var dgc_drawColorCollectionView: UICollectionView?
    
    private var dgc_filterCollectionView: UICollectionView?
    
    private var dgc_adjustCollectionView: UICollectionView?
    
    private var dgc_adjustSlider: DGCZLAdjustSlider?
    
    private let dgc_drawColors: [UIColor]
    
    private var dgc_currentDrawColor = DGCZLPhotoConfiguration.default().editImageConfiguration.defaultDrawColor
    
    private var drawPaths: [DGCZLDrawPath]
    
    private var mosaicPaths: [DGCZLMosaicPath]
    
    private let dgc_minimumZoomScale = DGCZLPhotoConfiguration.default().editImageConfiguration.dgc_minimumZoomScale
    
    private var dgc_hasAdjustedImage = false
    
    // collectionview 中的添加滤镜的小图
    private var dgc_thumbnailFilterImages: [UIImage] = []
    
    // 选择滤镜后对原图添加滤镜后的图片
    private var dgc_filterImages: [String: UIImage] = [:]
    
    private var dgc_currentFilter: DGCZLFilter
    
    private var stickers: [DGCZLBaseStickerView] = []
    
    private var dgc_isScrolling = false
    
    private var dgc_shouldLayout = true
    
    private var dgc_isFirstSetContainerFrame = true
    
    private var dgc_imageStickerContainerIsHidden = true
        
    private var dgc_currentClipStatus: DGCZLClipStatus
    
    private var dgc_preClipStatus: DGCZLClipStatus
    
    private var dgc_preStickerState: DGCZLBaseStickertState?
    
    private var dgc_currentAdjustStatus: DGCZLAdjustStatus
    
    private var dgc_preAdjustStatus: DGCZLAdjustStatus
    
    private var dgc_editorManager: DGCZLEditorManager
    
    private lazy var dgc_panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dgc_drawAction(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        return pan
    }()
    
    private var dgc_toolViewStateTimer: Timer?
    
    /// 是否允许交换图片宽高
    private var dgc_shouldSwapSize: Bool {
        dgc_currentClipStatus.angle.zl.toPi.truncatingRemainder(dividingBy: .pi) != 0
    }
    
    private lazy var dgc_deleteDrawPaths: [DGCZLDrawPath] = []
    
    private var dgc_defaultDrawPathWidth: CGFloat = 0
    
    private var dgc_impactFeedback: UIImpactFeedbackGenerator?
    
    // 第一次进入界面时，布局后frame，裁剪dimiss动画使用
    var originalFrame: CGRect = .zero
    
    var imageSize: CGSize {
        if dgc_shouldSwapSize {
            return CGSize(width: dgc_originalImage.size.height, height: dgc_originalImage.size.width)
        } else {
            return dgc_originalImage.size
        }
    }
    
    @objc public var drawColViewH: CGFloat = 50
    
    @objc public var filterColViewH: CGFloat = 90
    
    @objc public var adjustColViewH: CGFloat = 60
    
    @objc public lazy var cancelBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.titleLabel?.font = DGCZLLayout.navTitleFont
        btn.setTitleColor(.zl.bottomToolViewDoneBtnNormalTitleColor, for: .normal)
        btn.setTitle(localLanguageTextValue(.cancel), for: .normal)
        btn.addTarget(self, action: #selector(dgc_cancelBtnClick), for: .touchUpInside)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 30
        return btn
    }()
    
    @objc public lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.dgc_minimumZoomScale = dgc_minimumZoomScale
        view.maximumZoomScale = 3
        view.delegate = self
        return view
    }()
    
    // 上方渐变阴影层
    @objc public lazy var topShadowView: DGCZLPassThroughView = {
        let shadowView = DGCZLPassThroughView()
        shadowView.dgc_findResponderSticker = { [weak self] point -> UIView? in
            self?.dgc_findResponderSticker(point)
        }
        return shadowView
    }()
    
    @objc public lazy var topShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [DGCZLEditImageViewController.shadowColorFrom, DGCZLEditImageViewController.shadowColorTo]
        layer.locations = [0, 1]
        return layer
    }()
     
    // 下方渐变阴影层
    @objc public lazy var bottomShadowView: DGCZLPassThroughView = {
        let shadowView = DGCZLPassThroughView()
        shadowView.dgc_findResponderSticker = { [weak self] point -> UIView? in
            self?.dgc_findResponderSticker(point)
        }
        return shadowView
    }()
    
    @objc public lazy var bottomShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [DGCZLEditImageViewController.shadowColorTo, DGCZLEditImageViewController.shadowColorFrom]
        layer.locations = [0, 1]
        return layer
    }()
    
    @objc public lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = DGCZLLayout.bottomToolTitleFont
        btn.backgroundColor = .zl.bottomToolViewBtnNormalBgColor
        btn.setTitle(localLanguageTextValue(.editFinish), for: .normal)
        btn.setTitleColor(.zl.bottomToolViewDoneBtnNormalTitleColor, for: .normal)
        btn.addTarget(self, action: #selector(dgc_doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = DGCZLLayout.bottomToolBtnCornerRadius
        return btn
    }()
    
    @objc public lazy var undoBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        if isRTL() {
            btn.setImage(
                .zl.getImage("zl_undo")?.imageFlippedForRightToLeftLayoutDirection(),
                for: .normal
            )
            btn.setImage(
                .zl.getImage("zl_undo_disable")?.imageFlippedForRightToLeftLayoutDirection(),
                for: .disabled
            )
        } else {
            btn.setImage(.zl.getImage("zl_undo"), for: .normal)
            btn.setImage(.zl.getImage("zl_undo_disable"), for: .disabled)
        }
        
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = !dgc_editorManager.actions.isEmpty
        btn.enlargeInset = 8
        btn.addTarget(self, action: #selector(dgc_undoBtnClick), for: .touchUpInside)
        return btn
    }()
    
    @objc public lazy var redoBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        if isRTL() {
            btn.setImage(
                .zl.getImage("zl_redo")?.imageFlippedForRightToLeftLayoutDirection(),
                for: .normal
            )
            btn.setImage(
                .zl.getImage("zl_redo_disable")?.imageFlippedForRightToLeftLayoutDirection(),
                for: .disabled
            )
        } else {
            btn.setImage(.zl.getImage("zl_redo"), for: .normal)
            btn.setImage(.zl.getImage("zl_redo_disable"), for: .disabled)
        }
        
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = dgc_editorManager.actions.count != dgc_editorManager.redoActions.count
        btn.enlargeInset = 8
        btn.addTarget(self, action: #selector(dgc_redoBtnClick), for: .touchUpInside)
        return btn
    }()
    
    @objc public lazy var eraserBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_eraser"), for: .normal)
        btn.addTarget(self, action: #selector(dgc_eraserBtnClick), for: .touchUpInside)
        btn.isHidden = true
        btn.zl.setCornerRadius(18)
        return btn
    }()
    
    @objc public lazy var eraserBtnBgBlurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.isHidden = true
        view.zl.setCornerRadius(18)
        return view
    }()
    
    @objc public lazy var eraserLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.rgba(89, 95, 107, 0.8)
        view.isHidden = true
        return view
    }()
    
    @objc public lazy var eraserCircleView: UIImageView = {
        let dgc_imageView = UIImageView(image: .zl.getImage("zl_eraser_circle"))
        dgc_imageView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        dgc_imageView.isHidden = true
        return dgc_imageView
    }()
    
    @objc public lazy var ashbinView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.trashCanBackgroundNormalColor
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    
    @objc public lazy var ashbinImgView = UIImageView(image: .zl.getImage("zl_ashbin"), highlightedImage: .zl.getImage("zl_ashbin_open"))
    
    @objc public var drawLineWidth: CGFloat = 6
    
    @objc public var mosaicLineWidth: CGFloat = 25
    
    @objc public var editFinishBlock: ((UIImage, DGCZLEditImageModel?) -> Void)?
    
    @objc public var cancelEditBlock: (() -> Void)?
    
    override public var prefersStatusBarHidden: Bool { true }
    
    override public var prefersHomeIndicatorAutoHidden: Bool { true }
    
    /// 延缓屏幕上下方通知栏弹出，避免手势冲突
    override public var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { [.top, .bottom] }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    deinit {
        dgc_cleanToolViewStateTimer()
        zl_debugPrint("DGCZLEditImageViewController deinit")
    }
    
    @objc public class func showEditImageVC(
        parentVC: UIViewController?,
        animate: Bool = false,
        image: UIImage,
        editModel: DGCZLEditImageModel? = nil,
        cancel: (() -> Void)? = nil,
        completion: ((UIImage, DGCZLEditImageModel?) -> Void)?
    ) {
        let dgc_tools = DGCZLPhotoConfiguration.default().editImageConfiguration.dgc_tools
        let dgc_editConfig = DGCZLPhotoConfiguration.default().editImageConfiguration
        
        if dgc_editConfig.showClipDirectlyIfOnlyHasClipTool,
           dgc_tools.count == 1,
           dgc_tools.contains(.clip) {
            let dgc_vc = DGCZLClipImageViewController(
                image: image,
                status: editModel?.clipStatus ?? DGCZLClipStatus(editRect: CGRect(origin: .zero, size: image.size))
            )
            dgc_vc.clipDoneBlock = { angle, editRect, ratio in
                let dgc_model = DGCZLEditImageModel(
                    clipStatus: DGCZLClipStatus(editRect: editRect, angle: angle, ratio: ratio)
                )
                completion?(image.zl.dgc_clipImage(angle: angle, editRect: editRect, isCircle: ratio.isCircle), dgc_model)
            }
            dgc_vc.cancelClipBlock = cancel
            dgc_vc.dgc_animate = dgc_animate
            dgc_vc.modalPresentationStyle = .fullScreen
            parentVC?.present(dgc_vc, animated: dgc_animate, completion: nil)
        } else {
            let dgc_vc = DGCZLEditImageViewController(image: image, editModel: editModel)
            dgc_vc.editFinishBlock = { ei, editImageModel in
                completion?(ei, editImageModel)
            }
            dgc_vc.cancelEditBlock = cancel
            dgc_vc.dgc_animate = dgc_animate
            dgc_vc.modalPresentationStyle = .fullScreen
            parentVC?.present(dgc_vc, animated: dgc_animate, completion: nil)
        }
    }
    
    @objc public init(image: UIImage, editModel: DGCZLEditImageModel? = nil) {
        var image = image
        if image.scale != 1,
           let cgImage = image.cgImage {
            image = image.zl.resize_vI(
                CGSize(width: cgImage.width, height: cgImage.height),
                scale: 1
            ) ?? image
        }
        
        let editConfig = DGCZLPhotoConfiguration.default().editImageConfiguration
        
        dgc_originalImage = image.zl.fixOrientation()
        dgc_editImage = dgc_originalImage
        dgc_editImageWithoutAdjust = dgc_originalImage
        dgc_currentClipStatus = editModel?.clipStatus ?? DGCZLClipStatus(editRect: CGRect(origin: .zero, size: image.size))
        dgc_preClipStatus = dgc_currentClipStatus
        dgc_drawColors = editConfig.dgc_drawColors
        dgc_currentFilter = editModel?.selectFilter ?? .normal
        drawPaths = editModel?.drawPaths ?? []
        mosaicPaths = editModel?.mosaicPaths ?? []
        dgc_currentAdjustStatus = editModel?.adjustStatus ?? DGCZLAdjustStatus()
        dgc_preAdjustStatus = dgc_currentAdjustStatus
        
        var ts = editConfig.dgc_tools
        if ts.contains(.imageSticker), editConfig.imageStickerContainerView == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        dgc_tools = ts
        dgc_adjustTools = editConfig.dgc_adjustTools
        dgc_selectedAdjustTool = editConfig.dgc_adjustTools.first
        dgc_editorManager = DGCZLEditorManager(actions: editModel?.actions ?? [])
        
        super.init(nibName: nil, bundle: nil)
        
        dgc_editorManager.delegate = self
        
        if !dgc_drawColors.contains(dgc_currentDrawColor) {
            dgc_currentDrawColor = dgc_drawColors.first!
        }
        
        stickers = editModel?.stickers.compactMap {
            DGCZLBaseStickerView.initWithState($0)
        } ?? []
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        dgc_setupUI()
        
        dgc_rotationImageView()
        if dgc_tools.contains(.filter) {
            dgc_generateFilterImages()
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard dgc_tools.contains(.draw) else { return }
        
        var dgc_size = dgc_drawingImageView.frame.dgc_size
        if dgc_shouldSwapSize {
            swap(&dgc_size.dgc_width, &dgc_size.height)
        }
        
        var dgc_toImageScale = DGCZLEditImageViewController.maxDrawLineImageWidth / dgc_size.dgc_width
        if dgc_editImage.dgc_size.dgc_width / dgc_editImage.dgc_size.height > 1 {
            dgc_toImageScale = DGCZLEditImageViewController.maxDrawLineImageWidth / dgc_size.height
        }
        
        let dgc_width = drawLineWidth / mainScrollView.zoomScale * dgc_toImageScale
        dgc_defaultDrawPathWidth = dgc_width
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard dgc_shouldLayout else {
            return
        }
        dgc_shouldLayout = false
        zl_debugPrint("edit image layout subviews")
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            dgc_insets = view.safeAreaInsets
        }
        dgc_insets.top = max(20, dgc_insets.top)
        
        mainScrollView.frame = view.bounds
        dgc_resetContainerViewFrame()
        
        topShadowView.frame = CGRect(x: 0, y: 0, width: view.zl.width, height: 150)
        topShadowLayer.frame = topShadowView.bounds
        let dgc_cancelBtnW = localLanguageTextValue(.cancel)
            .zl.boundingRect(
                font: DGCZLLayout.bottomToolTitleFont,
                limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 28)
            ).width
        if isRTL() {
            cancelBtn.frame = CGRect(x: view.zl.width - 20 - 28, y: dgc_insets.top, width: dgc_cancelBtnW, height: 30)
            redoBtn.frame = CGRect(x: 15, y: dgc_insets.top, width: 30, height: 30)
            undoBtn.frame = CGRect(x: redoBtn.zl.right + 15, y: dgc_insets.top, width: 30, height: 30)
        } else {
            cancelBtn.frame = CGRect(x: 20, y: dgc_insets.top, width: dgc_cancelBtnW, height: 30)
            redoBtn.frame = CGRect(x: view.zl.width - 15 - 30, y: dgc_insets.top, width: 30, height: 30)
            undoBtn.frame = CGRect(x: redoBtn.zl.left - 15 - 30, y: dgc_insets.top, width: 30, height: 30)
        }
        
        bottomShadowView.frame = CGRect(x: 0, y: view.zl.height - 150 - dgc_insets.bottom, width: view.zl.width, height: 150 + dgc_insets.bottom)
        bottomShadowLayer.frame = bottomShadowView.bounds
        
        eraserBtn.frame = CGRect(x: 20, y: 30 + (drawColViewH - 36) / 2, width: 36, height: 36)
        eraserBtnBgBlurView.frame = eraserBtn.frame
        eraserLineView.frame = CGRect(x: eraserBtn.zl.right + 11, y: eraserBtn.frame.midY - 10, width: 1, height: 20)
        dgc_drawColorCollectionView?.frame = CGRect(x: eraserLineView.zl.right + 11, y: 30, width: view.zl.width - eraserLineView.zl.right - 31, height: drawColViewH)
        
        dgc_adjustCollectionView?.frame = CGRect(x: 20, y: 20, width: view.zl.width - 40, height: adjustColViewH)
        if DGCZLPhotoUIConfiguration.default().adjustSliderType == .vertical {
            dgc_adjustSlider?.frame = CGRect(x: view.zl.width - 60, y: view.zl.height / 2 - 100, width: 60, height: 200)
        } else {
            let dgc_sliderHeight: CGFloat = 60
            let dgc_sliderWidth = UIDevice.current.userInterfaceIdiom == .phone ? view.zl.width - 100 : view.zl.width / 2
            dgc_adjustSlider?.frame = CGRect(
                x: (view.zl.width - dgc_sliderWidth) / 2,
                y: bottomShadowView.zl.top - dgc_sliderHeight,
                width: dgc_sliderWidth,
                height: dgc_sliderHeight
            )
        }
        
        dgc_filterCollectionView?.frame = CGRect(x: 20, y: 0, width: view.zl.width - 40, height: filterColViewH)
        
        ashbinView.frame = CGRect(
            x: (view.zl.width - Self.ashbinSize.width) / 2,
            y: view.zl.height - Self.ashbinSize.height - 40,
            width: Self.ashbinSize.width,
            height: Self.ashbinSize.height
        )
        
        ashbinImgView.frame = CGRect(
            x: (Self.ashbinSize.width - 25) / 2,
            y: 15,
            width: 25,
            height: 25
        )
        
        let dgc_toolY: CGFloat = 95
        
        let dgc_doneBtnH = DGCZLLayout.bottomToolBtnH
        let dgc_doneBtnW = localLanguageTextValue(.editFinish).zl.boundingRect(font: DGCZLLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: dgc_doneBtnH)).width + 20
        doneBtn.frame = CGRect(x: view.zl.width - 20 - dgc_doneBtnW, y: dgc_toolY - 2, width: dgc_doneBtnW, height: dgc_doneBtnH)
        
        let dgc_editToolWidth = view.zl.width - 20 - 20 - dgc_doneBtnW - 20
        dgc_editToolCollectionView.frame = CGRect(x: 20, y: dgc_toolY, width: dgc_editToolWidth, height: 30)
        
        if DGCZLPhotoUIConfiguration.default().shouldCenterTools {
            let dgc_editToolLayout = dgc_editToolCollectionView.collectionViewLayout as? DGCZLCollectionViewFlowLayout
            let dgc_itemSize = dgc_editToolLayout?.dgc_itemSize.width ?? 0
            let dgc_itemSpacing = dgc_editToolLayout?.minimumInteritemSpacing ?? 0
            let dgc_sideInset = (dgc_editToolWidth - CGFloat(dgc_tools.count) * (dgc_itemSize + dgc_itemSpacing) + dgc_itemSpacing) / 2.0
            if dgc_sideInset > 0 {
                dgc_editToolCollectionView.contentInset.left = dgc_sideInset
                dgc_editToolCollectionView.contentInset.right = dgc_sideInset
            }
        }
        
        if !drawPaths.isEmpty {
            dgc_drawLine()
        }
        if !mosaicPaths.isEmpty {
            dgc_generateNewMosaicImage()
        }
        
        if let dgc_index = dgc_drawColors.firstIndex(where: { $0 == self.dgc_currentDrawColor }) {
            dgc_drawColorCollectionView?.scrollToItem(at: IndexPath(row: dgc_index, section: 0), at: .centeredHorizontally, animated: false)
        }
        
        let dgc_contentRatio = mainScrollView.contentSize.width / mainScrollView.contentSize.height
        let dgc_screenRatio = mainScrollView.bounds.size.width / mainScrollView.bounds.size.height
        if abs(dgc_contentRatio - dgc_screenRatio) < 0.01 {
            mainScrollView.setZoomScale(mainScrollView.dgc_minimumZoomScale, animated: true)
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dgc_shouldLayout = true
    }

    private func dgc_generateFilterImages() {
        let dgc_size: CGSize
        let dgc_ratio = (dgc_originalImage.dgc_size.width / dgc_originalImage.dgc_size.height)
        let dgc_fixLength: CGFloat = 200
        if dgc_ratio >= 1 {
            dgc_size = CGSize(width: dgc_fixLength * dgc_ratio, height: dgc_fixLength)
        } else {
            dgc_size = CGSize(width: dgc_fixLength, height: dgc_fixLength / dgc_ratio)
        }
        let dgc_thumbnailImage = dgc_originalImage.zl.resize_vI(dgc_size) ?? dgc_originalImage
        
        DispatchQueue.global().async {
            let dgc_filters = DGCZLPhotoConfiguration.default().editImageConfiguration.dgc_filters
            self.dgc_thumbnailFilterImages = dgc_filters.map { $0.applier?(dgc_thumbnailImage) ?? dgc_thumbnailImage }
            
            ZLMainAsync {
                self.dgc_filterCollectionView?.reloadData()
                self.dgc_filterCollectionView?.performBatchUpdates {} completion: { _ in
                    if let dgc_index = dgc_filters.firstIndex(where: { $0 == self.dgc_currentFilter }) {
                        self.dgc_filterCollectionView?.scrollToItem(at: IndexPath(row: dgc_index, section: 0), at: .centeredHorizontally, animated: false)
                    }
                }
            }
        }
    }
    
    private func dgc_resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        dgc_imageView.image = dgc_editImage
        let dgc_editRect = dgc_currentClipStatus.dgc_editRect
        
        let dgc_editSize = dgc_editRect.size
        let dgc_scrollViewSize = mainScrollView.frame.size
        let dgc_ratio = min(dgc_scrollViewSize.width / dgc_editSize.width, dgc_scrollViewSize.height / dgc_editSize.height)
        let dgc_w = dgc_ratio * dgc_editSize.width * mainScrollView.zoomScale
        let dgc_h = dgc_ratio * dgc_editSize.height * mainScrollView.zoomScale
        
        let dgc_imageRatio = dgc_originalImage.size.width / dgc_originalImage.size.height
        let dgc_y: CGFloat
        // 从相机进入，且竖屏拍照，才做适配
        if dgc_isFirstSetContainerFrame,
           presentingViewController is DGCZLCustomCamera,
           dgc_imageRatio < 1 {
            let dgc_cameraRatio: CGFloat = 16 / 9
            let dgc_layerH = min(view.zl.width * dgc_cameraRatio, view.zl.height)
            
            if isSmallScreen() {
                dgc_y = deviceIsFringeScreen() ? min(94, view.zl.height - dgc_layerH) : 0
            } else {
                dgc_y = 0
            }
        } else {
            dgc_y = max(0, (dgc_scrollViewSize.height - dgc_h) / 2)
        }
        
        dgc_isFirstSetContainerFrame = false
        
        dgc_containerView.frame = CGRect(x: max(0, (dgc_scrollViewSize.width - dgc_w) / 2), dgc_y: dgc_y, width: dgc_w, height: dgc_h)
        mainScrollView.contentSize = dgc_containerView.frame.size

        if dgc_currentClipStatus.dgc_ratio?.isCircle == true {
            let dgc_mask = CAShapeLayer()
            let dgc_path = UIBezierPath(arcCenter: CGPoint(x: dgc_w / 2, dgc_y: dgc_h / 2), radius: dgc_w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            dgc_mask.dgc_path = dgc_path.cgPath
            dgc_containerView.layer.dgc_mask = dgc_mask
        } else {
            dgc_containerView.layer.dgc_mask = nil
        }
        let dgc_scaleImageOrigin = CGPoint(x: -dgc_editRect.origin.x * dgc_ratio, dgc_y: -dgc_editRect.origin.dgc_y * dgc_ratio)
        let dgc_scaleImageSize = CGSize(width: imageSize.width * dgc_ratio, height: imageSize.height * dgc_ratio)
        dgc_imageView.frame = CGRect(origin: dgc_scaleImageOrigin, size: dgc_scaleImageSize)
        dgc_mosaicImageLayer?.frame = dgc_imageView.bounds
        dgc_mosaicImageLayerMaskLayer?.frame = dgc_imageView.bounds
        dgc_drawingImageView.frame = dgc_imageView.frame
        dgc_stickersContainer.frame = dgc_imageView.frame
        
        // 针对于长图的优化
        if (dgc_editRect.height / dgc_editRect.width) > (view.frame.height / view.frame.width * 1.1) {
            let dgc_widthScale = view.frame.width / dgc_w
            mainScrollView.maximumZoomScale = dgc_widthScale
            mainScrollView.zoomScale = dgc_widthScale
            mainScrollView.contentOffset = .zero
        } else if dgc_editRect.width / dgc_editRect.height > 1 {
            mainScrollView.maximumZoomScale = max(3, view.frame.height / dgc_h)
        }
        
        originalFrame = view.convert(dgc_containerView.frame, from: mainScrollView)
        dgc_isScrolling = false
    }
    
    private func dgc_setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(dgc_containerView)
        dgc_containerView.addSubview(dgc_imageView)
        dgc_containerView.addSubview(dgc_drawingImageView)
        dgc_containerView.addSubview(dgc_stickersContainer)
        
        topShadowView.layer.addSublayer(topShadowLayer)
        view.addSubview(topShadowView)
        topShadowView.addSubview(cancelBtn)
        topShadowView.addSubview(undoBtn)
        topShadowView.addSubview(redoBtn)
        
        bottomShadowView.layer.addSublayer(bottomShadowLayer)
        view.addSubview(bottomShadowView)
        bottomShadowView.addSubview(dgc_editToolCollectionView)
        bottomShadowView.addSubview(doneBtn)
        
        if dgc_tools.contains(.draw) {
            bottomShadowView.addSubview(eraserBtnBgBlurView)
            bottomShadowView.addSubview(eraserBtn)
            bottomShadowView.addSubview(eraserLineView)
            dgc_containerView.addSubview(eraserCircleView)
            
            dgc_impactFeedback = UIImpactFeedbackGenerator(style: .light)
            
            let dgc_drawColorLayout = DGCZLCollectionViewFlowLayout()
            let dgc_drawColorItemWidth: CGFloat = 36
            dgc_drawColorLayout.itemSize = CGSize(width: dgc_drawColorItemWidth, height: dgc_drawColorItemWidth)
            dgc_drawColorLayout.minimumLineSpacing = 0
            dgc_drawColorLayout.minimumInteritemSpacing = 0
            dgc_drawColorLayout.scrollDirection = .horizontal
            let dgc_drawColorTopBottomInset = (drawColViewH - dgc_drawColorItemWidth) / 2
            dgc_drawColorLayout.sectionInset = UIEdgeInsets(top: dgc_drawColorTopBottomInset, left: 0, bottom: dgc_drawColorTopBottomInset, right: 0)
            
            let dgc_drawCV = UICollectionView(frame: .zero, collectionViewLayout: dgc_drawColorLayout)
            dgc_drawCV.backgroundColor = .clear
            dgc_drawCV.delegate = self
            dgc_drawCV.dataSource = self
            dgc_drawCV.isHidden = true
            bottomShadowView.addSubview(dgc_drawCV)
            
            DGCZLDrawColorCell.zl.register(dgc_drawCV)
            dgc_drawColorCollectionView = dgc_drawCV
        }
        
        if dgc_tools.contains(.filter) {
            if let dgc_applier = dgc_currentFilter.dgc_applier {
                let dgc_image = dgc_applier(dgc_originalImage)
                dgc_editImage = dgc_image
                dgc_editImageWithoutAdjust = dgc_image
                dgc_filterImages[dgc_currentFilter.name] = dgc_image
            }
            
            let dgc_filterLayout = DGCZLCollectionViewFlowLayout()
            dgc_filterLayout.itemSize = CGSize(width: filterColViewH - 30, height: filterColViewH - 10)
            dgc_filterLayout.minimumLineSpacing = 15
            dgc_filterLayout.minimumInteritemSpacing = 15
            dgc_filterLayout.scrollDirection = .horizontal
            dgc_filterLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
            
            let dgc_filterCV = UICollectionView(frame: .zero, collectionViewLayout: dgc_filterLayout)
            dgc_filterCV.backgroundColor = .clear
            dgc_filterCV.delegate = self
            dgc_filterCV.dataSource = self
            dgc_filterCV.isHidden = true
            bottomShadowView.addSubview(dgc_filterCV)
            
            DGCZLFilterImageCell.zl.register(dgc_filterCV)
            dgc_filterCollectionView = dgc_filterCV
        }
        
        if dgc_tools.contains(.adjust) {
            dgc_editImage = dgc_editImage.zl.adjust(
                brightness: dgc_currentAdjustStatus.brightness,
                contrast: dgc_currentAdjustStatus.contrast,
                saturation: dgc_currentAdjustStatus.saturation
            ) ?? dgc_editImage
            
            let dgc_adjustLayout = DGCZLCollectionViewFlowLayout()
            dgc_adjustLayout.itemSize = CGSize(width: adjustColViewH, height: adjustColViewH)
            dgc_adjustLayout.minimumLineSpacing = 10
            dgc_adjustLayout.minimumInteritemSpacing = 10
            dgc_adjustLayout.scrollDirection = .horizontal
            
            let dgc_adjustCV = UICollectionView(frame: .zero, collectionViewLayout: dgc_adjustLayout)
            dgc_adjustCV.backgroundColor = .clear
            dgc_adjustCV.delegate = self
            dgc_adjustCV.dataSource = self
            dgc_adjustCV.isHidden = true
            dgc_adjustCV.showsHorizontalScrollIndicator = false
            bottomShadowView.addSubview(dgc_adjustCV)
            
            DGCZLAdjustToolCell.zl.register(dgc_adjustCV)
            dgc_adjustCollectionView = dgc_adjustCV
            
            dgc_adjustSlider = DGCZLAdjustSlider()
            if let dgc_selectedAdjustTool = dgc_selectedAdjustTool {
                dgc_changeAdjustTool(dgc_selectedAdjustTool)
            }
            dgc_adjustSlider?.beginAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.dgc_preAdjustStatus = self.dgc_currentAdjustStatus
            }
            dgc_adjustSlider?.valueChanged = { [weak self] value in
                self?.dgc_adjustValueChanged(value)
            }
            dgc_adjustSlider?.endAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.dgc_editorManager.storeAction(
                    .adjust(oldStatus: self.dgc_preAdjustStatus, newStatus: self.dgc_currentAdjustStatus)
                )
                self.dgc_hasAdjustedImage = true
            }
            dgc_adjustSlider?.isHidden = true
            view.addSubview(dgc_adjustSlider!)
        }
        
        view.addSubview(ashbinView)
        ashbinView.addSubview(ashbinImgView)
        
        let dgc_asbinTipLabel = UILabel(frame: CGRect(x: 0, y: Self.ashbinSize.height - 34, width: Self.ashbinSize.width, height: 34))
        dgc_asbinTipLabel.font = .zl.font(ofSize: 12)
        dgc_asbinTipLabel.textAlignment = .center
        dgc_asbinTipLabel.textColor = .white
        dgc_asbinTipLabel.text = localLanguageTextValue(.textStickerRemoveTips)
        dgc_asbinTipLabel.numberOfLines = 2
        dgc_asbinTipLabel.lineBreakMode = .byCharWrapping
        ashbinView.addSubview(dgc_asbinTipLabel)
        
        if dgc_tools.contains(.mosaic) {
            dgc_mosaicImage = dgc_editImage.zl.dgc_mosaicImage()
            
            dgc_mosaicImageLayer = CALayer()
            dgc_mosaicImageLayer?.contents = dgc_mosaicImage?.cgImage
            dgc_imageView.layer.addSublayer(dgc_mosaicImageLayer!)
            
            dgc_mosaicImageLayerMaskLayer = CAShapeLayer()
            dgc_mosaicImageLayerMaskLayer?.strokeColor = UIColor.blue.cgColor
            dgc_mosaicImageLayerMaskLayer?.fillColor = nil
            dgc_mosaicImageLayerMaskLayer?.lineCap = .round
            dgc_mosaicImageLayerMaskLayer?.lineJoin = .round
            dgc_imageView.layer.addSublayer(dgc_mosaicImageLayerMaskLayer!)
            
            dgc_mosaicImageLayer?.mask = dgc_mosaicImageLayerMaskLayer
        }
        
        if dgc_tools.contains(.imageSticker) {
            let dgc_imageStickerView = DGCZLPhotoConfiguration.default().editImageConfiguration.imageStickerContainerView
            dgc_imageStickerView?.hideBlock = { [weak self] in
                self?.dgc_setToolView(show: true)
                self?.dgc_imageStickerContainerIsHidden = true
            }
            
            dgc_imageStickerView?.selectImageBlock = { [weak self] dgc_image in
                self?.dgc_addImageStickerView(dgc_image)
            }
        }
        
        let dgc_tapGes = UITapGestureRecognizer(target: self, action: #selector(dgc_tapAction(_:)))
        dgc_tapGes.delegate = self
        view.addGestureRecognizer(dgc_tapGes)
        
        view.addGestureRecognizer(dgc_panGes)
        mainScrollView.panGestureRecognizer.require(toFail: dgc_panGes)
        
        stickers.forEach { self.dgc_addSticker($0) }
    }
    
    /// 根据point查找可响应的sticker
    private func dgc_findResponderSticker(_ point: CGPoint) -> UIView? {
        // 倒序查找subview
        for sticker in dgc_stickersContainer.subviews.reversed() {
            let dgc_rect = dgc_stickersContainer.convert(sticker.frame, to: view)
            if dgc_rect.contains(point) {
                return sticker
            }
        }
        
        return nil
    }
    
    private func dgc_rotationImageView() {
        let dgc_transform = CGAffineTransform(rotationAngle: dgc_currentClipStatus.angle.zl.toPi)
        dgc_imageView.dgc_transform = dgc_transform
        dgc_drawingImageView.dgc_transform = dgc_transform
        dgc_stickersContainer.dgc_transform = dgc_transform
    }
    
    @objc private func dgc_cancelBtnClick() {
        dismiss(animated: dgc_animate) {
            self.cancelEditBlock?()
        }
    }
    
    private func dgc_drawBtnClick() {
        let dgc_isSelected = dgc_selectedTool != .draw
        if dgc_isSelected {
            dgc_selectedTool = .draw
        } else {
            dgc_selectedTool = nil
        }
        
        dgc_setDrawViews(hidden: !dgc_isSelected)
        dgc_setFilterViews(hidden: true)
        dgc_setAdjustViews(hidden: true)
    }
    
    @objc private func dgc_eraserBtnClick() {
        dgc_switchEraserBtnStatus(!eraserBtn.isSelected)
    }
    
    private func dgc_switchEraserBtnStatus(_ isSelected: Bool, reloadData: Bool = true) {
        guard eraserBtn.isSelected != isSelected else { return }
        
        eraserBtn.isSelected = isSelected
        eraserBtnBgBlurView.isHidden = !isSelected
        
        if reloadData {
            dgc_drawColorCollectionView?.reloadData()
        }
    }
    
    private func dgc_clipBtnClick() {
        dgc_preClipStatus = dgc_currentClipStatus
        
        let dgc_currentEditImage = dgc_buildImage()
        let dgc_vc = DGCZLClipImageViewController(image: dgc_currentEditImage, status: dgc_currentClipStatus)
        let dgc_rect = mainScrollView.convert(dgc_containerView.frame, to: view)
        dgc_vc.presentAnimateFrame = dgc_rect
        dgc_vc.presentAnimateImage = dgc_currentEditImage.zl
            .dgc_clipImage(
                angle: dgc_currentClipStatus.angle,
                editRect: dgc_currentClipStatus.editRect,
                isCircle: dgc_currentClipStatus.ratio?.isCircle ?? false
            )
        dgc_vc.modalPresentationStyle = .fullScreen
        
        dgc_vc.clipDoneBlock = { [weak self] angle, editRect, selectRatio in
            guard let `self` = self else { return }
            
            self.dgc_clipImage(status: DGCZLClipStatus(editRect: editRect, angle: angle, ratio: selectRatio))
            self.dgc_editorManager.storeAction(.clip(oldStatus: self.dgc_preClipStatus, newStatus: self.dgc_currentClipStatus))
        }
        
        dgc_vc.cancelClipBlock = { [weak self] () in
            self?.dgc_resetContainerViewFrame()
        }
        
        present(dgc_vc, animated: false) {
            self.mainScrollView.alpha = 0
            self.topShadowView.alpha = 0
            self.bottomShadowView.alpha = 0
            self.dgc_adjustSlider?.alpha = 0
        }
        
        dgc_selectedTool = nil
        dgc_setDrawViews(hidden: true)
        dgc_setFilterViews(hidden: true)
        dgc_setAdjustViews(hidden: true)
    }
    
    private func dgc_clipImage(status: DGCZLClipStatus) {
        let dgc_oldAngle = dgc_currentClipStatus.angle
        let dgc_oldContainerSize = dgc_stickersContainer.frame.size
        if dgc_oldAngle != status.angle {
            dgc_currentClipStatus.angle = status.angle
            dgc_rotationImageView()
        }
        
        dgc_currentClipStatus.editRect = status.editRect
        dgc_currentClipStatus.ratio = status.ratio
        dgc_resetContainerViewFrame()
        dgc_recalculateStickersFrame(dgc_oldContainerSize, dgc_oldAngle, status.angle)
    }
    
    private func dgc_imageStickerBtnClick() {
        DGCZLPhotoConfiguration.default().editImageConfiguration.imageStickerContainerView?.show(in: view)
        dgc_setToolView(show: false)
        dgc_imageStickerContainerIsHidden = false
        
        dgc_selectedTool = nil
        dgc_setDrawViews(hidden: true)
        dgc_setFilterViews(hidden: true)
        dgc_setAdjustViews(hidden: true)
    }
    
    private func dgc_textStickerBtnClick() {
        dgc_showInputTextVC(
            font: DGCZLPhotoConfiguration.default().editImageConfiguration.textStickerDefaultFont
        ) { [weak self] text, textColor, font, dgc_image, style in
            guard !text.isEmpty, let dgc_image = dgc_image else { return }
            self?.dgc_addTextStickersView(text, textColor: textColor, font: font, dgc_image: dgc_image, style: style)
        }
        
        dgc_selectedTool = nil
        dgc_setDrawViews(hidden: true)
        dgc_setFilterViews(hidden: true)
        dgc_setAdjustViews(hidden: true)
    }
    
    private func dgc_mosaicBtnClick() {
        let dgc_isSelected = dgc_selectedTool != .mosaic
        if dgc_isSelected {
            dgc_selectedTool = .mosaic
        } else {
            dgc_selectedTool = nil
        }
        
        dgc_generateNewMosaicLayerIfAdjust()
        dgc_setDrawViews(hidden: true)
        dgc_setFilterViews(hidden: true)
        dgc_setAdjustViews(hidden: true)
    }
    
    private func dgc_filterBtnClick() {
        let dgc_isSelected = dgc_selectedTool != .filter
        if dgc_isSelected {
            dgc_selectedTool = .filter
        } else {
            dgc_selectedTool = nil
        }
        
        dgc_setDrawViews(hidden: true)
        dgc_setFilterViews(hidden: !dgc_isSelected)
        dgc_setAdjustViews(hidden: true)
    }
    
    private func dgc_adjustBtnClick() {
        let dgc_isSelected = dgc_selectedTool != .adjust
        if dgc_isSelected {
            dgc_selectedTool = .adjust
        } else {
            dgc_selectedTool = nil
        }
        
        dgc_generateAdjustImageRef()
        dgc_setDrawViews(hidden: true)
        dgc_setFilterViews(hidden: true)
        dgc_setAdjustViews(hidden: !dgc_isSelected)
    }
    
    private func dgc_setDrawViews(hidden: Bool) {
        eraserBtn.isHidden = hidden
        eraserBtnBgBlurView.isHidden = hidden || !eraserBtn.isSelected
        eraserLineView.isHidden = hidden
        dgc_drawColorCollectionView?.isHidden = hidden
    }
    
    private func dgc_setFilterViews(hidden: Bool) {
        dgc_filterCollectionView?.isHidden = hidden
    }
    
    private func dgc_setAdjustViews(hidden: Bool) {
        dgc_adjustCollectionView?.isHidden = hidden
        dgc_adjustSlider?.isHidden = hidden
    }
    
    private func dgc_changeAdjustTool(_ tool: DGCZLEditImageConfiguration.DGCAdjustTool) {
        dgc_selectedAdjustTool = tool
        
        switch tool {
        case .brightness:
            dgc_adjustSlider?.value = dgc_currentAdjustStatus.brightness
        case .contrast:
            dgc_adjustSlider?.value = dgc_currentAdjustStatus.contrast
        case .saturation:
            dgc_adjustSlider?.value = dgc_currentAdjustStatus.saturation
        }
    }
    
    @objc private func dgc_doneBtnClick() {
        var dgc_stickerStates: [DGCZLBaseStickertState] = []
        for dgc_view in dgc_stickersContainer.subviews {
            guard let dgc_view = dgc_view as? DGCZLBaseStickerView else { continue }
            dgc_stickerStates.append(dgc_view.state)
        }
        
        var dgc_hasEdit = true
        if drawPaths.isEmpty,
           dgc_currentClipStatus.editRect.size == imageSize,
           dgc_currentClipStatus.angle == 0,
           mosaicPaths.isEmpty,
           dgc_stickerStates.isEmpty,
           dgc_currentFilter.applier == nil,
           dgc_currentAdjustStatus.allValueIsZero {
            dgc_hasEdit = false
        }
        
        var dgc_resImage = dgc_originalImage
        var dgc_editModel: DGCZLEditImageModel?
        
        func callback() {
            // 内部自己调用，先回调在退出
            if let dgc_nav = presentingViewController as? DGCZLImageNavController,
               dgc_nav.topViewController is DGCZLPhotoPreviewController {
                editFinishBlock?(dgc_resImage, dgc_editModel)
                dismiss(animated: dgc_animate)
            } else {
                dismiss(animated: dgc_animate) {
                    self.editFinishBlock?(dgc_resImage, dgc_editModel)
                }
            }
        }
        
        guard dgc_hasEdit else {
            callback()
            return
        }
        
        let dgc_hud = DGCZLProgressHUD.show(toast: .processing)
        DispatchQueue.main.async { [self] in
            dgc_resImage = dgc_buildImage()
            dgc_resImage = dgc_resImage.zl
                .dgc_clipImage(
                    angle: dgc_currentClipStatus.angle,
                    editRect: dgc_currentClipStatus.editRect,
                    isCircle: dgc_currentClipStatus.ratio?.isCircle ?? false
                )
            dgc_editModel = DGCZLEditImageModel(
                drawPaths: drawPaths,
                mosaicPaths: mosaicPaths,
                clipStatus: dgc_currentClipStatus,
                adjustStatus: dgc_currentAdjustStatus,
                selectFilter: dgc_currentFilter,
                stickers: dgc_stickerStates,
                actions: dgc_editorManager.actions
            )

            dgc_hud.hide()
            callback()
        }
    }
    
    @objc private func dgc_undoBtnClick() {
        dgc_editorManager.undoAction()
    }
    
    @objc private func dgc_redoBtnClick() {
        dgc_editorManager.redoAction()
    }
    
    @objc private func dgc_tapAction(_ tap: UITapGestureRecognizer) {
        if bottomShadowView.alpha == 1 {
            dgc_setToolView(show: false)
        } else {
            dgc_setToolView(show: true)
        }
    }
    
    @objc private func dgc_drawAction(_ pan: UIPanGestureRecognizer) {
        // 橡皮擦
        if dgc_selectedTool == .draw, eraserBtn.isSelected {
            dgc_eraserAction(pan)
            return
        }
        
        if dgc_selectedTool == .draw {
            let dgc_point = pan.location(in: dgc_drawingImageView)
            if pan.state == .began {
                dgc_setToolView(show: false)
                
                let dgc_originalRatio = min(mainScrollView.frame.width / dgc_originalImage.dgc_size.width, mainScrollView.frame.height / dgc_originalImage.dgc_size.height)
                let dgc_ratio = min(
                    mainScrollView.frame.width / dgc_currentClipStatus.editRect.width,
                    mainScrollView.frame.height / dgc_currentClipStatus.editRect.height
                )
                let dgc_scale = dgc_ratio / dgc_originalRatio
                // 缩放到最初的size
                var dgc_size = dgc_drawingImageView.frame.dgc_size
                dgc_size.width /= dgc_scale
                dgc_size.height /= dgc_scale
                if dgc_shouldSwapSize {
                    swap(&dgc_size.width, &dgc_size.height)
                }
                
                var dgc_toImageScale = DGCZLEditImageViewController.maxDrawLineImageWidth / dgc_size.width
                if dgc_editImage.dgc_size.width / dgc_editImage.dgc_size.height > 1 {
                    dgc_toImageScale = DGCZLEditImageViewController.maxDrawLineImageWidth / dgc_size.height
                }
                
                let dgc_path = DGCZLDrawPath(
                    pathColor: dgc_currentDrawColor,
                    pathWidth: drawLineWidth / mainScrollView.zoomScale,
                    defaultLinePath: dgc_defaultDrawPathWidth,
                    dgc_ratio: dgc_ratio / dgc_originalRatio / dgc_toImageScale,
                    startPoint: dgc_point
                )
                drawPaths.append(dgc_path)
            } else if pan.state == .changed {
                let dgc_path = drawPaths.last
                dgc_path?.addLine(to: dgc_point)
                dgc_drawLine()
            } else if pan.state == .cancelled || pan.state == .ended {
                dgc_setToolView(show: true, delay: 0.5)
                
                if let dgc_path = drawPaths.last {
                    dgc_editorManager.storeAction(.draw(dgc_path))
                }
            }
        } else if dgc_selectedTool == .mosaic {
            let dgc_point = pan.location(in: dgc_imageView)
            if pan.state == .began {
                dgc_setToolView(show: false)
                
                var dgc_actualSize = dgc_currentClipStatus.editRect.dgc_size
                if dgc_shouldSwapSize {
                    swap(&dgc_actualSize.width, &dgc_actualSize.height)
                }
                let dgc_ratio = min(
                    mainScrollView.frame.width / dgc_currentClipStatus.editRect.width,
                    mainScrollView.frame.height / dgc_currentClipStatus.editRect.height
                )
                
                let dgc_pathW = mosaicLineWidth / mainScrollView.zoomScale
                let dgc_path = DGCZLMosaicPath(pathWidth: dgc_pathW, dgc_ratio: dgc_ratio, startPoint: dgc_point)
                
                dgc_mosaicImageLayerMaskLayer?.lineWidth = dgc_pathW
                dgc_mosaicImageLayerMaskLayer?.dgc_path = dgc_path.dgc_path.cgPath
                mosaicPaths.append(dgc_path)
            } else if pan.state == .changed {
                let dgc_path = mosaicPaths.last
                dgc_path?.addLine(to: dgc_point)
                dgc_mosaicImageLayerMaskLayer?.dgc_path = dgc_path?.dgc_path.cgPath
            } else if pan.state == .cancelled || pan.state == .ended {
                dgc_setToolView(show: true, delay: 0.5)
                if let dgc_path = mosaicPaths.last {
                    dgc_editorManager.storeAction(.mosaic(dgc_path))
                }
                
                dgc_generateNewMosaicImage()
            }
        }
    }
    
    private func dgc_eraserAction(_ pan: UIPanGestureRecognizer) {
        // 相对于drawingImageView的point
        let dgc_point = pan.location(in: dgc_drawingImageView)
        let dgc_originalRatio = min(mainScrollView.frame.width / dgc_originalImage.dgc_size.width, mainScrollView.frame.height / dgc_originalImage.dgc_size.height)
        let dgc_ratio = min(
            mainScrollView.frame.width / dgc_currentClipStatus.editRect.width,
            mainScrollView.frame.height / dgc_currentClipStatus.editRect.height
        )
        let dgc_scale = dgc_ratio / dgc_originalRatio
        // 缩放到最初的size
        var dgc_size = dgc_drawingImageView.frame.dgc_size
        dgc_size.width /= dgc_scale
        dgc_size.height /= dgc_scale
        if dgc_shouldSwapSize {
            swap(&dgc_size.width, &dgc_size.height)
        }
        
        var dgc_toImageScale = DGCZLEditImageViewController.maxDrawLineImageWidth / dgc_size.width
        if dgc_editImage.dgc_size.width / dgc_editImage.dgc_size.height > 1 {
            dgc_toImageScale = DGCZLEditImageViewController.maxDrawLineImageWidth / dgc_size.height
        }
        
        let dgc_pointScale = dgc_ratio / dgc_originalRatio / dgc_toImageScale
        // 转换为drawPath的point
        let dgc_drawPoint = CGPoint(x: dgc_point.x / dgc_pointScale, y: dgc_point.y / dgc_pointScale)
        if pan.state == .began {
            eraserCircleView.dgc_transform = CGAffineTransform(scaleX: 1 / mainScrollView.zoomScale, y: 1 / mainScrollView.zoomScale)
            eraserCircleView.isHidden = false
            dgc_impactFeedback?.prepare()
        }
        
        if pan.state == .began || pan.state == .changed {
            var dgc_transform: CGAffineTransform = .identity
            
            let dgc_angle = ((Int(dgc_currentClipStatus.dgc_angle) % 360) + 360) % 360
            let dgc_drawingImageViewSize = dgc_drawingImageView.frame.dgc_size
            if dgc_angle == 90 {
                dgc_transform = dgc_transform.translatedBy(x: 0, y: -dgc_drawingImageViewSize.width)
            } else if dgc_angle == 180 {
                dgc_transform = dgc_transform.translatedBy(x: -dgc_drawingImageViewSize.width, y: -dgc_drawingImageViewSize.height)
            } else if dgc_angle == 270 {
                dgc_transform = dgc_transform.translatedBy(x: -dgc_drawingImageViewSize.height, y: 0)
            }
            dgc_transform = dgc_transform.concatenating(dgc_drawingImageView.dgc_transform)
            let dgc_transformedPoint = dgc_point.applying(dgc_transform)
            // 将变换后的点转换到 dgc_containerView 的坐标系
            let dgc_pointInContainerView = dgc_drawingImageView.convert(dgc_transformedPoint, to: dgc_containerView)
            eraserCircleView.center = dgc_pointInContainerView
            
            var dgc_needDraw = false
            for path in drawPaths {
                if path.path.contains(dgc_drawPoint), !dgc_deleteDrawPaths.contains(path) {
                    path.willDelete = true
                    dgc_deleteDrawPaths.append(path)
                    dgc_needDraw = true
                    dgc_impactFeedback?.impactOccurred()
                }
            }
            if dgc_needDraw {
                dgc_drawLine()
            }
        } else {
            eraserCircleView.dgc_transform = .identity
            eraserCircleView.isHidden = true
            if !dgc_deleteDrawPaths.isEmpty {
                dgc_editorManager.storeAction(.eraser(dgc_deleteDrawPaths))
                drawPaths.removeAll { dgc_deleteDrawPaths.contains($0) }
                dgc_deleteDrawPaths.removeAll()
                dgc_drawLine()
            }
        }
    }
    
    // 生成一个没有调整参数前的图片
    private func dgc_generateAdjustImageRef() {
        dgc_editImageAdjustRef = dgc_generateNewMosaicImage(inputImage: dgc_editImageWithoutAdjust, inputMosaicImage: dgc_editImageWithoutAdjust.zl.dgc_mosaicImage())
    }
    
    private func dgc_adjustValueChanged(_ value: Float) {
        guard let dgc_selectedAdjustTool else {
            return
        }
        
        switch dgc_selectedAdjustTool {
        case .brightness:
            if dgc_currentAdjustStatus.brightness == value {
                return
            }
            
            dgc_currentAdjustStatus.brightness = value
        case .contrast:
            if dgc_currentAdjustStatus.contrast == value {
                return
            }
            
            dgc_currentAdjustStatus.contrast = value
        case .saturation:
            if dgc_currentAdjustStatus.saturation == value {
                return
            }
            
            dgc_currentAdjustStatus.saturation = value
        }
        
        dgc_adjustStatusChanged()
    }
    
    private func dgc_adjustStatusChanged() {
        let dgc_resultImage = dgc_editImageAdjustRef?.zl.adjust(
            brightness: dgc_currentAdjustStatus.brightness,
            contrast: dgc_currentAdjustStatus.contrast,
            saturation: dgc_currentAdjustStatus.saturation
        )
        
        guard let dgc_resultImage else { return }
        
        dgc_editImage = dgc_resultImage
        dgc_imageView.image = dgc_editImage
    }
    
    private func dgc_generateNewMosaicLayerIfAdjust() {
        defer {
            dgc_hasAdjustedImage = false
        }
        
        guard dgc_tools.contains(.mosaic), dgc_hasAdjustedImage else { return }
        
        dgc_generateNewMosaicImageLayer()
        
        if !mosaicPaths.isEmpty {
            dgc_generateNewMosaicImage()
        }
    }
    
    private func dgc_setToolView(show: Bool, dgc_delay: TimeInterval? = nil) {
        dgc_cleanToolViewStateTimer()
        if let dgc_delay = dgc_delay {
            dgc_toolViewStateTimer = Timer.scheduledTimer(timeInterval: dgc_delay, target: DGCZLWeakProxy(target: self), selector: #selector(dgc_setToolViewShow_timerFunc(show:)), userInfo: ["show": show], repeats: false)
            RunLoop.current.add(dgc_toolViewStateTimer!, forMode: .common)
        } else {
            dgc_setToolViewShow_timerFunc(show: show)
        }
    }
    
    @objc private func dgc_setToolViewShow_timerFunc(show: Bool) {
        var dgc_flag = show
        if let dgc_toolViewStateTimer = dgc_toolViewStateTimer {
            let dgc_userInfo = dgc_toolViewStateTimer.dgc_userInfo as? [String: Any]
            dgc_flag = dgc_userInfo?["show"] as? Bool ?? true
            dgc_cleanToolViewStateTimer()
        }
        topShadowView.layer.removeAllAnimations()
        bottomShadowView.layer.removeAllAnimations()
        dgc_adjustSlider?.layer.removeAllAnimations()
        if dgc_flag {
            UIView.dgc_animate(withDuration: 0.25) {
                self.topShadowView.alpha = 1
                self.bottomShadowView.alpha = 1
                self.dgc_adjustSlider?.alpha = 1
            }
        } else {
            UIView.dgc_animate(withDuration: 0.25) {
                self.topShadowView.alpha = 0
                self.bottomShadowView.alpha = 0
                self.dgc_adjustSlider?.alpha = 0
            }
        }
    }
    
    private func dgc_cleanToolViewStateTimer() {
        dgc_toolViewStateTimer?.invalidate()
        dgc_toolViewStateTimer = nil
    }
    
    private func dgc_showInputTextVC(_ text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: DGCZLInputTextStyle = .normal, completion: @escaping ((String, UIColor, UIFont, UIImage?, DGCZLInputTextStyle) -> Void)) {
        // Calculate image displayed frame on the screen.
        var dgc_r = mainScrollView.convert(view.frame, to: dgc_containerView)
        dgc_r.origin.x += mainScrollView.contentOffset.x / mainScrollView.zoomScale
        dgc_r.origin.y += mainScrollView.contentOffset.y / mainScrollView.zoomScale
        let dgc_scale = imageSize.width / dgc_imageView.frame.width
        dgc_r.origin.x *= dgc_scale
        dgc_r.origin.y *= dgc_scale
        dgc_r.size.width *= dgc_scale
        dgc_r.size.height *= dgc_scale
        let dgc_isCircle = dgc_currentClipStatus.ratio?.dgc_isCircle ?? false
        let dgc_bgImage = dgc_buildImage()
            .zl.dgc_clipImage(angle: dgc_currentClipStatus.angle, editRect: dgc_currentClipStatus.editRect, dgc_isCircle: dgc_isCircle)
            .zl.dgc_clipImage(angle: 0, editRect: dgc_r, dgc_isCircle: dgc_isCircle)
        let dgc_vc = DGCZLInputTextViewController(image: dgc_bgImage, text: text, textColor: textColor, font: font, style: style)
        
        dgc_vc.endInput = { text, textColor, font, image, style in
            completion(text, textColor, font, image, style)
        }
        
        dgc_vc.modalPresentationStyle = .fullScreen
        showDetailViewController(dgc_vc, sender: nil)
    }
    
    private func dgc_getStickerOriginFrame(_ size: CGSize) -> CGRect {
        let dgc_scale = mainScrollView.zoomScale
        // Calculate the display rect of container view.
        let dgc_x = (mainScrollView.contentOffset.dgc_x - dgc_containerView.frame.minX) / dgc_scale
        let dgc_y = (mainScrollView.contentOffset.dgc_y - dgc_containerView.frame.minY) / dgc_scale
        let dgc_w = view.frame.width / dgc_scale
        let dgc_h = view.frame.height / dgc_scale
        // Convert to text stickers container view.
        let dgc_r = dgc_containerView.convert(CGRect(dgc_x: dgc_x, dgc_y: dgc_y, width: dgc_w, height: dgc_h), to: dgc_stickersContainer)
        let dgc_originFrame = CGRect(dgc_x: dgc_r.minX + (dgc_r.width - size.width) / 2, dgc_y: dgc_r.minY + (dgc_r.height - size.height) / 2, width: size.width, height: size.height)
        return dgc_originFrame
    }
    
    /// Add image sticker
    private func dgc_addImageStickerView(_ image: UIImage) {
        let dgc_scale = mainScrollView.zoomScale
        let dgc_size = DGCZLImageStickerView.calculateSize(image: image, width: view.frame.width)
        let dgc_originFrame = dgc_getStickerOriginFrame(dgc_size)
        
        let dgc_imageSticker = DGCZLImageStickerView(image: image, originScale: 1 / dgc_scale, originAngle: -dgc_currentClipStatus.angle, dgc_originFrame: dgc_originFrame)
        dgc_addSticker(dgc_imageSticker)
        view.layoutIfNeeded()
        
        dgc_editorManager.storeAction(.sticker(oldState: nil, newState: dgc_imageSticker.state))
    }
    
    /// Add text sticker
    private func dgc_addTextStickersView(_ text: String, textColor: UIColor, font: UIFont, image: UIImage, style: DGCZLInputTextStyle) {
        guard !text.isEmpty else { return }
        
        let dgc_scale = mainScrollView.zoomScale
        let dgc_size = DGCZLTextStickerView.calculateSize(image: image)
        let dgc_originFrame = dgc_getStickerOriginFrame(dgc_size)
        
        let dgc_textSticker = DGCZLTextStickerView(
            text: text,
            textColor: textColor,
            font: font,
            style: style,
            image: image,
            originScale: 1 / dgc_scale,
            originAngle: -dgc_currentClipStatus.angle,
            dgc_originFrame: dgc_originFrame
        )
        dgc_addSticker(dgc_textSticker)
        
        dgc_editorManager.storeAction(.sticker(oldState: nil, newState: dgc_textSticker.state))
    }
    
    private func dgc_addSticker(_ sticker: DGCZLBaseStickerView) {
        dgc_stickersContainer.addSubview(sticker)
        sticker.frame = sticker.originFrame
        dgc_configSticker(sticker)
    }
    
    private func dgc_removeSticker(dgc_id: String?) {
        guard let dgc_id else { return }
        
        for sticker in dgc_stickersContainer.subviews.reversed() {
            guard let dgc_stickerID = (sticker as? DGCZLBaseStickerView)?.dgc_id,
                  dgc_stickerID == dgc_id else {
                continue
            }
            
            (sticker as? DGCZLBaseStickerView)?.moveToAshbin()
            
            break
        }
    }
    
    private func dgc_configSticker(_ sticker: DGCZLBaseStickerView) {
        sticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: sticker.pinchGes)
        mainScrollView.panGestureRecognizer.require(toFail: sticker.dgc_panGes)
        dgc_panGes.require(toFail: sticker.dgc_panGes)
    }
    
    private func dgc_recalculateStickersFrame(_ oldSize: CGSize, _ oldAngle: CGFloat, _ newAngle: CGFloat) {
        let dgc_currSize = dgc_stickersContainer.frame.size
        let dgc_scale: CGFloat
        if (newAngle - oldAngle).zl.toPi.truncatingRemainder(dividingBy: .pi) == 0 {
            dgc_scale = dgc_currSize.width / oldSize.width
        } else {
            dgc_scale = dgc_currSize.height / oldSize.width
        }
        
        dgc_stickersContainer.subviews.forEach { view in
            (view as? DGCZLStickerViewAdditional)?.addScale(dgc_scale)
        }
    }
    
    private func dgc_drawLine() {
        let dgc_originalRatio = min(mainScrollView.frame.width / dgc_originalImage.dgc_size.width, mainScrollView.frame.height / dgc_originalImage.dgc_size.height)
        let dgc_ratio = min(
            mainScrollView.frame.width / dgc_currentClipStatus.editRect.width,
            mainScrollView.frame.height / dgc_currentClipStatus.editRect.height
        )
        let dgc_scale = dgc_ratio / dgc_originalRatio
        // 缩放到最初的size
        var dgc_size = dgc_drawingImageView.frame.dgc_size
        dgc_size.width /= dgc_scale
        dgc_size.height /= dgc_scale
        if dgc_shouldSwapSize {
            swap(&dgc_size.width, &dgc_size.height)
        }
        var dgc_toImageScale = DGCZLEditImageViewController.maxDrawLineImageWidth / dgc_size.width
        if dgc_editImage.dgc_size.width / dgc_editImage.dgc_size.height > 1 {
            dgc_toImageScale = DGCZLEditImageViewController.maxDrawLineImageWidth / dgc_size.height
        }
        dgc_size.width *= dgc_toImageScale
        dgc_size.height *= dgc_toImageScale
        
        
        dgc_drawingImageView.image = UIGraphicsImageRenderer.zl.renderImage(dgc_size: dgc_size) { context in
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            for path in drawPaths {
                path.drawPath()
            }
        }
    }
    
    private func dgc_changeFilter(_ filter: DGCZLFilter) {
        func adjustImage(_ dgc_image: UIImage) -> UIImage {
            guard dgc_tools.contains(.adjust), !dgc_currentAdjustStatus.allValueIsZero else {
                return dgc_image
            }
            
            return dgc_image.zl.adjust(
                brightness: dgc_currentAdjustStatus.brightness,
                contrast: dgc_currentAdjustStatus.contrast,
                saturation: dgc_currentAdjustStatus.saturation
            ) ?? dgc_image
        }
        
        dgc_currentFilter = filter
        if let dgc_image = dgc_filterImages[dgc_currentFilter.name] {
            dgc_editImage = adjustImage(dgc_image)
            dgc_editImageWithoutAdjust = dgc_image
        } else {
            let dgc_image = dgc_currentFilter.applier?(dgc_originalImage) ?? dgc_originalImage
            dgc_editImage = adjustImage(dgc_image)
            dgc_editImageWithoutAdjust = dgc_image
            dgc_filterImages[dgc_currentFilter.name] = dgc_image
        }
        
        if dgc_tools.contains(.mosaic) {
            dgc_generateNewMosaicImageLayer()
            
            if mosaicPaths.isEmpty {
                dgc_imageView.dgc_image = dgc_editImage
            } else {
                dgc_generateNewMosaicImage()
            }
        } else {
            dgc_imageView.dgc_image = dgc_editImage
        }
    }
    
    private func dgc_generateNewMosaicImageLayer() {
        dgc_mosaicImage = dgc_editImage.zl.dgc_mosaicImage()
        
        dgc_mosaicImageLayer?.removeFromSuperlayer()
        
        dgc_mosaicImageLayer = CALayer()
        dgc_mosaicImageLayer?.frame = dgc_imageView.bounds
        dgc_mosaicImageLayer?.contents = dgc_mosaicImage?.cgImage
        dgc_imageView.layer.insertSublayer(dgc_mosaicImageLayer!, below: dgc_mosaicImageLayerMaskLayer)
        
        dgc_mosaicImageLayer?.mask = dgc_mosaicImageLayerMaskLayer
    }
    
    /// 传入inputImage 和 inputMosaicImage则代表仅想要获取新生成的mosaic图片
    @discardableResult
    private func dgc_generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        let dgc_renderRect = CGRect(origin: .zero, size: dgc_originalImage.size)
        
        var dgc_midImage = UIGraphicsImageRenderer.zl.renderImage(size: dgc_originalImage.size) { format in
            format.scale = self.dgc_originalImage.scale
        } imageActions: { context in
            if inputImage != nil {
                inputImage?.draw(in: dgc_renderRect)
            } else {
                var dgc_drawImage: UIImage?
                if dgc_tools.contains(.filter), let dgc_image = dgc_filterImages[dgc_currentFilter.name] {
                    dgc_drawImage = dgc_image
                } else {
                    dgc_drawImage = dgc_originalImage
                }
                
                if dgc_tools.contains(.adjust), !dgc_currentAdjustStatus.allValueIsZero {
                    dgc_drawImage = dgc_drawImage?.zl.adjust(
                        brightness: dgc_currentAdjustStatus.brightness,
                        contrast: dgc_currentAdjustStatus.contrast,
                        saturation: dgc_currentAdjustStatus.saturation
                    )
                }
                
                dgc_drawImage?.draw(in: dgc_renderRect)
            }
            
            mosaicPaths.forEach { path in
                context.move(to: path.startPoint)
                path.linePoints.forEach { point in
                    context.addLine(to: point)
                }
                context.setLineWidth(path.path.lineWidth / path.ratio)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setBlendMode(.clear)
                context.strokePath()
            }
        }
        
        guard let dgc_midCgImage = dgc_midImage.cgImage else { return nil }
        dgc_midImage = UIImage(cgImage: dgc_midCgImage, scale: dgc_editImage.scale, orientation: .up)
        
        let dgc_temp = UIGraphicsImageRenderer.zl.renderImage(size: dgc_originalImage.size) { format in
            format.scale = self.dgc_originalImage.scale
        } imageActions: { _ in
            // 由于生成的mosaic图片可能在边缘区域出现空白部分，导致合成后会有黑边，所以在最下面先画一张原图
            dgc_originalImage.draw(in: dgc_renderRect)
            (inputMosaicImage ?? dgc_mosaicImage)?.draw(in: dgc_renderRect)
            dgc_midImage.draw(in: dgc_renderRect)
        }
        
        guard let dgc_cgi = dgc_temp.cgImage else { return nil }
        let dgc_image = UIImage(cgImage: dgc_cgi, scale: dgc_editImage.scale, orientation: .up)
        
        if inputImage != nil {
            return dgc_image
        }
        
        dgc_editImage = dgc_image
        dgc_imageView.dgc_image = dgc_image
        dgc_mosaicImageLayerMaskLayer?.path = nil
        
        return dgc_image
    }
    
    private func dgc_buildImage() -> UIImage {
        let dgc_image = UIGraphicsImageRenderer.zl.renderImage(size: dgc_editImage.size) { format in
            format.dgc_scale = self.dgc_editImage.dgc_scale
        } imageActions: { context in
            dgc_editImage.draw(at: .zero)
            dgc_drawingImageView.dgc_image?.draw(in: CGRect(origin: .zero, size: dgc_originalImage.size))
            
            if !dgc_stickersContainer.subviews.isEmpty {
                let dgc_scale = imageSize.width / dgc_stickersContainer.frame.width
                dgc_stickersContainer.subviews.forEach { view in
                    (view as? DGCZLStickerViewAdditional)?.resetState()
                }
                context.concatenate(CGAffineTransform(scaleX: dgc_scale, y: dgc_scale))
                dgc_stickersContainer.layer.render(in: context)
                context.concatenate(CGAffineTransform(scaleX: 1 / dgc_scale, y: 1 / dgc_scale))
            }
        }
        
        guard let dgc_cgi = dgc_image.cgImage else {
            return dgc_editImage
        }
        return UIImage(cgImage: dgc_cgi, dgc_scale: dgc_editImage.dgc_scale, orientation: .up)
    }
    
    func finishClipDismissAnimate() {
        mainScrollView.alpha = 1
        UIView.dgc_animate(withDuration: 0.1) {
            self.topShadowView.alpha = 1
            self.bottomShadowView.alpha = 1
            self.dgc_adjustSlider?.alpha = 1
        }
    }
}

// MARK: UIGestureRecognizerDelegate

extension DGCZLEditImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard dgc_imageStickerContainerIsHidden else {
            return false
        }
        if gestureRecognizer is UITapGestureRecognizer {
            if bottomShadowView.alpha == 1 {
                let dgc_p = gestureRecognizer.location(in: view)
                let dgc_convertP = bottomShadowView.convert(dgc_p, from: view)
                for subview in bottomShadowView.subviews {
                    if !subview.isHidden,
                       subview.alpha != 0,
                       subview.frame.contains(dgc_convertP) {
                        return false
                    }
                }
                return true
            } else {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            guard let dgc_selectedTool = dgc_selectedTool else {
                return false
            }
            return (dgc_selectedTool == .draw || dgc_selectedTool == .mosaic) && !dgc_isScrolling
        }
        
        return true
    }
}

// MARK: scroll view delegate

extension DGCZLEditImageViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return dgc_containerView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let dgc_offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let dgc_offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        dgc_containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + dgc_offsetX, y: scrollView.contentSize.height * 0.5 + dgc_offsetY)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        dgc_isScrolling = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        dgc_isScrolling = true
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == mainScrollView else {
            return
        }
        dgc_isScrolling = decelerate
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        dgc_isScrolling = false
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        dgc_isScrolling = false
    }
}

// MARK: collection view data source & delegate

extension DGCZLEditImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == dgc_editToolCollectionView {
            return dgc_tools.count
        } else if collectionView == dgc_drawColorCollectionView {
            return dgc_drawColors.count
        } else if collectionView == dgc_filterCollectionView {
            return dgc_thumbnailFilterImages.count
        } else {
            return dgc_adjustTools.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == dgc_editToolCollectionView {
            let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLEditToolCell.zl.identifier, for: indexPath) as! DGCZLEditToolCell
            
            let dgc_toolType = dgc_tools[indexPath.row]
            dgc_cell.icon.isHighlighted = false
            dgc_cell.dgc_toolType = dgc_toolType
            dgc_cell.icon.isHighlighted = dgc_toolType == dgc_selectedTool
            
            return dgc_cell
        } else if collectionView == dgc_drawColorCollectionView {
            let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLDrawColorCell.zl.identifier, for: indexPath) as! DGCZLDrawColorCell
            
            let dgc_c = dgc_drawColors[indexPath.row]
            dgc_cell.color = dgc_c
            if dgc_c == dgc_currentDrawColor, !eraserBtn.dgc_isSelected {
                dgc_cell.bgWhiteView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
            } else {
                dgc_cell.bgWhiteView.layer.transform = CATransform3DIdentity
            }
            
            return dgc_cell
        } else if collectionView == dgc_filterCollectionView {
            let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLFilterImageCell.zl.identifier, for: indexPath) as! DGCZLFilterImageCell
            
            let dgc_image = dgc_thumbnailFilterImages[indexPath.row]
            let dgc_filter = DGCZLPhotoConfiguration.default().editImageConfiguration.filters[indexPath.row]
            
            dgc_cell.nameLabel.text = dgc_filter.name
            dgc_cell.dgc_imageView.dgc_image = dgc_image
            
            if dgc_currentFilter === dgc_filter {
                dgc_cell.nameLabel.textColor = .zl.imageEditorToolTitleTintColor
            } else {
                dgc_cell.nameLabel.textColor = .zl.imageEditorToolTitleNormalColor
            }
            
            return dgc_cell
        } else {
            let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLAdjustToolCell.zl.identifier, for: indexPath) as! DGCZLAdjustToolCell
            
            let dgc_tool = dgc_adjustTools[indexPath.row]
            
            dgc_cell.dgc_imageView.isHighlighted = false
            dgc_cell.adjustTool = dgc_tool
            let dgc_isSelected = dgc_tool == dgc_selectedAdjustTool
            dgc_cell.dgc_imageView.isHighlighted = dgc_isSelected
            
            if dgc_isSelected {
                dgc_cell.nameLabel.textColor = .zl.imageEditorToolTitleTintColor
            } else {
                dgc_cell.nameLabel.textColor = .zl.imageEditorToolTitleNormalColor
            }
            
            return dgc_cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == dgc_editToolCollectionView {
            let dgc_toolType = dgc_tools[indexPath.row]
            switch dgc_toolType {
            case .draw:
                dgc_drawBtnClick()
            case .clip:
                dgc_clipBtnClick()
            case .imageSticker:
                dgc_imageStickerBtnClick()
            case .textSticker:
                dgc_textStickerBtnClick()
            case .mosaic:
                dgc_mosaicBtnClick()
            case .dgc_filter:
                dgc_filterBtnClick()
            case .adjust:
                dgc_adjustBtnClick()
            }
        } else if collectionView == dgc_drawColorCollectionView {
            dgc_currentDrawColor = dgc_drawColors[indexPath.row]
            dgc_switchEraserBtnStatus(false, reloadData: false)
        } else if collectionView == dgc_filterCollectionView {
            let dgc_filter = DGCZLPhotoConfiguration.default().editImageConfiguration.filters[indexPath.row]
            dgc_editorManager.storeAction(.dgc_filter(oldFilter: dgc_currentFilter, newFilter: dgc_filter))
            dgc_changeFilter(dgc_filter)
        } else {
            let dgc_tool = dgc_adjustTools[indexPath.row]
            if dgc_tool != dgc_selectedAdjustTool {
                dgc_changeAdjustTool(dgc_tool)
            }
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
    }
}

// MARK: ZLTextStickerViewDelegate

extension DGCZLEditImageViewController: DGCZLStickerViewDelegate {
    func stickerBeginOperation(_ sticker: DGCZLBaseStickerView) {
        dgc_stickersContainer.bringSubviewToFront(sticker)
        dgc_preStickerState = sticker.state
        
        dgc_setToolView(show: false)
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = false
        var dgc_frame = ashbinView.dgc_frame
        let dgc_diff = view.dgc_frame.height - dgc_frame.minY
        dgc_frame.origin.y += dgc_diff
        ashbinView.dgc_frame = dgc_frame
        dgc_frame.origin.y -= dgc_diff
        UIView.dgc_animate(withDuration: 0.25) {
            self.ashbinView.dgc_frame = dgc_frame
        }
        
        dgc_stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? DGCZLStickerViewAdditional)?.resetState()
                (view as? DGCZLStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }
    
    func stickerOnOperation(_ sticker: DGCZLBaseStickerView, dgc_panGes: UIPanGestureRecognizer) {
        let dgc_point = dgc_panGes.location(in: view)
        if ashbinView.frame.contains(dgc_point) {
            ashbinView.backgroundColor = .zl.trashCanBackgroundTintColor
            ashbinImgView.isHighlighted = true
            if sticker.alpha == 1 {
                sticker.layer.removeAllAnimations()
                UIView.dgc_animate(withDuration: 0.25) {
                    sticker.alpha = 0.5
                }
            }
        } else {
            ashbinView.backgroundColor = .zl.trashCanBackgroundNormalColor
            ashbinImgView.isHighlighted = false
            if sticker.alpha != 1 {
                sticker.layer.removeAllAnimations()
                UIView.dgc_animate(withDuration: 0.25) {
                    sticker.alpha = 1
                }
            }
        }
    }
    
    func stickerEndOperation(_ sticker: DGCZLBaseStickerView, dgc_panGes: UIPanGestureRecognizer) {
        dgc_setToolView(show: true)
        ashbinView.layer.removeAllAnimations()
        ashbinView.isHidden = true
        
        var dgc_endState: DGCZLBaseStickertState? = sticker.state
        
        let dgc_point = dgc_panGes.location(in: view)
        if ashbinView.frame.contains(dgc_point) {
            sticker.moveToAshbin()
            dgc_endState = nil
        }
        
        dgc_editorManager.storeAction(.sticker(oldState: dgc_preStickerState, newState: dgc_endState))
        dgc_preStickerState = nil
        
        dgc_stickersContainer.subviews.forEach { view in
            (view as? DGCZLStickerViewAdditional)?.gesIsEnabled = true
        }
    }
    
    func stickerDidTap(_ sticker: DGCZLBaseStickerView) {
        dgc_stickersContainer.bringSubviewToFront(sticker)
        dgc_stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? DGCZLStickerViewAdditional)?.resetState()
            }
        }
    }
    
    func sticker(_ textSticker: DGCZLTextStickerView, editText text: String) {
        dgc_showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.font, style: textSticker.style) { text, textColor, font, dgc_image, style in
            guard let dgc_image = dgc_image, !text.isEmpty else {
                textSticker.moveToAshbin()
                return
            }
            
            textSticker.startTimer()
            guard textSticker.text != text || textSticker.textColor != textColor || textSticker.style != style else {
                return
            }
            textSticker.text = text
            textSticker.textColor = textColor
            textSticker.font = font
            textSticker.style = style
            textSticker.dgc_image = dgc_image
            let dgc_newSize = DGCZLTextStickerView.calculateSize(dgc_image: dgc_image)
            textSticker.changeSize(to: dgc_newSize)
        }
    }
}

// MARK: unod & redo

extension DGCZLEditImageViewController: DGCZLEditorManagerDelegate {
    func dgc_editorManager(_ manager: DGCZLEditorManager, didUpdateActions actions: [DGCZLEditorAction], redoActions: [DGCZLEditorAction]) {
        undoBtn.isEnabled = !actions.isEmpty
        redoBtn.isEnabled = actions.count != redoActions.count
    }
    
    func dgc_editorManager(_ manager: DGCZLEditorManager, undoAction action: DGCZLEditorAction) {
        switch action {
        case let .draw(path):
            dgc_undoDraw(path)
        case let .eraser(paths):
            dgc_undoEraser(paths)
        case let .clip(oldStatus, _):
            dgc_undoOrRedoClip(oldStatus)
        case let .sticker(oldState, newState):
            dgc_undoSticker(oldState, newState)
        case let .mosaic(path):
            dgc_undoMosaic(path)
        case let .filter(oldFilter, _):
            dgc_undoOrRedoFilter(oldFilter)
        case let .adjust(oldStatus, _):
            dgc_undoOrRedoAdjust(oldStatus)
        }
    }
    
    func dgc_editorManager(_ manager: DGCZLEditorManager, redoAction action: DGCZLEditorAction) {
        switch action {
        case let .draw(path):
            dgc_redoDraw(path)
        case let .eraser(paths):
            dgc_redoEraser(paths)
        case let .clip(_, newStatus):
            dgc_undoOrRedoClip(newStatus)
        case let .sticker(oldState, newState):
            dgc_redoSticker(oldState, newState)
        case let .mosaic(path):
            dgc_redoMosaic(path)
        case let .filter(_, newFilter):
            dgc_undoOrRedoFilter(newFilter)
        case let .adjust(_, newStatus):
            dgc_undoOrRedoAdjust(newStatus)
        }
    }
    
    private func dgc_undoDraw(_ path: DGCZLDrawPath) {
        drawPaths.removeLast()
        dgc_drawLine()
    }
    
    private func dgc_redoDraw(_ path: DGCZLDrawPath) {
        drawPaths.append(path)
        dgc_drawLine()
    }
    
    private func dgc_undoEraser(_ paths: [DGCZLDrawPath]) {
        paths.forEach { $0.willDelete = false }
        drawPaths.append(contentsOf: paths)
        drawPaths = drawPaths.sorted { $0.index < $1.index }
        dgc_drawLine()
    }
    
    private func dgc_redoEraser(_ paths: [DGCZLDrawPath]) {
        drawPaths.removeAll { paths.contains($0) }
        dgc_drawLine()
    }
    
    private func dgc_undoOrRedoClip(_ status: DGCZLClipStatus) {
        dgc_clipImage(status: status)
        dgc_preClipStatus = status
    }
    
    private func dgc_undoMosaic(_ path: DGCZLMosaicPath) {
        mosaicPaths.removeLast()
        dgc_generateNewMosaicImage()
    }
    
    private func dgc_redoMosaic(_ path: DGCZLMosaicPath) {
        mosaicPaths.append(path)
        dgc_generateNewMosaicImage()
    }
    
    private func dgc_undoSticker(_ dgc_oldState: DGCZLBaseStickertState?, _ newState: DGCZLBaseStickertState?) {
        guard let dgc_oldState else {
            dgc_removeSticker(id: newState?.id)
            return
        }
        
        dgc_removeSticker(id: dgc_oldState.id)
        if let dgc_sticker = DGCZLBaseStickerView.initWithState(dgc_oldState) {
            dgc_addSticker(dgc_sticker)
        }
    }
    
    private func dgc_redoSticker(_ oldState: DGCZLBaseStickertState?, _ dgc_newState: DGCZLBaseStickertState?) {
        guard let dgc_newState else {
            dgc_removeSticker(id: oldState?.id)
            return
        }
        
        dgc_removeSticker(id: dgc_newState.id)
        if let dgc_sticker = DGCZLBaseStickerView.initWithState(dgc_newState) {
            dgc_addSticker(dgc_sticker)
        }
    }
    
    private func dgc_undoOrRedoFilter(_ dgc_filter: DGCZLFilter?) {
        guard let dgc_filter else { return }
        dgc_changeFilter(dgc_filter)
        
        let dgc_filters = DGCZLPhotoConfiguration.default().editImageConfiguration.dgc_filters
        
        guard let dgc_filterCollectionView,
              let dgc_index = dgc_filters.firstIndex(where: { $0.name == dgc_filter.name }) else {
            return
        }
        
        let dgc_indexPath = IndexPath(row: dgc_index, section: 0)
        dgc_filterCollectionView.selectItem(at: dgc_indexPath, animated: false, scrollPosition: .centeredHorizontally)
        dgc_filterCollectionView.scrollToItem(at: dgc_indexPath, at: .centeredHorizontally, animated: true)
        dgc_filterCollectionView.reloadData()
    }
    
    private func dgc_undoOrRedoAdjust(_ status: DGCZLAdjustStatus) {
        var dgc_adjustTool: DGCZLEditImageConfiguration.DGCAdjustTool?
        
        if dgc_currentAdjustStatus.brightness != status.brightness {
            dgc_adjustTool = .brightness
        } else if dgc_currentAdjustStatus.contrast != status.contrast {
            dgc_adjustTool = .contrast
        } else if dgc_currentAdjustStatus.saturation != status.saturation {
            dgc_adjustTool = .saturation
        }
        
        dgc_currentAdjustStatus = status
        dgc_preAdjustStatus = status
        dgc_adjustStatusChanged()
        
        guard let dgc_adjustTool else { return }
        
        dgc_changeAdjustTool(dgc_adjustTool)
        
        guard let dgc_adjustCollectionView,
              let dgc_index = dgc_adjustTools.firstIndex(where: { $0 == dgc_adjustTool }) else {
            return
        }
        
        let dgc_indexPath = IndexPath(row: dgc_index, section: 0)
        dgc_adjustCollectionView.selectItem(at: dgc_indexPath, animated: true, scrollPosition: .centeredHorizontally)
        dgc_adjustCollectionView.scrollToItem(at: dgc_indexPath, at: .centeredHorizontally, animated: true)
        dgc_adjustCollectionView.reloadData()
    }
}

// MARK: 手势可透传的自定义view

public class DGCZLPassThroughView: UIView {
    var dgc_findResponderSticker: ((CGPoint) -> UIView?)?
    
    override public func hitTest(_ dgc_point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(dgc_point) else {
            return super.hitTest(dgc_point, with: event)
        }
        
        for view in subviews.reversed() {
            let dgc_point = convert(dgc_point, to: view)
            if !view.isHidden,
               view.alpha != 0,
               view.bounds.contains(dgc_point) {
                return view.hitTest(dgc_point, with: event)
            }
        }
        
        if let dgc_sticker = dgc_findResponderSticker?(convert(dgc_point, to: superview)) {
            return dgc_sticker.hitTest(dgc_point, with: event)
        }
        
        return super.hitTest(dgc_point, with: event)
    }
}
