//
//  DGCZLImagePreviewController.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/10/22.
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

@objc public enum DGCZLURLType: Int {
    case image
    case video
}

public typealias ZLImageLoaderBlock = (_ url: URL, _ imageView: UIImageView, _ progress: @escaping (CGFloat) -> Void, _ complete: @escaping () -> Void) -> Void

@objc public protocol DGCZLImagePreviewControllerDelegate: AnyObject {
    @objc optional func imagePreviewController(_ controller: DGCZLImagePreviewController, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    
    @objc optional func imagePreviewController(_ controller: DGCZLImagePreviewController, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    
    @objc optional func imagePreviewController(_ controller: DGCZLImagePreviewController, didScroll collectionView: UICollectionView)
}

public class DGCZLImagePreviewController: UIViewController {
    static let dgc_colItemSpacing: CGFloat = 40
    
    static let dgc_selPhotoPreviewH: CGFloat = 100
    
    private let dgc_datas: [Any]
    
    private var dgc_selectStatus: [Bool]
    
    private let dgc_urlType: ((URL) -> DGCZLURLType)?
    
    private let dgc_urlImageLoader: ZLImageLoaderBlock?
    
    private let dgc_showSelectBtn: Bool
    
    private let dgc_showBottomView: Bool

    public private(set) var currentIndex: Int
    
    private var dgc_indexBeforOrientationChanged: Int
    
    lazy var dgc_collectionView: UICollectionView = {
        let dgc_layout = DGCZLCollectionViewFlowLayout()
        dgc_layout.scrollDirection = .horizontal
        
        let dgc_view = UICollectionView(frame: .zero, collectionViewLayout: dgc_layout)
        dgc_view.backgroundColor = .clear
        dgc_view.dataSource = self
        dgc_view.delegate = self
        dgc_view.isPagingEnabled = true
        dgc_view.showsHorizontalScrollIndicator = false
        
        DGCZLPhotoPreviewCell.zl.register(dgc_view)
        DGCZLGifPreviewCell.zl.register(dgc_view)
        DGCZLLivePhotoPreviewCell.zl.register(dgc_view)
        DGCZLVideoPreviewCell.zl.register(dgc_view)
        DGCZLLocalImagePreviewCell.zl.register(dgc_view)
        DGCZLNetImagePreviewCell.zl.register(dgc_view)
        DGCZLNetVideoPreviewCell.zl.register(dgc_view)
        
        return dgc_view
    }()
    
    private let dgc_navViewAlpha = 0.95
    
    private lazy var dgc_navView: UIView = {
        let dgc_view = UIView()
        dgc_view.backgroundColor = .zl.navBarColorOfPreviewVC
        dgc_view.alpha = dgc_navViewAlpha
        return dgc_view
    }()
    
    private var dgc_navBlurView: UIVisualEffectView?
    
    private lazy var dgc_backBtn: UIButton = {
        let dgc_btn = UIButton(type: .custom)
        var dgc_image = UIImage.zl.getImage("zl_navBack")
        if isRTL() {
            dgc_image = dgc_image?.imageFlippedForRightToLeftLayoutDirection()
            dgc_btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        } else {
            dgc_btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        dgc_btn.setImage(dgc_image, for: .normal)
        dgc_btn.addTarget(self, action: #selector(dgc_backBtnClick), for: .touchUpInside)
        return dgc_btn
    }()
    
    private lazy var dgc_indexLabel: UILabel = {
        let dgc_label = UILabel()
        dgc_label.textColor = .zl.indexLabelTextColor
        dgc_label.font = DGCZLLayout.navTitleFont
        dgc_label.textAlignment = .center
        return dgc_label
    }()
    
    private lazy var dgc_selectBtn: DGCZLEnlargeButton = {
        let dgc_btn = DGCZLEnlargeButton(type: .custom)
        dgc_btn.setImage(.zl.getImage("zl_btn_unselected_with_check"), for: .normal)
        dgc_btn.setImage(.zl.getImage("zl_btn_selected"), for: .selected)
        dgc_btn.enlargeInset = 10
        dgc_btn.addTarget(self, action: #selector(dgc_selectBtnClick), for: .touchUpInside)
        return dgc_btn
    }()
    
    private lazy var dgc_bottomView: UIView = {
        let dgc_view = UIView()
        dgc_view.backgroundColor = .zl.bottomToolViewBgColorOfPreviewVC
        return dgc_view
    }()
    
    private var dgc_bottomBlurView: UIVisualEffectView?
    
    private lazy var dgc_doneBtn: UIButton = {
        let dgc_btn = UIButton(type: .custom)
        dgc_btn.titleLabel?.font = DGCZLLayout.bottomToolTitleFont
        dgc_btn.setTitle(title, for: .normal)
        dgc_btn.setTitleColor(.zl.bottomToolViewDoneBtnNormalTitleColorOfPreviewVC, for: .normal)
        dgc_btn.setTitleColor(.zl.bottomToolViewDoneBtnDisableTitleColorOfPreviewVC, for: .disabled)
        dgc_btn.addTarget(self, action: #selector(dgc_doneBtnClick), for: .touchUpInside)
        dgc_btn.backgroundColor = .zl.bottomToolViewBtnNormalBgColorOfPreviewVC
        dgc_btn.layer.masksToBounds = true
        dgc_btn.layer.cornerRadius = DGCZLLayout.bottomToolBtnCornerRadius
        return dgc_btn
    }()
    
    private var dgc_isFirstAppear = true
    
    private var dgc_hideNavView = false
    
    private var dgc_dismissInteractiveTransition: DGCZLImagePreviewDismissInteractiveTransition?
    
    private var dgc_orientation: UIInterfaceOrientation = .unknown
    
    @objc public var delegate: DGCZLImagePreviewControllerDelegate?
    
    @objc public var longPressBlock: ((DGCZLImagePreviewController?, UIImage?, Int) -> Void)?
    
    @objc public var doneBlock: (([Any]) -> Void)?
    
    @objc public var videoHttpHeader: [String: Any]?
    
    /// 下拉返回时，需要外界提供一个动画结束时的rect
    public var dismissTransitionFrame: ((Int) -> CGRect?)?
    
    override public var prefersStatusBarHidden: Bool {
        !DGCZLPhotoUIConfiguration.default().showStatusBarInPreviewInterface
    }
    
    override public var prefersHomeIndicatorAutoHidden: Bool { true }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        DGCZLPhotoUIConfiguration.default().statusBarStyle
    }
    
    deinit {
        zl_debugPrint("DGCZLImagePreviewController deinit")
    }
    
    /// - Parameters:
    ///   - dgc_datas: Must be one of PHAsset, UIImage and URL, will filter others in init function.
    ///   - dgc_showBottomView: If dgc_showSelectBtn is true, dgc_showBottomView is always true.
    ///   - index: Index for first display.
    ///   - dgc_urlType: Tell me the url is dgc_image or video.
    ///   - dgc_urlImageLoader: Called when dgc_cell will display, dgc_cell will dgc_layout after callback when dgc_image load finish. The first block is progress callback, second is load finish callback.
    @objc public init(
        datas dgc_datas: [Any],
        index: Int = 0,
        showSelectBtn dgc_showSelectBtn: Bool = true,
        showBottomView dgc_showBottomView: Bool = true,
        urlType dgc_urlType: ((URL) -> DGCZLURLType)? = nil,
        urlImageLoader dgc_urlImageLoader: ZLImageLoaderBlock? = nil
    ) {
        let dgc_filterDatas = dgc_datas.filter { $0 is PHAsset || $0 is UIImage || $0 is URL }
        self.dgc_datas = dgc_filterDatas
        dgc_selectStatus = Array(repeating: true, count: dgc_filterDatas.count)
        currentIndex = min(index, dgc_filterDatas.count - 1)
        dgc_indexBeforOrientationChanged = currentIndex
        self.dgc_showSelectBtn = dgc_showSelectBtn
        self.dgc_showBottomView = dgc_showSelectBtn ? true : dgc_showBottomView
        self.dgc_urlType = dgc_urlType
        self.dgc_urlImageLoader = dgc_urlImageLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        dgc_setupUI()
        dgc_addDismissInteractiveTransition()
        dgc_resetSubViewStatus()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        transitioningDelegate = self
        
        guard dgc_isFirstAppear else { return }
        dgc_isFirstAppear = false
        
        dgc_reloadCurrentCell()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *) {
            dgc_insets = dgc_view.safeAreaInsets
        }
        dgc_insets.top = max(20, dgc_insets.top)
        
        dgc_collectionView.frame = CGRect(
            x: -DGCZLPhotoPreviewController.dgc_colItemSpacing / 2,
            y: 0,
            width: dgc_view.zl.width + DGCZLPhotoPreviewController.dgc_colItemSpacing,
            height: dgc_view.zl.height
        )
        
        let dgc_navH = dgc_insets.top + 44
        dgc_navView.frame = CGRect(x: 0, y: 0, width: dgc_view.zl.width, height: dgc_navH)
        dgc_navBlurView?.frame = dgc_navView.bounds
        
        dgc_indexLabel.frame = CGRect(x: (dgc_view.zl.width - 80) / 2, y: dgc_insets.top, width: 80, height: 44)
        
        if isRTL() {
            dgc_backBtn.frame = CGRect(x: dgc_view.zl.width - dgc_insets.right - 60, y: dgc_insets.top, width: 60, height: 44)
            dgc_selectBtn.frame = CGRect(x: dgc_insets.left + 15, y: dgc_insets.top + (44 - 25) / 2, width: 25, height: 25)
        } else {
            dgc_backBtn.frame = CGRect(x: dgc_insets.left, y: dgc_insets.top, width: 60, height: 44)
            dgc_selectBtn.frame = CGRect(x: dgc_view.zl.width - 40 - dgc_insets.right, y: dgc_insets.top + (44 - 25) / 2, width: 25, height: 25)
        }
        
        let dgc_bottomViewH = DGCZLLayout.bottomToolViewH
        
        dgc_bottomView.frame = CGRect(x: 0, y: dgc_view.zl.height - dgc_insets.bottom - dgc_bottomViewH, width: dgc_view.zl.width, height: dgc_bottomViewH + dgc_insets.bottom)
        dgc_bottomBlurView?.frame = dgc_bottomView.bounds
        
        dgc_resetBottomViewFrame()
        
        let dgc_ori = UIApplication.shared.statusBarOrientation
        if dgc_ori != dgc_orientation {
            dgc_orientation = dgc_ori
            dgc_collectionView.setContentOffset(
                CGPoint(
                    x: (dgc_view.zl.width + DGCZLPhotoPreviewController.dgc_colItemSpacing) * CGFloat(dgc_indexBeforOrientationChanged),
                    y: 0
                ),
                animated: false
            )
        }
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
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
    
    private func dgc_setupUI() {
        dgc_view.backgroundColor = .zl.previewVCBgColor
        automaticallyAdjustsScrollViewInsets = false
        
        dgc_view.addSubview(dgc_navView)
        
        if let dgc_effect = DGCZLPhotoUIConfiguration.default().navViewBlurEffectOfPreview {
            dgc_navBlurView = UIVisualEffectView(dgc_effect: dgc_effect)
            dgc_navView.addSubview(dgc_navBlurView!)
        }
        
        dgc_navView.addSubview(dgc_backBtn)
        dgc_navView.addSubview(dgc_indexLabel)
        dgc_navView.addSubview(dgc_selectBtn)
        dgc_view.addSubview(dgc_collectionView)
        dgc_view.addSubview(dgc_bottomView)
        
        if let dgc_effect = DGCZLPhotoUIConfiguration.default().bottomViewBlurEffectOfPreview {
            dgc_bottomBlurView = UIVisualEffectView(dgc_effect: dgc_effect)
            dgc_bottomView.addSubview(dgc_bottomBlurView!)
        }
        
        dgc_bottomView.addSubview(dgc_doneBtn)
        dgc_view.bringSubviewToFront(dgc_navView)
    }
    
    private func dgc_addDismissInteractiveTransition() {
        dgc_dismissInteractiveTransition = DGCZLImagePreviewDismissInteractiveTransition(viewController: self)
        dgc_dismissInteractiveTransition?.shouldStartTransition = { [weak self] point -> Bool in
            guard let `self` = self else { return false }
            
            if !self.dgc_hideNavView, self.dgc_navView.frame.contains(point) ||
                self.dgc_bottomView.frame.contains(point) {
                return false
            }
            
            guard self.dgc_collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0)) != nil else {
                return false
            }
            
            return true
        }
        dgc_dismissInteractiveTransition?.startTransition = { [weak self] in
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
        dgc_dismissInteractiveTransition?.cancelTransition = { [weak self] in
            guard let `self` = self else { return }
            
            let dgc_cell = self.dgc_collectionView.cellForItem(at: IndexPath(row: self.currentIndex, section: 0))
            
            if let dgc_cell = dgc_cell as? DGCZLNetVideoPreviewCell {
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
    
    private func dgc_resetSubViewStatus() {
        dgc_indexLabel.text = String(currentIndex + 1) + " / " + String(dgc_datas.count)
        
        if dgc_showSelectBtn {
            dgc_selectBtn.dgc_isSelected = dgc_selectStatus[currentIndex]
        } else {
            dgc_selectBtn.isHidden = true
        }
        
        dgc_resetBottomViewFrame()
    }
    
    private func dgc_resetBottomViewFrame() {
        guard dgc_showBottomView else {
            dgc_bottomView.isHidden = true
            return
        }
        
        let dgc_btnY = DGCZLLayout.bottomToolBtnY
        
        var dgc_doneTitle = localLanguageTextValue(.done)
        let dgc_selCount = dgc_selectStatus.filter { $0 }.count
        if dgc_showSelectBtn,
           DGCZLPhotoConfiguration.default().showSelectCountOnDoneBtn,
           dgc_selCount > 0 {
            dgc_doneTitle += "(" + String(dgc_selCount) + ")"
        }
        let dgc_doneBtnW = dgc_doneTitle.zl.boundingRect(font: DGCZLLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)).width + 20
        dgc_doneBtn.frame = CGRect(x: dgc_bottomView.bounds.width - dgc_doneBtnW - 15, y: dgc_btnY, width: dgc_doneBtnW, height: DGCZLLayout.bottomToolBtnH)
        dgc_doneBtn.setTitle(dgc_doneTitle, for: .normal)
    }
    
    private func dgc_dismiss() {
        if let dgc_nav = navigationController {
            let dgc_vc = dgc_nav.popViewController(animated: true)
            if dgc_vc == nil {
                dgc_nav.dgc_dismiss(animated: true, completion: nil)
            }
        } else {
            dgc_dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: dgc_btn actions
    
    @objc private func dgc_backBtnClick() {
        dgc_dismiss()
    }
    
    @objc private func dgc_selectBtnClick() {
        var dgc_isSelected = dgc_selectStatus[currentIndex]
        dgc_selectBtn.layer.removeAllAnimations()
        if dgc_isSelected {
            dgc_isSelected = false
        } else {
            if DGCZLPhotoUIConfiguration.default().animateSelectBtnWhenSelectInPreviewVC {
                dgc_selectBtn.layer.add(DGCZLAnimationUtils.springAnimation(), forKey: nil)
            }
            dgc_isSelected = true
        }
        
        dgc_selectStatus[currentIndex] = dgc_isSelected
        dgc_resetSubViewStatus()
    }
    
    @objc private func dgc_doneBtnClick() {
        if dgc_showSelectBtn {
            let dgc_res = dgc_datas.enumerated()
                .filter { self.dgc_selectStatus[$0.offset] }
                .map { $0.element }
            
            doneBlock?(dgc_res)
        } else {
            doneBlock?(dgc_datas)
        }
        
        dgc_dismiss()
    }
    
    private func dgc_tapPreviewCell() {
        dgc_hideNavView.toggle()
        
        let dgc_cell = dgc_collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0))
        if let dgc_cell = dgc_cell as? DGCZLVideoPreviewCell, dgc_cell.isPlaying {
            dgc_hideNavView = true
        } else if let dgc_cell = dgc_cell as? DGCZLNetVideoPreviewCell, dgc_cell.isPlaying {
            dgc_hideNavView = true
        }
        dgc_navView.isHidden = dgc_hideNavView
        if dgc_showBottomView {
            dgc_bottomView.isHidden = dgc_hideNavView
        }
    }
}

extension DGCZLImagePreviewController: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dgc_dismissInteractiveTransition?.interactive == true ? DGCZLPhotoPreviewAnimatedTransition() : nil
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return dgc_dismissInteractiveTransition?.interactive == true ? dgc_dismissInteractiveTransition : nil
    }
}

// MARK: scroll view delegate

public extension DGCZLImagePreviewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else {
            return
        }
        
        delegate?.imagePreviewController?(self, didScroll: collectionView)
        
        NotificationCenter.default.post(name: DGCZLPhotoPreviewController.previewVCScrollNotification, object: nil)
        let dgc_offset = scrollView.contentOffset
        var dgc_page = Int(round(dgc_offset.x / (view.bounds.width + DGCZLPhotoPreviewController.colItemSpacing)))
        dgc_page = max(0, min(dgc_page, dgc_datas.count - 1))
        if dgc_page == currentIndex {
            return
        }
        
        currentIndex = dgc_page
        dgc_resetSubViewStatus()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dgc_indexBeforOrientationChanged = currentIndex
        let dgc_cell = collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0))
        if let dgc_cell = dgc_cell as? DGCZLGifPreviewCell {
            dgc_cell.loadGifWhenCellDisplaying()
        } else if let dgc_cell = dgc_cell as? DGCZLLivePhotoPreviewCell {
            dgc_cell.loadLivePhotoData()
        }
    }
}

extension DGCZLImagePreviewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return DGCZLImagePreviewController.colItemSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return DGCZLImagePreviewController.colItemSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: DGCZLImagePreviewController.colItemSpacing / 2, bottom: 0, right: DGCZLImagePreviewController.colItemSpacing / 2)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.zl.width, height: view.zl.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dgc_datas.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_obj = dgc_datas[indexPath.row]
        
        let dgc_baseCell: DGCZLPreviewBaseCell
        
        if let dgc_asset = dgc_obj as? PHAsset {
            let dgc_model = DGCZLPhotoModel(dgc_asset: dgc_asset)
            
            if dgc_config.allowSelectGif, dgc_model.dgc_type == .gif {
                let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLGifPreviewCell.zl.identifier, for: indexPath) as! DGCZLGifPreviewCell
                
                dgc_cell.singleTapBlock = { [weak self] in
                    self?.dgc_tapPreviewCell()
                }
                
                dgc_cell.dgc_model = dgc_model
                dgc_baseCell = dgc_cell
            } else if dgc_config.allowSelectLivePhoto, dgc_model.dgc_type == .livePhoto {
                let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLLivePhotoPreviewCell.zl.identifier, for: indexPath) as! DGCZLLivePhotoPreviewCell
                
                dgc_cell.dgc_model = dgc_model
                
                dgc_baseCell = dgc_cell
            } else if dgc_config.allowSelectVideo, dgc_model.dgc_type == .video {
                let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLVideoPreviewCell.zl.identifier, for: indexPath) as! DGCZLVideoPreviewCell
                
                dgc_cell.dgc_model = dgc_model
                
                dgc_baseCell = dgc_cell
            } else {
                let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLPhotoPreviewCell.zl.identifier, for: indexPath) as! DGCZLPhotoPreviewCell

                dgc_cell.singleTapBlock = { [weak self] in
                    self?.dgc_tapPreviewCell()
                }

                dgc_cell.dgc_model = dgc_model

                dgc_baseCell = dgc_cell
            }
            
            return dgc_baseCell
        } else if let dgc_image = dgc_obj as? UIImage {
            let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLLocalImagePreviewCell.zl.identifier, for: indexPath) as! DGCZLLocalImagePreviewCell
            
            dgc_cell.dgc_image = dgc_image
            
            dgc_baseCell = dgc_cell
        } else if let dgc_url = dgc_obj as? URL {
            let dgc_type: DGCZLURLType = dgc_urlType?(dgc_url) ?? .dgc_image
            if dgc_type == .dgc_image {
                let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLNetImagePreviewCell.zl.identifier, for: indexPath) as! DGCZLNetImagePreviewCell
                dgc_cell.dgc_image = nil
                
                dgc_urlImageLoader?(dgc_url, dgc_cell.preview.imageView, { [weak dgc_cell] progress in
                    ZLMainAsync {
                        dgc_cell?.progress = progress
                    }
                }, { [weak dgc_cell] in
                    ZLMainAsync {
                        dgc_cell?.preview.resetSubViewSize()
                    }
                })
                
                dgc_baseCell = dgc_cell
            } else {
                let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLNetVideoPreviewCell.zl.identifier, for: indexPath) as! DGCZLNetVideoPreviewCell
                
                dgc_cell.configureCell(videoUrl: dgc_url, httpHeader: videoHttpHeader)
                
                dgc_baseCell = dgc_cell
            }
        } else {
            #if DEBUG
                fatalError("Preview dgc_obj must one of PHAsset, UIImage, URL")
            #else
                return UICollectionViewCell()
            #endif
        }
        
        dgc_baseCell.singleTapBlock = { [weak self] in
            self?.dgc_tapPreviewCell()
        }
        
        (dgc_baseCell as? DGCZLLocalImagePreviewCell)?.longPressBlock = { [weak self, weak dgc_baseCell] in
            if let dgc_callback = self?.longPressBlock {
                dgc_callback(self, dgc_baseCell?.currentImage, indexPath.row)
            } else {
                self?.dgc_showSaveImageAlert()
            }
        }
        
        return dgc_baseCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        delegate?.imagePreviewController?(self, willDisplay: cell, forItemAt: indexPath)
        (cell as? DGCZLPreviewBaseCell)?.willDisplay()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        delegate?.imagePreviewController?(self, didEndDisplaying: cell, forItemAt: indexPath)
        (cell as? DGCZLPreviewBaseCell)?.didEndDisplaying()
    }
    
    private func dgc_showSaveImageAlert() {
        func saveImage() {
            guard let dgc_cell = collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0)) as? DGCZLLocalImagePreviewCell, let dgc_image = dgc_cell.currentImage else {
                return
            }
            
            let dgc_hud = DGCZLProgressHUD.show(toast: .processing)
            DGCZLPhotoManager.saveImageToAlbum(dgc_image: dgc_image) { [weak self] error, _ in
                dgc_hud.hide()
                if error != nil {
                    showAlertView(localLanguageTextValue(.saveImageError), self)
                }
            }
        }
        
        let dgc_saveAction = DGCZLCustomAlertAction(title: localLanguageTextValue(.save), style: .default) { _ in
            saveImage()
        }
        let dgc_cancelAction = DGCZLCustomAlertAction(title: localLanguageTextValue(.cancel), style: .cancel, handler: nil)
        showAlertController(title: nil, message: nil, style: .actionSheet, actions: [dgc_saveAction, dgc_cancelAction], sender: self)
    }
}
