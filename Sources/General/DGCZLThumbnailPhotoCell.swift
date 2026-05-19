//
//  DGCZLThumbnailPhotoCell.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/12.
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

class DGCZLThumbnailPhotoCell: UICollectionViewCell {
    private let dgc_selectBtnWH: CGFloat = 24
    
    private lazy var dgc_containerView = UIView()
    
    private lazy var dgc_bottomShadowView = UIImageView(image: .zl.getImage("zl_shadow"))
    
    private lazy var dgc_videoTag = UIImageView(image: .zl.getImage("zl_video"))
    
    private lazy var dgc_livePhotoTag = UIImageView(image: .zl.getImage("zl_livePhoto"))
    
    private lazy var dgc_editImageTag = UIImageView(image: .zl.getImage("zl_editImage_tag"))
    
    private lazy var dgc_descLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 13)
        label.textAlignment = .right
        label.textColor = .white
        return label
    }()
    
    private lazy var dgc_progressView: DGCZLProgressView = {
        let view = DGCZLProgressView()
        view.isHidden = true
        return view
    }()
    
    private var dgc_imageIdentifier = ""
    
    private var dgc_smallImageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    private var dgc_bigImageReqeustID: PHImageRequestID = PHInvalidImageRequestID
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    lazy var btnSelect: DGCZLEnlargeButton = {
        let btn = DGCZLEnlargeButton(type: .custom)
        btn.setBackgroundImage(.zl.getImage("zl_btn_unselected"), for: .normal)
        btn.setBackgroundImage(.zl.getImage("zl_btn_selected"), for: .selected)
        btn.addTarget(self, action: #selector(btnSelectClick), for: .touchUpInside)
        btn.enlargeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 10, right: 5)
        return btn
    }()
    
    lazy var coverView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()
    
    lazy var indexLabel: UILabel = {
        let label = UILabel()
        label.textColor = .zl.indexLabelTextColor
        label.backgroundColor = .zl.indexLabelBgColor
        if DGCZLPhotoUIConfiguration.default().showIndexOnSelectBtn {
            label.font = .zl.font(ofSize: 14)
            label.textAlignment = .center
            label.layer.cornerRadius = dgc_selectBtnWH / 2
            label.layer.masksToBounds = true
        } else {
            label.font = .zl.font(ofSize: 14, bold: true)
            label.textAlignment = .left
        }
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    var enableSelect = true {
        didSet {
            dgc_containerView.alpha = enableSelect ? 1 : 0.2
        }
    }
    
    var selectedBlock: ((@escaping (Bool) -> Void) -> Void)?
    
    var model: DGCZLPhotoModel! {
        didSet {
            dgc_configureCell()
        }
    }
    
    var index = 0 {
        didSet {
            indexLabel.text = String(index)
        }
    }
    
    deinit {
        zl_debugPrint("DGCZLThumbnailPhotoCell deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(coverView)
        contentView.addSubview(dgc_containerView)
        dgc_containerView.addSubview(btnSelect)
        dgc_containerView.addSubview(indexLabel)
        dgc_containerView.addSubview(dgc_bottomShadowView)
        dgc_bottomShadowView.addSubview(dgc_videoTag)
        dgc_bottomShadowView.addSubview(dgc_livePhotoTag)
        dgc_bottomShadowView.addSubview(dgc_editImageTag)
        dgc_bottomShadowView.addSubview(dgc_descLabel)
        dgc_containerView.addSubview(dgc_progressView)
        
        if DGCZLPhotoUIConfiguration.default().showSelectedBorder {
            layer.borderColor = UIColor.zl.selectedBorderColor.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = bounds
        
        dgc_containerView.frame = bounds
        coverView.frame = bounds
        btnSelect.frame = CGRect(x: bounds.width - 32, y: 8, width: dgc_selectBtnWH, height: dgc_selectBtnWH)
        if DGCZLPhotoUIConfiguration.default().showIndexOnSelectBtn {
            indexLabel.frame = btnSelect.frame
        } else {
            indexLabel.frame = CGRect(x: 8, y: 5, width: 50, height: dgc_selectBtnWH)
        }
        
        dgc_bottomShadowView.frame = CGRect(x: 0, y: bounds.height - 25, width: bounds.width, height: 25)
        dgc_videoTag.frame = CGRect(x: 5, y: 1, width: 20, height: 15)
        dgc_livePhotoTag.frame = CGRect(x: 5, y: -1, width: 20, height: 20)
        dgc_editImageTag.frame = CGRect(x: 5, y: -1, width: 20, height: 20)
        dgc_descLabel.frame = CGRect(x: 30, y: 1, width: bounds.width - 35, height: 17)
        dgc_progressView.frame = CGRect(x: (bounds.width - 20) / 2, y: (bounds.height - 20) / 2, width: 20, height: 20)
    }
    
    @objc func btnSelectClick() {
        selectedBlock?({ [weak self] isSelected in
            self?.btnSelect.isSelected = isSelected
            self?.btnSelect.layer.removeAllAnimations()
            
            if isSelected,
               DGCZLPhotoUIConfiguration.default().animateSelectBtnWhenSelectInThumbVC {
                self?.btnSelect.layer.add(DGCZLAnimationUtils.springAnimation(), forKey: nil)
            }
            
            if isSelected {
                self?.dgc_fetchBigImage()
            } else {
                self?.dgc_progressView.isHidden = true
                self?.dgc_cancelFetchBigImage()
            }
        })
    }
    
    private func dgc_configureCell() {
        let dgc_config = DGCZLPhotoConfiguration.default()
        let dgc_uiConfig = DGCZLPhotoUIConfiguration.default()
        
        if dgc_uiConfig.cellCornerRadio > 0 {
            layer.cornerRadius = DGCZLPhotoUIConfiguration.default().cellCornerRadio
            layer.masksToBounds = true
        }
        
        if model.type == .video {
            dgc_bottomShadowView.isHidden = false
            dgc_videoTag.isHidden = false
            dgc_livePhotoTag.isHidden = true
            dgc_editImageTag.isHidden = true
            dgc_descLabel.text = model.duration
        } else if model.type == .gif {
            dgc_bottomShadowView.isHidden = !dgc_config.allowSelectGif
            dgc_videoTag.isHidden = true
            dgc_livePhotoTag.isHidden = true
            dgc_editImageTag.isHidden = true
            dgc_descLabel.text = "GIF"
        } else if model.type == .livePhoto {
            dgc_bottomShadowView.isHidden = !dgc_config.allowSelectLivePhoto
            dgc_videoTag.isHidden = true
            dgc_livePhotoTag.isHidden = false
            dgc_editImageTag.isHidden = true
            dgc_descLabel.text = "Live"
        } else {
            if let _ = model.dgc_editImage {
                dgc_bottomShadowView.isHidden = false
                dgc_videoTag.isHidden = true
                dgc_livePhotoTag.isHidden = true
                dgc_editImageTag.isHidden = false
                dgc_descLabel.text = ""
            } else {
                dgc_bottomShadowView.isHidden = true
            }
        }
        
        let dgc_showSelBtn: Bool
        if dgc_config.maxSelectCount > 1 {
            if !dgc_config.allowMixSelect {
                dgc_showSelBtn = model.type.rawValue < DGCZLPhotoModel.DGCMediaType.video.rawValue
            } else {
                dgc_showSelBtn = true
            }
        } else {
            dgc_showSelBtn = dgc_config.showSelectBtnWhenSingleSelect
        }
        
        btnSelect.isHidden = !dgc_showSelBtn
        btnSelect.isUserInteractionEnabled = dgc_showSelBtn
        btnSelect.isSelected = model.isSelected
        
        if model.isSelected {
            dgc_fetchBigImage()
        } else {
            dgc_cancelFetchBigImage()
        }
        
        if let dgc_editImage = model.dgc_editImage {
            imageView.image = dgc_editImage
        } else {
            dgc_fetchSmallImage()
        }
    }
    
    private func dgc_fetchSmallImage() {
        let dgc_size: CGSize
        let dgc_maxSideLength = bounds.width * 2
        if model.whRatio > 1 {
            let dgc_w = dgc_maxSideLength * model.whRatio
            dgc_size = CGSize(width: dgc_w, height: dgc_maxSideLength)
        } else {
            let dgc_h = dgc_maxSideLength / model.whRatio
            dgc_size = CGSize(width: dgc_maxSideLength, height: dgc_h)
        }
        
        if dgc_smallImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_smallImageRequestID)
        }
        
        dgc_imageIdentifier = model.ident
        imageView.image = nil
        dgc_smallImageRequestID = DGCZLPhotoManager.fetchImage(for: model.asset, dgc_size: dgc_size, completion: { [weak self] image, isDegraded in
            if self?.dgc_imageIdentifier == self?.model.ident {
                self?.imageView.image = image
            }
            if !isDegraded {
                self?.dgc_smallImageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    private func dgc_fetchBigImage() {
        dgc_cancelFetchBigImage()
        
        dgc_bigImageReqeustID = DGCZLPhotoManager.fetchOriginalImageData(for: model.asset, progress: { [weak self] progress, _, _, _ in
            if self?.model.isSelected == true {
                self?.dgc_progressView.isHidden = false
                self?.dgc_progressView.progress = max(0.1, progress)
                self?.imageView.alpha = 0.5
                if progress >= 1 {
                    self?.dgc_resetProgressViewStatus()
                }
            } else {
                self?.dgc_cancelFetchBigImage()
            }
        }, completion: { [weak self] _, _, _ in
            self?.dgc_resetProgressViewStatus()
        })
    }
    
    private func dgc_cancelFetchBigImage() {
        if dgc_bigImageReqeustID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(dgc_bigImageReqeustID)
        }
        dgc_resetProgressViewStatus()
    }
    
    private func dgc_resetProgressViewStatus() {
        dgc_progressView.isHidden = true
        imageView.alpha = 1
    }
}
