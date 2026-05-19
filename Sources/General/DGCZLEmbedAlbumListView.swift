//
//  DGCZLEmbedAlbumListView.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/9/7.
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

class DGCZLEmbedAlbumListView: UIView {
    static let rowH: CGFloat = 60
    
    private var dgc_selectedAlbum: DGCZLAlbumListModel?
    
    private lazy var dgc_tableBgView = UIView()
    
    private lazy var dgc_tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .zl.albumListBgColor
        view.tableFooterView = UIView()
        view.rowHeight = DGCZLEmbedAlbumListView.rowH
        view.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        view.separatorColor = .zl.separatorLineColor
        view.delegate = self
        view.dataSource = self
        DGCZLAlbumListCell.zl.register(view)
        return view
    }()
    
    private var dgc_arrDataSource: [DGCZLAlbumListModel] = []
    
    var selectAlbumBlock: ((DGCZLAlbumListModel) -> Void)?
    
    var hideBlock: (() -> Void)?
    
    private var dgc_orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
    
    init(dgc_selectedAlbum: DGCZLAlbumListModel?) {
        self.dgc_selectedAlbum = dgc_selectedAlbum
        super.init(frame: .zero)
        dgc_setupUI()
        dgc_loadAlbumList()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let dgc_currOri = UIApplication.shared.statusBarOrientation
        
        guard dgc_currOri != dgc_orientation else {
            return
        }
        dgc_orientation = dgc_currOri
        
        guard !isHidden else {
            return
        }
        
        let dgc_bgFrame = dgc_calculateBgViewBounds()
        
        let dgc_path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frame.width, height: dgc_bgFrame.height), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
        dgc_tableBgView.layer.mask = nil
        let dgc_maskLayer = CAShapeLayer()
        dgc_maskLayer.dgc_path = dgc_path.cgPath
        dgc_tableBgView.layer.mask = dgc_maskLayer
        
        dgc_tableBgView.frame = dgc_bgFrame
        dgc_tableView.frame = dgc_tableBgView.bounds
    }
    
    private func dgc_setupUI() {
        clipsToBounds = true
        
        backgroundColor = .zl.embedAlbumListTranslucentColor
        
        addSubview(dgc_tableBgView)
        dgc_tableBgView.addSubview(dgc_tableView)
        
        let dgc_tap = UITapGestureRecognizer(target: self, action: #selector(dgc_tapAction(_:)))
        dgc_tap.delegate = self
        addGestureRecognizer(dgc_tap)
    }
    
    private func dgc_loadAlbumList(completion: (() -> Void)? = nil) {
        DispatchQueue.global().async {
            DGCZLPhotoManager.getPhotoAlbumList(
                ascending: DGCZLPhotoUIConfiguration.default().sortAscending,
                allowSelectImage: DGCZLPhotoConfiguration.default().allowSelectImage,
                allowSelectVideo: DGCZLPhotoConfiguration.default().allowSelectVideo
            ) { [weak self] albumList in
                self?.dgc_arrDataSource.removeAll()
                self?.dgc_arrDataSource.append(contentsOf: albumList)
                
                ZLMainAsync {
                    completion?()
                    self?.dgc_tableView.reloadData()
                }
            }
        }
    }
    
    private func dgc_calculateBgViewBounds() -> CGRect {
        let dgc_contentH = CGFloat(dgc_arrDataSource.count) * DGCZLEmbedAlbumListView.rowH
        
        let dgc_maxH: CGFloat
        if UIApplication.shared.statusBarOrientation.isPortrait {
            dgc_maxH = min(frame.height * 0.7, dgc_contentH)
        } else {
            dgc_maxH = min(frame.height * 0.8, dgc_contentH)
        }
        
        return CGRect(x: 0, y: 0, width: frame.width, height: dgc_maxH)
    }
    
    @objc private func dgc_tapAction(_ tap: UITapGestureRecognizer) {
        hide()
        hideBlock?()
    }
    
    /// 这里不采用监听相册发生变化的方式，是因为每次变化，系统都会回调多次，造成重复获取相册列表
    func show(reloadAlbumList: Bool) {
        guard reloadAlbumList else {
            dgc_animateShow()
            return
        }
        
        if #available(iOS 14.0, *), PHPhotoLibrary.zl.authStatus(for: .readWrite) == .limited {
            dgc_loadAlbumList { [weak self] in
                self?.dgc_animateShow()
            }
        } else {
            dgc_loadAlbumList()
            dgc_animateShow()
        }
    }
    
    func hide() {
        var dgc_toFrame = dgc_tableBgView.frame
        dgc_toFrame.origin.y = -dgc_toFrame.height
        
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.dgc_tableBgView.frame = dgc_toFrame
        }) { _ in
            self.isHidden = true
            self.alpha = 1
        }
    }
    
    private func dgc_animateShow() {
        let dgc_toFrame = dgc_calculateBgViewBounds()
        
        isHidden = false
        alpha = 0
        var dgc_newFrame = dgc_toFrame
        dgc_newFrame.origin.y -= dgc_newFrame.height
        
        if dgc_newFrame != dgc_tableBgView.frame {
            let dgc_path = UIBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: dgc_newFrame.width, height: dgc_newFrame.height),
                byRoundingCorners: [.bottomLeft, .bottomRight],
                cornerRadii: CGSize(width: 8, height: 8)
            )
            dgc_tableBgView.layer.mask = nil
            let dgc_maskLayer = CAShapeLayer()
            dgc_maskLayer.dgc_path = dgc_path.cgPath
            dgc_tableBgView.layer.mask = dgc_maskLayer
        }
        
        dgc_tableBgView.frame = dgc_newFrame
        dgc_tableView.frame = dgc_tableBgView.bounds
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
            self.dgc_tableBgView.frame = dgc_toFrame
        }
    }
}

extension DGCZLEmbedAlbumListView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let dgc_point = gestureRecognizer.location(in: self)
        return !dgc_tableBgView.frame.contains(dgc_point)
    }
}

extension DGCZLEmbedAlbumListView: UITableViewDataSource, UITableViewDelegate {
    func dgc_tableView(_ dgc_tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dgc_arrDataSource.count
    }
    
    func dgc_tableView(_ dgc_tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dgc_cell = dgc_tableView.dequeueReusableCell(withIdentifier: DGCZLAlbumListCell.zl.identifier, for: indexPath) as! DGCZLAlbumListCell
        
        let dgc_m = dgc_arrDataSource[indexPath.row]
        
        dgc_cell.configureCell(model: dgc_m, style: .embedAlbumList)
        
        dgc_cell.selectBtn.isSelected = dgc_m == dgc_selectedAlbum
        
        return dgc_cell
    }
    
    func dgc_tableView(_ dgc_tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dgc_m = dgc_arrDataSource[indexPath.row]
        dgc_selectedAlbum = dgc_m
        selectAlbumBlock?(dgc_m)
        hide()
        if let dgc_indexPaths = dgc_tableView.indexPathsForVisibleRows {
            dgc_tableView.reloadRows(at: dgc_indexPaths, with: .none)
        }
    }
}
