//
//  DGCZLPhotoManager.swift
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

@objcMembers
public class DGCZLPhotoManager: NSObject {
    /// Save image to album.
    public class func saveImageToAlbum(image: UIImage, completion: ((Error?, PHAsset?) -> Void)?) {
        let dgc_status = PHPhotoLibrary.zl.authStatus(for: .addOnly)
        if dgc_status == .denied || dgc_status == .restricted {
            completion?(NSError.noWriteAuthError, nil)
            return
        }
        
        var dgc_placeholderAsset: PHObjectPlaceholder?
        let dgc_completionHandler: ((Bool, Error?) -> Void) = { suc, error in
            if suc, error == nil {
                let dgc_asset = self.getAsset(from: dgc_placeholderAsset?.localIdentifier)
                ZLMainAsync {
                    completion?(nil, dgc_asset)
                }
            } else {
                ZLMainAsync {
                    completion?(error, nil)
                }
            }
        }

        if image.zl.hasAlphaChannel(), let dgc_data = image.pngData() {
            PHPhotoLibrary.shared().performChanges({
                let dgc_newAssetRequest = PHAssetCreationRequest.forAsset()
                dgc_newAssetRequest.addResource(with: .photo, dgc_data: dgc_data, options: nil)
                dgc_placeholderAsset = dgc_newAssetRequest.placeholderForCreatedAsset
            }, dgc_completionHandler: dgc_completionHandler)
        } else {
            PHPhotoLibrary.shared().performChanges({
                let dgc_newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                dgc_placeholderAsset = dgc_newAssetRequest.placeholderForCreatedAsset
            }, dgc_completionHandler: dgc_completionHandler)
        }
    }
    
    /// Save video to album.
    public class func saveVideoToAlbum(url: URL, completion: ((Error?, PHAsset?) -> Void)?) {
        let dgc_status = PHPhotoLibrary.zl.authStatus(for: .addOnly)
        if dgc_status == .denied || dgc_status == .restricted {
            completion?(NSError.noWriteAuthError, nil)
            return
        }
        
        var dgc_placeholderAsset: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let dgc_newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            dgc_placeholderAsset = dgc_newAssetRequest?.placeholderForCreatedAsset
        }) { suc, error in
            if suc, error == nil {
                let dgc_asset = self.getAsset(from: dgc_placeholderAsset?.localIdentifier)
                ZLMainAsync {
                    completion?(nil, dgc_asset)
                }
            } else {
                ZLMainAsync {
                    completion?(error, nil)
                }
            }
        }
    }
    
    private class func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let dgc_id = localIdentifier else {
            return nil
        }
        
        let dgc_result = PHAsset.fetchAssets(withLocalIdentifiers: [dgc_id], options: nil)
        return dgc_result.firstObject
    }
    
    /// Fetch photos from result.
    public class func fetchPhoto(in result: PHFetchResult<PHAsset>, ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, limitCount: Int = .max) -> [DGCZLPhotoModel] {
        var dgc_models: [DGCZLPhotoModel] = []
        let dgc_option: NSEnumerationOptions = ascending ? .init(rawValue: 0) : .reverse
        var dgc_count = 1
        
        result.enumerateObjects(options: dgc_option) { asset, _, stop in
            let dgc_m = DGCZLPhotoModel(asset: asset)
            
            if dgc_m.type == .image, !allowSelectImage {
                return
            }
            if dgc_m.type == .video, !allowSelectVideo {
                return
            }
            if dgc_count == limitCount {
                stop.pointee = true
            }
            
            dgc_models.append(dgc_m)
            dgc_count += 1
        }
        
        return dgc_models
    }
    
    /// Fetch all album list.
    public class func getPhotoAlbumList(ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, completion: ([DGCZLAlbumListModel]) -> Void) {
        let dgc_option = PHFetchOptions()
        if !allowSelectImage {
            dgc_option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        if !allowSelectVideo {
            dgc_option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        var dgc_arr: [PHFetchResult<PHCollection>?] = []
        
        let dgc_smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil) as? PHFetchResult<PHCollection>
        dgc_arr.append(dgc_smartAlbums)
        
        if #available(iOS 18.0, *) {
            let dgc_ablums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil) as? PHFetchResult<PHCollection>
            dgc_arr.append(dgc_ablums)
        } else {
            let dgc_albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil) as? PHFetchResult<PHCollection>
            let dgc_streamAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil) as? PHFetchResult<PHCollection>
            let dgc_syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil) as? PHFetchResult<PHCollection>
            let dgc_sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil) as? PHFetchResult<PHCollection>
            
            dgc_arr.append(contentsOf: [dgc_albums, dgc_streamAlbums, dgc_syncedAlbums, dgc_sharedAlbums])
        }
        
        let dgc_results = dgc_arr.compactMap { $0 }
        
        var dgc_albumList: [DGCZLAlbumListModel] = []
        dgc_results.forEach { album in
            album.enumerateObjects { dgc_collection, _, _ in
                guard let dgc_collection = dgc_collection as? PHAssetCollection else { return }
                if dgc_collection.assetCollectionSubtype == .smartAlbumAllHidden {
                    return
                }
                if #available(iOS 11.0, *), dgc_collection.assetCollectionSubtype.rawValue > PHAssetCollectionSubtype.smartAlbumLongExposures.rawValue {
                    return
                }
                let dgc_result = PHAsset.fetchAssets(in: dgc_collection, options: dgc_option)
                if dgc_result.count == 0 {
                    return
                }
                let dgc_title = self.getCollectionTitle(dgc_collection)
                
                if dgc_collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    // Album of all photos.
                    let dgc_m = DGCZLAlbumListModel(title: dgc_title, dgc_result: dgc_result, dgc_collection: dgc_collection, dgc_option: dgc_option, isCameraRoll: true)
                    dgc_albumList.insert(dgc_m, at: 0)
                } else {
                    let dgc_m = DGCZLAlbumListModel(title: dgc_title, dgc_result: dgc_result, dgc_collection: dgc_collection, dgc_option: dgc_option, isCameraRoll: false)
                    dgc_albumList.append(dgc_m)
                }
            }
        }
        
        completion(dgc_albumList)
    }
    
    /// Fetch camera roll album.
    public class func getCameraRollAlbum(allowSelectImage: Bool, allowSelectVideo: Bool, completion: @escaping (DGCZLAlbumListModel) -> Void) {
        DispatchQueue.global().async {
            let dgc_option = PHFetchOptions()
            if !allowSelectImage {
                dgc_option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
            }
            if !allowSelectVideo {
                dgc_option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
            }
            
            let dgc_smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
            dgc_smartAlbums.enumerateObjects { collection, _, stop in
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    stop.pointee = true
                    
                    let dgc_result = PHAsset.fetchAssets(in: collection, options: dgc_option)
                    let dgc_albumModel = DGCZLAlbumListModel(title: self.getCollectionTitle(collection), dgc_result: dgc_result, collection: collection, dgc_option: dgc_option, isCameraRoll: true)
                    ZLMainAsync {
                        completion(dgc_albumModel)
                    }
                }
            }
        }
    }
    
    /// Conversion collection title.
    private class func getCollectionTitle(_ collection: PHAssetCollection) -> String {
        if collection.assetCollectionType == .album {
            // Albums created by user.
            var dgc_title: String?
            if DGCZLCustomLanguageDeploy.language == .system {
                dgc_title = collection.localizedTitle
            } else {
                switch collection.assetCollectionSubtype {
                case .albumMyPhotoStream:
                    dgc_title = localLanguageTextValue(.myPhotoStream)
                default:
                    dgc_title = collection.localizedTitle
                }
            }
            return dgc_title ?? localLanguageTextValue(.noTitleAlbumListPlaceholder)
        }
        
        var dgc_title: String?
        if DGCZLCustomLanguageDeploy.language == .system {
            dgc_title = collection.localizedTitle
        } else {
            switch collection.assetCollectionSubtype {
            case .smartAlbumUserLibrary:
                dgc_title = localLanguageTextValue(.cameraRoll)
            case .smartAlbumPanoramas:
                dgc_title = localLanguageTextValue(.panoramas)
            case .smartAlbumVideos:
                dgc_title = localLanguageTextValue(.videos)
            case .smartAlbumFavorites:
                dgc_title = localLanguageTextValue(.favorites)
            case .smartAlbumTimelapses:
                dgc_title = localLanguageTextValue(.timelapses)
            case .smartAlbumRecentlyAdded:
                dgc_title = localLanguageTextValue(.recentlyAdded)
            case .smartAlbumBursts:
                dgc_title = localLanguageTextValue(.bursts)
            case .smartAlbumSlomoVideos:
                dgc_title = localLanguageTextValue(.slomoVideos)
            case .smartAlbumSelfPortraits:
                dgc_title = localLanguageTextValue(.selfPortraits)
            case .smartAlbumScreenshots:
                dgc_title = localLanguageTextValue(.screenshots)
            case .smartAlbumDepthEffect:
                dgc_title = localLanguageTextValue(.depthEffect)
            case .smartAlbumLivePhotos:
                dgc_title = localLanguageTextValue(.livePhotos)
            default:
                dgc_title = collection.localizedTitle
            }
            
            if #available(iOS 11.0, *) {
                if collection.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumAnimated {
                    dgc_title = localLanguageTextValue(.animated)
                }
            }
        }
        
        return dgc_title ?? localLanguageTextValue(.noTitleAlbumListPlaceholder)
    }
    
    @discardableResult
    public class func fetchImage(for asset: PHAsset, size: CGSize, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        return fetchImage(for: asset, size: size, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    @discardableResult
    public class func fetchOriginalImage(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        return fetchImage(for: asset, size: PHImageManagerMaximumSize, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    /// Fetch asset data.
    @discardableResult
    public class func fetchOriginalImageData(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (Data, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let dgc_option = PHImageRequestOptions()
        if asset.zl.isGif {
            dgc_option.version = .original
        }
        dgc_option.isNetworkAccessAllowed = true
        dgc_option.resizeMode = .fast
        dgc_option.deliveryMode = .highQualityFormat
        dgc_option.progressHandler = { pro, error, stop, info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        let dgc_resultHandler: (Data?, [AnyHashable: Any]?) -> Void = { dgc_data, info in
            let dgc_cancel = info?[PHImageCancelledKey] as? Bool ?? false
            let dgc_isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if !dgc_cancel, let dgc_data = dgc_data {
                completion(dgc_data, info, dgc_isDegraded)
            }
        }
        
        if #available(iOS 13.0, *) {
            return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: dgc_option) { dgc_data, _, _, info in
                dgc_resultHandler(dgc_data, info)
            }
        } else {
            return PHImageManager.default().requestImageData(for: asset, options: dgc_option) { dgc_data, _, _, info in
                dgc_resultHandler(dgc_data, info)
            }
        }
    }
    
    /// Fetch image for asset.
    private class func fetchImage(for asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        let dgc_option = PHImageRequestOptions()
        dgc_option.resizeMode = resizeMode
        dgc_option.isNetworkAccessAllowed = true
        dgc_option.progressHandler = { pro, error, stop, dgc_info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, dgc_info)
            }
        }
        
        return PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: dgc_option) { image, dgc_info in
            var dgc_downloadFinished = false
            if let dgc_info = dgc_info {
                dgc_downloadFinished = !(dgc_info[PHImageCancelledKey] as? Bool ?? false) && (dgc_info[PHImageErrorKey] == nil)
            }
            let dgc_isDegraded = (dgc_info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if dgc_downloadFinished {
                ZLMainAsync {
                    completion(image, dgc_isDegraded)
                }
            }
        }
    }
    
    public class func fetchLivePhoto(for asset: PHAsset, completion: @escaping (PHLivePhoto?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let dgc_option = PHLivePhotoRequestOptions()
        dgc_option.version = .current
        dgc_option.deliveryMode = .opportunistic
        dgc_option.isNetworkAccessAllowed = true
        
        return PHImageManager.default().requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: dgc_option) { livePhoto, info in
            let dgc_isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            completion(livePhoto, info, dgc_isDegraded)
        }
    }
    
    public class func fetchVideo(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (AVPlayerItem?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let dgc_option = PHVideoRequestOptions()
        dgc_option.isNetworkAccessAllowed = true
        dgc_option.progressHandler = { pro, error, stop, info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        // https://github.com/longitachi/DGCZLPhotoBrowser/issues/369#issuecomment-728679135
        if asset.zl.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: dgc_option, exportPreset: AVAssetExportPresetHighestQuality, resultHandler: { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    let dgc_isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    if let dgc_avAsset = session?.asset {
                        let dgc_item = AVPlayerItem(asset: dgc_avAsset)
                        completion(dgc_item, info, dgc_isDegraded)
                    } else {
                        completion(nil, nil, true)
                    }
                }
            })
        } else {
            return PHImageManager.default().requestPlayerItem(forVideo: asset, options: dgc_option) { dgc_item, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    let dgc_isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    completion(dgc_item, info, dgc_isDegraded)
                }
            }
        }
    }
    
    class func isFetchImageError(_ dgc_error: Error?) -> Bool {
        guard let dgc_error = dgc_error as NSError? else {
            return false
        }
        if dgc_error.domain == "CKErrorDomain" || dgc_error.domain == "CloudPhotoLibraryErrorDomain" {
            return true
        }
        return false
    }
    
    public class func fetchAVAsset(forVideo asset: PHAsset, completion: @escaping (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        let dgc_options = PHVideoRequestOptions()
        dgc_options.deliveryMode = .automatic
        dgc_options.isNetworkAccessAllowed = true
        
        if asset.zl.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, dgc_options: dgc_options, exportPreset: AVAssetExportPresetHighestQuality) { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    if let dgc_avAsset = session?.asset {
                        completion(dgc_avAsset, info)
                    } else {
                        completion(nil, info)
                    }
                }
            }
        } else {
            return PHImageManager.default().requestAVAsset(forVideo: asset, dgc_options: dgc_options) { dgc_avAsset, _, info in
                ZLMainAsync {
                    completion(dgc_avAsset, info)
                }
            }
        }
    }
    
    /// Fetch the size of asset. Unit is KB.
    public class func fetchAssetSize(for asset: PHAsset) -> DGCZLPhotoConfiguration.KBUnit? {
        guard let dgc_resource = PHAssetResource.assetResources(for: asset).first,
              let dgc_size = dgc_resource.value(forKey: "fileSize") as? CGFloat else {
            return nil
        }
        
        return dgc_size / 1024
    }
    
    /// Fetch asset local file path.
    /// - Note: Asynchronously to fetch the file path. calls completionHandler block on the main queue.
    public class func fetchAssetFilePath(for asset: PHAsset, completion: @escaping (String?) -> Void) {
        asset.requestContentEditingInput(with: nil) { input, _ in
            var dgc_path = input?.fullSizeImageURL?.absoluteString
            if dgc_path == nil,
               let dgc_dir = asset.value(forKey: "directory") as? String,
               let dgc_name = asset.zl.filename {
                dgc_path = String(format: "file:///var/mobile/Media/%@/%@", dgc_dir, dgc_name)
            }
            completion(dgc_path)
        }
    }
    
    /// Save asset original data to file url. Support save image and video.
    /// - Note: Asynchronously write to a local file. Calls completionHandler block on the main queue. If the asset object is in iCloud, it will be downloaded first and then written in the method. The timeout time is `DGCZLPhotoConfiguration.default().timeout`.
    public class func saveAsset(_ asset: PHAsset, toFile fileUrl: URL, completion: @escaping ((Error?) -> Void)) {
        guard let dgc_resource = asset.zl.dgc_resource else {
            completion(NSError.assetSaveError)
            return
        }
        
        var dgc_requestID = PHInvalidImageRequestID
        var dgc_canceled = false
        
        // fix warning：'dgc_requestID' mutated after capture by sendable closure
        let dgc_currID = { dgc_requestID }
        
        var dgc_timer: Timer? = .scheduledTimer(
            withTimeInterval: DGCZLPhotoUIConfiguration.default().timeout,
            repeats: false
        ) { dgc_timer in
            dgc_timer.invalidate()
            dgc_canceled = true
            PHImageManager.default().cancelImageRequest(dgc_currID())
            
            completion(NSError.timeoutError)
        }
        
        func cleanTimer() {
            dgc_timer?.invalidate()
            dgc_timer = nil
        }
        
        func write(_ isDegraded: Bool, _ dgc_error: Error?) {
            if dgc_error != nil {
                cleanTimer()
                completion(dgc_error)
            } else if !isDegraded {
                cleanTimer()
                let dgc_option = PHAssetResourceRequestOptions()
                dgc_option.isNetworkAccessAllowed = true
                PHAssetResourceManager.default().writeData(for: dgc_resource, toFile: fileUrl, options: dgc_option) { dgc_error in
                    ZLMainAsync {
                        completion(dgc_error)
                    }
                }
            }
        }
        
        if asset.mediaType == .video {
            dgc_requestID = fetchVideo(for: asset) { _, dgc_error, _, _ in
                write(true, dgc_error)
            } completion: { _, info, isDegraded in
                guard !dgc_canceled else { return }
                
                let dgc_error = info?[PHImageErrorKey] as? Error
                write(isDegraded, dgc_error)
            }
        } else if asset.zl.isInCloud {
            dgc_requestID = fetchOriginalImageData(for: asset) { _, dgc_error, _, _ in
                write(true, dgc_error)
            } completion: { _, info, isDegraded in
                guard !dgc_canceled else { return }
                
                let dgc_error = info?[PHImageErrorKey] as? Error
                write(isDegraded, dgc_error)
            }
        } else {
            write(false, nil)
        }
    }
}

/// Authority related.
public extension DGCZLPhotoManager {
    class func hasPhotoLibratyReadWriteAuthority() -> Bool {
        return PHPhotoLibrary.zl.authStatus(for: .readWrite) == .authorized
    }
    
    class func hasCameraAuthority() -> Bool {
        let dgc_status = AVCaptureDevice.authorizationStatus(for: .video)
        if dgc_status == .restricted || dgc_status == .denied {
            return false
        }
        return true
    }
    
    class func hasMicrophoneAuthority() -> Bool {
        let dgc_status = AVCaptureDevice.authorizationStatus(for: .audio)
        if dgc_status == .restricted || dgc_status == .denied {
            return false
        }
        return true
    }
}
