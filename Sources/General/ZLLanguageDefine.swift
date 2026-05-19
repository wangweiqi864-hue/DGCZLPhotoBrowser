//
//  ZLLanguageDefine.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/17.
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

import Foundation

@objc public enum DGCZLLanguageType: Int, CaseIterable {
    case system
    case chineseSimplified
    case chineseTraditional
    case english
    case japanese
    case french
    case german
    case russian
    case vietnamese
    case korean
    case malay
    case italian
    case indonesian
    case portuguese
    case spanish
    case turkish
    case arabic
    case dutch
    
    var key: String {
        var key = "en"
        
        switch self {
        case .system:
            key = Locale.preferredLanguages.first ?? "en"
            
            if key.hasPrefix("zh") {
                if key.range(of: "Hans") != nil {
                    key = "zh-Hans"
                } else {
                    key = "zh-Hant"
                }
            } else if key.hasPrefix("ja") {
                key = "ja-US"
            } else if key.hasPrefix("fr") {
                key = "fr"
            } else if key.hasPrefix("de") {
                key = "de"
            } else if key.hasPrefix("ru") {
                key = "ru"
            } else if key.hasPrefix("vi") {
                key = "vi"
            } else if key.hasPrefix("ko") {
                key = "ko"
            } else if key.hasPrefix("ms") {
                key = "ms"
            } else if key.hasPrefix("it") {
                key = "it"
            } else if key.hasPrefix("id") {
                key = "id"
            } else if key.hasPrefix("pt") {
                key = "pt-BR"
            } else if key.hasPrefix("es") {
                key = "es-419"
            } else if key.hasPrefix("tr") {
                key = "tr"
            } else if key.hasPrefix("ar") {
                key = "ar"
            } else if key.hasPrefix("nl") {
                key = "nl"
            } else {
                key = "en"
            }
        case .chineseSimplified:
            key = "zh-Hans"
        case .chineseTraditional:
            key = "zh-Hant"
        case .english:
            key = "en"
        case .japanese:
            key = "ja-US"
        case .french:
            key = "fr"
        case .german:
            key = "de"
        case .russian:
            key = "ru"
        case .vietnamese:
            key = "vi"
        case .korean:
            key = "ko"
        case .malay:
            key = "ms"
        case .italian:
            key = "it"
        case .indonesian:
            key = "id"
        case .portuguese:
            key = "pt-BR"
        case .spanish:
            key = "es-419"
        case .turkish:
            key = "tr"
        case .arabic:
            key = "ar"
        case .dutch:
            key = "nl"
        }
        
        return key
    }
}

public struct DGCZLLocalLanguageKey: Hashable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Camera (拍照)
    public static let previewCamera = DGCZLLocalLanguageKey(rawValue: "previewCamera")
    
    /// Record (拍摄)
    public static let previewCameraRecord = DGCZLLocalLanguageKey(rawValue: "previewCameraRecord")
    
    /// Album (相册)
    public static let previewAlbum = DGCZLLocalLanguageKey(rawValue: "previewAlbum")
    
    /// Cancel (取消)
    public static let cancel = DGCZLLocalLanguageKey(rawValue: "cancel")
    
    /// No Photo (无照片)
    public static let noPhotoTips = DGCZLLocalLanguageKey(rawValue: "noPhotoTips")
    
    /// Loading (正在加载)
    public static let hudLoading = DGCZLLocalLanguageKey(rawValue: "hudLoading")
    
    /// Processing (正在处理)
    public static let hudProcessing = DGCZLLocalLanguageKey(rawValue: "hudProcessing")
    
    /// Done (确定)
    public static let done = DGCZLLocalLanguageKey(rawValue: "done")
    
    /// Done (确定)
    public static let cameraDone = DGCZLLocalLanguageKey(rawValue: "cameraDone")
    
    /// Done (确定)
    public static let inputDone = DGCZLLocalLanguageKey(rawValue: "inputDone")
    
    /// OK (确定)
    public static let ok = DGCZLLocalLanguageKey(rawValue: "ok")
    
    /// Request timed out (请求超时)
    public static let timeout = DGCZLLocalLanguageKey(rawValue: "timeout")
    
    /// Please Allow %@ to access your album in \"Settings\"->\"Privacy\"->\"Photos\"
    /// (请在iPhone的\"设置-隐私-照片\"选项中，允许%@访问你的照片)
    public static let noPhotoLibraryAuthorityAlertMessage = DGCZLLocalLanguageKey(rawValue: "noPhotoLibraryAuthorityAlertMessage")
    
    /// Please allow %@ to access your device's camera in \"Settings\"->\"Privacy\"->\"Camera\"
    /// (请在iPhone的\"设置-隐私-相机\"选项中，允许%@访问你的相机)
    public static let noCameraAuthorityAlertMessage = DGCZLLocalLanguageKey(rawValue: "noCameraAuthorityAlertMessage")
    
    /// Unable to record audio. Go to \"Settings\" > \"%@\" and enable microphone access.
    /// (无法录制声音，前往\"设置 > %@\"中打开麦克风权限)
    public static let noMicrophoneAuthorityAlertMessage = DGCZLLocalLanguageKey(rawValue: "noMicrophoneAuthorityAlertMessage")
    
    /// %@ can only access selected photos. Allow permission for %@ to access \"All Photos\"
    /// （你已设置%@只能访问相册部分照片，建议允许访问「所有照片」）
    public static let unableToAccessAllPhotos = DGCZLLocalLanguageKey(rawValue: "unableToAccessAllPhotos")
    
    /// Unable to access photos in album
    /// （无法访问相册中照片）
    public static let noLibraryAuthTitleInThumbList = DGCZLLocalLanguageKey(rawValue: "noLibraryAuthTitleInThumbList")
    
    /// %@ cannot access photos. Allow permission for %@ to access \"All Photos\"
    /// 你已关闭%@照片访问权限，建议允许访问「所有照片」
    public static let noLibraryAuthDescInThumbList = DGCZLLocalLanguageKey(rawValue: "noLibraryAuthDescInThumbList")
    
    /// Go to system settings
    /// 前往系统设置
    public static let gotoSystemSettingInThumbList = DGCZLLocalLanguageKey(rawValue: "gotoSystemSettingInThumbList")
    
    /// Camera is unavailable (相机不可用)
    public static let cameraUnavailable = DGCZLLocalLanguageKey(rawValue: "cameraUnavailable")
    
    /// Keep Recording (继续拍摄)
    public static let keepRecording = DGCZLLocalLanguageKey(rawValue: "keepRecording")
    
    /// Go to Settings (前往设置)
    public static let gotoSettings = DGCZLLocalLanguageKey(rawValue: "gotoSettings")
    
    /// Photos (照片)
    public static let photo = DGCZLLocalLanguageKey(rawValue: "photo")
    
    /// Full Image (原图)
    public static let originalPhoto = DGCZLLocalLanguageKey(rawValue: "originalPhoto")
    
    /// Total (共)
    public static let originalTotalSize = DGCZLLocalLanguageKey(rawValue: "originalTotalSize")
    
    /// Back (返回)
    public static let back = DGCZLLocalLanguageKey(rawValue: "back")
    
    /// Edit (编辑)
    public static let edit = DGCZLLocalLanguageKey(rawValue: "edit")
    
    /// Done (完成)
    public static let editFinish = DGCZLLocalLanguageKey(rawValue: "editFinish")
    
    /// Undo (还原)
    public static let revert = DGCZLLocalLanguageKey(rawValue: "revert")
    
    /// Brightness (亮度)
    public static let brightness = DGCZLLocalLanguageKey(rawValue: "brightness")
    
    /// Contrast (对比度)
    public static let contrast = DGCZLLocalLanguageKey(rawValue: "contrast")
    
    /// Saturation (饱和度)
    public static let saturation = DGCZLLocalLanguageKey(rawValue: "saturation")
    
    /// Preview (预览)
    public static let preview = DGCZLLocalLanguageKey(rawValue: "preview")
    
    /// Save (保存)
    public static let save = DGCZLLocalLanguageKey(rawValue: "save")
    
    /// Failed to save the image (图片保存失败)
    public static let saveImageError = DGCZLLocalLanguageKey(rawValue: "saveImageError")
    
    /// Failed to save the video (视频保存失败)
    public static let saveVideoError = DGCZLLocalLanguageKey(rawValue: "saveVideoError")
    
    /// Max select count: %ld (最多只能选择%ld张图片)
    public static let exceededMaxSelectCount = DGCZLLocalLanguageKey(rawValue: "exceededMaxSelectCount")
    
    /// Max count for video selection: %ld (最多只能选择%ld个视频)
    public static let exceededMaxVideoSelectCount = DGCZLLocalLanguageKey(rawValue: "exceededMaxVideoSelectCount")
    
    /// Min count for video selection: %ld (最少选择%ld个视频)
    public static let lessThanMinVideoSelectCount = DGCZLLocalLanguageKey(rawValue: "lessThanMinVideoSelectCount")
    
    /// Can't select videos longer than %lds
    /// (不能选择超过%ld秒的视频)
    public static let longerThanMaxVideoDuration = DGCZLLocalLanguageKey(rawValue: "longerThanMaxVideoDuration")
    
    /// Can't select videos shorter than %lds
    /// (不能选择低于%ld秒的视频)
    public static let shorterThanMinVideoDuration = DGCZLLocalLanguageKey(rawValue: "shorterThanMinVideoDuration")
    
    /// Can't select videos larger than %@MB
    /// (不能选择大于%@MB的视频)
    public static let largerThanMaxVideoDataSize = DGCZLLocalLanguageKey(rawValue: "largerThanMaxVideoDataSize")
    
    /// Can't select videos smaller than %@MB
    /// (不能选择小于%@MB的视频)
    public static let smallerThanMinVideoDataSize = DGCZLLocalLanguageKey(rawValue: "smallerThanMinVideoDataSize")
    
    /// Unable to sync from iCloud (iCloud无法同步)
    public static let iCloudVideoLoadFaild = DGCZLLocalLanguageKey(rawValue: "iCloudVideoLoadFaild")
    
    /// loading failed (图片加载失败)
    public static let imageLoadFailed = DGCZLLocalLanguageKey(rawValue: "imageLoadFailed")
    
    /// Tap to take photo and hold to record video (轻触拍照，按住摄像)
    public static let customCameraTips = DGCZLLocalLanguageKey(rawValue: "customCameraTips")
    
    /// Tap to take photo (轻触拍照)
    public static let customCameraTakePhotoTips = DGCZLLocalLanguageKey(rawValue: "customCameraTakePhotoTips")
    
    /// Hold to record video (按住摄像)
    public static let customCameraRecordVideoTips = DGCZLLocalLanguageKey(rawValue: "customCameraRecordVideoTips")
    
    /// Tap to record video (轻触摄像)
    public static let customCameraTapToRecordVideoTips = DGCZLLocalLanguageKey(rawValue: "customCameraTapToRecordVideoTips")
    
    /// Record at least %lds (至少录制%ld秒)
    public static let minRecordTimeTips = DGCZLLocalLanguageKey(rawValue: "minRecordTimeTips")
    
    /// Recents (所有照片)
    public static let cameraRoll = DGCZLLocalLanguageKey(rawValue: "cameraRoll")
    
    /// Panoramas (全景照片)
    public static let panoramas = DGCZLLocalLanguageKey(rawValue: "panoramas")
    
    /// Videos (视频)
    public static let videos = DGCZLLocalLanguageKey(rawValue: "videos")
    
    /// Favorites (个人收藏)
    public static let favorites = DGCZLLocalLanguageKey(rawValue: "favorites")
    
    /// Time-Lapse (延时摄影)
    public static let timelapses = DGCZLLocalLanguageKey(rawValue: "timelapses")
    
    /// Recently Added (最近添加)
    public static let recentlyAdded = DGCZLLocalLanguageKey(rawValue: "recentlyAdded")
    
    /// Bursts (连拍快照)
    public static let bursts = DGCZLLocalLanguageKey(rawValue: "bursts")
    
    /// Slo-mo (慢动作)
    public static let slomoVideos = DGCZLLocalLanguageKey(rawValue: "slomoVideos")
    
    /// Selfies (自拍)
    public static let selfPortraits = DGCZLLocalLanguageKey(rawValue: "selfPortraits")
    
    /// Screenshots (屏幕快照)
    public static let screenshots = DGCZLLocalLanguageKey(rawValue: "screenshots")
    
    /// Portrait (人像)
    public static let depthEffect = DGCZLLocalLanguageKey(rawValue: "depthEffect")
    
    /// Live Photo
    public static let livePhotos = DGCZLLocalLanguageKey(rawValue: "livePhotos")
    
    /// Animated (动图)
    public static let animated = DGCZLLocalLanguageKey(rawValue: "animated")
    
    /// My Photo Stream (我的照片流)
    public static let myPhotoStream = DGCZLLocalLanguageKey(rawValue: "myPhotoStream")
    
    /// All Photos (所有照片)
    public static let noTitleAlbumListPlaceholder = DGCZLLocalLanguageKey(rawValue: "noTitleAlbumListPlaceholder")
    
    /// Drag here to remove (拖到此处删除)
    public static let textStickerRemoveTips = DGCZLLocalLanguageKey(rawValue: "textStickerRemoveTips")
}

func localLanguageTextValue(_ key: DGCZLLocalLanguageKey) -> String {
    if let dgc_value = DGCZLCustomLanguageDeploy.deploy[key] {
        return dgc_value
    }
    return Bundle.zlLocalizedString(key.rawValue)
}
