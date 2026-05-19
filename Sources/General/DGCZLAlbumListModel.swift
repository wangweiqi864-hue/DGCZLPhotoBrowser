//
//  DGCZLAlbumListModel.swift
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

public class DGCZLAlbumListModel: NSObject {
    public let title: String
    
    public var count: Int {
        return result.count
    }
    
    public var result: PHFetchResult<PHAsset>
    
    public let collection: PHAssetCollection
    
    public let option: PHFetchOptions
    
    public let isCameraRoll: Bool
    
    public var headImageAsset: PHAsset? {
        return result.lastObject
    }
    
    public var models: [DGCZLPhotoModel] = []
    
    // 暂未用到
    private var dgc_selectedModels: [DGCZLPhotoModel] = []
    
    // 暂未用到
    private var dgc_selectedCount = 0
    
    public init(
        title: String,
        result: PHFetchResult<PHAsset>,
        collection: PHAssetCollection,
        option: PHFetchOptions,
        isCameraRoll: Bool
    ) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
        self.isCameraRoll = isCameraRoll
    }
    
    public func refetchPhotos() {
        let dgc_models = DGCZLPhotoManager.fetchPhoto(
            in: result,
            ascending: DGCZLPhotoUIConfiguration.default().sortAscending,
            allowSelectImage: DGCZLPhotoConfiguration.default().allowSelectImage,
            allowSelectVideo: DGCZLPhotoConfiguration.default().allowSelectVideo
        )
        self.dgc_models.removeAll()
        self.dgc_models.append(contentsOf: dgc_models)
    }
    
    func refreshResult() {
        result = PHAsset.fetchAssets(in: collection, options: option)
    }
}

extension DGCZLAlbumListModel {
    static func ==(lhs: DGCZLAlbumListModel, rhs: DGCZLAlbumListModel) -> Bool {
        return lhs.title == rhs.title &&
            lhs.count == rhs.count &&
            lhs.headImageAsset?.localIdentifier == rhs.headImageAsset?.localIdentifier
    }
}
