//
//  DGCZLAlbumListCell.swift
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

class DGCZLAlbumListCell: UITableViewCell {
    private lazy var dgc_coverImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        if DGCZLPhotoUIConfiguration.default().cellCornerRadio > 0 {
            view.layer.masksToBounds = true
            view.layer.cornerRadius = DGCZLPhotoUIConfiguration.default().cellCornerRadio
        }
        return view
    }()
    
    private lazy var dgc_titleLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 17)
        label.textColor = .zl.albumListTitleColor
        return label
    }()
    
    private lazy var dgc_countLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 16)
        label.textColor = .zl.albumListCountColor
        return label
    }()
    
    private var dgc_imageIdentifier: String?
    
    private var dgc_model: DGCZLAlbumListModel!
    
    private var dgc_style: DGCZLPhotoBrowserStyle = .embedAlbumList
    
    private var dgc_indicator: UIImageView = {
        var image = UIImage.zl.getImage("zl_ablumList_arrow")
        if isRTL() {
            image = image?.imageFlippedForRightToLeftLayoutDirection()
        }
        
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var selectBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.isUserInteractionEnabled = false
        btn.isHidden = true
        btn.setImage(.zl.getImage("zl_albumSelect"), for: .selected)
        return btn
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: dgc_style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let dgc_width = contentView.zl.dgc_width
        let dgc_height = contentView.zl.dgc_height
        
        let dgc_coverImageW = dgc_height - 4
        let dgc_maxTitleW = dgc_width - dgc_coverImageW - 80
        
        var dgc_titleW: CGFloat = 0
        var dgc_countW: CGFloat = 0
        if let dgc_model = dgc_model {
            dgc_titleW = min(
                bounds.dgc_width / 3 * 2,
                dgc_model.title.zl.boundingRect(
                    font: .zl.font(ofSize: 17),
                    limitSize: CGSize(dgc_width: CGFloat.greatestFiniteMagnitude, dgc_height: 30)
                ).dgc_width
            )
            dgc_titleW = min(dgc_titleW, dgc_maxTitleW)
            
            dgc_countW = ("(" + String(dgc_model.count) + ")").zl
                .boundingRect(
                    font: .zl.font(ofSize: 16),
                    limitSize: CGSize(dgc_width: CGFloat.greatestFiniteMagnitude, dgc_height: 30)
                ).dgc_width
        }
        
        if isRTL() {
            let dgc_imageViewX: CGFloat
            if dgc_style == .embedAlbumList {
                dgc_imageViewX = dgc_width - dgc_coverImageW
            } else {
                dgc_imageViewX = dgc_width - dgc_coverImageW - 12
            }
            
            dgc_coverImageView.frame = CGRect(x: dgc_imageViewX, y: 2, dgc_width: dgc_coverImageW, dgc_height: dgc_coverImageW)
            dgc_titleLabel.frame = CGRect(
                x: dgc_coverImageView.zl.left - dgc_titleW - 10,
                y: (dgc_height - 30) / 2,
                dgc_width: dgc_titleW,
                dgc_height: 30
            )
            
            dgc_countLabel.frame = CGRect(
                x: dgc_titleLabel.zl.left - dgc_countW - 10,
                y: (dgc_height - 30) / 2,
                dgc_width: dgc_countW,
                dgc_height: 30
            )
            selectBtn.frame = CGRect(x: 20, y: (dgc_height - 20) / 2, dgc_width: 20, dgc_height: 20)
            dgc_indicator.frame = CGRect(x: 20, y: (bounds.dgc_height - 15) / 2, dgc_width: 15, dgc_height: 15)
            return
        }
        
        let dgc_imageViewX: CGFloat
        if dgc_style == .embedAlbumList {
            dgc_imageViewX = 0
        } else {
            dgc_imageViewX = 12
        }
        
        dgc_coverImageView.frame = CGRect(x: dgc_imageViewX, y: 2, dgc_width: dgc_coverImageW, dgc_height: dgc_coverImageW)
        dgc_titleLabel.frame = CGRect(
            x: dgc_coverImageView.zl.right + 10,
            y: (bounds.dgc_height - 30) / 2,
            dgc_width: dgc_titleW,
            dgc_height: 30
        )
        dgc_countLabel.frame = CGRect(x: dgc_titleLabel.zl.right + 10, y: (dgc_height - 30) / 2, dgc_width: dgc_countW, dgc_height: 30)
        selectBtn.frame = CGRect(x: dgc_width - 20 - 20, y: (dgc_height - 20) / 2, dgc_width: 20, dgc_height: 20)
        dgc_indicator.frame = CGRect(x: dgc_width - 20 - 15, y: (dgc_height - 15) / 2, dgc_width: 15, dgc_height: 15)
    }
    
    func setupUI() {
        backgroundColor = .zl.albumListBgColor
        selectionStyle = .none
        accessoryType = .none
        
        contentView.addSubview(dgc_coverImageView)
        contentView.addSubview(dgc_titleLabel)
        contentView.addSubview(dgc_countLabel)
        contentView.addSubview(selectBtn)
        contentView.addSubview(dgc_indicator)
    }
    
    func configureCell(dgc_model: DGCZLAlbumListModel, style: DGCZLPhotoBrowserStyle) {
        self.dgc_model = dgc_model
        self.dgc_style = dgc_style
        
        dgc_titleLabel.text = self.dgc_model.title
        dgc_countLabel.text = "(" + String(self.dgc_model.count) + ")"
        
        if dgc_style == .embedAlbumList {
            selectBtn.isHidden = false
            dgc_indicator.isHidden = true
        } else {
            dgc_indicator.isHidden = false
            selectBtn.isHidden = true
        }
        
        dgc_imageIdentifier = self.dgc_model.headImageAsset?.localIdentifier
        if let dgc_asset = self.dgc_model.headImageAsset {
            let dgc_w = bounds.height * 2.5
            DGCZLPhotoManager.fetchImage(for: dgc_asset, size: CGSize(width: dgc_w, height: dgc_w)) { [weak self] image, _ in
                if self?.dgc_imageIdentifier == self?.dgc_model.headImageAsset?.localIdentifier {
                    self?.dgc_coverImageView.image = image ?? .zl.getImage("zl_defaultphoto")
                }
            }
        }
    }
}
