//
//  DGCZLAddPhotoCell.swift
//  DGCZLPhotoBrowser
//
//  Created by ruby109 on 2020/11/3.
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
import Foundation

class DGCZLAddPhotoCell: UICollectionViewCell {
    private lazy var dgc_imageView: UIImageView = {
        let view = UIImageView(image: .zl.getImage("zl_addPhoto"))
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    deinit {
        zl_debugPrint("DGCZLAddPhotoCell deinit")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dgc_imageView.frame = CGRect(x: 0, y: 0, width: bounds.width / 3, height: bounds.width / 3)
        dgc_imageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func setupUI() {
        if DGCZLPhotoUIConfiguration.default().cellCornerRadio > 0 {
            layer.masksToBounds = true
            layer.cornerRadius = DGCZLPhotoUIConfiguration.default().cellCornerRadio
        }
        
        backgroundColor = .zl.cameraCellBgColor
        contentView.addSubview(dgc_imageView)
    }
}
