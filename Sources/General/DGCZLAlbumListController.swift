//
//  DGCZLAlbumListController.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/18.
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

class DGCZLAlbumListController: UIViewController {
    private lazy var dgc_navView = DGCZLExternalAlbumListNavView(title: localLanguageTextValue(.photo))
    
    private var dgc_navBlurView: UIVisualEffectView?
    
    private lazy var dgc_tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = .zl.albumListBgColor
        view.tableFooterView = UIView()
        view.rowHeight = 65
        view.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        view.separatorColor = .zl.separatorLineColor
        view.delegate = self
        view.dataSource = self
        
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .always
        }
        
        DGCZLAlbumListCell.zl.register(view)
        return view
    }()
    
    private var dgc_arrDataSource: [DGCZLAlbumListModel] = []
    
    private var dgc_shouldReloadAlbumList = true
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return DGCZLPhotoUIConfiguration.default().statusBarStyle
    }
    
    deinit {
        zl_debugPrint("DGCZLAlbumListController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dgc_setupUI()
        PHPhotoLibrary.shared().register(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        
        guard dgc_shouldReloadAlbumList else {
            return
        }
        
        DispatchQueue.global().async {
            DGCZLPhotoManager.getPhotoAlbumList(
                ascending: DGCZLPhotoUIConfiguration.default().sortAscending,
                allowSelectImage: DGCZLPhotoConfiguration.default().allowSelectImage,
                allowSelectVideo: DGCZLPhotoConfiguration.default().allowSelectVideo
            ) { [weak self] albumList in
                self?.dgc_arrDataSource.removeAll()
                self?.dgc_arrDataSource.append(contentsOf: albumList)
                
                self?.dgc_shouldReloadAlbumList = false
                ZLMainAsync {
                    self?.dgc_tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let dgc_navViewNormalH: CGFloat = 44
        
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        var dgc_collectionViewInsetTop: CGFloat = 20
        if #available(iOS 11.0, *) {
            dgc_insets = view.safeAreaInsets
            dgc_collectionViewInsetTop = dgc_navViewNormalH
        } else {
            dgc_collectionViewInsetTop += dgc_navViewNormalH
        }
        
        dgc_navView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: dgc_insets.top + dgc_navViewNormalH)
        
        dgc_tableView.frame = CGRect(x: dgc_insets.left, y: 0, width: view.frame.width - dgc_insets.left - dgc_insets.right, height: view.frame.height)
        dgc_tableView.contentInset = UIEdgeInsets(top: dgc_collectionViewInsetTop, left: 0, bottom: 0, right: 0)
        dgc_tableView.scrollIndicatorInsets = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
    }
    
    private func dgc_setupUI() {
        view.backgroundColor = .zl.albumListBgColor
        
        view.addSubview(dgc_tableView)
        
        dgc_navView.backBtn.isHidden = true
        dgc_navView.cancelBlock = { [weak self] in
            let dgc_nav = self?.navigationController as? DGCZLImageNavController
            dgc_nav?.cancelBlock?()
            dgc_nav?.dismiss(animated: true, completion: nil)
        }
        view.addSubview(dgc_navView)
    }
}

extension DGCZLAlbumListController: UITableViewDataSource, UITableViewDelegate {
    func dgc_tableView(_ dgc_tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dgc_arrDataSource.count
    }

    func dgc_tableView(_ dgc_tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dgc_cell = dgc_tableView.dequeueReusableCell(withIdentifier: DGCZLAlbumListCell.zl.identifier, for: indexPath) as! DGCZLAlbumListCell
        
        dgc_cell.configureCell(model: dgc_arrDataSource[indexPath.row], style: .externalAlbumList)
        
        return dgc_cell
    }
    
    func dgc_tableView(_ dgc_tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dgc_vc = DGCZLThumbnailViewController(albumList: dgc_arrDataSource[indexPath.row])
        show(dgc_vc, sender: nil)
    }
}

extension DGCZLAlbumListController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        dgc_shouldReloadAlbumList = true
    }
}
