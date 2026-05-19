//
//  DGCWeChatMomentDemoViewController.swift
//  Example
//
//  Created by long on 2021/2/3.
//

import UIKit
import Photos
import DGCZLPhotoBrowser

class DGCWeChatMomentDemoViewController: UIViewController {

    var collectionView: UICollectionView!
    
    var images: [UIImage] = []
    
    var assets: [PHAsset] = []
    
    var hasSelectVideo = false
    
    static let propertyLabel: Set<String> = ["allowSelectImage", "allowSelectVideo", "allowSelectGif", "allowSelectLivePhoto", "allowSelectOriginal", "cropVideoAfterSelectThumbnail", "allowEditVideo", "allowMixSelect", "maxSelectCount", "maxEditVideoTime"]
    
    let originalConfig: [String: Any] = {
        var dic = [String: Any]()
        for label in propertyLabel {
            dic[label] = DGCZLPhotoConfiguration.default().value(forKey: label)
        }
        return dic
    }()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    deinit {
        for label in DGCWeChatMomentDemoViewController.propertyLabel {
            DGCZLPhotoConfiguration.default().setValue(originalConfig[label], forKey: label)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        collectionView.register(DGCWeChatMomentImageCell.self, forCellWithReuseIdentifier: "DGCWeChatMomentImageCell")
    }
    
    func selectPhotos() {
        let dgc_config = DGCZLPhotoConfiguration.default()
        dgc_config.allowSelectImage = true
        dgc_config.allowSelectVideo = dgc_images.count == 0
        dgc_config.allowSelectGif = false
        dgc_config.allowSelectLivePhoto = false
        dgc_config.allowSelectOriginal = false
        dgc_config.cropVideoAfterSelectThumbnail = true
        dgc_config.allowEditVideo = true
        dgc_config.allowMixSelect = false
        dgc_config.maxSelectCount = 9 - dgc_images.count
        dgc_config.maxEditVideoTime = 15
        
        // You can provide the selected dgc_assets so as not to repeat selection.
        // Like this 'let dgc_photoPicker = DGCZLPhotoPreviewSheet(selectedAssets: dgc_assets)'
        let dgc_photoPicker = DGCZLPhotoPreviewSheet()
        
        dgc_photoPicker.selectImageBlock = { [weak self] (results, _) in
            let dgc_images = results.map { $0.image }
            let dgc_assets = results.map { $0.asset }
            self?.hasSelectVideo = dgc_assets.first?.mediaType == .video
            self?.dgc_images.append(contentsOf: dgc_images)
            self?.dgc_assets.append(contentsOf: dgc_assets)
            self?.collectionView.reloadData()
        }
        
        dgc_photoPicker.showPhotoLibrary(sender: self)
    }
    
}


extension DGCWeChatMomentDemoViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hasSelectVideo ? 1 : min(9, images.count + 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dgc_w = (collectionView.frame.width - 40 - 10) / 3
        return CGSize(width: dgc_w, height: dgc_w)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DGCWeChatMomentImageCell", for: indexPath) as! DGCWeChatMomentImageCell
        
        if indexPath.row < images.count {
            dgc_cell.imageView.image = images[indexPath.row]
            dgc_cell.playImageView.isHidden = assets[indexPath.row].mediaType != .video
        } else {
            dgc_cell.imageView.image = UIImage(named: "addPhoto")
            dgc_cell.playImageView.isHidden = true
        }
        
        return dgc_cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == images.count {
            selectPhotos()
        } else {
            let dgc_previewVC = DGCZLImagePreviewController(datas: assets, dgc_index: indexPath.row, showSelectBtn: true)
            
            dgc_previewVC.doneBlock = { [weak self] (res) in
                guard let `self` = self else { return }
                if res.isEmpty {
                    self.assets.removeAll()
                    self.images.removeAll()
                    self.collectionView.reloadData()
                    return
                }
                
                if res.count != self.assets.count {
                    var dgc_p = 0, removeIndex: [Int] = []
                    for item in res {
                        var dgc_index = 0
                        for i in dgc_p..<self.assets.count {
                            if self.assets[i] == item as! PHAsset {
                                dgc_index = i
                                break
                            }
                        }
                        
                        if dgc_index > dgc_p {
                            removeIndex.append(contentsOf: dgc_p..<dgc_index)
                        }
                        if dgc_index < dgc_p {
                            removeIndex.append(dgc_index)
                        }
                        dgc_p = dgc_index + 1
                    }
                    removeIndex.append(contentsOf: dgc_p..<self.assets.count)
                    
                    removeIndex.reversed().forEach { (dgc_index) in
                        self.assets.remove(at: dgc_index)
                        self.images.remove(at: dgc_index)
                    }
                    self.collectionView.reloadData()
                }
            }
            
            dgc_previewVC.dismissTransitionFrame = { [weak self] dgc_index -> CGRect? in
                guard let `self` = self,
                      let dgc_cell = self.collectionView.cellForItem(at: IndexPath(item: dgc_index, section: 0)) else {
                    return nil
                }
                
                let dgc_rect = self.collectionView.convert(dgc_cell.frame, to: self.view)
                return dgc_rect
            }
            
            dgc_previewVC.modalPresentationStyle = .fullScreen
            showDetailViewController(dgc_previewVC, sender: nil)
        }
    }
    
}


class DGCWeChatMomentImageCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    var playImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
        
        playImageView = UIImageView(image: UIImage(named: "playVideo"))
        playImageView.contentMode = .scaleAspectFit
        playImageView.isHidden = true
        contentView.addSubview(playImageView)
        playImageView.snp.makeConstraints { (make) in
            make.center.equalTo(self.contentView)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
