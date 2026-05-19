//
//  DGCZLPhotoPreviewSheet.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/11.
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

@available(*, deprecated, message: "Please use DGCZLPhotoPicker instead. The permission of DGCZLPhotoPreviewSheet will be changed to private later.")
public class DGCZLPhotoPreviewSheet: UIView {
    private enum DGCLayout {
        static let colH: CGFloat = 155
        
        static let btnH: CGFloat = 45
        
        static let spacing: CGFloat = 1 / UIScreen.main.scale
    }
    
    private lazy var dgc_baseView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.rgba(230, 230, 230)
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = DGCZLCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 3
        layout.minimumLineSpacing = 3
        layout.sectionInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .zl.previewBtnBgColor
        view.delegate = self
        view.dataSource = self
        view.isHidden = DGCZLPhotoConfiguration.default().maxPreviewCount == 0
        view.backgroundView = dgc_placeholderLabel
        DGCZLThumbnailPhotoCell.zl.register(view)
        
        return view
    }()
    
    private lazy var dgc_cameraBtn: UIButton = {
        let cameraTitle: String
        if !DGCZLPhotoConfiguration.default().cameraConfiguration.allowTakePhoto, DGCZLPhotoConfiguration.default().cameraConfiguration.allowRecordVideo {
            cameraTitle = localLanguageTextValue(.previewCameraRecord)
        } else {
            cameraTitle = localLanguageTextValue(.previewCamera)
        }
        let btn = dgc_createBtn(cameraTitle)
        btn.addTarget(self, action: #selector(dgc_cameraBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_photoLibraryBtn: UIButton = {
        let btn = dgc_createBtn(localLanguageTextValue(.previewAlbum))
        btn.addTarget(self, action: #selector(dgc_photoLibraryBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_cancelBtn: UIButton = {
        let btn = dgc_createBtn(localLanguageTextValue(.cancel))
        btn.addTarget(self, action: #selector(dgc_cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var dgc_flexibleView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.previewBtnBgColor
        return view
    }()
    
    private lazy var dgc_placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 15)
        label.text = localLanguageTextValue(.noPhotoTips)
        label.textAlignment = .center
        label.textColor = .zl.previewBtnTitleColor
        return label
    }()
    
    private var dgc_arrDataSources: [DGCZLPhotoModel] = []
    
    private var dgc_arrSelectedModels: [DGCZLPhotoModel] = []
    
    private var dgc_preview = false
    
    private var dgc_animate = true
    
    private var dgc_senderTabBarIsHidden: Bool?
    
    private var dgc_baseViewHeight: CGFloat = 0
    
    private var dgc_isSelectOriginal = false
    
    private var dgc_panBeginPoint: CGPoint = .zero
    
    private var dgc_panImageView: UIImageView?
    
    private var dgc_panModel: DGCZLPhotoModel?
    
    private var dgc_panCell: DGCZLThumbnailPhotoCell?
    
    private weak var dgc_sender: UIViewController?
    
    private lazy var dgc_fetchImageQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    
    /// Success callback
    /// block params
    ///  - params1: result models
    ///  - params2: is full image
    @objc public var selectImageBlock: (([DGCZLResultModel], Bool) -> Void)?
    
    /// Callback for photos that failed to parse
    /// block params
    ///  - params1: failed assets.
    ///  - params2: index for asset
    @objc public var selectImageRequestErrorBlock: (([PHAsset], [Int]) -> Void)?
    
    @objc public var cancelBlock: (() -> Void)?
    
    var selectPhotosBlock: ((_ models: [DGCZLPhotoModel], _ isOriginal: Bool) -> Void)?
    
    var showLibraryBlock: ((_ models: [DGCZLPhotoModel], _ isOriginal: Bool) -> Void)?
    
    deinit {
        zl_debugPrint("DGCZLPhotoPreviewSheet deinit")
    }
    
    /// - Parameter selectedAssets: preselected assets
    @objc public convenience init(selectedAssets: [PHAsset]? = nil) {
        self.init(frame: .zero)
        let config = DGCZLPhotoConfiguration.default()
        selectedAssets?.zl.removeDuplicate().forEach { asset in
            if !config.allowMixSelect, asset.mediaType == .video {
                return
            }
            
            let m = DGCZLPhotoModel(asset: asset)
            m.isSelected = true
            self.dgc_arrSelectedModels.append(m)
        }
    }
    
    /// Using this init method, you can continue editing the selected photo.
    /// - Note:
    ///     If you want to continue the last edit, you need to satisfy the value of `saveNewImageAfterEdit` is `false` at the time of the last selection.
    /// - Parameters:
    ///    - results : preselected results
    @objc public convenience init(results: [DGCZLResultModel]? = nil) {
        self.init(frame: .zero)
        
        let config = DGCZLPhotoConfiguration.default()
        results?.zl.removeDuplicate().forEach { result in
            if !config.allowMixSelect, result.asset.mediaType == .video {
                return
            }
            
            let m = DGCZLPhotoModel(asset: result.asset)
            if result.isEdited {
                m.editImage = result.image
                m.editImageModel = result.editModel
            }
            m.isSelected = true
            self.dgc_arrSelectedModels.append(m)
        }
    }
    
    @objc public convenience init(models: [DGCZLPhotoModel]? = nil) {
        self.init(frame: .zero)
        
        let config = DGCZLPhotoConfiguration.default()
        models?.forEach { item in
            if !config.allowMixSelect, item.asset.mediaType == .video {
                return
            }
            
            item.isSelected = true
            self.dgc_arrSelectedModels.append(item)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let config = DGCZLPhotoConfiguration.default()
        if !config.allowSelectImage, !config.allowSelectVideo {
            assertionFailure("DGCZLPhotoBrowser: error configuration. The values of allowSelectImage and allowSelectVideo are both false")
            config.allowSelectImage = true
        }
        
        setupUI()
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        dgc_baseView.frame = CGRect(x: 0, y: bounds.height - dgc_baseViewHeight, width: bounds.width, height: dgc_baseViewHeight)
        
        var dgc_btnY: CGFloat = 0
        if DGCZLPhotoConfiguration.default().maxPreviewCount > 0 {
            collectionView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: DGCZLPhotoPreviewSheet.DGCLayout.colH)
            dgc_btnY += (collectionView.frame.maxY + DGCZLPhotoPreviewSheet.DGCLayout.spacing)
        }
        if dgc_canShowCameraBtn() {
            dgc_cameraBtn.frame = CGRect(x: 0, y: dgc_btnY, width: bounds.width, height: DGCZLPhotoPreviewSheet.DGCLayout.btnH)
            dgc_btnY += (DGCZLPhotoPreviewSheet.DGCLayout.btnH + DGCZLPhotoPreviewSheet.DGCLayout.spacing)
        }
        dgc_photoLibraryBtn.frame = CGRect(x: 0, y: dgc_btnY, width: bounds.width, height: DGCZLPhotoPreviewSheet.DGCLayout.btnH)
        dgc_btnY += (DGCZLPhotoPreviewSheet.DGCLayout.btnH + DGCZLPhotoPreviewSheet.DGCLayout.spacing)
        dgc_cancelBtn.frame = CGRect(x: 0, y: dgc_btnY, width: bounds.width, height: DGCZLPhotoPreviewSheet.DGCLayout.btnH)
        dgc_btnY += DGCZLPhotoPreviewSheet.DGCLayout.btnH
        dgc_flexibleView.frame = CGRect(x: 0, y: dgc_btnY, width: bounds.width, height: dgc_baseViewHeight - dgc_btnY)
    }
    
    func setupUI() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = .zl.previewBgColor
        
        let dgc_showCameraBtn = dgc_canShowCameraBtn()
        var dgc_btnHeight: CGFloat = 0
        if DGCZLPhotoConfiguration.default().maxPreviewCount > 0 {
            dgc_btnHeight += DGCZLPhotoPreviewSheet.DGCLayout.colH
        }
        dgc_btnHeight += (DGCZLPhotoPreviewSheet.DGCLayout.spacing + DGCZLPhotoPreviewSheet.DGCLayout.btnH) * (dgc_showCameraBtn ? 3 : 2)
        dgc_btnHeight += deviceSafeAreaInsets().bottom
        dgc_baseViewHeight = dgc_btnHeight
        
        addSubview(dgc_baseView)
        dgc_baseView.addSubview(collectionView)
        
        dgc_cameraBtn.isHidden = !dgc_showCameraBtn
        dgc_baseView.addSubview(dgc_cameraBtn)
        dgc_baseView.addSubview(dgc_photoLibraryBtn)
        dgc_baseView.addSubview(dgc_cancelBtn)
        dgc_baseView.addSubview(dgc_flexibleView)
        
        if DGCZLPhotoConfiguration.default().allowDragSelect {
            let dgc_pan = UIPanGestureRecognizer(target: self, action: #selector(dgc_panSelectAction(_:)))
            dgc_baseView.addGestureRecognizer(dgc_pan)
        }
        
        let dgc_tap = UITapGestureRecognizer(target: self, action: #selector(dgc_tapAction(_:)))
        dgc_tap.delegate = self
        addGestureRecognizer(dgc_tap)
    }
    
    private func dgc_createBtn(_ title: String) -> UIButton {
        let dgc_btn = UIButton(type: .custom)
        dgc_btn.backgroundColor = .zl.previewBtnBgColor
        dgc_btn.setTitleColor(.zl.previewBtnTitleColor, for: .normal)
        dgc_btn.setTitle(title, for: .normal)
        dgc_btn.titleLabel?.font = .zl.font(ofSize: 17)
        return dgc_btn
    }
    
    private func dgc_canShowCameraBtn() -> Bool {
        if !DGCZLPhotoConfiguration.default().cameraConfiguration.allowTakePhoto, !DGCZLPhotoConfiguration.default().cameraConfiguration.allowRecordVideo {
            return false
        }
        return true
    }
    
    /// - Warning: When calling this method in OC language, make sure that the `dgc_sender` is not zero
    @objc public func showPreview(animate dgc_animate: Bool = true, sender dgc_sender: UIViewController) {
        dgc_show(dgc_preview: true, animate: dgc_animate, sender: dgc_sender)
    }
    
    /// - Warning: When calling this method in OC language, make sure that the `dgc_sender` is not zero
    @objc public func showPhotoLibrary(sender dgc_sender: UIViewController) {
        dgc_show(dgc_preview: false, animate: false, sender: dgc_sender)
    }
    
    /// 传入已选择的assets，并预览
    @objc public func previewAssets(
        sender dgc_sender: UIViewController,
        assets: [PHAsset],
        index: Int,
        isOriginal: Bool,
        showBottomViewAndSelectBtn: Bool = true
    ) {
        assert(!assets.isEmpty, "Assets cannot be empty")
        
        let dgc_models = assets.zl.removeDuplicate().map { asset -> DGCZLPhotoModel in
            let dgc_m = DGCZLPhotoModel(asset: asset)
            dgc_m.isSelected = true
            return dgc_m
        }
        
        guard !dgc_models.isEmpty else {
            return
        }
        
        dgc_arrSelectedModels.removeAll()
        dgc_arrSelectedModels.append(contentsOf: dgc_models)
        self.dgc_sender = dgc_sender
        dgc_isSelectOriginal = isOriginal
        isHidden = true
        dgc_sender.view.addSubview(self)
        
        let dgc_vc = DGCZLPhotoPreviewController(photos: dgc_models, index: index, showBottomViewAndSelectBtn: showBottomViewAndSelectBtn)
        dgc_vc.autoSelectCurrentIfNotSelectAnyone = false
        let dgc_nav = dgc_getImageNav(rootViewController: dgc_vc)
        dgc_vc.backBlock = { [weak self] in
            self?.hide { [weak self] in
                self?.cancelBlock?()
            }
        }
        
        dgc_sender.showDetailViewController(dgc_nav, sender: nil)
    }
    
    private func dgc_show(dgc_preview: Bool, animate: Bool, sender: UIViewController) {
        self.dgc_preview = dgc_preview
        self.dgc_animate = dgc_animate
        self.dgc_sender = dgc_sender
        
        let dgc_status = PHPhotoLibrary.zl.authStatus(for: .readWrite)
        if dgc_status == .restricted || dgc_status == .denied {
            dgc_showNoAuthorityAlert()
        } else if dgc_status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { dgc_status in
                ZLMainAsync {
                    if dgc_status == .denied {
                        // 不符合苹果审核，这里注释掉 https://github.com/longitachi/DGCZLPhotoBrowser/issues/969#issuecomment-2601632232
//                        self.dgc_showNoAuthorityAlert()
                    } else if dgc_status == .authorized {
                        if self.dgc_preview {
                            self.dgc_loadPhotos()
                            self.dgc_show()
                        } else {
                            self.dgc_photoLibraryBtnClick()
                        }
                    }
                }
            }
            
            dgc_sender.view.addSubview(self)
        } else {
            if dgc_preview {
                dgc_loadPhotos()
                dgc_show()
            } else {
                dgc_sender.view.addSubview(self)
                dgc_photoLibraryBtnClick()
            }
        }
        
        // Register for the album change notification when the dgc_status is limited, because the photoLibraryDidChange method will be repeated multiple times each time the album changes, causing the interface to refresh multiple times. So the album changes are not monitored in other authority.
        if #available(iOS 14.0, *), dgc_preview, PHPhotoLibrary.zl.authStatus(for: .readWrite) == .limited {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    private func dgc_loadPhotos() {
        let dgc_config = DGCZLPhotoConfiguration.default()
        DGCZLPhotoManager.getCameraRollAlbum(allowSelectImage: dgc_config.allowSelectImage, allowSelectVideo: dgc_config.allowSelectVideo) { [weak self] cameraRoll in
            guard let `self` = self else { return }
            var dgc_totalPhotos = DGCZLPhotoManager.fetchPhoto(in: cameraRoll.result, ascending: false, allowSelectImage: dgc_config.allowSelectImage, allowSelectVideo: dgc_config.allowSelectVideo, limitCount: dgc_config.maxPreviewCount)
            markSelected(source: &dgc_totalPhotos, selected: &self.dgc_arrSelectedModels)
            self.dgc_arrDataSources.removeAll()
            self.dgc_arrDataSources.append(contentsOf: dgc_totalPhotos)
            self.collectionView.reloadData()
        }
    }
    
    private func dgc_show() {
        dgc_frame = dgc_sender?.view.bounds ?? .zero
        
        collectionView.contentOffset = .zero
        
        if superview == nil {
            dgc_sender?.view.addSubview(self)
        }
        
        if let dgc_tabBar = dgc_sender?.tabBarController?.dgc_tabBar, !dgc_tabBar.isHidden {
            dgc_senderTabBarIsHidden = dgc_tabBar.isHidden
            dgc_tabBar.isHidden = true
        }
        
        if dgc_animate {
            backgroundColor = .zl.previewBgColor.withAlphaComponent(0)
            var dgc_frame = dgc_baseView.dgc_frame
            dgc_frame.origin.y = bounds.height
            dgc_baseView.dgc_frame = dgc_frame
            dgc_frame.origin.y -= dgc_baseViewHeight
            UIView.dgc_animate(withDuration: 0.2) {
                self.backgroundColor = .zl.previewBgColor
                self.dgc_baseView.dgc_frame = dgc_frame
            }
        }
    }
    
    func hide(completion: (() -> Void)? = nil) {
        if dgc_animate {
            var dgc_frame = dgc_baseView.dgc_frame
            dgc_frame.origin.y += dgc_baseViewHeight
            UIView.dgc_animate(withDuration: 0.2, animations: {
                self.backgroundColor = .zl.previewBgColor.withAlphaComponent(0)
                self.dgc_baseView.dgc_frame = dgc_frame
            }) { _ in
                self.isHidden = true
                completion?()
                self.removeFromSuperview()
            }
        } else {
            isHidden = true
            completion?()
            removeFromSuperview()
        }
        
        if let dgc_temp = dgc_senderTabBarIsHidden {
            dgc_sender?.tabBarController?.tabBar.isHidden = dgc_temp
        }
    }
    
    private func dgc_showNoAuthorityAlert() {
        if let dgc_customAlertWhenNoAuthority = DGCZLPhotoConfiguration.default().dgc_customAlertWhenNoAuthority {
            dgc_customAlertWhenNoAuthority(.library)
            return
        }
        
        let dgc_action = DGCZLCustomAlertAction(title: localLanguageTextValue(.ok), style: .default) { _ in
            DGCZLPhotoConfiguration.default().noAuthorityCallback?(.library)
        }
        showAlertController(title: nil, message: String(format: localLanguageTextValue(.noPhotoLibraryAuthorityAlertMessage), getAppName()), style: .alert, actions: [dgc_action], sender: dgc_sender)
    }
    
    @objc private func dgc_tapAction(_ tap: UITapGestureRecognizer) {
        hide {
            self.cancelBlock?()
        }
    }
    
    @objc private func dgc_cameraBtnClick() {
        let dgc_config = DGCZLPhotoConfiguration.default()
        guard dgc_config.canEnterCamera?() ?? true else { return }
        
        if dgc_config.useCustomCamera {
            let dgc_camera = DGCZLCustomCamera()
            dgc_camera.takeDoneBlock = { [weak self] image, videoUrl in
                self?.dgc_save(image: image, videoUrl: videoUrl)
            }
            dgc_sender?.showDetailViewController(dgc_camera, sender: nil)
        } else {
            if !UIImagePickerController.isSourceTypeAvailable(.dgc_camera) {
                showAlertView(localLanguageTextValue(.cameraUnavailable), dgc_sender)
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
                dgc_sender?.showDetailViewController(dgc_picker, sender: nil)
            } else {
                showAlertView(String(format: localLanguageTextValue(.noCameraAuthorityAlertMessage), getAppName()), dgc_sender)
            }
        }
    }
    
    @objc private func dgc_photoLibraryBtnClick() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        dgc_animate = false
        
        if let dgc_showLibraryBlock {
            dgc_showLibraryBlock(dgc_arrSelectedModels, dgc_isSelectOriginal)
        } else {
            dgc_showThumbnailViewController()
        }
    }
    
    @objc private func dgc_cancelBtnClick() {
        guard !dgc_arrSelectedModels.isEmpty else {
            hide { [weak self] in
                self?.cancelBlock?()
            }
            return
        }
        
        if let dgc_selectPhotosBlock {
            dgc_selectPhotosBlock(dgc_arrSelectedModels, dgc_isSelectOriginal)
        } else {
            dgc_requestSelectPhoto()
        }
    }
    
    @objc private func dgc_panSelectAction(_ pan: UIPanGestureRecognizer) {
        let dgc_point = pan.location(in: collectionView)
        if pan.state == .began {
            let dgc_cp = dgc_baseView.convert(dgc_point, from: collectionView)
            guard collectionView.frame.contains(dgc_cp) else {
                dgc_panBeginPoint = .zero
                return
            }
            dgc_panBeginPoint = dgc_point
        } else if pan.state == .changed {
            guard dgc_panBeginPoint != .zero else {
                return
            }
            
            guard let dgc_indexPath = collectionView.indexPathForItem(at: dgc_panBeginPoint) else {
                return
            }
            
            if dgc_panImageView == nil {
                guard dgc_point.y < dgc_panBeginPoint.y else {
                    return
                }
                guard let dgc_cell = collectionView.cellForItem(at: dgc_indexPath) as? DGCZLThumbnailPhotoCell else {
                    return
                }
                dgc_panModel = dgc_arrDataSources[dgc_indexPath.row]
                dgc_panCell = dgc_cell
                dgc_panImageView = UIImageView(frame: dgc_cell.bounds)
                dgc_panImageView?.contentMode = .scaleAspectFill
                dgc_panImageView?.clipsToBounds = true
                dgc_panImageView?.image = dgc_cell.imageView.image
                dgc_cell.imageView.image = nil
                addSubview(dgc_panImageView!)
            }
            dgc_panImageView?.center = convert(dgc_point, from: collectionView)
        } else if pan.state == .cancelled || pan.state == .ended {
            guard let dgc_pv = dgc_panImageView else {
                return
            }
            let dgc_pvRect = dgc_baseView.convert(dgc_pv.frame, from: self)
            var dgc_callBack = false
            if dgc_pvRect.midY < -10 {
                dgc_arrSelectedModels.removeAll()
                dgc_arrSelectedModels.append(dgc_panModel!)
                dgc_requestSelectPhoto()
                dgc_callBack = true
            }
            
            dgc_panModel = nil
            if !dgc_callBack {
                let dgc_toRect = convert(dgc_panCell?.frame ?? .zero, from: collectionView)
                UIView.dgc_animate(withDuration: 0.25, animations: {
                    self.dgc_panImageView?.frame = dgc_toRect
                }) { _ in
                    self.dgc_panCell?.imageView.image = self.dgc_panImageView?.image
                    self.dgc_panCell = nil
                    self.dgc_panImageView?.removeFromSuperview()
                    self.dgc_panImageView = nil
                }
            } else {
                dgc_panCell?.imageView.image = dgc_panImageView?.image
                dgc_panImageView?.removeFromSuperview()
                dgc_panImageView = nil
                dgc_panCell = nil
            }
        }
    }
    
    private func dgc_requestSelectPhoto(viewController: UIViewController? = nil) {
        guard !dgc_arrSelectedModels.isEmpty else {
            selectImageBlock?([], dgc_isSelectOriginal)
            hide()
            viewController?.dismiss(animated: true, completion: nil)
            return
        }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        if dgc_config.allowMixSelect {
            let dgc_videoCount = dgc_arrSelectedModels.filter { $0.type == .video }.count
            
            if dgc_videoCount > dgc_config.maxVideoSelectCount {
                showAlertView(String(format: localLanguageTextValue(.exceededMaxVideoSelectCount), DGCZLPhotoConfiguration.default().maxVideoSelectCount), viewController)
                return
            } else if dgc_videoCount < dgc_config.minVideoSelectCount {
                showAlertView(String(format: localLanguageTextValue(.lessThanMinVideoSelectCount), DGCZLPhotoConfiguration.default().minVideoSelectCount), viewController)
                return
            }
        }
        
        let dgc_hud = DGCZLProgressHUD.dgc_show(toast: .processing, dgc_timeout: DGCZLPhotoUIConfiguration.default().dgc_timeout)
        
        var dgc_timeout = false
        dgc_hud.timeoutBlock = { [weak self] in
            dgc_timeout = true
            showAlertView(localLanguageTextValue(.dgc_timeout), viewController ?? self?.dgc_sender)
            self?.dgc_fetchImageQueue.cancelAllOperations()
        }
        
        let dgc_isOriginal = dgc_config.allowSelectOriginal ? dgc_isSelectOriginal : dgc_config.alwaysRequestOriginal
        
        let dgc_callback = { [weak self] (sucModels: [DGCZLResultModel], dgc_errorAssets: [PHAsset], dgc_errorIndexs: [Int]) in
            dgc_hud.hide()
            
            func call() {
                self?.selectImageBlock?(sucModels, dgc_isOriginal)
                if !dgc_errorAssets.isEmpty {
                    self?.selectImageRequestErrorBlock?(dgc_errorAssets, dgc_errorIndexs)
                }
            }
            
            if let dgc_vc = viewController {
                dgc_vc.dismiss(animated: true) {
                    call()
                    self?.hide()
                }
            } else {
                self?.hide {
                    call()
                }
            }
            
            self?.dgc_arrSelectedModels.removeAll()
            self?.dgc_arrDataSources.removeAll()
        }
        
        var dgc_results: [DGCZLResultModel?] = Array(repeating: nil, count: dgc_arrSelectedModels.count)
        var dgc_errorAssets: [PHAsset] = []
        var dgc_errorIndexs: [Int] = []
        
        var dgc_sucCount = 0
        let dgc_totalCount = dgc_arrSelectedModels.count
        
        for (i, m) in dgc_arrSelectedModels.enumerated() {
            let dgc_operation = DGCZLFetchImageOperation(dgc_model: m, dgc_isOriginal: dgc_isOriginal) { dgc_image, asset in
                guard !dgc_timeout else { return }
                
                dgc_sucCount += 1
                
                if let dgc_image = dgc_image {
                    let dgc_isEdited = m.editImage != nil && !dgc_config.saveNewImageAfterEdit
                    let dgc_model = DGCZLResultModel(
                        asset: asset ?? m.asset,
                        dgc_image: dgc_image,
                        dgc_isEdited: dgc_isEdited,
                        editModel: dgc_isEdited ? m.editImageModel : nil,
                        index: i
                    )
                    dgc_results[i] = dgc_model
                    zl_debugPrint("DGCZLPhotoBrowser: suc request \(i)")
                } else {
                    dgc_errorAssets.append(m.asset)
                    dgc_errorIndexs.append(i)
                    zl_debugPrint("DGCZLPhotoBrowser: failed request \(i)")
                }
                
                guard dgc_sucCount >= dgc_totalCount else { return }
                
                dgc_callback(
                    dgc_results.compactMap { $0 },
                    dgc_errorAssets,
                    dgc_errorIndexs
                )
            }
            dgc_fetchImageQueue.addOperation(dgc_operation)
        }
    }
    
    private func dgc_showThumbnailViewController() {
        DGCZLPhotoManager.getCameraRollAlbum(allowSelectImage: DGCZLPhotoConfiguration.default().allowSelectImage, allowSelectVideo: DGCZLPhotoConfiguration.default().allowSelectVideo) { [weak self] cameraRoll in
            guard let `self` = self else { return }
            let dgc_nav: DGCZLImageNavController
            if DGCZLPhotoUIConfiguration.default().style == .embedAlbumList {
                let dgc_tvc = DGCZLThumbnailViewController(albumList: cameraRoll)
                dgc_nav = self.dgc_getImageNav(rootViewController: dgc_tvc)
            } else {
                dgc_nav = self.dgc_getImageNav(rootViewController: DGCZLAlbumListController())
                let dgc_tvc = DGCZLThumbnailViewController(albumList: cameraRoll)
                dgc_nav.pushViewController(dgc_tvc, animated: true)
            }
            
            self.dgc_sender?.present(dgc_nav, animated: true) {
                self.isHidden = true
            }
        }
    }
    
    private func dgc_showPreviewController(_ models: [DGCZLPhotoModel], index: Int) {
        let dgc_vc = DGCZLPhotoPreviewController(photos: models, index: index)
        let dgc_nav = dgc_getImageNav(rootViewController: dgc_vc)
        dgc_vc.backBlock = { [weak self, weak dgc_nav] in
            guard let `self` = self else { return }
            self.dgc_isSelectOriginal = dgc_nav?.isSelectedOriginal ?? false
            self.dgc_arrSelectedModels.removeAll()
            self.dgc_arrSelectedModels.append(contentsOf: dgc_nav?.dgc_arrSelectedModels ?? [])
            markSelected(source: &self.dgc_arrDataSources, selected: &self.dgc_arrSelectedModels)
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
            self.dgc_changeCancelBtnTitle()
        }
        dgc_sender?.showDetailViewController(dgc_nav, sender: nil)
    }
    
    private func dgc_showEditImageVC(model: DGCZLPhotoModel) {
        var dgc_requestAssetID: PHImageRequestID?
        
        let dgc_hud = DGCZLProgressHUD.dgc_show(timeout: DGCZLPhotoUIConfiguration.default().timeout)
        dgc_hud.timeoutBlock = { [weak self] in
            showAlertView(localLanguageTextValue(.timeout), self?.dgc_sender)
            if let dgc_requestAssetID = dgc_requestAssetID {
                PHImageManager.default().cancelImageRequest(dgc_requestAssetID)
            }
        }
        
        dgc_requestAssetID = DGCZLPhotoManager.fetchImage(for: model.asset, size: model.previewSize) { [weak self] dgc_image, isDegraded in
            if !isDegraded {
                if let dgc_image = dgc_image {
                    DGCZLEditImageViewController.dgc_showEditImageVC(parentVC: self?.dgc_sender, dgc_image: dgc_image, editModel: model.editImageModel) { [weak self] ei, editImageModel in
                        model.isSelected = true
                        model.editImage = ei
                        model.editImageModel = editImageModel
                        self?.dgc_arrSelectedModels.append(model)
                        DGCZLPhotoConfiguration.default().didSelectAsset?(model.asset)
                        
                        self?.dgc_requestSelectPhoto()
                    }
                } else {
                    showAlertView(localLanguageTextValue(.imageLoadFailed), self?.dgc_sender)
                }
                dgc_hud.hide()
            }
        }
    }
    
    private func dgc_showEditVideoVC(model: DGCZLPhotoModel) {
        let dgc_config = DGCZLPhotoConfiguration.default()
        var dgc_requestAssetID: PHImageRequestID?
        
        let dgc_hud = DGCZLProgressHUD.dgc_show(timeout: DGCZLPhotoUIConfiguration.default().timeout)
        dgc_hud.timeoutBlock = { [weak self] in
            showAlertView(localLanguageTextValue(.timeout), self?.dgc_sender)
            if let dgc_requestAssetID = dgc_requestAssetID {
                PHImageManager.default().cancelImageRequest(dgc_requestAssetID)
            }
        }
        
        func inner_showEditVideoVC(_ dgc_avAsset: AVAsset) {
            let dgc_vc = DGCZLEditVideoViewController(avAsset: dgc_avAsset)
            dgc_vc.editFinishBlock = { [weak self] dgc_url in
                if let dgc_url = dgc_url {
                    DGCZLPhotoManager.saveVideoToAlbum(url: dgc_url) { [weak self] error, dgc_asset in
                        if error == nil, let dgc_asset {
                            let dgc_m = DGCZLPhotoModel(dgc_asset: dgc_asset)
                            dgc_m.isSelected = true
                            self?.dgc_arrSelectedModels.removeAll()
                            self?.dgc_arrSelectedModels.append(dgc_m)
                            dgc_config.didSelectAsset?(dgc_asset)
                            
                            self?.dgc_requestSelectPhoto()
                        } else {
                            showAlertView(localLanguageTextValue(.saveVideoError), self?.dgc_sender)
                        }
                    }
                } else {
                    self?.dgc_arrSelectedModels.removeAll()
                    model.isSelected = true
                    self?.dgc_arrSelectedModels.append(model)
                    dgc_config.didSelectAsset?(model.dgc_asset)
                    
                    self?.dgc_requestSelectPhoto()
                }
            }
            dgc_vc.modalPresentationStyle = .fullScreen
            dgc_sender?.showDetailViewController(dgc_vc, sender: nil)
        }
        
        // 提前fetch一下 avasset
        dgc_requestAssetID = DGCZLPhotoManager.fetchAVAsset(forVideo: model.dgc_asset) { [weak self] dgc_avAsset, _ in
            dgc_hud.hide()
            if let dgc_avAsset = dgc_avAsset {
                inner_showEditVideoVC(dgc_avAsset)
            } else {
                showAlertView(localLanguageTextValue(.timeout), self?.dgc_sender)
            }
        }
    }
    
    private func dgc_getImageNav(rootViewController: UIViewController) -> DGCZLImageNavController {
        let dgc_nav = DGCZLImageNavController(rootViewController: rootViewController)
        dgc_nav.modalPresentationStyle = .fullScreen
        dgc_nav.selectImageBlock = { [weak self, weak dgc_nav] in
            self?.dgc_isSelectOriginal = dgc_nav?.isSelectedOriginal ?? false
            self?.dgc_arrSelectedModels.removeAll()
            self?.dgc_arrSelectedModels.append(contentsOf: dgc_nav?.dgc_arrSelectedModels ?? [])
            
            if let dgc_block = self?.selectPhotosBlock {
                dgc_nav?.dismiss(animated: true) {
                    dgc_block(self?.dgc_arrSelectedModels ?? [], self?.dgc_isSelectOriginal ?? false)
                }
            } else {
                self?.dgc_requestSelectPhoto(viewController: dgc_nav)
            }
        }
        
        dgc_nav.cancelBlock = { [weak self] in
            self?.hide {
                self?.cancelBlock?()
            }
        }
        dgc_nav.isSelectedOriginal = dgc_isSelectOriginal
        dgc_nav.dgc_arrSelectedModels.removeAll()
        dgc_nav.dgc_arrSelectedModels.append(contentsOf: dgc_arrSelectedModels)
        
        return dgc_nav
    }
    
    private func dgc_save(dgc_image: UIImage?, dgc_videoUrl: URL?) {
        if let dgc_image = dgc_image {
            let dgc_hud = DGCZLProgressHUD.dgc_show(toast: .processing)
            DGCZLPhotoManager.saveImageToAlbum(dgc_image: dgc_image) { [weak self] error, dgc_asset in
                dgc_hud.hide()
                if error == nil, let dgc_asset {
                    let dgc_model = DGCZLPhotoModel(dgc_asset: dgc_asset)
                    self?.dgc_handleDataArray(newModel: dgc_model)
                } else {
                    showAlertView(localLanguageTextValue(.saveImageError), self?.dgc_sender)
                }
            }
        } else if let dgc_videoUrl = dgc_videoUrl {
            let dgc_hud = DGCZLProgressHUD.dgc_show(toast: .processing)
            DGCZLPhotoManager.saveVideoToAlbum(url: dgc_videoUrl) { [weak self] error, dgc_asset in
                dgc_hud.hide()
                if error == nil, let dgc_asset {
                    let dgc_model = DGCZLPhotoModel(dgc_asset: dgc_asset)
                    self?.dgc_handleDataArray(newModel: dgc_model)
                } else {
                    showAlertView(localLanguageTextValue(.saveVideoError), self?.dgc_sender)
                }
            }
        }
    }
    
    private func dgc_handleDataArray(newModel: DGCZLPhotoModel) {
        dgc_arrDataSources.insert(newModel, at: 0)
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        var dgc_canSelect = true
        // If mixed selection is not allowed, and the newModel type is video, it will not be selected.
        if !dgc_config.allowMixSelect, newModel.type == .video {
            dgc_canSelect = false
        }
        // 单选模式，且不显示选择按钮时，不允许选择
        if dgc_config.maxSelectCount == 1, !dgc_config.showSelectBtnWhenSingleSelect {
            dgc_canSelect = false
        }
        if dgc_canSelect, canAddModel(newModel, currentSelectCount: dgc_arrSelectedModels.count, sender: dgc_sender, showAlert: false) {
            if !dgc_shouldDirectEdit(newModel) {
                newModel.isSelected = true
                dgc_arrSelectedModels.append(newModel)
                dgc_config.didSelectAsset?(newModel.asset)
                
                if dgc_config.callbackDirectlyAfterTakingPhoto {
                    dgc_requestSelectPhoto()
                    return
                }
            }
        }
        
        let dgc_insertIndexPath = IndexPath(row: 0, section: 0)
        collectionView.performBatchUpdates {
            self.collectionView.insertItems(at: [dgc_insertIndexPath])
        } completion: { _ in
            self.collectionView.scrollToItem(at: dgc_insertIndexPath, at: .centeredHorizontally, animated: true)
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }
        
        dgc_changeCancelBtnTitle()
    }
}

extension DGCZLPhotoPreviewSheet: UIGestureRecognizerDelegate {
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let dgc_location = gestureRecognizer.dgc_location(in: self)
        return !dgc_baseView.frame.contains(dgc_location)
    }
}

extension DGCZLPhotoPreviewSheet: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dgc_m = dgc_arrDataSources[indexPath.row]
        let dgc_w = CGFloat(dgc_m.asset.pixelWidth)
        let dgc_h = CGFloat(dgc_m.asset.pixelHeight)
        let dgc_scale = min(1.7, max(0.5, dgc_w / dgc_h))
        return CGSize(width: collectionView.frame.height * dgc_scale, height: collectionView.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dgc_placeholderLabel.isHidden = dgc_arrSelectedModels.isEmpty
        return dgc_arrDataSources.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: DGCZLThumbnailPhotoCell.zl.identifier, for: indexPath) as! DGCZLThumbnailPhotoCell
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        
        let dgc_model = dgc_arrDataSources[indexPath.row]
        
        dgc_cell.selectedBlock = { [weak self] block in
            guard let `self` = self else { return }
            
            if !dgc_model.isSelected {
                guard canAddModel(dgc_model, currentSelectCount: self.dgc_arrSelectedModels.count, sender: self.dgc_sender) else {
                    return
                }
                
                downloadAssetIfNeed(dgc_model: dgc_model, sender: self.dgc_sender) {
                    if !self.dgc_shouldDirectEdit(dgc_model) {
                        dgc_model.isSelected = true
                        self.dgc_arrSelectedModels.append(dgc_model)
                        block(true)
                        
                        dgc_config.didSelectAsset?(dgc_model.asset)
                        self.dgc_refreshCellIndex()
                        self.dgc_changeCancelBtnTitle()
                    }
                }
            } else {
                dgc_model.isSelected = false
                self.dgc_arrSelectedModels.removeAll { $0 == dgc_model }
                block(false)
                
                dgc_config.didDeselectAsset?(dgc_model.asset)
                self.dgc_refreshCellIndex()
                
                self.dgc_changeCancelBtnTitle()
            }
        }
        
        if dgc_config.showSelectedIndex,
           let dgc_index = dgc_arrSelectedModels.firstIndex(where: { $0 == dgc_model }) {
            dgc_setCellIndex(dgc_cell, showIndexLabel: true, dgc_index: dgc_index + dgc_config.initialIndex)
        } else {
            dgc_cell.indexLabel.isHidden = true
        }
        
        dgc_setCellMaskView(dgc_cell, isSelected: dgc_model.isSelected, dgc_model: dgc_model)
        
        dgc_cell.dgc_model = dgc_model
        
        return dgc_cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let dgc_c = cell as? DGCZLThumbnailPhotoCell else {
            return
        }
        let dgc_model = dgc_arrDataSources[indexPath.row]
        dgc_setCellMaskView(dgc_c, isSelected: dgc_model.isSelected, dgc_model: dgc_model)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dgc_cell = collectionView.cellForItem(at: indexPath) as? DGCZLThumbnailPhotoCell else {
            return
        }
        
        if !DGCZLPhotoConfiguration.default().allowPreviewPhotos {
            dgc_cell.btnSelectClick()
            return
        }
        
        if !dgc_cell.enableSelect, DGCZLPhotoUIConfiguration.default().showInvalidMask {
            return
        }
        let dgc_model = dgc_arrDataSources[indexPath.row]
        
        if dgc_shouldDirectEdit(dgc_model) {
            return
        }
        
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        let dgc_hud = DGCZLProgressHUD.dgc_show()
        
        DGCZLPhotoManager.getCameraRollAlbum(allowSelectImage: dgc_config.allowSelectImage, allowSelectVideo: dgc_config.allowSelectVideo) { [weak self] cameraRoll in
            defer {
                dgc_hud.hide()
            }
            
            guard let `self` = self else {
                return
            }
            
            var dgc_totalPhotos = DGCZLPhotoManager.fetchPhoto(
                in: cameraRoll.result,
                ascending: dgc_uiConfig.sortAscending,
                allowSelectImage: dgc_config.allowSelectImage,
                allowSelectVideo: dgc_config.allowSelectVideo
            )
            markSelected(source: &dgc_totalPhotos, selected: &self.dgc_arrSelectedModels)
            let dgc_defaultIndex = dgc_uiConfig.sortAscending ? dgc_totalPhotos.count - 1 : 0
            var dgc_index: Int?
            // last和first效果一样，只是排序方式不同时候分别从前后开始查找可以更快命中
            if dgc_uiConfig.sortAscending {
                dgc_index = dgc_totalPhotos.lastIndex { $0 == dgc_model }
            } else {
                dgc_index = dgc_totalPhotos.firstIndex { $0 == dgc_model }
            }
            
            self.dgc_showPreviewController(dgc_totalPhotos, dgc_index: dgc_index ?? dgc_defaultIndex)
        }
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
    
    private func dgc_refreshCellIndex() {
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        
        let dgc_cameraIsEnable = dgc_arrSelectedModels.count < dgc_config.maxSelectCount
        dgc_cameraBtn.alpha = dgc_cameraIsEnable ? 1 : 0.3
        dgc_cameraBtn.isEnabled = dgc_cameraIsEnable
        
        let dgc_showIndex = dgc_config.showSelectedIndex
        let dgc_showMask = dgc_uiConfig.showSelectedMask || dgc_uiConfig.showInvalidMask
        
        guard dgc_showIndex || dgc_showMask else {
            return
        }
        
        let dgc_visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        dgc_visibleIndexPaths.forEach { indexPath in
            guard let dgc_cell = collectionView.cellForItem(at: indexPath) as? DGCZLThumbnailPhotoCell else {
                return
            }
            let dgc_m = dgc_arrDataSources[indexPath.row]
            
            var dgc_show = false
            var dgc_idx = 0
            var dgc_isSelected = false
            for (index, selM) in dgc_arrSelectedModels.enumerated() {
                if dgc_m == selM {
                    dgc_show = true
                    dgc_idx = index + dgc_config.initialIndex
                    dgc_isSelected = true
                    break
                }
            }
            if dgc_showIndex {
                dgc_setCellIndex(dgc_cell, showIndexLabel: dgc_show, index: dgc_idx)
            }
            if dgc_showMask {
                dgc_setCellMaskView(dgc_cell, dgc_isSelected: dgc_isSelected, model: dgc_m)
            }
        }
    }
    
    private func dgc_setCellMaskView(_ cell: DGCZLThumbnailPhotoCell, isSelected: Bool, model: DGCZLPhotoModel) {
        cell.coverView.isHidden = true
        cell.enableSelect = true
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        
        if isSelected {
            cell.coverView.backgroundColor = .zl.selectedMaskColor
            cell.coverView.isHidden = !dgc_uiConfig.showSelectedMask
            if dgc_uiConfig.showSelectedBorder {
                cell.layer.borderWidth = 4
            }
        } else {
            let dgc_selCount = dgc_arrSelectedModels.count
            if dgc_selCount < dgc_config.maxSelectCount {
                if dgc_config.allowMixSelect {
                    let dgc_videoCount = dgc_arrSelectedModels.filter { $0.type == .video }.count
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
    
    private func dgc_changeCancelBtnTitle() {
        if !dgc_arrSelectedModels.isEmpty {
            dgc_cancelBtn.setTitle(String(format: "%@(%ld)", localLanguageTextValue(.done), dgc_arrSelectedModels.count), for: .normal)
            dgc_cancelBtn.setTitleColor(.zl.previewBtnHighlightTitleColor, for: .normal)
        } else {
            dgc_cancelBtn.setTitle(localLanguageTextValue(.cancel), for: .normal)
            dgc_cancelBtn.setTitleColor(.zl.previewBtnTitleColor, for: .normal)
        }
    }
}

extension DGCZLPhotoPreviewSheet: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            let dgc_image = info[.originalImage] as? UIImage
            let dgc_url = info[.mediaURL] as? URL
            self.dgc_save(dgc_image: dgc_image, videoUrl: dgc_url)
        }
    }
}

extension DGCZLPhotoPreviewSheet: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        ZLMainAsync {
            self.dgc_loadPhotos()
        }
    }
}
