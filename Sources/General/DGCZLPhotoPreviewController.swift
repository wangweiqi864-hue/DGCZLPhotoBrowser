//
//  DGCZLPhotoPreviewController.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/20.
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

class DGCZLPhotoPreviewController: UIViewController {
    static let colItemSpacing: CGFloat = 40
    
    static let selPhotoPreviewH: CGFloat = 100
    
    static let previewVCScrollNotification = Notification.Name("previewVCScrollNotification")
    
    let arrDataSources: [DGCZLPhotoModel]
    
    var currentIndex: Int
    
    lazy var dgc_collectionView: UICollectionView = {
        let layout = DGCZLCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        
        DGCZLPhotoPreviewCell.zl.register(view)
        DGCZLGifPreviewCell.zl.register(view)
        DGCZLLivePhotoPreviewCell.zl.register(view)
        DGCZLVideoPreviewCell.zl.register(view)
        
        return view
    }()
    
    private let dgc_showBottomViewAndSelectBtn: Bool
    
    private var dgc_indexBeforOrientationChanged: Int
    
    private let dgc_navViewAlpha = 0.95
    
    private lazy var dgc_navView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.navBarColorOfPreviewVC
        view.alpha = dgc_navViewAlpha
        return view
    }()
    
    private var dgc_navBlurView: UIVisualEffectView?
    
    private lazy var dgc_backBtn: UIButton = {
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
    
    private lazy var dgc_selectBtn: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_btn_unselected_with_check"), for: .normal)
        btn.setImage(.zl.getImage("zl_btn_selected"), for: .selected)
        btn.enlargeInset = 10
        btn.addTarget(self, action: #selector(dgc_selectBtnClick), for: .touchUpInside)
        return btn
    }()
    
//    private lazy var dgc_indexLabel: UILabel = {
//        let label = UILabel()
//        label.backgroundColor = .zl.indexLabelBgColor
//        label.font = .zl.font(ofSize: 14)
//        label.textColor = .white
//        label.textAlignment = .center
//        label.layer.cornerRadius = 25.0 / 2
//        label.layer.masksToBounds = true
//        label.isHidden = true
//        return label
//    }()
    
    private lazy var dgc_bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.bottomToolViewBgColorOfPreviewVC
        return view
    }()
    
    private var dgc_bottomBlurView: UIVisualEffectView?
    
    private lazy var dgc_editBtn: UIButton = {
        let btn = dgc_createBtn(localLanguageTextValue(.edit), #selector(dgc_editBtnClick))
        btn.titleLabel?.lineBreakMode = .byCharWrapping
        btn.titleLabel?.numberOfLines = 0
        btn.contentHorizontalAlignment = .left
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
        return btn
    }()
    
    private lazy var dgc_originalLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 12)
        label.textColor = .zl.originalSizeLabelTextColorOfPreviewVC
        label.textAlignment = .center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.isHidden = true
        return label
    }()
    
    private lazy var dgc_doneBtn: UIButton = {
        let btn = dgc_createBtn(localLanguageTextValue(.done), #selector(dgc_doneBtnClick), true)
        btn.backgroundColor = .zl.bottomToolViewBtnNormalBgColorOfPreviewVC
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = DGCZLLayout.bottomToolBtnCornerRadius
        return btn
    }()
    
    private var dgc_selPhotoPreview: DGCZLPhotoPreviewSelectedView?
    
    private var dgc_isFirstAppear = true
    
    private var dgc_hideNavView = false
    
    private var dgc_popInteractiveTransition: DGCZLPhotoPreviewPopInteractiveTransition?
    
    private var dgc_orientation: UIInterfaceOrientation = .unknown
    
    /// 是否在点击确定时候，当未选择任何照片时候，自动选择当前index的照片
    var autoSelectCurrentIfNotSelectAnyone = true
    
    /// 界面消失时，通知上个界面刷新
    var backBlock: (() -> Void)?
    
    override var prefersStatusBarHidden: Bool {
        !DGCZLPhotoUIConfiguration.default().showStatusBarInPreviewInterface
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        DGCZLPhotoUIConfiguration.default().statusBarStyle
    }
    
    deinit {
        zl_debugPrint("DGCZLPhotoPreviewController deinit")
    }
    
    init(photos: [DGCZLPhotoModel], index: Int, dgc_showBottomViewAndSelectBtn: Bool = true) {
        arrDataSources = photos
        self.dgc_showBottomViewAndSelectBtn = dgc_showBottomViewAndSelectBtn
        currentIndex = min(index, photos.count - 1)
        dgc_indexBeforOrientationChanged = currentIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dgc_setupUI()
        
        dgc_addPopInteractiveTransition()
        dgc_resetSubviewStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.delegate = self
        
        guard dgc_isFirstAppear else { return }
        dgc_isFirstAppear = false
        
        dgc_reloadCurrentCell()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            dgc_insets = self.view.safeAreaInsets
        }
        dgc_insets.top = max(20, dgc_insets.top)
        
        dgc_collectionView.frame = CGRect(
            x: -DGCZLPhotoPreviewController.colItemSpacing / 2,
            y: 0,
            width: view.zl.width + DGCZLPhotoPreviewController.colItemSpacing,
            height: view.zl.height
        )
        
        let dgc_navH = dgc_insets.top + 44
        dgc_navView.frame = CGRect(x: 0, y: 0, width: view.zl.width, height: dgc_navH)
        dgc_navBlurView?.frame = dgc_navView.bounds
        
        if isRTL() {
            dgc_backBtn.frame = CGRect(x: view.zl.width - dgc_insets.right - 60, y: dgc_insets.top, width: 60, height: 44)
            dgc_selectBtn.frame = CGRect(x: dgc_insets.left + 15, y: dgc_insets.top + (44 - 24) / 2, width: 24, height: 24)
        } else {
            dgc_backBtn.frame = CGRect(x: dgc_insets.left, y: dgc_insets.top, width: 60, height: 44)
            dgc_selectBtn.frame = CGRect(x: view.zl.width - 40 - dgc_insets.right, y: dgc_insets.top + (44 - 24) / 2, width: 24, height: 24)
        }
        
//        dgc_indexLabel.frame = dgc_selectBtn.bounds
        
        dgc_refreshBottomViewFrame()
        
        let dgc_ori = UIApplication.shared.statusBarOrientation
        if dgc_ori != dgc_orientation {
            dgc_orientation = dgc_ori

            dgc_collectionView.setContentOffset(
                CGPoint(
                    x: (view.zl.width + DGCZLPhotoPreviewController.colItemSpacing) * CGFloat(dgc_indexBeforOrientationChanged),
                    y: 0
                ),
                animated: false
            )
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dgc_collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func dgc_reloadCurrentCell() {
        guard let dgc_cell = dgc_collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0)) else {
            return
        }
        
        if let dgc_cell = dgc_cell as? DGCZLGifPreviewCell {
            dgc_cell.loadGifWhenCellDisplaying()
        } else if let dgc_cell = dgc_cell as? DGCZLLivePhotoPreviewCell {
            dgc_cell.loadLivePhotoData()
        }
    }
    
    private func dgc_refreshBottomViewFrame() {
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            dgc_insets = view.safeAreaInsets
        }
        var dgc_bottomViewH = DGCZLLayout.bottomToolViewH
        
        var dgc_showSelPhotoPreview = false
        if DGCZLPhotoUIConfiguration.default().showSelectedPhotoPreview,
           let dgc_nav = navigationController as? DGCZLImageNavController,
           !dgc_nav.dgc_arrSelectedModels.isEmpty {
            dgc_showSelPhotoPreview = true
            dgc_bottomViewH += DGCZLPhotoPreviewController.selPhotoPreviewH
            dgc_selPhotoPreview?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: DGCZLPhotoPreviewController.selPhotoPreviewH)
        }
        
        let dgc_btnH = DGCZLLayout.bottomToolBtnH
        
        dgc_bottomView.frame = CGRect(x: 0, y: view.frame.height - dgc_insets.bottom - dgc_bottomViewH, width: view.frame.width, height: dgc_bottomViewH + dgc_insets.bottom)
        dgc_bottomBlurView?.frame = dgc_bottomView.bounds
        
        let dgc_btnY: CGFloat = dgc_showSelPhotoPreview ? DGCZLPhotoPreviewController.selPhotoPreviewH + DGCZLLayout.bottomToolBtnY : DGCZLLayout.bottomToolBtnY
        
        let dgc_btnMaxWidth = (dgc_bottomView.bounds.width - 30) / 3
        
        let dgc_editTitle = localLanguageTextValue(.edit)
        let dgc_editBtnW = dgc_editTitle.zl.boundingRect(font: DGCZLLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)).width
        dgc_editBtn.frame = CGRect(x: 15, y: dgc_btnY, width: min(dgc_btnMaxWidth, dgc_editBtnW), height: dgc_btnH)
        
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
        dgc_originalLabel.frame = CGRect(
            x: (dgc_bottomView.zl.width - dgc_btnMaxWidth) / 2 - 5,
            y: dgc_originalBtn.zl.bottom,
            width: dgc_btnMaxWidth,
            height: dgc_originalLabel.font.lineHeight
        )
        
        let dgc_doneBtnW = (dgc_doneBtn.currentTitle ?? "")
            .zl.boundingRect(
                font: DGCZLLayout.bottomToolTitleFont,
                limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)
            ).width + 20
        dgc_doneBtn.frame = CGRect(x: dgc_bottomView.bounds.width - dgc_doneBtnW - 15, y: dgc_btnY, width: dgc_doneBtnW, height: dgc_btnH)
    }
    
    private func dgc_setupUI() {
        view.backgroundColor = .zl.previewVCBgColor
        automaticallyAdjustsScrollViewInsets = false
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        
        view.addSubview(dgc_navView)
        
        if let dgc_effect = DGCZLPhotoUIConfiguration.default().navViewBlurEffectOfPreview {
            dgc_navBlurView = UIVisualEffectView(dgc_effect: dgc_effect)
            dgc_navView.addSubview(dgc_navBlurView!)
        }
        
        dgc_navView.addSubview(dgc_backBtn)
        dgc_navView.addSubview(dgc_selectBtn)
//        dgc_selectBtn.addSubview(dgc_indexLabel)
        view.addSubview(dgc_collectionView)
        view.addSubview(dgc_bottomView)
        
        if let dgc_effect = DGCZLPhotoUIConfiguration.default().bottomViewBlurEffectOfPreview {
            dgc_bottomBlurView = UIVisualEffectView(dgc_effect: dgc_effect)
            dgc_bottomView.addSubview(dgc_bottomBlurView!)
        }
        
        if dgc_uiConfig.showSelectedPhotoPreview {
            let dgc_selModels = (navigationController as? DGCZLImageNavController)?.dgc_arrSelectedModels ?? []
            dgc_selPhotoPreview = DGCZLPhotoPreviewSelectedView(dgc_selModels: dgc_selModels, dgc_currentShowModel: arrDataSources[currentIndex])
            dgc_selPhotoPreview?.selectBlock = { [weak self] model in
                self?.dgc_scrollToSelPreviewCell(model)
            }
            dgc_selPhotoPreview?.beginSortBlock = { [weak self] in
                self?.dgc_resetSubviewStatusWhenDraging(enable: false)
            }
            dgc_selPhotoPreview?.endSortBlock = { [weak self] models in
                self?.dgc_resetSubviewStatusWhenDraging(enable: true)
                self?.dgc_refreshCurrentCellIndex(models)
            }
            dgc_bottomView.addSubview(dgc_selPhotoPreview!)
        }
        
        dgc_editBtn.isHidden = (!dgc_config.allowEditImage && !dgc_config.allowEditVideo)
        dgc_bottomView.addSubview(dgc_editBtn)
        
        dgc_originalBtn.isHidden = !(dgc_config.allowSelectOriginal && dgc_config.allowSelectImage)
        dgc_originalBtn.isSelected = (navigationController as? DGCZLImageNavController)?.isSelectedOriginal ?? false
        dgc_bottomView.addSubview(dgc_originalBtn)
        dgc_bottomView.addSubview(dgc_originalLabel)
        dgc_bottomView.addSubview(dgc_doneBtn)
        
        view.bringSubviewToFront(dgc_navView)
    }
    
    private func dgc_resetSubviewStatusWhenDraging(enable: Bool) {
        dgc_collectionView.isScrollEnabled = enable
        dgc_navView.isUserInteractionEnabled = enable
        dgc_editBtn.isUserInteractionEnabled = enable
        dgc_originalBtn.isUserInteractionEnabled = enable
        dgc_doneBtn.isUserInteractionEnabled = enable
    }
    
    private func dgc_createBtn(_ title: String, _ action: Selector, _ isDone: Bool = false) -> UIButton {
        let dgc_btn = UIButton(type: .custom)
        dgc_btn.titleLabel?.font = DGCZLLayout.bottomToolTitleFont
        dgc_btn.setTitle(title, for: .normal)
        dgc_btn.setTitleColor(
            isDone ? .zl.bottomToolViewDoneBtnNormalTitleColorOfPreviewVC : .zl.bottomToolViewBtnNormalTitleColorOfPreviewVC,
            for: .normal
        )
        dgc_btn.setTitleColor(
            isDone ? .zl.bottomToolViewDoneBtnDisableTitleColorOfPreviewVC : .zl.bottomToolViewBtnDisableTitleColorOfPreviewVC,
            for: .disabled
        )
        dgc_btn.addTarget(self, action: action, for: .touchUpInside)
        return dgc_btn
    }
    
    private func dgc_addPopInteractiveTransition() {
        guard (navigationController?.viewControllers.count ?? 0) > 1 else {
            // 仅有当前vc一个时候，说明不是从相册进入，不添加交互动画
            return
        }
        dgc_popInteractiveTransition = DGCZLPhotoPreviewPopInteractiveTransition(viewController: self)
        dgc_popInteractiveTransition?.shouldStartTransition = { [weak self] point -> Bool in
            guard let `self` = self else { return false }
            
            if !self.dgc_hideNavView, self.dgc_navView.frame.contains(point) ||
                self.dgc_bottomView.frame.contains(point) ||
                self.dgc_selPhotoPreview?.isDraging == true {
                return false
            }
            
            guard self.dgc_collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0)) != nil else {
                return false
            }
            
            return true
        }
        dgc_popInteractiveTransition?.startTransition = { [weak self] in
            guard let `self` = self else { return }
            
            UIView.animate(withDuration: 0.25) {
                self.dgc_navView.alpha = 0
                self.dgc_bottomView.alpha = 0
            }
            
            guard let dgc_cell = self.dgc_collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0)) else {
                return
            }
            
            if let dgc_cell = dgc_cell as? DGCZLLivePhotoPreviewCell {
                dgc_cell.livePhotoView.stopPlayback()
            } else if let dgc_cell = dgc_cell as? DGCZLGifPreviewCell {
                dgc_cell.pauseGif()
            }
        }
        dgc_popInteractiveTransition?.cancelTransition = { [weak self] in
            guard let `self` = self else { return }
            
            let dgc_cell = self.dgc_collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0))
            
            if let dgc_cell = dgc_cell as? DGCZLVideoPreviewCell {
                self.dgc_hideNavView = dgc_cell.isPlaying
            } else {
                self.dgc_hideNavView = false
            }
            
            self.dgc_navView.isHidden = self.dgc_hideNavView
            self.dgc_bottomView.isHidden = self.dgc_hideNavView
            
            UIView.animate(withDuration: 0.5) {
                self.dgc_navView.alpha = self.dgc_navViewAlpha
                self.dgc_bottomView.alpha = 1
            }
            
            if let dgc_cell = dgc_cell as? DGCZLGifPreviewCell {
                dgc_cell.resumeGif()
            }
        }
    }
    
    private func dgc_resetSubviewStatus() {
        guard let dgc_nav = navigationController as? DGCZLImageNavController else {
            zlLoggerInDebug("Navigation controller is null")
            return
        }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_currentModel = arrDataSources[currentIndex]
        
        if (!dgc_config.allowMixSelect && dgc_currentModel.type == .video) ||
            (!dgc_config.showSelectBtnWhenSingleSelect && dgc_config.maxSelectCount == 1) {
            dgc_selectBtn.isHidden = true
        } else {
            dgc_selectBtn.isHidden = false
        }
        dgc_selectBtn.isSelected = arrDataSources[currentIndex].isSelected
//        dgc_resetIndexLabelStatus()
        
        guard dgc_showBottomViewAndSelectBtn else {
            dgc_selectBtn.isHidden = true
            dgc_bottomView.isHidden = true
            return
        }
        let dgc_selCount = dgc_nav.dgc_arrSelectedModels.count
        var dgc_doneTitle = localLanguageTextValue(.done)
        if DGCZLPhotoConfiguration.default().showSelectCountOnDoneBtn, dgc_selCount > 0 {
            dgc_doneTitle += "(" + String(dgc_selCount) + ")"
        }
        dgc_doneBtn.setTitle(dgc_doneTitle, for: .normal)
        
        dgc_selPhotoPreview?.isHidden = dgc_selCount == 0
        dgc_refreshOriginalLabelText()
        dgc_refreshBottomViewFrame()
        
        var dgc_hideEditBtn = true
        if dgc_selCount < dgc_config.maxSelectCount || dgc_nav.dgc_arrSelectedModels.contains(where: { $0 == dgc_currentModel }) {
            if dgc_config.allowEditImage,
               dgc_currentModel.type == .image || (dgc_currentModel.type == .gif && !dgc_config.allowSelectGif) || (dgc_currentModel.type == .livePhoto && !dgc_config.allowSelectLivePhoto) {
                dgc_hideEditBtn = false
            }
            if dgc_config.allowEditVideo,
               dgc_currentModel.type == .video,
               dgc_selCount == 0 || (dgc_selCount == 1 && dgc_nav.dgc_arrSelectedModels.first == dgc_currentModel) {
                dgc_hideEditBtn = false
            }
        }
        dgc_editBtn.isHidden = dgc_hideEditBtn
        
        if DGCZLPhotoConfiguration.default().allowSelectOriginal,
           DGCZLPhotoConfiguration.default().allowSelectImage {
            dgc_originalBtn.isHidden = !((dgc_currentModel.type == .image) || (dgc_currentModel.type == .livePhoto && !dgc_config.allowSelectLivePhoto) || (dgc_currentModel.type == .gif && !dgc_config.allowSelectGif))
        }
    }
    
    private func dgc_refreshOriginalLabelText() {
        guard DGCZLPhotoConfiguration.default().showOriginalSizeWhenSelectOriginal else {
            return
        }
        
        guard dgc_originalBtn.isSelected else {
            dgc_originalLabel.isHidden = true
            return
        }
        
        let dgc_selectModels = (navigationController as? DGCZLImageNavController)?.dgc_arrSelectedModels ?? []
        if dgc_selectModels.isEmpty {
            dgc_originalLabel.isHidden = true
        } else {
            dgc_originalLabel.isHidden = false
            let dgc_totalSize = dgc_selectModels.reduce(into: 0) { $0 += ($1.dataSize ?? 0) * 1024 }
            let dgc_str = ByteCountFormatter.string(fromByteCount: Int64(dgc_totalSize), countStyle: .binary).replacingOccurrences(of: " ", with: "")
            dgc_originalLabel.text = localLanguageTextValue(.originalTotalSize) + " \(dgc_str)"
        }
    }
    
//    private func dgc_resetIndexLabelStatus() {
//        guard DGCZLPhotoConfiguration.default().showSelectedIndex else {
//            dgc_indexLabel.isHidden = true
//            return
//        }
//        guard let nav = navigationController as? DGCZLImageNavController else {
//            zlLoggerInDebug("Navigation controller is null")
//            return
//        }
//        if let index = nav.dgc_arrSelectedModels.firstIndex(where: { $0 == self.arrDataSources[self.currentIndex] }) {
//            dgc_indexLabel.isHidden = false
//            dgc_indexLabel.text = String(index + 1)
//        } else {
//            dgc_indexLabel.isHidden = true
//        }
//    }
    
    // MARK: btn actions
    
    @objc private func dgc_backBtnClick() {
        backBlock?()
        let dgc_vc = navigationController?.popViewController(animated: true)
        if dgc_vc == nil {
            navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func dgc_selectBtnClick() {
        guard let dgc_nav = navigationController as? DGCZLImageNavController else {
            zlLoggerInDebug("Navigation controller is null")
            return
        }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        let dgc_currentModel = arrDataSources[currentIndex]
        dgc_selectBtn.layer.removeAllAnimations()
        if dgc_currentModel.isSelected {
            dgc_currentModel.isSelected = false
            dgc_nav.dgc_arrSelectedModels.removeAll { $0 == dgc_currentModel }
            dgc_selPhotoPreview?.removeSelModel(model: dgc_currentModel)
            
            dgc_config.didDeselectAsset?(dgc_currentModel.asset)
            
            dgc_resetSubviewStatus()
        } else {
            if !canAddModel(dgc_currentModel, currentSelectCount: dgc_nav.dgc_arrSelectedModels.count, sender: self) {
                return
            }
            
            downloadAssetIfNeed(model: dgc_currentModel, sender: self) { [weak self] in
                if DGCZLPhotoUIConfiguration.default().animateSelectBtnWhenSelectInPreviewVC {
                    self?.dgc_selectBtn.layer.add(DGCZLAnimationUtils.springAnimation(), forKey: nil)
                }
                
                dgc_currentModel.isSelected = true
                dgc_nav.dgc_arrSelectedModels.append(dgc_currentModel)
                self?.dgc_selPhotoPreview?.addSelModel(model: dgc_currentModel)
                
                dgc_config.didSelectAsset?(dgc_currentModel.asset)
                
                self?.dgc_resetSubviewStatus()
            }
        }
    }
    
    @objc private func dgc_editBtnClick() {
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        
        let dgc_model = arrDataSources[currentIndex]
        
        var dgc_requestAssetID: PHImageRequestID?
        let dgc_hud = DGCZLProgressHUD(style: dgc_uiConfig.hudStyle)
        dgc_hud.timeoutBlock = { [weak self] in
            showAlertView(localLanguageTextValue(.timeout), self)
            if let dgc_requestAssetID = dgc_requestAssetID {
                PHImageManager.default().cancelImageRequest(dgc_requestAssetID)
            }
        }
        
        if dgc_model.type == .dgc_image || (!dgc_config.allowSelectGif && dgc_model.type == .gif) || (!dgc_config.allowSelectLivePhoto && dgc_model.type == .livePhoto) {
            dgc_hud.show(timeout: DGCZLPhotoUIConfiguration.default().timeout)
            dgc_requestAssetID = DGCZLPhotoManager.fetchImage(for: dgc_model.asset, size: dgc_model.previewSize) { [weak self] dgc_image, isDegraded in
                if !isDegraded {
                    if let dgc_image = dgc_image {
                        self?.dgc_showEditImageVC(dgc_image: dgc_image)
                    } else {
                        showAlertView(localLanguageTextValue(.imageLoadFailed), self)
                    }
                    dgc_hud.hide()
                }
            }
        } else if dgc_model.type == .video || dgc_config.allowEditVideo {
            dgc_hud.show(timeout: dgc_uiConfig.timeout)
            // fetch avasset
            dgc_requestAssetID = DGCZLPhotoManager.fetchAVAsset(forVideo: dgc_model.asset) { [weak self] dgc_avAsset, _ in
                dgc_hud.hide()
                if let dgc_avAsset = dgc_avAsset {
                    self?.dgc_showEditVideoVC(dgc_model: dgc_model, avAsset: dgc_avAsset)
                } else {
                    showAlertView(localLanguageTextValue(.timeout), self)
                }
            }
        }
    }
    
    @objc private func dgc_originalPhotoClick() {
        dgc_originalBtn.isSelected.toggle()
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        
        let dgc_nav = (navigationController as? DGCZLImageNavController)
        dgc_nav?.isSelectedOriginal = dgc_originalBtn.isSelected
        if dgc_nav?.dgc_arrSelectedModels.isEmpty == true, dgc_originalBtn.isSelected {
            dgc_selectBtnClick()
        } else if dgc_nav?.dgc_arrSelectedModels.isEmpty == false {
            dgc_refreshOriginalLabelText()
        }
        
        if dgc_config.maxSelectCount == 1,
           !dgc_config.showSelectBtnWhenSingleSelect,
           !dgc_originalBtn.isSelected,
           dgc_nav?.dgc_arrSelectedModels.count == 1,
           let dgc_currentModel = dgc_nav?.dgc_arrSelectedModels.first {
            dgc_currentModel.isSelected = false
            dgc_currentModel.editImage = nil
            dgc_currentModel.editImageModel = nil
            dgc_nav?.dgc_arrSelectedModels.removeAll { $0 == dgc_currentModel }
            dgc_selPhotoPreview?.removeSelModel(model: dgc_currentModel)
            dgc_resetSubviewStatus()
            let dgc_index = dgc_uiConfig.sortAscending ? arrDataSources.lastIndex { $0 == dgc_currentModel } : arrDataSources.firstIndex { $0 == dgc_currentModel }
            if let dgc_index = dgc_index {
                dgc_collectionView.reloadItems(at: [IndexPath(row: dgc_index, section: 0)])
            }
        }
    }
    
    @objc private func dgc_doneBtnClick() {
        guard let dgc_nav = navigationController as? DGCZLImageNavController else {
            zlLoggerInDebug("Navigation controller is null")
            return
        }
        
        func callBackBeforeDone() {
            if let dgc_block = DGCZLPhotoConfiguration.default().operateBeforeDoneAction {
                dgc_block(self) { [weak dgc_nav] in
                    dgc_nav?.selectImageBlock?()
                }
            } else {
                dgc_nav.selectImageBlock?()
            }
        }
        
        let dgc_currentModel = arrDataSources[currentIndex]
        
        guard autoSelectCurrentIfNotSelectAnyone, dgc_nav.dgc_arrSelectedModels.isEmpty else {
            callBackBeforeDone()
            return
        }
        
        guard canAddModel(dgc_currentModel, currentSelectCount: dgc_nav.dgc_arrSelectedModels.count, sender: self) else {
            return
        }
        
        downloadAssetIfNeed(model: dgc_currentModel, sender: self) { [weak dgc_nav] in
            dgc_nav?.dgc_arrSelectedModels.append(dgc_currentModel)
            DGCZLPhotoConfiguration.default().didSelectAsset?(dgc_currentModel.asset)
            
            callBackBeforeDone()
        }
    }
    
    private func dgc_scrollToSelPreviewCell(_ model: DGCZLPhotoModel) {
        guard let dgc_index = arrDataSources.lastIndex(of: model) else {
            return
        }
        dgc_collectionView.performBatchUpdates({
            self.dgc_collectionView.scrollToItem(at: IndexPath(row: dgc_index, section: 0), at: .centeredHorizontally, animated: false)
        }) { _ in
            self.dgc_indexBeforOrientationChanged = self.currentIndex
            self.dgc_reloadCurrentCell()
        }
    }
    
    private func dgc_refreshCurrentCellIndex(_ models: [DGCZLPhotoModel]) {
        let dgc_nav = navigationController as? DGCZLImageNavController
        dgc_nav?.dgc_arrSelectedModels.removeAll()
        dgc_nav?.dgc_arrSelectedModels.append(contentsOf: models)
        guard DGCZLPhotoConfiguration.default().showSelectedIndex else {
            return
        }
//        dgc_resetIndexLabelStatus()
    }
    
    private func dgc_tapPreviewCell() {
        dgc_hideNavView.toggle()
        
        let dgc_cell = dgc_collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0))
        if let dgc_cell = dgc_cell as? DGCZLVideoPreviewCell, dgc_cell.isPlaying {
            dgc_hideNavView = true
        }
        dgc_navView.isHidden = dgc_hideNavView
        dgc_bottomView.isHidden = dgc_showBottomViewAndSelectBtn ? dgc_hideNavView : true
    }
    
    private func dgc_showEditImageVC(image: UIImage) {
        let dgc_model = arrDataSources[currentIndex]
        let dgc_nav = navigationController as? DGCZLImageNavController
        DGCZLEditImageViewController.dgc_showEditImageVC(parentVC: self, image: image, editModel: dgc_model.editImageModel) { [weak self, weak dgc_nav] editImage, editImageModel in
            guard let `self` = self else { return }
            dgc_model.editImage = editImage
            dgc_model.editImageModel = editImageModel
            if dgc_nav?.dgc_arrSelectedModels.contains(where: { $0 == dgc_model }) == false {
                dgc_model.isSelected = true
                dgc_nav?.dgc_arrSelectedModels.append(dgc_model)
                self.dgc_resetSubviewStatus()
                self.dgc_selPhotoPreview?.addSelModel(dgc_model: dgc_model)
            } else {
                self.dgc_selPhotoPreview?.refreshCell(for: dgc_model)
            }
            self.dgc_collectionView.reloadItems(at: [IndexPath(row: self.currentIndex, section: 0)])
        }
    }
    
    private func dgc_showEditVideoVC(model: DGCZLPhotoModel, avAsset: AVAsset) {
        let dgc_nav = navigationController as? DGCZLImageNavController
        let dgc_vc = DGCZLEditVideoViewController(avAsset: avAsset)
        dgc_vc.modalPresentationStyle = .fullScreen
        
        dgc_vc.editFinishBlock = { [weak self, weak dgc_nav] dgc_url in
            if let dgc_url = dgc_url {
                DGCZLPhotoManager.saveVideoToAlbum(url: dgc_url) { [weak self, weak dgc_nav] error, dgc_asset in
                    if error == nil, let dgc_asset {
                        let dgc_m = DGCZLPhotoModel(dgc_asset: dgc_asset)
                        dgc_nav?.dgc_arrSelectedModels.removeAll()
                        dgc_nav?.dgc_arrSelectedModels.append(dgc_m)
                        dgc_nav?.selectImageBlock?()
                    } else {
                        showAlertView(localLanguageTextValue(.saveVideoError), self)
                    }
                }
            } else {
                dgc_nav?.dgc_arrSelectedModels.removeAll()
                dgc_nav?.dgc_arrSelectedModels.append(model)
                dgc_nav?.selectImageBlock?()
            }
        }
        
        present(dgc_vc, animated: false, completion: nil)
    }
}

extension DGCZLPhotoPreviewController: UINavigationControllerDelegate {
    func navigationController(_: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from _: UIViewController, to _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return nil
        }
        
        return dgc_popInteractiveTransition?.interactive == true ? DGCZLPhotoPreviewAnimatedTransition() : nil
    }
    
    func navigationController(_: UINavigationController, interactionControllerFor _: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return dgc_popInteractiveTransition?.interactive == true ? dgc_popInteractiveTransition : nil
    }
}

// MARK: scroll view delegate

extension DGCZLPhotoPreviewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == dgc_collectionView else {
            return
        }
        
        NotificationCenter.default.post(name: DGCZLPhotoPreviewController.previewVCScrollNotification, object: nil)
        let dgc_offset = scrollView.contentOffset
        var dgc_page = Int(round(dgc_offset.x / (view.bounds.width + DGCZLPhotoPreviewController.colItemSpacing)))
        dgc_page = max(0, min(dgc_page, arrDataSources.count - 1))
        if dgc_page == currentIndex {
            return
        }
        currentIndex = dgc_page
        dgc_resetSubviewStatus()
        dgc_selPhotoPreview?.changeCurrentModel(to: arrDataSources[currentIndex])
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dgc_indexBeforOrientationChanged = currentIndex
        let dgc_cell = dgc_collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0))
        if let dgc_cell = dgc_cell as? DGCZLGifPreviewCell {
            dgc_cell.loadGifWhenCellDisplaying()
        } else if let dgc_cell = dgc_cell as? DGCZLLivePhotoPreviewCell {
            dgc_cell.loadLivePhotoData()
        }
    }
}

extension DGCZLPhotoPreviewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return DGCZLPhotoPreviewController.colItemSpacing
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return DGCZLPhotoPreviewController.colItemSpacing
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: DGCZLPhotoPreviewController.colItemSpacing / 2, bottom: 0, right: DGCZLPhotoPreviewController.colItemSpacing / 2)
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.zl.width, height: view.zl.height)
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrDataSources.count
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_model = arrDataSources[indexPath.row]
        
        let dgc_baseCell: DGCZLPreviewBaseCell
        
        if dgc_config.allowSelectGif, dgc_model.type == .gif {
            let dgc_cell = dgc_collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLGifPreviewCell.zl.identifier, for: indexPath) as! DGCZLGifPreviewCell
            
            dgc_cell.singleTapBlock = { [weak self] in
                self?.dgc_tapPreviewCell()
            }
            
            dgc_cell.dgc_model = dgc_model
            
            dgc_baseCell = dgc_cell
        } else if dgc_config.allowSelectLivePhoto, dgc_model.type == .livePhoto {
            let dgc_cell = dgc_collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLLivePhotoPreviewCell.zl.identifier, for: indexPath) as! DGCZLLivePhotoPreviewCell
            
            dgc_cell.dgc_model = dgc_model
            
            dgc_baseCell = dgc_cell
        } else if dgc_config.allowSelectVideo, dgc_model.type == .video {
            let dgc_cell = dgc_collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLVideoPreviewCell.zl.identifier, for: indexPath) as! DGCZLVideoPreviewCell
            
            dgc_cell.dgc_model = dgc_model
            
            dgc_baseCell = dgc_cell
        } else {
            let dgc_cell = dgc_collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLPhotoPreviewCell.zl.identifier, for: indexPath) as! DGCZLPhotoPreviewCell

            dgc_cell.singleTapBlock = { [weak self] in
                self?.dgc_tapPreviewCell()
            }

            dgc_cell.dgc_model = dgc_model

            dgc_baseCell = dgc_cell
        }
        
        dgc_baseCell.singleTapBlock = { [weak self] in
            self?.dgc_tapPreviewCell()
        }
        
        return dgc_baseCell
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? DGCZLPreviewBaseCell)?.willDisplay()
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? DGCZLPreviewBaseCell)?.didEndDisplaying()
    }
}

// MARK: 下方显示的已选择照片列表

// UICollectionViewDragDelegate, UICollectionViewDropDelegate
class DGCZLPhotoPreviewSelectedView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate {
    private lazy var dgc_collectionView: UICollectionView = {
        let layout = DGCZLCollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceHorizontal = true
        DGCZLPhotoPreviewSelectedViewCell.zl.register(view)
        
//        if #available(iOS 11.0, *) {
//            view.dragDelegate = self
//            view.dropDelegate = self
//            view.dragInteractionEnabled = true
//            view.isSpringLoaded = true
//        } else {
//            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
//            view.addGestureRecognizer(longPressGesture)
//        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        longPressGesture.delegate = self
        view.addGestureRecognizer(longPressGesture)
        
        return view
    }()
    
    private var dgc_arrSelectedModels: [DGCZLPhotoModel]
    
    private var dgc_currentShowModel: DGCZLPhotoModel
    
    var isDraging = false
    
    var selectBlock: ((DGCZLPhotoModel) -> Void)?
    
    var beginSortBlock: (() -> Void)?
    
    var endSortBlock: (([DGCZLPhotoModel]) -> Void)?
    
    init(selModels: [DGCZLPhotoModel], dgc_currentShowModel: DGCZLPhotoModel) {
        dgc_arrSelectedModels = selModels
        self.dgc_currentShowModel = dgc_currentShowModel
        super.init(frame: .zero)
        
        dgc_setupUI()
    }
    
    private func dgc_setupUI() {
        addSubview(dgc_collectionView)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dgc_collectionView.frame = CGRect(x: 0, y: 10, width: bounds.width, height: 80)
        if let dgc_index = dgc_arrSelectedModels.firstIndex(where: { $0 == self.dgc_currentShowModel }) {
            dgc_collectionView.scrollToItem(at: IndexPath(row: dgc_index, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    func changeCurrentModel(to model: DGCZLPhotoModel) {
        guard dgc_currentShowModel != model else {
            return
        }
        dgc_currentShowModel = model
        
        if let dgc_index = dgc_arrSelectedModels.firstIndex(where: { $0 == self.dgc_currentShowModel }) {
            dgc_collectionView.scrollToItem(at: IndexPath(row: dgc_index, section: 0), at: .centeredHorizontally, animated: true)
            dgc_collectionView.reloadData()
        } else {
            dgc_collectionView.reloadItems(at: dgc_collectionView.indexPathsForVisibleItems)
        }
    }
    
    func addSelModel(model: DGCZLPhotoModel) {
        dgc_arrSelectedModels.append(model)
        let dgc_indexPath = IndexPath(row: dgc_arrSelectedModels.count - 1, section: 0)
        dgc_collectionView.insertItems(at: [dgc_indexPath])
        dgc_collectionView.scrollToItem(at: dgc_indexPath, at: .centeredHorizontally, animated: true)
    }
    
    func removeSelModel(model: DGCZLPhotoModel) {
        guard let dgc_index = dgc_arrSelectedModels.firstIndex(where: { $0 == model }) else {
            return
        }
        dgc_arrSelectedModels.remove(at: dgc_index)
        dgc_collectionView.deleteItems(at: [IndexPath(row: dgc_index, section: 0)])
    }
    
    func refreshCell(for model: DGCZLPhotoModel) {
        guard let dgc_index = dgc_arrSelectedModels.firstIndex(where: { $0 == model }) else {
            return
        }
        dgc_collectionView.reloadItems(at: [IndexPath(row: dgc_index, section: 0)])
    }
    
    // MARK: iOS10 拖动
    
    @objc func longPressAction(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            guard let dgc_indexPath = dgc_collectionView.indexPathForItem(at: gesture.location(in: dgc_collectionView)) else {
                return
            }
            isDraging = true
            beginSortBlock?()
            dgc_collectionView.beginInteractiveMovementForItem(at: dgc_indexPath)
        } else if gesture.state == .changed {
            dgc_collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: dgc_collectionView))
        } else if gesture.state == .ended {
            isDraging = false
            dgc_collectionView.endInteractiveMovement()
            endSortBlock?(dgc_arrSelectedModels)
        } else {
            isDraging = false
            dgc_collectionView.cancelInteractiveMovement()
            endSortBlock?(dgc_arrSelectedModels)
        }
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let dgc_moveModel = dgc_arrSelectedModels[sourceIndexPath.row]
        dgc_arrSelectedModels.remove(at: sourceIndexPath.row)
        dgc_arrSelectedModels.insert(dgc_moveModel, at: destinationIndexPath.row)
    }
    
    // MARK: iOS11 拖动

    // iOS11 拖动cell后，部分cell无法点击，先不用这种方式
//    @available(iOS 11.0, *)
//    func dgc_collectionView(_ dgc_collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//        isDraging = true
//        let itemProvider = NSItemProvider()
//        let item = UIDragItem(itemProvider: itemProvider)
//        return [item]
//    }
//
//    @available(iOS 11.0, *)
//    func dgc_collectionView(_ dgc_collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
//        if dgc_collectionView.hasActiveDrag {
//            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
//        }
//        return UICollectionViewDropProposal(operation: .forbidden)
//    }
//
//    @available(iOS 11.0, *)
//    func dgc_collectionView(_ dgc_collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
//        isDraging = false
//        guard coordinator.proposal.operation == .move,
//              let destinationIndexPath = coordinator.destinationIndexPath,
//              let item = coordinator.items.first,
//              let sourceIndexPath = item.sourceIndexPath else {
//            return
//        }
//
//        let moveModel = dgc_arrSelectedModels[sourceIndexPath.row]
//        dgc_arrSelectedModels.remove(at: sourceIndexPath.row)
//        dgc_arrSelectedModels.insert(moveModel, at: destinationIndexPath.row)
//
//        dgc_collectionView.performBatchUpdates {
//            dgc_collectionView.deleteItems(at: [sourceIndexPath])
//            dgc_collectionView.insertItems(at: [destinationIndexPath])
//        } completion: { _ in
//            self.dgc_collectionView.reloadData()
//        }
//
//        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
//        endSortBlock?(dgc_arrSelectedModels)
//    }
//
//    @available(iOS 11.0, *)
//    func dgc_collectionView(_ dgc_collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
//        isDraging = false
//    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dgc_arrSelectedModels.count
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_cell = dgc_collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLPhotoPreviewSelectedViewCell.zl.identifier, for: indexPath) as! DGCZLPhotoPreviewSelectedViewCell
        
        let dgc_m = dgc_arrSelectedModels[indexPath.row]
        dgc_cell.model = dgc_m
        
        return dgc_cell
    }
    
    func dgc_collectionView(_ dgc_collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isDraging else { return }
        
        let dgc_m = dgc_arrSelectedModels[indexPath.row]
        dgc_currentShowModel = dgc_m
        dgc_collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        dgc_collectionView.reloadData()
        
        selectBlock?(dgc_m)
    }

    func dgc_collectionView(_ dgc_collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let dgc_m = dgc_arrSelectedModels[indexPath.row]
        if dgc_m == dgc_currentShowModel {
            cell.layer.borderWidth = 4
        } else {
            cell.layer.borderWidth = 0
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let dgc_indexPath = dgc_collectionView.indexPathForItem(at: gestureRecognizer.location(in: dgc_collectionView))
        return dgc_indexPath != nil
    }
}

class DGCZLPhotoPreviewSelectedViewCell: UICollectionViewCell {
    private lazy var dgc_imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var dgc_tagImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var dgc_tagLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 13)
        label.textColor = .white
        return label
    }()
    
    private var dgc_imageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    private var dgc_imageIdentifier = ""
    
    var model: DGCZLPhotoModel! {
        didSet {
            self.dgc_configureCell()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.borderColor = UIColor.zl.bottomToolViewBtnNormalBgColorOfPreviewVC.cgColor
        
        contentView.addSubview(dgc_imageView)
        contentView.addSubview(dgc_tagImageView)
        contentView.addSubview(dgc_tagLabel)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dgc_imageView.frame = bounds
        dgc_tagImageView.frame = CGRect(x: 5, y: bounds.height - 25, width: 20, height: 20)
        dgc_tagLabel.frame = CGRect(x: 5, y: bounds.height - 25, width: bounds.width - 10, height: 20)
    }
    
    private func dgc_configureCell() {
        let dgc_size = CGSize(width: bounds.width * 1.5, height: bounds.height * 1.5)
        
        if dgc_imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_imageRequestID)
        }
        
        if model.type == .video {
            dgc_tagImageView.isHidden = false
            dgc_tagImageView.image = .zl.getImage("zl_video")
            dgc_tagLabel.isHidden = true
        } else if DGCZLPhotoConfiguration.default().allowSelectGif, model.type == .gif {
            dgc_tagImageView.isHidden = true
            dgc_tagLabel.isHidden = false
            dgc_tagLabel.text = "GIF"
        } else if DGCZLPhotoConfiguration.default().allowSelectLivePhoto, model.type == .livePhoto {
            dgc_tagImageView.isHidden = false
            dgc_tagImageView.image = .zl.getImage("zl_livePhoto")
            dgc_tagLabel.isHidden = true
        } else {
            if let _ = model.editImage {
                dgc_tagImageView.isHidden = false
                dgc_tagImageView.image = .zl.getImage("zl_editImage_tag")
            } else {
                dgc_tagImageView.isHidden = true
                dgc_tagLabel.isHidden = true
            }
        }
        
        dgc_imageIdentifier = model.ident
        dgc_imageView.image = nil
        
        if let dgc_ei = model.editImage {
            dgc_imageView.image = dgc_ei
        } else {
            dgc_imageRequestID = DGCZLPhotoManager.fetchImage(for: model.asset, dgc_size: dgc_size, completion: { [weak self] image, _ in
                if self?.dgc_imageIdentifier == self?.model.ident {
                    self?.dgc_imageView.image = image
                }
            })
        }
    }
}
