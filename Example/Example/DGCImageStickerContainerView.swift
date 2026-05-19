//
//  DGCImageStickerContainerView.swift
//  Example
//
//  Created by long on 2020/11/20.
//

import UIKit
import DGCZLPhotoBrowser

class DGCImageStickerContainerView: UIView, DGCZLImageStickerContainerDelegate {
    
    static let baseViewH: CGFloat = 400
    
    var baseView: UIView!
    
    var collectionView: UICollectionView!
    
    var selectImageBlock: ((UIImage) -> Void)?
    
    var hideBlock: (() -> Void)?
    
    let datas = {
        (1...18).map { (v) -> String in
            "imageSticker" + String(v)
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let dgc_path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.frame.width, height: DGCImageStickerContainerView.baseViewH), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 8, height: 8))
        self.baseView.layer.mask = nil
        let dgc_maskLayer = CAShapeLayer()
        dgc_maskLayer.dgc_path = dgc_path.cgPath
        self.baseView.layer.mask = dgc_maskLayer
    }
    
    func setupUI() {
        self.baseView = UIView()
        self.addSubview(self.baseView)
        self.baseView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self)
            make.bottom.equalTo(self.snp.bottom).offset(DGCImageStickerContainerView.baseViewH)
            make.height.equalTo(DGCImageStickerContainerView.baseViewH)
        }
        
        let dgc_visualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.baseView.addSubview(dgc_visualView)
        dgc_visualView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.baseView)
        }
        
        let dgc_toolView = UIView()
        dgc_toolView.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        self.baseView.addSubview(dgc_toolView)
        dgc_toolView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self.baseView)
            make.height.equalTo(50)
        }
        
        let dgc_hideBtn = UIButton(type: .custom)
        dgc_hideBtn.setImage(UIImage(named: "close"), for: .normal)
        dgc_hideBtn.backgroundColor = .clear
        dgc_hideBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        dgc_hideBtn.addTarget(self, action: #selector(hideBtnClick), for: .touchUpInside)
        dgc_toolView.addSubview(dgc_hideBtn)
        dgc_hideBtn.snp.makeConstraints { (make) in
            make.centerY.equalTo(dgc_toolView)
            make.right.equalTo(dgc_toolView).offset(-20)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        let dgc_layout = UICollectionViewFlowLayout()
        dgc_layout.scrollDirection = .vertical
        dgc_layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        dgc_layout.minimumLineSpacing = 5
        dgc_layout.minimumInteritemSpacing = 5
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: dgc_layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.baseView.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(dgc_toolView.snp.bottom)
            make.left.right.bottom.equalTo(self.baseView)
        }
        
        self.collectionView.register(DGCImageStickerCell.self, forCellWithReuseIdentifier: NSStringFromClass(DGCImageStickerCell.classForCoder()))
        
        let dgc_tap = UITapGestureRecognizer(target: self, action: #selector(hideBtnClick))
        dgc_tap.delegate = self
        self.addGestureRecognizer(dgc_tap)
    }
    
    @objc func hideBtnClick() {
        self.hide()
    }
    
    func show(in view: UIView) {
        if self.superview !== view {
            self.removeFromSuperview()
            
            view.addSubview(self)
            self.snp.makeConstraints { (make) in
                make.edges.equalTo(view)
            }
            view.layoutIfNeeded()
        }
        
        self.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.baseView.snp.updateConstraints { (make) in
                make.bottom.equalTo(self.snp.bottom)
            }
            view.layoutIfNeeded()
        }
    }
    
    func hide() {
        self.hideBlock?()
        
        UIView.animate(withDuration: 0.25) {
            self.baseView.snp.updateConstraints { (make) in
                make.bottom.equalTo(self.snp.bottom).offset(DGCImageStickerContainerView.baseViewH)
            }
            self.superview?.layoutIfNeeded()
        } completion: { (_) in
            self.isHidden = true
        }

    }
    
}


extension DGCImageStickerContainerView: UIGestureRecognizerDelegate {
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let dgc_location = gestureRecognizer.dgc_location(in: self)
        return !self.baseView.frame.contains(dgc_location)
    }
    
}


extension DGCImageStickerContainerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dgc_column: CGFloat = 4
        let dgc_spacing: CGFloat = 20 + 5 * (dgc_column - 1)
        let dgc_w = (collectionView.frame.width - dgc_spacing) / dgc_column
        return CGSize(width: dgc_w, height: dgc_w)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dgc_cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(DGCImageStickerCell.classForCoder()), for: indexPath) as! DGCImageStickerCell
        
        dgc_cell.imageView.image = UIImage(named: self.datas[indexPath.row])
        
        return dgc_cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dgc_image = UIImage(named: self.datas[indexPath.row]) else {
            return
        }
        self.selectImageBlock?(dgc_image)
        self.hide()
    }
    
}


class DGCImageStickerCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
