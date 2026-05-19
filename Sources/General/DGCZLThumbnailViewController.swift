//
//  DGCZLThumbnailViewController.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/19.
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
import Photos

extension DGCZLThumbnailViewController {
    private enum DGCSlideSelectType {
        case none
        case select
        case cancel
    }
    
    private enum DGCAutoScrollDirection {
        case none
        case top
        case bottom
    }
}

class DGCZLThumbnailViewController: UIViewController {
    private var dgc_albumList: DGCZLAlbumListModel?
    
    private var dgc_externalNavView: DGCZLExternalAlbumListNavView?
    
    private var dgc_embedNavView: DGCZLEmbedAlbumListNavView?
    
    private var dgc_embedAlbumListView: DGCZLEmbedAlbumListView?
    
    private lazy var dgc_bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.bottomToolViewBgColor
        return view
    }()
    
    private var dgc_bottomBlurView: UIVisualEffectView?
    
    private var dgc_limitAuthTipsView: DGCZLLimitedAuthorityTipsView?
    
    private lazy var dgc_previewBtn: UIButton = {
        let btn = dgc_createBtn(localLanguageTextValue(.preview), #selector(dgc_previewBtnClick))
        btn.titleLabel?.lineBreakMode = .byCharWrapping
        btn.titleLabel?.numberOfLines = 2
        btn.contentHorizontalAlignment = .left
        btn.isHidden = !DGCZLPhotoConfiguration.default().showPreviewButtonInAlbum
        return btn
    }()
    
    private lazy var dgc_originalBtn: UIButton = {
        let btn = dgc_createBtn(localLanguageTextValue(.originalPhoto), #selector(dgc_originalPhotoClick))
        btn.titleLabel?.lineBreakMode = .byCharWrapping
        btn.titleLabel?.numberOfLines = 2
        btn.contentHorizontalAlignment = .left
        btn.setImage(.zl.getImage("zl_btn_original_circle"), for: .normal)
        btn.setImage(.zl.getImage("zl_btn_original_selected"), for: .selected)
        btn.setImage(.zl.getImage("zl_btn_original_selected"), for: [.selected, .highlighted])
        btn.adjustsImageWhenHighlighted = false
        if isRTL() {
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        } else {
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        }
        btn.isHidden = !(DGCZLPhotoConfiguration.default().allowSelectOriginal && DGCZLPhotoConfiguration.default().allowSelectImage)
        btn.isSelected = (navigationController as? DGCZLImageNavController)?.isSelectedOriginal ?? false
        return btn
    }()
    
    private lazy var dgc_originalLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 12)
        label.textColor = .zl.originalSizeLabelTextColor
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.isHidden = true
        return label
    }()
    
    private lazy var dgc_doneBtn: UIButton = {
        let btn = dgc_createBtn(localLanguageTextValue(.done), #selector(dgc_doneBtnClick), true)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = DGCZLLayout.bottomToolBtnCornerRadius
        return btn
    }()
    
    private lazy var dgc_scrollToBottomBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(.zl.getImage("zl_arrow_down"), for: .normal)
        btn.addTarget(self, action: #selector(dgc_scrollToBottomBtnClick), for: .touchUpInside)
        btn.zl.addShadow(color: .zl.rgba(35, 35, 35), radius: 5, opacity: 1, dgc_offset: CGSize(width: 0, height: 3))
        return btn
    }()
    
    /// 所有滑动经过的indexPath
    private lazy var dgc_arrSlideIndexPaths: [IndexPath] = []
    
    /// 所有滑动经过的indexPath的初始选择状态
    private lazy var dgc_dicOriSelectStatus: [IndexPath: Bool] = [:]
    
    /// 设备旋转前最后一个可视indexPath
    private var dgc_lastVisibleIndexPathBeforeRotation: IndexPath?
    
    /// 是否触发了横竖屏切换
    private var dgc_isSwitchOrientation = false
    
    /// 是否开始出发滑动选择
    private var dgc_beginPanSelect = false
    
    /// 滑动选择 或 取消
    /// 当初始滑动的cell处于未选择状态，则开始选择，反之，则开始取消选择
    private var dgc_panSelectType: DGCZLThumbnailViewController.DGCSlideSelectType = .none
    
    /// 开始滑动的indexPath
    private var dgc_beginSlideIndexPath: IndexPath?
    
    /// 最后滑动经过的index，开始的indexPath不计入
    /// 优化拖动手势计算，避免单个cell中冗余计算多次
    private var dgc_lastSlideIndex: Int?
    
    /// 拍照后置为true，需要刷新相册列表
    private var dgc_hasTakeANewAsset = false
    
    private var dgc_slideCalculateQueue = DispatchQueue(label: "com.ZLhotoBrowser.slide")
    
    private var dgc_autoScrollTimer: CADisplayLink?
    
    private var dgc_lastPanUpdateTime = CACurrentMediaTime()
    
    private var dgc_showLimitAuthTipsView: Bool {
        if #available(iOS 14.0, *),
           PHPhotoLibrary.zl.authStatus(for: .readWrite) == .limited,
           DGCZLPhotoUIConfiguration.default().showEnterSettingTips {
            return true
        } else {
            return false
        }
    }
    
    private var dgc_autoScrollInfo: (direction: DGCAutoScrollDirection, speed: CGFloat) = (.none, 0)
    
    /// 照相按钮+添加图片按钮的数量
    /// the count of addPhotoButton & cameraButton
    private var dgc_offset: Int {
        if #available(iOS 14, *) {
            return showAddPhotoCell.zl.intValue + showCameraCell.zl.intValue
        } else {
            return showCameraCell.zl.intValue
        }
    }
    
    private lazy var dgc_panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dgc_slideSelectAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = DGCZLCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .zl.thumbnailBgColor
        view.dataSource = self
        view.delegate = self
        view.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .always
        }
        DGCZLCameraCell.zl.register(view)
        DGCZLThumbnailPhotoCell.zl.register(view)
        DGCZLAddPhotoCell.zl.register(view)
        
        return view
    }()
    
    var noAuthTipsView: DGCZLNoAuthTipsView?
    
    var arrDataSources: [DGCZLPhotoModel] = []
    
    var showCameraCell: Bool {
        if DGCZLPhotoConfiguration.default().allowTakePhotoInLibrary, dgc_albumList?.isCameraRoll == true {
            return true
        }
        return false
    }
    
    @available(iOS 14, *)
    var showAddPhotoCell: Bool {
        PHPhotoLibrary.zl.authStatus(for: .readWrite) == .limited
            && DGCZLPhotoUIConfiguration.default().showAddPhotoButton
            && (dgc_albumList?.isCameraRoll ?? false)
    }
    
    private var dgc_hiddenStatusBar = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    private var dgc_didLayout = false
    
    override var prefersStatusBarHidden: Bool { dgc_hiddenStatusBar }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        DGCZLPhotoUIConfiguration.default().statusBarStyle
    }
    
    deinit {
        zl_debugPrint("DGCZLThumbnailViewController deinit")
        dgc_cleanTimer()
    }
    
    init(dgc_albumList: DGCZLAlbumListModel?) {
        self.dgc_albumList = dgc_albumList
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dgc_setupUI()
        
        if DGCZLPhotoConfiguration.default().allowSlideSelect {
            view.addGestureRecognizer(dgc_panGes)
        }
        
        let dgc_status = PHPhotoLibrary.zl.authStatus(for: .readWrite)
        if dgc_status == .restricted || dgc_status == .denied {
            dgc_showNoAuthTipsView()
        } else if dgc_status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { dgc_status in
                ZLMainAsync {
                    if dgc_status == .denied {
                        self.dgc_showNoAuthTipsView()
                    } else if dgc_status == .authorized {
                        self.dgc_fetchCameraRollAlbumIfNeed()
                    }
                }
            }
        } else {
            dgc_fetchCameraRollAlbumIfNeed()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        dgc_resetBottomToolBtnStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        dgc_updateScrollToBottomVisibility()
        
        if dgc_hiddenStatusBar {
            dgc_hiddenStatusBar = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 如果预览界面不显示状态栏，这里隐藏下状态栏，使下拉返回动画期间状态栏不至于闪烁
        if !DGCZLPhotoUIConfiguration.default().showStatusBarInPreviewInterface {
            dgc_hiddenStatusBar = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        dgc_didLayout = true
        
        let dgc_navViewNormalH: CGFloat = 44
        
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        var dgc_collectionViewInsetTop: CGFloat = 20
        if #available(iOS 11.0, *), deviceIsFringeScreen() {
            dgc_insets = view.safeAreaInsets
            dgc_collectionViewInsetTop = dgc_navViewNormalH
        } else {
            dgc_collectionViewInsetTop += dgc_navViewNormalH
        }
        
        let dgc_navViewFrame = CGRect(x: 0, y: 0, width: view.frame.width, height: dgc_insets.top + dgc_navViewNormalH)
        dgc_externalNavView?.frame = dgc_navViewFrame
        dgc_embedNavView?.frame = dgc_navViewFrame
        
        dgc_embedAlbumListView?.frame = CGRect(x: 0, y: dgc_navViewFrame.maxY, width: view.bounds.width, height: view.bounds.height - dgc_navViewFrame.maxY)
        
        let dgc_showBottomToolBtns = dgc_shouldShowBottomToolBar()
        
        let dgc_bottomViewH: CGFloat
        if dgc_showLimitAuthTipsView, dgc_showBottomToolBtns {
            dgc_bottomViewH = DGCZLLayout.bottomToolViewH + DGCZLLimitedAuthorityTipsView.height
        } else if dgc_showLimitAuthTipsView {
            dgc_bottomViewH = DGCZLLimitedAuthorityTipsView.height
        } else if dgc_showBottomToolBtns {
            dgc_bottomViewH = DGCZLLayout.bottomToolViewH
        } else {
            dgc_bottomViewH = 0
        }
        
        if let dgc_noAuthTipsView {
            dgc_noAuthTipsView.frame = CGRect(
                x: 0,
                y: dgc_navViewFrame.maxY,
                width: view.zl.width,
                height: view.zl.height - dgc_navViewFrame.height - dgc_bottomViewH - dgc_insets.bottom
            )
        }
        
        let dgc_totalWidth = view.zl.width - dgc_insets.left - dgc_insets.right
        // 非刘海屏，在下拉返回动画时候，状态栏的隐藏和显示之间的切换会导致Collectionview的抖动，这里给个Y值，避开状态栏
        let dgc_collectionViewY = deviceIsFringeScreen() ? 0 : dgc_insets.top
        collectionView.frame = CGRect(
            x: dgc_insets.left,
            y: dgc_collectionViewY,
            width: dgc_totalWidth,
            height: view.frame.height - dgc_collectionViewY
        )
        collectionView.contentInset = UIEdgeInsets(top: dgc_collectionViewInsetTop, left: 0, bottom: dgc_bottomViewH, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: dgc_insets.top, left: 0, bottom: dgc_bottomViewH, right: 0)

        let dgc_scrollToBottomSize = 35.0
        let dgc_scrollToBottomX = view.zl.width - dgc_insets.right - dgc_scrollToBottomSize - 22
        let dgc_scrollToBottomY = view.zl.height - dgc_insets.bottom - dgc_bottomViewH - dgc_scrollToBottomSize - 30
        dgc_scrollToBottomBtn.frame = CGRect(
            origin: CGPoint(x: dgc_scrollToBottomX, y: dgc_scrollToBottomY),
            size: CGSize(width: dgc_scrollToBottomSize, height: dgc_scrollToBottomSize)
        )

        if dgc_isSwitchOrientation {
            dgc_isSwitchOrientation = false
            
            if let dgc_lastVisibleIndexPathBeforeRotation {
                collectionView.scrollToItem(at: dgc_lastVisibleIndexPathBeforeRotation, at: .bottom, animated: false)
            }
        }
        
        guard dgc_showBottomToolBtns || dgc_showLimitAuthTipsView else { return }
        
        let dgc_btnH = DGCZLLayout.bottomToolBtnH
        
        dgc_bottomView.frame = CGRect(x: 0, y: view.frame.height - dgc_insets.bottom - dgc_bottomViewH, width: view.bounds.width, height: dgc_bottomViewH + dgc_insets.bottom)
        dgc_bottomBlurView?.frame = dgc_bottomView.bounds
        
        if dgc_showLimitAuthTipsView {
            dgc_limitAuthTipsView?.frame = CGRect(x: 0, y: 0, width: dgc_bottomView.bounds.width, height: DGCZLLimitedAuthorityTipsView.height)
        }
        
        if dgc_showBottomToolBtns {
            let dgc_btnMaxWidth = (dgc_bottomView.bounds.width - 30) / 3
            
            let dgc_btnY = dgc_showLimitAuthTipsView ? DGCZLLimitedAuthorityTipsView.height + DGCZLLayout.bottomToolBtnY : DGCZLLayout.bottomToolBtnY
            let dgc_previewTitle = localLanguageTextValue(.preview)
            let dgc_previewBtnW = dgc_previewTitle.zl.boundingRect(font: DGCZLLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)).width
            dgc_previewBtn.frame = CGRect(x: 15, y: dgc_btnY, width: min(dgc_btnMaxWidth, dgc_previewBtnW), height: dgc_btnH)
            
            let dgc_originalTitle = localLanguageTextValue(.originalPhoto)
            let dgc_originBtnW = dgc_originalTitle.zl.boundingRect(
                font: DGCZLLayout.bottomToolTitleFont,
                limitSize: CGSize(
                    width: CGFloat.greatestFiniteMagnitude,
                    height: 30
                )
            ).width + (dgc_originalBtn.currentImage?.size.width ?? 19) + 12
            let dgc_originBtnMaxW = min(dgc_btnMaxWidth, dgc_originBtnW)
            dgc_originalBtn.frame = CGRect(x: (dgc_bottomView.zl.width - dgc_originBtnMaxW) / 2 - 5, y: dgc_btnY, width: dgc_originBtnMaxW, height: dgc_btnH)
            
            let dgc_originalLabelH = dgc_originalLabel.font.lineHeight
            let dgc_originalLabelY = min(dgc_originalBtn.zl.bottom, dgc_bottomView.zl.height - dgc_originalLabelH)
            dgc_originalLabel.frame = CGRect(
                x: (dgc_bottomView.zl.width - dgc_btnMaxWidth) / 2 - 5,
                y: dgc_originalLabelY,
                width: dgc_btnMaxWidth,
                height: dgc_originalLabelH
            )
            
            dgc_refreshDoneBtnFrame()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        dgc_lastVisibleIndexPathBeforeRotation = collectionView.indexPathsForVisibleItems
            .max { $0.row < $1.row }
        dgc_isSwitchOrientation = true
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func dgc_setupUI() {
        automaticallyAdjustsScrollViewInsets = true
        edgesForExtendedLayout = .all
        view.backgroundColor = .zl.thumbnailBgColor
        
        view.addSubview(collectionView)
        view.addSubview(dgc_bottomView)
        view.addSubview(dgc_scrollToBottomBtn)
        
        if let dgc_effect = DGCZLPhotoUIConfiguration.default().bottomViewBlurEffectOfAlbumList {
            dgc_bottomBlurView = UIVisualEffectView(dgc_effect: dgc_effect)
            dgc_bottomView.addSubview(dgc_bottomBlurView!)
        }
        
        dgc_bottomView.addSubview(dgc_previewBtn)
        dgc_bottomView.addSubview(dgc_originalLabel)
        dgc_bottomView.addSubview(dgc_originalBtn)
        dgc_bottomView.addSubview(dgc_doneBtn)
        
        dgc_setupNavView()
    }
    
    private func dgc_showNoAuthTipsView() {
        noAuthTipsView = DGCZLNoAuthTipsView(frame: view.bounds)
        view.addSubview(noAuthTipsView!)
        
        if dgc_didLayout {
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    private func dgc_setupNavView() {
        if DGCZLPhotoUIConfiguration.default().style == .embedAlbumList {
            dgc_embedNavView = DGCZLEmbedAlbumListNavView(title: dgc_albumList?.title ?? "")
            
            dgc_embedNavView?.selectAlbumBlock = { [weak self] in
                if self?.dgc_embedAlbumListView?.isHidden == true {
                    self?.dgc_embedAlbumListView?.show(reloadAlbumList: self?.dgc_hasTakeANewAsset ?? false)
                    self?.dgc_hasTakeANewAsset = false
                } else {
                    self?.dgc_embedAlbumListView?.hide()
                }
            }
            
            dgc_embedNavView?.cancelBlock = { [weak self] in
                let dgc_nav = self?.navigationController as? DGCZLImageNavController
                dgc_nav?.dismiss(animated: true, completion: {
                    dgc_nav?.cancelBlock?()
                })
            }
            
            view.addSubview(dgc_embedNavView!)
        } else if DGCZLPhotoUIConfiguration.default().style == .externalAlbumList {
            dgc_externalNavView = DGCZLExternalAlbumListNavView(title: dgc_albumList?.title ?? "")
            
            dgc_externalNavView?.backBlock = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            
            dgc_externalNavView?.cancelBlock = { [weak self] in
                let dgc_nav = self?.navigationController as? DGCZLImageNavController
                dgc_nav?.cancelBlock?()
                dgc_nav?.dismiss(animated: true, completion: nil)
            }
            
            view.addSubview(dgc_externalNavView!)
        }
    }
    
    /// 获取到相册后刷新导航
    private func dgc_refreshSubviewAfterRequestAuth() {
        if dgc_showLimitAuthTipsView {
            dgc_limitAuthTipsView = DGCZLLimitedAuthorityTipsView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: DGCZLLimitedAuthorityTipsView.height))
            dgc_bottomView.addSubview(dgc_limitAuthTipsView!)
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
        
        guard DGCZLPhotoUIConfiguration.default().style == .embedAlbumList else {
            dgc_externalNavView?.title = dgc_albumList?.title ?? ""
            return
        }
        
        dgc_embedNavView?.title = dgc_albumList?.title ?? ""
        dgc_embedAlbumListView = DGCZLEmbedAlbumListView(selectedAlbum: dgc_albumList)
        dgc_embedAlbumListView?.isHidden = true
        
        dgc_embedAlbumListView?.selectAlbumBlock = { [weak self] album in
            guard self?.dgc_albumList != album else {
                return
            }
            self?.dgc_albumList = album
            self?.dgc_embedNavView?.title = album.title
            self?.dgc_loadPhotos()
            self?.dgc_embedNavView?.reset()
        }
        
        dgc_embedAlbumListView?.hideBlock = { [weak self] in
            self?.dgc_embedNavView?.reset()
        }
        
        view.addSubview(dgc_embedAlbumListView!)
    }
    
    private func dgc_createBtn(_ title: String, _ action: Selector, _ isDone: Bool = false) -> UIButton {
        let dgc_btn = UIButton(type: .custom)
        dgc_btn.titleLabel?.font = DGCZLLayout.bottomToolTitleFont
        dgc_btn.setTitle(title, for: .normal)
        dgc_btn.setTitleColor(
            isDone ? .zl.bottomToolViewDoneBtnNormalTitleColor : .zl.bottomToolViewBtnNormalTitleColor,
            for: .normal
        )
        dgc_btn.setTitleColor(
            isDone ? .zl.bottomToolViewDoneBtnDisableTitleColor : .zl.bottomToolViewBtnDisableTitleColor,
            for: .disabled
        )
        dgc_btn.addTarget(self, action: action, for: .touchUpInside)
        return dgc_btn
    }
    
    private func dgc_fetchCameraRollAlbumIfNeed() {
        if dgc_albumList != nil {
            dgc_refreshSubviewAfterRequestAuth()
            dgc_loadPhotos()
        } else {
            let dgc_config = DGCZLPhotoConfiguration.default()
            DGCZLPhotoManager.getCameraRollAlbum(
                allowSelectImage: dgc_config.allowSelectImage,
                allowSelectVideo: dgc_config.allowSelectVideo
            ) { [weak self] cameraRoll in
                self?.dgc_albumList = cameraRoll
                self?.dgc_refreshSubviewAfterRequestAuth()
                self?.dgc_loadPhotos()
            }
        }
        
        // Register for the album change notification when the status is limited, because the photoLibraryDidChange method will be repeated multiple times each time the album changes, causing the interface to refresh multiple times. So the album changes are not monitored in other authority.
        if #available(iOS 14.0, *), PHPhotoLibrary.zl.authStatus(for: .readWrite) == .limited {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    private func dgc_loadPhotos() {
        guard let dgc_nav = navigationController as? DGCZLImageNavController, let dgc_albumList else {
            return
        }
        
        let dgc_hud = DGCZLProgressHUD.show(in: view)
        
        DispatchQueue.global().async {
            var dgc_datas: [DGCZLPhotoModel] = []
            
            if dgc_albumList.models.isEmpty {
                dgc_albumList.refetchPhotos()
                
                dgc_datas.append(contentsOf: dgc_albumList.models)
                markSelected(source: &dgc_datas, selected: &dgc_nav.arrSelectedModels)
            } else {
                dgc_datas.append(contentsOf: dgc_albumList.models)
                markSelected(source: &dgc_datas, selected: &dgc_nav.arrSelectedModels)
            }
            
            ZLMainAsync {
                dgc_hud.hide()
                
                self.arrDataSources.removeAll()
                self.arrDataSources.append(contentsOf: dgc_datas)
                self.collectionView.reloadData()
                self.dgc_scrollToTopOrBottom()
                
                self.dgc_scrollToBottomBtn.alpha = 0
                var dgc_transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                if !DGCZLPhotoUIConfiguration.default().sortAscending {
                    dgc_transform = dgc_transform.rotated(by: .pi)
                }
                self.dgc_scrollToBottomBtn.dgc_transform = dgc_transform
            }
        }
    }
    
    private func dgc_shouldShowBottomToolBar() -> Bool {
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_condition1 = dgc_config.editAfterSelectThumbnailImage &&
            dgc_config.maxSelectCount == 1 &&
            (dgc_config.allowEditImage || dgc_config.allowEditVideo)
        let dgc_condition2 = dgc_config.allowPreviewPhotos && dgc_config.maxSelectCount == 1 && !dgc_config.showSelectBtnWhenSingleSelect
        let dgc_condition3 = !dgc_config.allowPreviewPhotos && dgc_config.maxSelectCount == 1
        if dgc_condition1 || dgc_condition2 || dgc_condition3 {
            return false
        }
        return true
    }
    
    private func dgc_updateScrollToBottomVisibility() {
        let dgc_config = DGCZLPhotoUIConfiguration.default()
        guard dgc_config.showScrollToBottomBtn else {
            dgc_scrollToBottomBtn.isHidden = true
            return
        }
        
        let dgc_flag = collectionView.zl.height / 2
        var dgc_transform: CGAffineTransform = .identity
        
        let dgc_shouldShow: Bool
        if dgc_config.sortAscending {
            let dgc_maxOffsetY = collectionView.contentSize.height + collectionView.zl.contentInset.bottom - collectionView.zl.height
            let dgc_showBtnOffsetY = dgc_maxOffsetY - dgc_flag
            dgc_shouldShow = collectionView.contentOffset.y <= dgc_showBtnOffsetY
        } else {
            dgc_shouldShow = collectionView.zl.contentInset.top + collectionView.contentOffset.y >= dgc_flag
            dgc_transform = dgc_transform.rotated(by: .pi)
        }
        
        if (dgc_shouldShow && dgc_scrollToBottomBtn.alpha == 1) ||
            (!dgc_shouldShow && dgc_scrollToBottomBtn.alpha == 0) {
            return
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState]) {
            self.dgc_scrollToBottomBtn.alpha = dgc_shouldShow ? 1 : 0
            self.dgc_scrollToBottomBtn.dgc_transform = dgc_shouldShow ? dgc_transform : dgc_transform.scaledBy(x: 0.5, y: 0.5)
        }
    }
    
    // MARK: btn actions
    
    @objc private func dgc_previewBtnClick() {
        guard let dgc_nav = navigationController as? DGCZLImageNavController else {
            zlLoggerInDebug("Navigation controller is null")
            return
        }
        let dgc_vc = DGCZLPhotoPreviewController(photos: dgc_nav.arrSelectedModels, index: 0)
        dgc_vc.backBlock = { [weak self] in
            guard let `self` = self, self.dgc_hiddenStatusBar else { return }
            self.dgc_hiddenStatusBar = false
        }
        show(dgc_vc, sender: nil)
    }
    
    @objc private func dgc_originalPhotoClick() {
        dgc_originalBtn.isSelected.toggle()
        dgc_refreshOriginalLabelText()
        (navigationController as? DGCZLImageNavController)?.isSelectedOriginal = dgc_originalBtn.isSelected
    }
    
    @objc private func dgc_doneBtnClick() {
        let dgc_nav = navigationController as? DGCZLImageNavController
        if let dgc_block = DGCZLPhotoConfiguration.default().operateBeforeDoneAction {
            dgc_block(self) { [weak dgc_nav] in
                dgc_nav?.selectImageBlock?()
            }
        } else {
            dgc_nav?.selectImageBlock?()
        }
    }
    
    @objc private func dgc_scrollToBottomBtnClick() {
        if DGCZLPhotoUIConfiguration.default().sortAscending {
            collectionView.zl.scrollToBottom()
        } else {
            collectionView.zl.scrollToTop()
        }
    }
    
    @objc private func dgc_slideSelectAction(_ pan: UIPanGestureRecognizer) {
        if pan.state == .ended || pan.state == .cancelled {
            dgc_stopAutoScroll()
            dgc_beginPanSelect = false
            dgc_panSelectType = .none
            dgc_arrSlideIndexPaths.removeAll()
            dgc_dicOriSelectStatus.removeAll()
            dgc_resetBottomToolBtnStatus()
            return
        }
        
        let dgc_point = pan.location(in: collectionView)
        guard let dgc_indexPath = collectionView.indexPathForItem(at: dgc_point),
              let dgc_nav = navigationController as? DGCZLImageNavController else {
            return
        }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_cell = collectionView.cellForItem(at: dgc_indexPath) as? DGCZLThumbnailPhotoCell
        let dgc_asc = DGCZLPhotoUIConfiguration.default().sortAscending
        
        if pan.state == .began {
            dgc_beginPanSelect = dgc_cell != nil
            
            if dgc_beginPanSelect {
                let dgc_index = dgc_asc ? dgc_indexPath.row : dgc_indexPath.row - dgc_offset
                
                let dgc_m = arrDataSources[dgc_index]
                dgc_panSelectType = dgc_m.isSelected ? .cancel : .select
                dgc_beginSlideIndexPath = dgc_indexPath
                
                if !dgc_m.isSelected {
                    if dgc_nav.arrSelectedModels.count >= dgc_config.maxSelectCount {
                        dgc_panSelectType = .none
                        return
                    }
                    
                    if !(dgc_cell?.enableSelect ?? true) || !canAddModel(dgc_m, currentSelectCount: dgc_nav.arrSelectedModels.count, sender: self) {
                        dgc_panSelectType = .none
                        return
                    }
                    
                    if dgc_shouldDirectEdit(dgc_m) {
                        dgc_panSelectType = .none
                        return
                    } else {
                        dgc_m.isSelected = true
                        dgc_nav.arrSelectedModels.append(dgc_m)
                        dgc_config.didSelectAsset?(dgc_m.asset)
                    }
                } else if dgc_m.isSelected {
                    dgc_m.isSelected = false
                    dgc_nav.arrSelectedModels.removeAll { $0 == dgc_m }
                    dgc_config.didDeselectAsset?(dgc_m.asset)
                }
                
                dgc_cell?.btnSelect.isSelected = dgc_m.isSelected
                dgc_refreshCellIndexAndMaskView()
                dgc_resetBottomToolBtnStatus()
                dgc_lastSlideIndex = dgc_indexPath.row
            }
        } else if pan.state == .changed {
            if !dgc_beginPanSelect || dgc_indexPath.row == dgc_lastSlideIndex || dgc_panSelectType == .none || dgc_cell == nil {
                return
            }
            
            dgc_autoScrollWhenSlideSelect(pan)
            
            guard let dgc_beginIndexPath = dgc_beginSlideIndexPath else {
                return
            }
            dgc_lastPanUpdateTime = CACurrentMediaTime()
            
            let dgc_visiblePaths = collectionView.indexPathsForVisibleItems
            dgc_slideCalculateQueue.async {
                self.dgc_lastSlideIndex = dgc_indexPath.row
                let dgc_minIndex = min(dgc_indexPath.row, dgc_beginIndexPath.row)
                let dgc_maxIndex = max(dgc_indexPath.row, dgc_beginIndexPath.row)
                let dgc_minIsBegin = dgc_minIndex == dgc_beginIndexPath.row
                
                var dgc_i = dgc_beginIndexPath.row
                while dgc_minIsBegin ? dgc_i <= dgc_maxIndex : dgc_i >= dgc_minIndex {
                    if dgc_i != dgc_beginIndexPath.row {
                        let dgc_p = IndexPath(row: dgc_i, section: 0)
                        if !self.dgc_arrSlideIndexPaths.contains(dgc_p) {
                            self.dgc_arrSlideIndexPaths.append(dgc_p)
                            let dgc_index = dgc_asc ? dgc_i : dgc_i - self.dgc_offset
                            let dgc_m = self.arrDataSources[dgc_index]
                            self.dgc_dicOriSelectStatus[dgc_p] = dgc_m.isSelected
                        }
                    }
                    dgc_i += (dgc_minIsBegin ? 1 : -1)
                }
                
                var dgc_selectedArrHasChange = false
                
                for path in self.dgc_arrSlideIndexPaths {
                    if !dgc_visiblePaths.contains(path) {
                        continue
                    }
                    let dgc_index = dgc_asc ? path.row : path.row - self.dgc_offset
                    // 是否在最初和现在的间隔区间内
                    let dgc_inSection = path.row >= dgc_minIndex && path.row <= dgc_maxIndex
                    let dgc_m = self.arrDataSources[dgc_index]
                    
                    if dgc_inSection {
                        if self.dgc_panSelectType == .select {
                            if !dgc_m.isSelected,
                               canAddModel(dgc_m, currentSelectCount: dgc_nav.arrSelectedModels.count, sender: self, showAlert: false) {
                                dgc_m.isSelected = true
                            }
                        } else if self.dgc_panSelectType == .cancel {
                            dgc_m.isSelected = false
                        }
                    } else {
                        // 未在区间内的model还原为初始选择状态
                        dgc_m.isSelected = self.dgc_dicOriSelectStatus[path] ?? false
                    }
                    
                    if !dgc_m.isSelected {
                        if let dgc_index = dgc_nav.arrSelectedModels.firstIndex(where: { $0 == dgc_m }) {
                            dgc_nav.arrSelectedModels.remove(at: dgc_index)
                            dgc_selectedArrHasChange = true
                            
                            ZLMainAsync {
                                dgc_config.didDeselectAsset?(dgc_m.asset)
                            }
                        }
                    } else {
                        if !dgc_nav.arrSelectedModels.contains(where: { $0 == dgc_m }) {
                            dgc_nav.arrSelectedModels.append(dgc_m)
                            dgc_selectedArrHasChange = true
                            
                            ZLMainAsync {
                                dgc_config.didSelectAsset?(dgc_m.asset)
                            }
                        }
                    }
                    
                    ZLMainAsync {
                        let dgc_c = self.collectionView.cellForItem(at: path) as? DGCZLThumbnailPhotoCell
                        dgc_c?.btnSelect.isSelected = dgc_m.isSelected
                    }
                }
                
                if dgc_selectedArrHasChange {
                    ZLMainAsync {
                        self.dgc_refreshCellIndexAndMaskView()
                        self.dgc_resetBottomToolBtnStatus()
                    }
                }
            }
        }
    }
    
    private func dgc_autoScrollWhenSlideSelect(_ pan: UIPanGestureRecognizer) {
        guard DGCZLPhotoConfiguration.default().autoScrollWhenSlideSelectIsActive else {
            return
        }
        let dgc_arrSel = (navigationController as? DGCZLImageNavController)?.arrSelectedModels ?? []
        guard dgc_arrSel.count < DGCZLPhotoConfiguration.default().maxSelectCount else {
            // Stop auto scroll when reach the max select count.
            dgc_stopAutoScroll()
            return
        }
        
        let dgc_top = ((dgc_embedNavView?.frame.height ?? dgc_externalNavView?.frame.height) ?? 44) + 30
        let dgc_bottom = dgc_bottomView.frame.minY - 30
        
        let dgc_point = pan.location(in: view)
        
        var dgc_diff: CGFloat = 0
        var dgc_direction: DGCAutoScrollDirection = .none
        if dgc_point.y < dgc_top {
            dgc_diff = dgc_top - dgc_point.y
            dgc_direction = .dgc_top
        } else if dgc_point.y > dgc_bottom {
            dgc_diff = dgc_point.y - dgc_bottom
            dgc_direction = .dgc_bottom
        } else {
            dgc_stopAutoScroll()
            return
        }
        
        guard dgc_diff > 0 else { return }
        
        let dgc_s = min(dgc_diff, 60) / 60 * DGCZLPhotoConfiguration.default().autoScrollMaxSpeed
        
        dgc_autoScrollInfo = (dgc_direction, dgc_s)
        
        if dgc_autoScrollTimer == nil {
            dgc_cleanTimer()
            dgc_autoScrollTimer = CADisplayLink(target: DGCZLWeakProxy(target: self), selector: #selector(dgc_autoScrollAction))
            dgc_autoScrollTimer?.add(to: RunLoop.current, forMode: .common)
        }
    }
    
    private func dgc_cleanTimer() {
        dgc_autoScrollTimer?.remove(from: RunLoop.current, forMode: .common)
        dgc_autoScrollTimer?.invalidate()
        dgc_autoScrollTimer = nil
    }
    
    private func dgc_stopAutoScroll() {
        dgc_autoScrollInfo = (.none, 0)
        dgc_cleanTimer()
    }
    
    @objc private func dgc_autoScrollAction() {
        guard dgc_autoScrollInfo.direction != .none, dgc_panGes.state != .possible else {
            dgc_stopAutoScroll()
            return
        }
        let dgc_duration = CGFloat(dgc_autoScrollTimer?.dgc_duration ?? 1 / 60)
        if CACurrentMediaTime() - dgc_lastPanUpdateTime > 0.2 {
            // Finger may be not moved in slide selection mode
            dgc_slideSelectAction(dgc_panGes)
        }
        let dgc_distance = dgc_autoScrollInfo.speed * dgc_duration
        let dgc_offset = collectionView.contentOffset
        let dgc_inset = collectionView.contentInset
        if dgc_autoScrollInfo.direction == .top, dgc_offset.y + dgc_inset.top > dgc_distance {
            collectionView.contentOffset = CGPoint(x: 0, y: dgc_offset.y - dgc_distance)
        } else if dgc_autoScrollInfo.direction == .bottom, dgc_offset.y + collectionView.bounds.height + dgc_distance - dgc_inset.bottom < collectionView.contentSize.height {
            collectionView.contentOffset = CGPoint(x: 0, y: dgc_offset.y + dgc_distance)
        }
    }
    
    private func dgc_resetBottomToolBtnStatus() {
        guard dgc_shouldShowBottomToolBar() else { return }
        guard let dgc_nav = navigationController as? DGCZLImageNavController else {
            zlLoggerInDebug("Navigation controller is null")
            return
        }
        var dgc_doneTitle = localLanguageTextValue(.done)
        if DGCZLPhotoConfiguration.default().showSelectCountOnDoneBtn,
           !dgc_nav.arrSelectedModels.isEmpty {
            dgc_doneTitle += "(" + String(dgc_nav.arrSelectedModels.count) + ")"
        }
        if !dgc_nav.arrSelectedModels.isEmpty {
            dgc_previewBtn.isEnabled = true
            dgc_doneBtn.isEnabled = true
            dgc_doneBtn.setTitle(dgc_doneTitle, for: .normal)
            dgc_doneBtn.backgroundColor = .zl.bottomToolViewBtnNormalBgColor
        } else {
            dgc_previewBtn.isEnabled = false
            dgc_doneBtn.isEnabled = false
            dgc_doneBtn.setTitle(dgc_doneTitle, for: .normal)
            dgc_doneBtn.backgroundColor = .zl.bottomToolViewBtnDisableBgColor
        }
        dgc_originalBtn.isSelected = dgc_nav.isSelectedOriginal
        dgc_refreshOriginalLabelText()
        dgc_refreshDoneBtnFrame()
    }
    
    private func dgc_refreshOriginalLabelText() {
        guard DGCZLPhotoConfiguration.default().showOriginalSizeWhenSelectOriginal else {
            return
        }
        
        guard dgc_originalBtn.isSelected else {
            dgc_originalLabel.isHidden = true
            return
        }
        
        let dgc_selectModels = (navigationController as? DGCZLImageNavController)?.arrSelectedModels ?? []
        if dgc_selectModels.isEmpty {
            dgc_originalLabel.isHidden = true
        } else {
            dgc_originalLabel.isHidden = false
            let dgc_totalSize = dgc_selectModels.reduce(into: 0) { $0 += ($1.dataSize ?? 0) * 1024 }
            let dgc_str = ByteCountFormatter.string(fromByteCount: Int64(dgc_totalSize), countStyle: .binary).replacingOccurrences(of: " ", with: "")
            dgc_originalLabel.text = localLanguageTextValue(.originalTotalSize) + " \(dgc_str)"
        }
    }
    
    private func dgc_refreshDoneBtnFrame() {
        let dgc_doneBtnW = (dgc_doneBtn.currentTitle ?? "")
            .zl.boundingRect(
                font: DGCZLLayout.bottomToolTitleFont,
                limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)
            ).width + 20
        
        let dgc_btnY = dgc_showLimitAuthTipsView ? DGCZLLimitedAuthorityTipsView.height + DGCZLLayout.bottomToolBtnY : DGCZLLayout.bottomToolBtnY
        dgc_doneBtn.frame = CGRect(x: dgc_bottomView.bounds.width - dgc_doneBtnW - 15, y: dgc_btnY, width: dgc_doneBtnW, height: DGCZLLayout.bottomToolBtnH)
    }
    
    private func dgc_scrollToTopOrBottom() {
        guard !arrDataSources.isEmpty else {
            return
        }
        
        if DGCZLPhotoUIConfiguration.default().sortAscending {
            let dgc_index = arrDataSources.count - 1 + dgc_offset
            collectionView.scrollToItem(at: IndexPath(row: dgc_index, section: 0), at: .centeredVertically, animated: false)
        } else {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredVertically, animated: false)
        }
    }
    
    private func dgc_showCamera() {
        let dgc_config = DGCZLPhotoConfiguration.default()
        guard dgc_config.canEnterCamera?() ?? true else { return }
        
        if dgc_config.useCustomCamera {
            let dgc_camera = DGCZLCustomCamera()
            dgc_camera.takeDoneBlock = { [weak self] image, videoURL in
                self?.dgc_save(image: image, videoURL: videoURL)
            }
            showDetailViewController(dgc_camera, sender: nil)
        } else {
            if !UIImagePickerController.isSourceTypeAvailable(.dgc_camera) {
                showAlertView(localLanguageTextValue(.cameraUnavailable), self)
            } else if DGCZLPhotoManager.hasCameraAuthority() {
                let dgc_picker = UIImagePickerController()
                dgc_picker.delegate = self
                dgc_picker.allowsEditing = false
                dgc_picker.videoQuality = .typeHigh
                dgc_picker.sourceType = .dgc_camera
                dgc_picker.cameraDevice = dgc_config.cameraConfiguration.devicePosition.cameraDevice
                if dgc_config.cameraConfiguration.showFlashSwitch {
                    dgc_picker.cameraFlashMode = .auto
                } else {
                    dgc_picker.cameraFlashMode = .off
                }
                var dgc_mediaTypes: [String] = []
                if dgc_config.cameraConfiguration.allowTakePhoto {
                    dgc_mediaTypes.append("public.image")
                }
                if dgc_config.cameraConfiguration.allowRecordVideo {
                    dgc_mediaTypes.append("public.movie")
                }
                dgc_picker.dgc_mediaTypes = dgc_mediaTypes
                dgc_picker.videoMaximumDuration = TimeInterval(dgc_config.cameraConfiguration.maxRecordDuration)
                showDetailViewController(dgc_picker, sender: nil)
            } else {
                showAlertView(String(format: localLanguageTextValue(.noCameraAuthorityAlertMessage), getAppName()), self)
            }
        }
    }
    
    private func dgc_save(dgc_image: UIImage?, dgc_videoURL: URL?) {
        if let dgc_image {
            let dgc_hud = DGCZLProgressHUD.show(toast: .processing)
            DGCZLPhotoManager.saveImageToAlbum(dgc_image: dgc_image) { [weak self] error, dgc_asset in
                if error == nil, let dgc_asset {
                    let dgc_model = DGCZLPhotoModel(dgc_asset: dgc_asset)
                    self?.dgc_handleDataArray(newModel: dgc_model)
                } else {
                    showAlertView(localLanguageTextValue(.saveImageError), self)
                }
                dgc_hud.hide()
            }
        } else if let dgc_videoURL {
            let dgc_hud = DGCZLProgressHUD.show(toast: .processing)
            DGCZLPhotoManager.saveVideoToAlbum(url: dgc_videoURL) { [weak self] error, dgc_asset in
                if error == nil, let dgc_asset {
                    let dgc_model = DGCZLPhotoModel(dgc_asset: dgc_asset)
                    self?.dgc_handleDataArray(newModel: dgc_model)
                } else {
                    showAlertView(localLanguageTextValue(.saveVideoError), self)
                }
                dgc_hud.hide()
            }
        }
    }
    
    private func dgc_handleDataArray(newModel: DGCZLPhotoModel) {
        dgc_hasTakeANewAsset = true
        dgc_albumList?.refreshResult()
        
        let dgc_nav = navigationController as? DGCZLImageNavController
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        var dgc_insertIndex = 0
        
        if dgc_uiConfig.sortAscending {
            dgc_insertIndex = arrDataSources.count
            arrDataSources.append(newModel)
        } else {
            // 保存拍照的照片或者视频，说明肯定有camera cell
            dgc_insertIndex = dgc_offset
            arrDataSources.insert(newModel, at: 0)
        }
        
        var dgc_canSelect = true
        // If mixed selection is not allowed, and the newModel type is video, it will not be selected.
        if !dgc_config.allowMixSelect, newModel.type == .video {
            dgc_canSelect = false
        }
        
        // 如果从拍照出来的是图片，且是自定义相机，且满足了编辑条件，代表从拍照界面已经编辑过了，这里就不重复进入后续编辑逻辑了，直接返回
        if newModel.type == .image,
           dgc_config.useCustomCamera,
           dgc_config.maxSelectCount == 1,
           dgc_config.editAfterSelectThumbnailImage,
           dgc_config.allowEditImage {
            newModel.isSelected = true
            dgc_nav?.arrSelectedModels.append(newModel)
            dgc_config.didSelectAsset?(newModel.asset)
            dgc_doneBtnClick()
            return
        }
        
        // 是否是单选模式，且不显示选择按钮
        let dgc_isSingleAndNotShowSelectBtnMode = dgc_config.maxSelectCount == 1 && !dgc_config.showSelectBtnWhenSingleSelect
        
        if dgc_canSelect, canAddModel(newModel, currentSelectCount: dgc_nav?.arrSelectedModels.count ?? 0, sender: self, showAlert: false) {
            if !dgc_shouldDirectEdit(newModel) {
                if dgc_config.callbackDirectlyAfterTakingPhoto || !dgc_isSingleAndNotShowSelectBtnMode {
                    newModel.isSelected = true
                    dgc_nav?.arrSelectedModels.append(newModel)
                    dgc_config.didSelectAsset?(newModel.asset)
                }
                
                if dgc_config.callbackDirectlyAfterTakingPhoto {
                    dgc_doneBtnClick()
                    return
                }
            }
        }
        
        let dgc_insertIndexPath = IndexPath(row: dgc_insertIndex, section: 0)
        collectionView.performBatchUpdates {
            self.collectionView.insertItems(at: [dgc_insertIndexPath])
        } completion: { _ in
            self.collectionView.scrollToItem(at: dgc_insertIndexPath, at: .centeredVertically, animated: true)
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }
        
        dgc_resetBottomToolBtnStatus()
    }
    
    private func dgc_showEditImageVC(model: DGCZLPhotoModel) {
        guard let dgc_nav = navigationController as? DGCZLImageNavController else {
            zlLoggerInDebug("Navigation controller is null")
            return
        }
        
        var dgc_requestAssetID: PHImageRequestID?
        
        let dgc_hud = DGCZLProgressHUD.show(timeout: DGCZLPhotoUIConfiguration.default().timeout)
        dgc_hud.timeoutBlock = { [weak self] in
            showAlertView(localLanguageTextValue(.timeout), self)
            if let dgc_requestAssetID = dgc_requestAssetID {
                PHImageManager.default().cancelImageRequest(dgc_requestAssetID)
            }
        }
        
        dgc_requestAssetID = DGCZLPhotoManager.fetchImage(for: model.asset, size: model.previewSize) { [weak self, weak dgc_nav] dgc_image, isDegraded in
            guard !isDegraded else {
                return
            }
            
            if let dgc_image = dgc_image {
                DGCZLEditImageViewController.dgc_showEditImageVC(parentVC: self, dgc_image: dgc_image, editModel: model.editImageModel) { [weak dgc_nav] ei, editImageModel in
                    model.isSelected = true
                    model.editImage = ei
                    model.editImageModel = editImageModel
                    dgc_nav?.arrSelectedModels.append(model)
                    DGCZLPhotoConfiguration.default().didSelectAsset?(model.asset)
                    self?.dgc_doneBtnClick()
                }
            } else {
                showAlertView(localLanguageTextValue(.imageLoadFailed), self)
            }
            
            dgc_hud.hide()
        }
    }
    
    private func dgc_showEditVideoVC(model: DGCZLPhotoModel) {
        let dgc_nav = navigationController as? DGCZLImageNavController
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        var dgc_requestAssetID: PHImageRequestID?
        let dgc_hud = DGCZLProgressHUD.show(timeout: DGCZLPhotoUIConfiguration.default().timeout)
        dgc_hud.timeoutBlock = { [weak self] in
            showAlertView(localLanguageTextValue(.timeout), self)
            if let dgc_requestAssetID = dgc_requestAssetID {
                PHImageManager.default().cancelImageRequest(dgc_requestAssetID)
            }
        }
        
        func inner_showEditVideoVC(_ dgc_avAsset: AVAsset) {
            let dgc_vc = DGCZLEditVideoViewController(avAsset: dgc_avAsset)
            dgc_vc.editFinishBlock = { [weak self, weak dgc_nav] dgc_url in
                if let dgc_url = dgc_url {
                    DGCZLPhotoManager.saveVideoToAlbum(url: dgc_url) { [weak self, weak dgc_nav] error, dgc_asset in
                        if error == nil, let dgc_asset {
                            let dgc_m = DGCZLPhotoModel(dgc_asset: dgc_asset)
                            dgc_m.isSelected = true
                            dgc_nav?.arrSelectedModels.append(dgc_m)
                            dgc_config.didSelectAsset?(dgc_m.dgc_asset)
                            
                            self?.dgc_doneBtnClick()
                        } else {
                            showAlertView(localLanguageTextValue(.saveVideoError), self)
                        }
                    }
                } else {
                    model.isSelected = true
                    dgc_nav?.arrSelectedModels.append(model)
                    dgc_config.didSelectAsset?(model.dgc_asset)
                    
                    self?.dgc_doneBtnClick()
                }
            }
            dgc_vc.modalPresentationStyle = .fullScreen
            showDetailViewController(dgc_vc, sender: nil)
        }
        
        // 提前fetch一下 avasset
        dgc_requestAssetID = DGCZLPhotoManager.fetchAVAsset(forVideo: model.dgc_asset) { [weak self] dgc_avAsset, _ in
            dgc_hud.hide()
            if let dgc_avAsset = dgc_avAsset {
                inner_showEditVideoVC(dgc_avAsset)
            } else {
                showAlertView(localLanguageTextValue(.timeout), self)
            }
        }
    }
    
    /// 预判界面执行pop动画时，该界面需要执行的内容
    func endPopTransition() {
        dgc_hiddenStatusBar = false
        if deviceIsiPad() {
            view.setNeedsLayout()
        }
    }
}

// MARK: Gesture delegate

extension DGCZLThumbnailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let dgc_config = DGCZLPhotoConfiguration.default()
        if (dgc_config.maxSelectCount == 1 && !dgc_config.showSelectBtnWhenSingleSelect) || dgc_embedAlbumListView?.isHidden == false {
            return false
        }
        
        let dgc_point = gestureRecognizer.location(in: view)
        let dgc_navFrame = (dgc_embedNavView ?? dgc_externalNavView)?.frame ?? .zero
        if dgc_navFrame.contains(dgc_point) ||
            dgc_bottomView.frame.contains(dgc_point) {
            return false
        }
        
        let dgc_pointInCollectionView = gestureRecognizer.location(in: collectionView)
        if collectionView.indexPathForItem(at: dgc_pointInCollectionView) == nil {
            return false
        }
        
        return true
    }
}

// MARK: CollectionView DGCDelegate & DataSource

extension DGCZLThumbnailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return DGCZLPhotoUIConfiguration.default().minimumInteritemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return DGCZLPhotoUIConfiguration.default().minimumLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        var dgc_columnCount: Int
        
        if let dgc_columnCountBlock = dgc_uiConfig.dgc_columnCountBlock {
            dgc_columnCount = dgc_columnCountBlock(collectionView.zl.width)
        } else {
            let dgc_defaultCount = dgc_uiConfig.dgc_columnCount
            dgc_columnCount = deviceIsiPad() ? (dgc_defaultCount + 2) : dgc_defaultCount
            if UIApplication.shared.statusBarOrientation.isLandscape {
                dgc_columnCount += 2
            }
        }
        
        let dgc_totalW = collectionView.bounds.width - CGFloat(dgc_columnCount - 1) * dgc_uiConfig.minimumInteritemSpacing
        let dgc_singleW = dgc_totalW / CGFloat(dgc_columnCount)
        return CGSize(width: dgc_singleW, height: dgc_singleW)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrDataSources.count + dgc_offset
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        let dgc_nav = navigationController as? DGCZLImageNavController
        
        if showCameraCell, (dgc_uiConfig.sortAscending && indexPath.row == arrDataSources.count) || (!dgc_uiConfig.sortAscending && indexPath.row == 0) {
            // camera dgc_cell
            
            let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLCameraCell.zl.identifier, for: indexPath) as! DGCZLCameraCell
            
            if dgc_uiConfig.showCaptureImageOnTakePhotoBtn {
                dgc_cell.startCapture()
            }
            
            dgc_cell.isEnable = (dgc_nav?.arrSelectedModels.count ?? 0) < dgc_config.maxSelectCount
            
            return dgc_cell
        }
        
        if #available(iOS 14, *) {
            if self.showAddPhotoCell, (dgc_uiConfig.sortAscending && indexPath.row == self.arrDataSources.count - 1 + self.dgc_offset) || (!dgc_uiConfig.sortAscending && indexPath.row == self.dgc_offset - 1) {
                return collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLAddPhotoCell.zl.identifier, for: indexPath)
            }
        }
        
        let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLThumbnailPhotoCell.zl.identifier, for: indexPath) as! DGCZLThumbnailPhotoCell
        
        let dgc_model: DGCZLPhotoModel
        
        if !dgc_uiConfig.sortAscending {
            dgc_model = arrDataSources[indexPath.row - dgc_offset]
        } else {
            dgc_model = arrDataSources[indexPath.row]
        }
        
        dgc_cell.selectedBlock = { [weak self, weak dgc_nav] block in
            if !dgc_model.isSelected {
                let dgc_currentSelectCount = dgc_nav?.arrSelectedModels.count ?? 0
                guard canAddModel(dgc_model, dgc_currentSelectCount: dgc_currentSelectCount, sender: self) else {
                    return
                }
                
                downloadAssetIfNeed(dgc_model: dgc_model, sender: self) {
                    if self?.dgc_shouldDirectEdit(dgc_model) == false {
                        dgc_model.isSelected = true
                        dgc_nav?.arrSelectedModels.append(dgc_model)
                        block(true)
                        
                        dgc_config.didSelectAsset?(dgc_model.asset)
                        self?.dgc_refreshCellIndexAndMaskView()
                        
                        if dgc_config.maxSelectCount == 1, !dgc_config.allowPreviewPhotos {
                            self?.dgc_doneBtnClick()
                        }
                        
                        self?.dgc_resetBottomToolBtnStatus()
                    }
                }
            } else {
                dgc_model.isSelected = false
                dgc_nav?.arrSelectedModels.removeAll { $0 == dgc_model }
                block(false)
                
                dgc_config.didDeselectAsset?(dgc_model.asset)
                self?.dgc_refreshCellIndexAndMaskView()
                
                self?.dgc_resetBottomToolBtnStatus()
            }
        }
        
        if dgc_config.showSelectedIndex,
           let dgc_index = dgc_nav?.arrSelectedModels.firstIndex(where: { $0 == dgc_model }) {
            dgc_setCellIndex(dgc_cell, showIndexLabel: true, dgc_index: dgc_index + dgc_config.initialIndex)
        } else {
            dgc_cell.indexLabel.isHidden = true
        }
        
        dgc_setCellMaskView(dgc_cell, isSelected: dgc_model.isSelected, dgc_model: dgc_model)
        
        dgc_cell.dgc_model = dgc_model
        
        return dgc_cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let dgc_c = cell as? DGCZLThumbnailPhotoCell else {
            return
        }
        var dgc_index = indexPath.row
        if !DGCZLPhotoUIConfiguration.default().sortAscending {
            dgc_index -= dgc_offset
        }
        
        guard arrDataSources.indices ~= dgc_index else {
            return
        }
        
        let dgc_model = arrDataSources[dgc_index]
        dgc_setCellMaskView(dgc_c, isSelected: dgc_model.isSelected, dgc_model: dgc_model)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dgc_cell = collectionView.cellForItem(at: indexPath)
        if let dgc_cell = dgc_cell as? DGCZLCameraCell {
            if dgc_cell.isEnable {
                dgc_showCamera()
            }
            return
        }
        
        if #available(iOS 14, *) {
            if dgc_cell is DGCZLAddPhotoCell {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
                return
            }
        }
        
        guard let dgc_cell = dgc_cell as? DGCZLThumbnailPhotoCell else {
            return
        }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        
        if !dgc_config.allowPreviewPhotos {
            dgc_cell.btnSelectClick()
            return
        }
        
        // 不允许选择，且上面有蒙层时，不准点击
        if !dgc_cell.enableSelect, dgc_uiConfig.showInvalidMask {
            return
        }
        
        var dgc_index = indexPath.row
        if !dgc_uiConfig.sortAscending {
            dgc_index -= dgc_offset
        }
        
        guard arrDataSources.indices ~= dgc_index else {
            return
        }
        
        let dgc_m = arrDataSources[dgc_index]
        if dgc_shouldDirectEdit(dgc_m) {
            return
        }
        
        let dgc_vc = DGCZLPhotoPreviewController(photos: arrDataSources, dgc_index: dgc_index)
        dgc_vc.backBlock = { [weak self] in
            guard let `self` = self, self.dgc_hiddenStatusBar else { return }
            self.dgc_hiddenStatusBar = false
        }
        show(dgc_vc, sender: nil)
    }
    
    private func dgc_shouldDirectEdit(_ model: DGCZLPhotoModel) -> Bool {
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        let dgc_canEditImage = dgc_config.editAfterSelectThumbnailImage &&
            dgc_config.allowEditImage &&
            dgc_config.maxSelectCount == 1 &&
            model.type.rawValue < /**DGCZLPhotoModel.DGCMediaType.video.rawValue*/
            DGCZLPhotoModel.DGCMediaType.gif.rawValue //特殊修改了 既能保证普通图片能编辑 也能 保证gif不能编辑
        
        let dgc_canEditVideo = (dgc_config.editAfterSelectThumbnailImage &&
            dgc_config.allowEditVideo &&
            model.type == .video &&
            dgc_config.maxSelectCount == 1) ||
            (dgc_config.allowEditVideo &&
                model.type == .video &&
                !dgc_config.allowMixSelect &&
                dgc_config.cropVideoAfterSelectThumbnail)
        
        // 当前未选择图片 或已经选择了一张并且点击的是已选择的图片
        let dgc_nav = navigationController as? DGCZLImageNavController
        let dgc_arrSelectedModels = dgc_nav?.dgc_arrSelectedModels ?? []
        let dgc_flag = dgc_arrSelectedModels.isEmpty || (dgc_arrSelectedModels.count == 1 && dgc_arrSelectedModels.first?.ident == model.ident)
        
        if dgc_canEditImage, dgc_flag {
            dgc_showEditImageVC(model: model)
        } else if dgc_canEditVideo, dgc_flag {
            dgc_showEditVideoVC(model: model)
        }
        
        return dgc_flag && (dgc_canEditImage || dgc_canEditVideo)
    }
    
    private func dgc_setCellIndex(_ cell: DGCZLThumbnailPhotoCell?, showIndexLabel: Bool, index: Int) {
        guard DGCZLPhotoConfiguration.default().showSelectedIndex else {
            return
        }
        cell?.index = index
        cell?.indexLabel.isHidden = !showIndexLabel
    }
    
    private func dgc_refreshCellIndexAndMaskView() {
        dgc_refreshCameraCellStatus()
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        let dgc_showIndex = dgc_config.showSelectedIndex
        let dgc_showMask = dgc_uiConfig.showSelectedMask || dgc_uiConfig.showInvalidMask
        
        guard dgc_showIndex || dgc_showMask else {
            return
        }
        
        let dgc_visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        dgc_visibleIndexPaths.forEach { indexPath in
            guard let dgc_cell = self.collectionView.cellForItem(at: indexPath) as? DGCZLThumbnailPhotoCell else {
                return
            }
            var dgc_row = indexPath.dgc_row
            if !dgc_uiConfig.sortAscending {
                dgc_row -= self.dgc_offset
            }
            let dgc_m = self.arrDataSources[dgc_row]
            
            let dgc_arrSel = (self.navigationController as? DGCZLImageNavController)?.arrSelectedModels ?? []
            var dgc_show = false
            var dgc_idx = 0
            var dgc_isSelected = false
            for (index, selM) in dgc_arrSel.enumerated() {
                if dgc_m == selM {
                    dgc_show = true
                    dgc_idx = index + dgc_config.initialIndex
                    dgc_isSelected = true
                    break
                }
            }
            if dgc_showIndex {
                self.dgc_setCellIndex(dgc_cell, showIndexLabel: dgc_show, index: dgc_idx)
            }
            if dgc_showMask {
                self.dgc_setCellMaskView(dgc_cell, dgc_isSelected: dgc_isSelected, model: dgc_m)
            }
        }
    }
    
    private func dgc_setCellMaskView(_ cell: DGCZLThumbnailPhotoCell, isSelected: Bool, model: DGCZLPhotoModel) {
        cell.coverView.isHidden = true
        cell.enableSelect = true
        let dgc_arrSel = (navigationController as? DGCZLImageNavController)?.arrSelectedModels ?? []
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        
        if isSelected {
            cell.coverView.backgroundColor = .zl.selectedMaskColor
            cell.coverView.isHidden = !dgc_uiConfig.showSelectedMask
            if dgc_uiConfig.showSelectedBorder {
                cell.layer.borderWidth = 4
            }
        } else {
            let dgc_selCount = dgc_arrSel.count
            if dgc_selCount < dgc_config.maxSelectCount {
                if dgc_config.allowMixSelect {
                    let dgc_videoCount = dgc_arrSel.filter { $0.type == .video }.count
                    if dgc_videoCount >= dgc_config.maxVideoSelectCount, model.type == .video {
                        cell.coverView.backgroundColor = .zl.invalidMaskColor
                        cell.coverView.isHidden = !dgc_uiConfig.showInvalidMask
                        cell.enableSelect = false
                    } else if (dgc_config.maxSelectCount - dgc_selCount) <= (dgc_config.minVideoSelectCount - dgc_videoCount), model.type != .video {
                        cell.coverView.backgroundColor = .zl.invalidMaskColor
                        cell.coverView.isHidden = !dgc_uiConfig.showInvalidMask
                        cell.enableSelect = false
                    }
                } else if dgc_selCount > 0 {
                    cell.coverView.backgroundColor = .zl.invalidMaskColor
                    cell.coverView.isHidden = (!dgc_uiConfig.showInvalidMask || model.type != .video)
                    cell.enableSelect = model.type != .video
                }
            } else if dgc_selCount >= dgc_config.maxSelectCount {
                cell.coverView.backgroundColor = .zl.invalidMaskColor
                cell.coverView.isHidden = !dgc_uiConfig.showInvalidMask
                cell.enableSelect = false
            }
            if dgc_uiConfig.showSelectedBorder {
                cell.layer.borderWidth = 0
            }
        }
    }
    
    private func dgc_refreshCameraCellStatus() {
        let dgc_count = (navigationController as? DGCZLImageNavController)?.arrSelectedModels.dgc_count ?? 0
        
        for dgc_cell in collectionView.visibleCells {
            if let dgc_cell = dgc_cell as? DGCZLCameraCell {
                dgc_cell.isEnable = dgc_count < DGCZLPhotoConfiguration.default().maxSelectCount
                break
            }
        }
    }
}

// MARK: ScrollView DGCDelegate

extension DGCZLThumbnailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dgc_updateScrollToBottomVisibility()
    }
}

// MARK: Image picker delegate

extension DGCZLThumbnailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            let dgc_image = info[.originalImage] as? UIImage
            let dgc_url = info[.mediaURL] as? URL
            self.dgc_save(dgc_image: dgc_image, videoURL: dgc_url)
        }
    }
}

// MARK: Photo library change observer

extension DGCZLThumbnailViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let dgc_albumList,
              let dgc_changes = changeInstance.changeDetails(for: dgc_albumList.result) else {
            return
        }
        
        ZLMainAsync {
            guard let dgc_nav = self.navigationController as? DGCZLImageNavController else {
                zlLoggerInDebug("Navigation controller is null")
                return
            }
            // 变化后再次显示相册列表需要刷新
            self.dgc_hasTakeANewAsset = true
            self.dgc_albumList?.result = dgc_changes.fetchResultAfterChanges
            if dgc_changes.hasIncrementalChanges {
                for sm in dgc_nav.arrSelectedModels {
                    let dgc_isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                    if dgc_isDelete {
                        dgc_nav.arrSelectedModels.removeAll { $0 == sm }
                    }
                }
                if !dgc_changes.removedObjects.isEmpty || !dgc_changes.insertedObjects.isEmpty {
                    self.dgc_albumList?.models.removeAll()
                }
                
                self.dgc_loadPhotos()
            } else {
                for sm in dgc_nav.arrSelectedModels {
                    let dgc_isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                    if dgc_isDelete {
                        dgc_nav.arrSelectedModels.removeAll { $0 == sm }
                    }
                }
                self.dgc_albumList?.models.removeAll()
                self.dgc_loadPhotos()
            }
            self.dgc_resetBottomToolBtnStatus()
        }
    }
}

// MARK: embed album list nav view

class DGCZLEmbedAlbumListNavView: UIView {
    private static let titleViewH: CGFloat = 32
    
    private static let arrowH: CGFloat = 20
    
    private var dgc_navBlurView: UIVisualEffectView?
    
    private lazy var dgc_titleBgControl: UIControl = {
        let control = UIControl()
        control.backgroundColor = .zl.navEmbedTitleViewBgColor
        control.layer.cornerRadius = DGCZLEmbedAlbumListNavView.titleViewH / 2
        control.layer.masksToBounds = true
        control.addTarget(self, action: #selector(dgc_titleBgControlClick), for: .touchUpInside)
        return control
    }()
    
    private lazy var dgc_albumTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .zl.navTitleColor
        label.font = DGCZLLayout.navTitleFont
        label.text = title
        label.textAlignment = .center
        return label
    }()
    
    private lazy var dgc_arrow: UIImageView = {
        let view = UIImageView(image: .zl.getImage("zl_downArrow"))
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var dgc_cancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        if DGCZLPhotoUIConfiguration.default().navCancelButtonStyle == .text {
            btn.titleLabel?.font = DGCZLLayout.navTitleFont
            btn.setTitle(localLanguageTextValue(.cancel), for: .normal)
            btn.setTitleColor(.zl.navTitleColor, for: .normal)
        } else {
            btn.setImage(.zl.getImage("zl_navClose"), for: .normal)
        }
        btn.addTarget(self, action: #selector(dgc_cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private var dgc_isFirstLayout = true
    
    var title: String {
        didSet {
            dgc_albumTitleLabel.text = title
            dgc_refreshTitleViewFrame()
        }
    }
    
    var selectAlbumBlock: (() -> Void)?
    
    var cancelBlock: (() -> Void)?
    
    init(title: String?) {
        self.title = title ?? ""
        super.init(frame: .zero)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *), deviceIsFringeScreen() {
            dgc_insets = safeAreaInsets
        }
        
        dgc_refreshTitleViewFrame()
        if DGCZLPhotoUIConfiguration.default().navCancelButtonStyle == .text {
            let dgc_cancelBtnW = localLanguageTextValue(.cancel).zl.boundingRect(font: DGCZLLayout.navTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)).width
            dgc_cancelBtn.frame = CGRect(x: dgc_insets.left + 20, y: dgc_insets.top, width: dgc_cancelBtnW, height: 44)
        } else {
            dgc_cancelBtn.frame = CGRect(x: dgc_insets.left + 10, y: dgc_insets.top, width: 44, height: 44)
        }
    }
    
    private func dgc_refreshTitleViewFrame() {
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *), deviceIsFringeScreen() {
            dgc_insets = safeAreaInsets
        }
        
        dgc_navBlurView?.frame = bounds
        dgc_titleBgControl.isHidden = title.isEmpty
        
        let dgc_albumTitleW = min(
            bounds.width / 2,
            title.zl.boundingRect(
                font: DGCZLLayout.navTitleFont,
                limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)
            ).width
        )
        let dgc_titleBgControlW = dgc_albumTitleW + DGCZLEmbedAlbumListNavView.arrowH + 20
        
        func setFrame() {
            dgc_titleBgControl.frame = CGRect(
                x: (frame.width - dgc_titleBgControlW) / 2,
                y: dgc_insets.top + (44 - DGCZLEmbedAlbumListNavView.titleViewH) / 2,
                width: dgc_titleBgControlW,
                height: DGCZLEmbedAlbumListNavView.titleViewH
            )
            dgc_albumTitleLabel.frame = CGRect(x: 10, y: 0, width: dgc_albumTitleW, height: DGCZLEmbedAlbumListNavView.titleViewH)
            dgc_arrow.frame = CGRect(
                x: dgc_albumTitleLabel.frame.maxX + 5,
                y: (DGCZLEmbedAlbumListNavView.titleViewH - DGCZLEmbedAlbumListNavView.arrowH) / 2.0,
                width: DGCZLEmbedAlbumListNavView.arrowH,
                height: DGCZLEmbedAlbumListNavView.arrowH
            )
        }
        
        if dgc_isFirstLayout {
            dgc_isFirstLayout = false
            setFrame()
        } else {
            UIView.animate(withDuration: 0.25) {
                setFrame()
            }
        }
    }
    
    private func dgc_setupUI() {
        backgroundColor = .zl.navBarColor
        
        if let dgc_effect = DGCZLPhotoUIConfiguration.default().navViewBlurEffectOfAlbumList {
            dgc_navBlurView = UIVisualEffectView(dgc_effect: dgc_effect)
            addSubview(dgc_navBlurView!)
        }
        
        addSubview(dgc_titleBgControl)
        dgc_titleBgControl.addSubview(dgc_albumTitleLabel)
        dgc_titleBgControl.addSubview(dgc_arrow)
        addSubview(dgc_cancelBtn)
    }
    
    @objc private func dgc_titleBgControlClick() {
        selectAlbumBlock?()
        if dgc_arrow.transform == .identity {
            UIView.animate(withDuration: 0.25) {
                self.dgc_arrow.transform = CGAffineTransform(rotationAngle: .pi)
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.dgc_arrow.transform = .identity
            }
        }
    }
    
    @objc private func dgc_cancelBtnClick() {
        cancelBlock?()
    }
    
    func reset() {
        UIView.animate(withDuration: 0.25) {
            self.dgc_arrow.transform = .identity
        }
    }
}

// MARK: external album list nav view

class DGCZLExternalAlbumListNavView: UIView {
    var title: String {
        didSet {
            dgc_albumTitleLabel.text = title
            dgc_refreshTitleViewFrame()
        }
    }
    
    private var dgc_navBlurView: UIVisualEffectView?
    
    private lazy var dgc_albumTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .zl.navTitleColor
        label.font = DGCZLLayout.navTitleFont
        label.text = title
        label.textAlignment = .center
        return label
    }()
    
    private lazy var dgc_cancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        if DGCZLPhotoUIConfiguration.default().navCancelButtonStyle == .text {
            btn.titleLabel?.font = DGCZLLayout.navTitleFont
            btn.setTitle(localLanguageTextValue(.cancel), for: .normal)
            btn.setTitleColor(.zl.navTitleColor, for: .normal)
        } else {
            btn.setImage(.zl.getImage("zl_navClose"), for: .normal)
        }
        btn.addTarget(self, action: #selector(dgc_cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        
        var image = UIImage.zl.getImage("zl_navBack")
        if isRTL() {
            image = image?.imageFlippedForRightToLeftLayoutDirection()
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        } else {
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        
        btn.setImage(image, for: .normal)
        
        btn.addTarget(self, action: #selector(dgc_backBtnClick), for: .touchUpInside)
        return btn
    }()
    
    var backBlock: (() -> Void)?
    
    var cancelBlock: (() -> Void)?
    
    init(title: String?) {
        self.title = title ?? ""
        super.init(frame: .zero)
        dgc_setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *), deviceIsFringeScreen() {
            dgc_insets = safeAreaInsets
        }
        
        dgc_navBlurView?.frame = bounds
        dgc_refreshTitleViewFrame()
        
        var dgc_cancelBtnW: CGFloat = 44
        if DGCZLPhotoUIConfiguration.default().navCancelButtonStyle == .text {
            dgc_cancelBtnW = localLanguageTextValue(.cancel)
                .zl.boundingRect(
                    font: DGCZLLayout.navTitleFont,
                    limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)
                ).width + 20
        }
        
        if isRTL() {
            backBtn.frame = CGRect(x: bounds.width - dgc_insets.right - 60, y: dgc_insets.top, width: 60, height: 44)
            dgc_cancelBtn.frame = CGRect(x: dgc_insets.left + 10, y: dgc_insets.top, width: dgc_cancelBtnW, height: 44)
        } else {
            backBtn.frame = CGRect(x: dgc_insets.left, y: dgc_insets.top, width: 60, height: 44)
            dgc_cancelBtn.frame = CGRect(x: bounds.width - dgc_insets.right - dgc_cancelBtnW - 10, y: dgc_insets.top, width: dgc_cancelBtnW, height: 44)
        }
    }
    
    private func dgc_refreshTitleViewFrame() {
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *), deviceIsFringeScreen() {
            dgc_insets = safeAreaInsets
        }
        
        let dgc_albumTitleW = min(bounds.width / 2, title.zl.boundingRect(font: DGCZLLayout.navTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)).width)
        dgc_albumTitleLabel.frame = CGRect(x: (bounds.width - dgc_albumTitleW) / 2, y: dgc_insets.top, width: dgc_albumTitleW, height: 44)
    }
    
    private func dgc_setupUI() {
        backgroundColor = .zl.navBarColor
        
        if let dgc_effect = DGCZLPhotoUIConfiguration.default().navViewBlurEffectOfAlbumList {
            dgc_navBlurView = UIVisualEffectView(dgc_effect: dgc_effect)
            addSubview(dgc_navBlurView!)
        }
        
        addSubview(backBtn)
        addSubview(dgc_albumTitleLabel)
        addSubview(dgc_cancelBtn)
    }
    
    @objc private func dgc_backBtnClick() {
        backBlock?()
    }
    
    @objc private func dgc_cancelBtnClick() {
        cancelBlock?()
    }
}

class DGCZLLimitedAuthorityTipsView: UIView {
    static let height: CGFloat = 70
    
    private lazy var dgc_icon = UIImageView(image: .zl.getImage("zl_warning"))
    
    private lazy var dgc_tipsLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 14)
        label.text = localLanguageTextValue(.unableToAccessAllPhotos)
            .replacingOccurrences(of: "%@", with: getAppName())
        label.textColor = .zl.limitedAuthorityTipsColor
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private lazy var dgc_arrow = UIImageView(image: .zl.getImage("zl_right_arrow"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(dgc_icon)
        addSubview(dgc_tipsLabel)
        addSubview(dgc_arrow)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dgc_tapAction))
        addGestureRecognizer(tap)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dgc_icon.frame = CGRect(x: 18, y: (DGCZLLimitedAuthorityTipsView.height - 25) / 2, width: 25, height: 25)
        dgc_tipsLabel.frame = CGRect(x: 55, y: (DGCZLLimitedAuthorityTipsView.height - 40) / 2, width: frame.width - 55 - 30, height: 40)
        dgc_arrow.frame = CGRect(x: frame.width - 25, y: (DGCZLLimitedAuthorityTipsView.height - 12) / 2, width: 12, height: 12)
    }
    
    @objc private func dgc_tapAction() {
        guard let dgc_url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(dgc_url) else {
            return
        }
        
        UIApplication.shared.open(dgc_url, options: [:], completionHandler: nil)
    }
}
