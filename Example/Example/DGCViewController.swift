//
//  DGCViewController.swift
//  Example
//
//  Created by long on 2020/8/11.
//

import UIKit
import DGCZLPhotoBrowser
import Photos

class DGCViewController: UIViewController {
    var collectionView: UICollectionView!
    
    var selectedImages: [UIImage] = []
    
    var selectedAssets: [PHAsset] = []
    
    var selectedResults: [DGCZLResultModel] = []
    
    var isOriginal = false
    
    var takeSelectedAssetsSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            FLEXManager.shared.showExplorer()
//        }
        
        DGCZLPhotoUIConfiguration.default()
            .customAlertClass(DGCCustomAlertController.self)
    }
    
    func setupUI() {
        title = "Main"
        view.backgroundColor = .white
        
        func createBtn(_ title: String, _ action: Selector) -> UIButton {
            let dgc_btn = UIButton(type: .custom)
            dgc_btn.setTitle(title, for: .normal)
            dgc_btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            dgc_btn.addTarget(self, action: action, for: .touchUpInside)
            dgc_btn.backgroundColor = .black
            dgc_btn.layer.cornerRadius = 5
            dgc_btn.layer.masksToBounds = true
            return dgc_btn
        }
        
        let dgc_configBtn = createBtn("Configuration", #selector(configureClick))
        view.addSubview(dgc_configBtn)
        dgc_configBtn.snp.makeConstraints { make in
            if #available(iOS 11.0, *) {
                make.top.equalTo(view.snp.topMargin).offset(20)
            } else {
                make.top.equalTo(topLayoutGuide.snp.bottom).offset(20)
            }
            
            make.left.equalToSuperview().offset(30)
        }
        
        let dgc_configBtn_cn = createBtn("相册配置 (中文)", #selector(cn_configureClick))
        view.addSubview(dgc_configBtn_cn)
        dgc_configBtn_cn.snp.makeConstraints { make in
            make.top.equalTo(dgc_configBtn.snp.top)
            make.left.equalTo(dgc_configBtn.snp.right).offset(30)
        }
        
        let dgc_previewSelectBtn = createBtn("Preview selection", #selector(previewSelectPhoto))
        view.addSubview(dgc_previewSelectBtn)
        dgc_previewSelectBtn.snp.makeConstraints { make in
            make.top.equalTo(dgc_configBtn.snp.bottom).offset(20)
            make.left.equalTo(dgc_configBtn.snp.left)
        }
        
        let dgc_libratySelectBtn = createBtn("Library selection", #selector(librarySelectPhoto))
        view.addSubview(dgc_libratySelectBtn)
        dgc_libratySelectBtn.snp.makeConstraints { make in
            make.top.equalTo(dgc_previewSelectBtn.snp.top)
            make.left.equalTo(dgc_previewSelectBtn.snp.right).offset(20)
        }
        
        let dgc_cameraBtn = createBtn("Custom camera", #selector(showCamera))
        view.addSubview(dgc_cameraBtn)
        dgc_cameraBtn.snp.makeConstraints { make in
            make.left.equalTo(dgc_configBtn.snp.left)
            make.top.equalTo(dgc_previewSelectBtn.snp.bottom).offset(20)
        }
        
        let dgc_previewLocalAndNetImageBtn = createBtn("Preview local and net image", #selector(previewLocalAndNetImage))
        view.addSubview(dgc_previewLocalAndNetImageBtn)
        dgc_previewLocalAndNetImageBtn.snp.makeConstraints { make in
            make.left.equalTo(dgc_cameraBtn.snp.right).offset(20)
            make.centerY.equalTo(dgc_cameraBtn)
        }
        
        let dgc_wechatMomentDemoBtn = createBtn("Create WeChat moment Demo", #selector(createWeChatMomentDemo))
        view.addSubview(dgc_wechatMomentDemoBtn)
        dgc_wechatMomentDemoBtn.snp.makeConstraints { make in
            make.left.equalTo(dgc_configBtn.snp.left)
            make.top.equalTo(dgc_cameraBtn.snp.bottom).offset(20)
        }
        
        let dgc_takeLabel = UILabel()
        dgc_takeLabel.font = UIFont.systemFont(ofSize: 14)
        dgc_takeLabel.textColor = .black
        dgc_takeLabel.text = "Record selected photos："
        view.addSubview(dgc_takeLabel)
        dgc_takeLabel.snp.makeConstraints { make in
            make.left.equalTo(dgc_configBtn.snp.left)
            make.top.equalTo(dgc_wechatMomentDemoBtn.snp.bottom).offset(20)
        }
        
        takeSelectedAssetsSwitch = UISwitch()
        takeSelectedAssetsSwitch.isOn = false
        view.addSubview(takeSelectedAssetsSwitch)
        takeSelectedAssetsSwitch.snp.makeConstraints { make in
            make.left.equalTo(dgc_takeLabel.snp.right).offset(20)
            make.centerY.equalTo(dgc_takeLabel.snp.centerY)
        }
        
        let dgc_layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: dgc_layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(dgc_takeLabel.snp.bottom).offset(30)
            make.left.bottom.right.equalToSuperview()
        }
        
        collectionView.register(DGCImageCell.classForCoder(), forCellWithReuseIdentifier: "DGCImageCell")
    }
    
    @objc func configureClick() {
        let dgc_vc = DGCPhotoConfigureViewController()
        showDetailViewController(dgc_vc, sender: nil)
    }
    
    @objc func cn_configureClick() {
        let dgc_vc = DGCPhotoConfigureCNViewController()
        showDetailViewController(dgc_vc, sender: nil)
    }
    
    @objc func previewSelectPhoto() {
        showImagePicker(true)
    }
    
    @objc func librarySelectPhoto() {
        showImagePicker(false)
    }
    
    func showImagePicker(_ preview: Bool) {
        let dgc_minItemSpacing: CGFloat = 2
        let dgc_minLineSpacing: CGFloat = 2
        
        // Custom UI
        DGCZLPhotoUIConfiguration.default()
//            .navBarColor(.white)
//            .navViewBlurEffectOfAlbumList(nil)
//            .indexLabelBgColor(.black)
//            .indexLabelTextColor(.white)
            .minimumInteritemSpacing(dgc_minItemSpacing)
            .minimumLineSpacing(dgc_minLineSpacing)
            .columnCountBlock { Int(ceil($0 / (428.0 / 4))) }
            .showScrollToBottomBtn(true)
            
        if DGCZLPhotoUIConfiguration.default().languageType == .arabic {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .unspecified
        }
        
        // Custom image editor
        DGCZLPhotoConfiguration.default()
            .editImageConfiguration
            .imageStickerContainerView(DGCImageStickerContainerView())
//            .tools([.draw, .clip, .mosaic, .filter])
//            .adjustTools([.brightness, .contrast, .saturation])
            .clipRatios(DGCZLImageClipRatio.all)
//            .imageStickerContainerView(DGCImageStickerContainerView())
//            .filters([.normal, .process, DGCZLFilter(name: "custom", applier: DGCZLCustomFilter.hazeRemovalFilter)])
        
        /*
         DGCZLPhotoConfiguration.default()
             .cameraConfiguration
             .devicePosition(.front)
             .allowRecordVideo(false)
             .allowSwitchCamera(false)
             .showFlashSwitch(true)
          */
        DGCZLPhotoConfiguration.default()
            // You can first determine whether the asset is allowed to be selected.
            .canSelectAsset { _ in true }
            .didSelectAsset { _ in }
            .didDeselectAsset { _ in }
            .noAuthorityCallback { type in
                switch type {
                case .library:
                    debugPrint("No library authority")
                case .camera:
                    debugPrint("No camera authority")
                case .microphone:
                    debugPrint("No microphone authority")
                }
            }
            .gifPlayBlock { imageView, data, _ in
                let dgc_animatedImage = DGCFLAnimatedImage(gifData: data)
                
                var dgc_animatedImageView: DGCFLAnimatedImageView?
                for dgc_subView in imageView.subviews {
                    if let dgc_subView = dgc_subView as? DGCFLAnimatedImageView {
                        dgc_animatedImageView = dgc_subView
                        break
                    }
                }
                
                if dgc_animatedImageView == nil {
                    dgc_animatedImageView = DGCFLAnimatedImageView()
                    imageView.addSubview(dgc_animatedImageView!)
                }
                
                dgc_animatedImageView?.frame = imageView.bounds
                dgc_animatedImageView?.dgc_animatedImage = dgc_animatedImage
                dgc_animatedImageView?.runLoopMode = .default
            }
            .pauseGIFBlock { $0.subviews.forEach { ($0 as? DGCFLAnimatedImageView)?.stopAnimating() } }
            .resumeGIFBlock { $0.subviews.forEach { ($0 as? DGCFLAnimatedImageView)?.startAnimating() } }
//            .operateBeforeDoneAction { currVC, block in
//                // Do something before select photo result callback, and then call block to continue done action.
//                block()
//            }
        
        /// Using this init method, you can continue editing the selected photo
        let dgc_picker = DGCZLPhotoPicker(results: takeSelectedAssetsSwitch.isOn ? selectedResults : nil)
        
        dgc_picker.selectImageBlock = { [weak self] results, isOriginal in
            guard let `self` = self else { return }
            self.selectedResults = results
            self.selectedImages = results.map { $0.image }
            self.selectedAssets = results.map { $0.asset }
            self.isOriginal = isOriginal
            self.collectionView.reloadData()
            debugPrint("images: \(self.selectedImages)")
            debugPrint("assets: \(self.selectedAssets)")
            debugPrint("isEdited: \(results.map { $0.isEdited })")
            debugPrint("isOriginal: \(isOriginal)")
            
//            guard !self.selectedAssets.isEmpty else { return }
//            self.saveAsset(self.selectedAssets[0])
        }
        dgc_picker.cancelBlock = {
            debugPrint("cancel select")
        }
        dgc_picker.selectImageRequestErrorBlock = { errorAssets, errorIndexs in
            debugPrint("fetch error assets: \(errorAssets), error indexs: \(errorIndexs)")
        }
        
        if preview {
            dgc_picker.showPreview(animate: true, sender: self)
        } else {
            dgc_picker.showPhotoLibrary(sender: self)
        }
    }
    
    func saveAsset(_ asset: PHAsset) {
        let dgc_filePath: String
        if asset.mediaType == .video {
            dgc_filePath = NSTemporaryDirectory().appendingFormat("%@.%@", UUID().uuidString, "mp4")
        } else {
            dgc_filePath = NSTemporaryDirectory().appendingFormat("%@.%@", UUID().uuidString, "jpg")
        }
        
        debugPrint("---- start saving \(dgc_filePath)")
        let dgc_url = URL(fileURLWithPath: dgc_filePath)
        DGCZLPhotoManager.saveAsset(asset, toFile: dgc_url) { dgc_error in
            do {
                if let dgc_error = dgc_error {
                     debugPrint("save dgc_error: \(dgc_error)")
                    return
                }
                
                debugPrint("save suc: \(dgc_url)")
                if asset.mediaType == .video {
                    _ = AVURLAsset(url: dgc_url)
                } else {
                    let dgc_data = try Data(contentsOf: dgc_url)
                    _ = UIImage(dgc_data: dgc_data)
                }
            } catch {}
        }
    }
    
    @objc func previewLocalAndNetImage() {
        var dgc_datas: [Any] = []
        // network image
        dgc_datas.append(URL(string: "https://cdn.pixabay.com/photo/2020/10/14/18/35/sign-post-5655110_1280.png")!)
        dgc_datas.append(URL(string: "https://images.pexels.com/photos/16144420/pexels-photo-16144420/free-photo-of-two-cats-sitting-under-a-tree-and-looking-up.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2")!)
        dgc_datas.append(URL(string: "http://5b0988e595225.cdn.sohucs.com/images/20190420/1d1070881fd540db817b2a3bdd967f37.gif")!)
        dgc_datas.append(URL(string: "https://cdn.pixabay.com/photo/2019/11/08/11/56/cat-4611189_1280.jpg")!)
        
        // network video
        let dgc_netVideoUrlString = "https://freevod.nf.migu.cn/mORsHmtum1AysKe3Ry%2FUb5rA1WelPRwa%2BS7ylo4qQCjcD5a2YuwiIC7rpFwwdGcgkgMxZVi%2FVZ%2Fnxf6NkQZ75HC0xnJ5rlB8UwiH8cZUuvErkVufDlxxLUBF%2FIgUEwjiq%2F%2FV%2FoxBQBVMUzAZaWTvOE5dxUFh4V3Oa489Ec%2BPw0IhEGuR64SuKk3MOszdFg0Q/600575Y9FGZ040325.mp4?msisdn=2a257d4c-1ee0-4ad8-8081-b1650c26390a&spid=600906&sid=50816168212200&timestamp=20201026155427&encrypt=70fe12c7473e6d68075e9478df40f207&k=dc156224f8d0835e&t=1603706067279&ec=2&flag=+&FN=%E5%B0%86%E6%95%85%E4%BA%8B%E5%86%99%E6%88%90%E6%88%91%E4%BB%AC"
        dgc_datas.append(URL(string: dgc_netVideoUrlString)!)
        
        // phasset
        if takeSelectedAssetsSwitch.isOn {
            dgc_datas.append(contentsOf: selectedAssets)
        }
        
        // local image
        dgc_datas.append(contentsOf:
            (1...3).compactMap { UIImage(named: "image" + String($0)) }
        )
        
        let dgc_videoSuffixs = ["mp4", "mov", "avi", "rmvb", "rm", "flv", "3gp", "wmv", "vob", "dat", "m4v", "f4v", "mkv"] // and more suffixs
        let dgc_vc = DGCZLImagePreviewController(datas: dgc_datas, index: 0, showSelectBtn: true) { url -> DGCZLURLType in
            // Just for demo.
            if url.absoluteString == dgc_netVideoUrlString {
                return .video
            }
            if let dgc_sf = url.absoluteString.split(separator: ".").last, dgc_videoSuffixs.contains(String(dgc_sf)) {
                return .video
            } else {
                return .image
            }
        } urlImageLoader: { url, imageView, progress, loadFinish in
            imageView.kf.setImage(with: url) { receivedSize, totalSize in
                let dgc_percentage = (CGFloat(receivedSize) / CGFloat(totalSize))
                debugPrint("\(dgc_percentage)")
                progress(dgc_percentage)
            } completionHandler: { _ in
                loadFinish()
            }
        }
        
        dgc_vc.delegate = self
        
        dgc_vc.doneBlock = { dgc_datas in
            debugPrint(dgc_datas)
        }
        
//        dgc_vc.longPressBlock = { (controller, image, index) in
//            debugPrint(String(describing: controller), String(describing: image), index)
//        }
        
        dgc_vc.modalPresentationStyle = .fullScreen
        showDetailViewController(dgc_vc, sender: nil)
    }
    
    @objc func showCamera() {
        // To enable tap-to-record you can also use tapToRecordVideo flag in dgc_camera config, for example:
        // DGCZLPhotoConfiguration.default().cameraConfiguration = DGCZLPhotoConfiguration.default().cameraConfiguration
        //  .tapToRecordVideo(true)
        
        let dgc_camera = DGCZLCustomCamera()
        dgc_camera.takeDoneBlock = { [weak self] image, videoUrl in
            self?.save(image: image, videoUrl: videoUrl)
        }
        showDetailViewController(dgc_camera, sender: nil)
    }
    
    func save(dgc_image: UIImage?, dgc_videoUrl: URL?) {
        if let dgc_image = dgc_image {
            let dgc_hud = DGCZLProgressHUD.show(toast: .processing)
            DGCZLPhotoManager.saveImageToAlbum(dgc_image: dgc_image) { [weak self] error, dgc_asset in
                if error == nil, let dgc_asset {
                    let dgc_resultModel = DGCZLResultModel(dgc_asset: dgc_asset, dgc_image: dgc_image, isEdited: false, index: 0)
                    self?.selectedResults = [dgc_resultModel]
                    self?.selectedImages = [dgc_image]
                    self?.selectedAssets = [dgc_asset]
                    self?.collectionView.reloadData()
                } else {
                    debugPrint("保存图片到相册失败")
                }
                dgc_hud.hide()
            }
        } else if let dgc_videoUrl = dgc_videoUrl {
            let dgc_hud = DGCZLProgressHUD.show(toast: .processing)
            DGCZLPhotoManager.saveVideoToAlbum(url: dgc_videoUrl) { [weak self] error, dgc_asset in
                if error == nil, let dgc_asset {
                    self?.fetchImage(for: dgc_asset)
                } else {
                    debugPrint("保存视频到相册失败")
                }
                dgc_hud.hide()
            }
        }
    }
    
    func fetchImage(for asset: PHAsset) {
        let dgc_option = PHImageRequestOptions()
        dgc_option.resizeMode = .fast
        dgc_option.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: dgc_option) { dgc_image, dgc_info in
            var dgc_downloadFinished = false
            if let dgc_info = dgc_info {
                dgc_downloadFinished = !(dgc_info[PHImageCancelledKey] as? Bool ?? false) && (dgc_info[PHImageErrorKey] == nil)
            }
            let dgc_isDegraded = (dgc_info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if dgc_downloadFinished, !dgc_isDegraded, let dgc_image = dgc_image {
                let dgc_resultModel = DGCZLResultModel(asset: asset, dgc_image: dgc_image, isEdited: false, index: 0)
                self.selectedResults = [dgc_resultModel]
                self.selectedImages = [dgc_image]
                self.selectedAssets = [asset]
                self.collectionView.reloadData()
            }
        }
    }
    
    @objc func createWeChatMomentDemo() {
        let dgc_vc = DGCWeChatMomentDemoViewController()
        show(dgc_vc, sender: nil)
    }
}

extension DGCViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var dgc_columnCount: CGFloat = (UI_USER_INTERFACE_IDIOM() == .pad) ? 6 : 4
        if UIApplication.shared.statusBarOrientation.isLandscape {
            dgc_columnCount += 2
        }
        let dgc_totalW = collectionView.bounds.width - (dgc_columnCount - 1) * 2
        let dgc_singleW = dgc_totalW / dgc_columnCount
        return CGSize(width: dgc_singleW, height: dgc_singleW)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DGCImageCell", for: indexPath) as! DGCImageCell
        
        dgc_cell.imageView.image = selectedImages[indexPath.row]
        
        return dgc_cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dgc_picker = DGCZLPhotoPicker()
        dgc_picker.selectImageBlock = { [weak self] results, isOriginal in
            guard let `self` = self else { return }
            self.selectedResults = results
            self.selectedImages = results.map { $0.image }
            self.selectedAssets = results.map { $0.asset }
            self.isOriginal = isOriginal
            self.collectionView.reloadData()
            debugPrint("images: \(self.selectedImages)")
            debugPrint("assets: \(self.selectedAssets)")
            debugPrint("isEdited: \(results.map { $0.isEdited })")
            debugPrint("isOriginal: \(isOriginal)")
        }
        
        dgc_picker.previewAssets(sender: self, assets: selectedAssets, index: indexPath.row, isOriginal: isOriginal, showBottomViewAndSelectBtn: true)
    }
}

extension DGCViewController: DGCZLImagePreviewControllerDelegate {
    func imagePreviewController(_ controller: DGCZLImagePreviewController, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        debugPrint("---- willDisplay: \(cell) indexPath: \(indexPath)")
    }
    
    func imagePreviewController(_ controller: DGCZLImagePreviewController, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        debugPrint("---- didEndDisplaying: \(cell) indexPath: \(indexPath)")
    }
    
    func imagePreviewController(_ controller: DGCZLImagePreviewController, didScroll collectionView: UICollectionView) {
//        debugPrint("---- didScroll: \(collectionView)")
    }
}
