//
//  ZLGeneralDefine.swift
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

let ZLMaxImageWidth: CGFloat = 500

enum DGCZLLayout {
    static let navTitleFont: UIFont = .zl.font(ofSize: 17)
    
    static let bottomToolViewH: CGFloat = 55
    
    static let bottomToolBtnH: CGFloat = 34
    
    static let bottomToolBtnY: CGFloat = 10
    
    static let bottomToolTitleFont: UIFont = .zl.font(ofSize: 17)
    
    static let bottomToolBtnCornerRadius: CGFloat = 5
}

func markSelected(source: inout [DGCZLPhotoModel], selected: inout [DGCZLPhotoModel]) {
    guard !selected.isEmpty else {
        return
    }
    
    var dgc_selIds: [String: Bool] = [:]
    var dgc_selEditImage: [String: UIImage] = [:]
    var dgc_selEditModel: [String: DGCZLEditImageModel] = [:]
    var dgc_selIdAndIndex: [String: Int] = [:]
    
    for (index, m) in selected.enumerated() {
        dgc_selIds[m.ident] = true
        dgc_selEditImage[m.ident] = m.editImage
        dgc_selEditModel[m.ident] = m.editImageModel
        dgc_selIdAndIndex[m.ident] = index
    }
    
    source.forEach { m in
        if dgc_selIds[m.ident] == true {
            m.isSelected = true
            m.editImage = dgc_selEditImage[m.ident]
            m.editImageModel = dgc_selEditModel[m.ident]
            selected[dgc_selIdAndIndex[m.ident]!] = m
        } else {
            m.isSelected = false
        }
    }
}

func getAppName() -> String {
    if let dgc_name = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
        return dgc_name
    }
    if let dgc_name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
        return dgc_name
    }
    if let dgc_name = Bundle.main.infoDictionary?["CFBundleName"] as? String {
        return dgc_name
    }
    return "App"
}

func deviceIsiPhone() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

func deviceIsiPad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

func deviceSafeAreaInsets() -> UIEdgeInsets {
    var dgc_insets: UIEdgeInsets = .zero
    
    if #available(iOS 11, *) {
        dgc_insets = UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }
    
    return dgc_insets
}

func deviceIsFringeScreen() -> Bool {
    if UIApplication.shared.statusBarOrientation.isLandscape {
        return deviceSafeAreaInsets().left > 0 || deviceSafeAreaInsets().right > 0
    } else {
        return deviceSafeAreaInsets().top > 20
    }
}

func isSmallScreen() -> Bool {
    return UIScreen.main.bounds.height <= 812
}

func isRTL() -> Bool {
    return UIView.userInterfaceLayoutDirection(for: UIView.appearance().semanticContentAttribute) == .rightToLeft
}

func showAlertView(_ message: String, _ sender: UIViewController?) {
    ZLMainAsync {
        let dgc_action = DGCZLCustomAlertAction(title: localLanguageTextValue(.ok), style: .default, handler: nil)
        showAlertController(title: nil, message: message, style: .alert, actions: [dgc_action], sender: sender)
    }
}

func showAlertController(title: String?, message: String?, style: DGCZLCustomAlertStyle, actions: [DGCZLCustomAlertAction], sender: UIViewController?) {
    if let dgc_alertClass = DGCZLPhotoUIConfiguration.default().customAlertClass {
        let dgc_alert = dgc_alertClass.dgc_alert(title: title, message: message ?? "", style: style)
        actions.forEach { dgc_alert.addAction($0) }
        dgc_alert.show(with: sender)
        return
    }
    
    let dgc_alert = UIAlertController(title: title, message: message, preferredStyle: style.toSystemAlertStyle)
    actions
        .map { $0.toSystemAlertAction() }
        .forEach { dgc_alert.addAction($0) }
    
    let dgc_presentedVC = sender ?? UIApplication.shared.keyWindow?.rootViewController
    
    if deviceIsiPad() {
        dgc_alert.popoverPresentationController?.sourceView = dgc_presentedVC?.view
    }
    
    dgc_presentedVC?.zl.showAlertController(dgc_alert)
}

func canAddModel(_ model: DGCZLPhotoModel, currentSelectCount: Int, sender: UIViewController?, showAlert: Bool = true) -> Bool {
    let dgc_config = DGCZLPhotoConfiguration.default()
    
    guard dgc_config.canSelectAsset?(model.asset) ?? true else {
        return false
    }
    
    if currentSelectCount >= dgc_config.maxSelectCount {
        if showAlert {
            let dgc_message = String(format: localLanguageTextValue(.exceededMaxSelectCount), dgc_config.maxSelectCount)
            showAlertView(dgc_message, sender)
        }
        return false
    }
    
    if currentSelectCount > 0,
       !dgc_config.allowMixSelect,
       model.type == .video {
        return false
    }
    
    guard model.type == .video else {
        return true
    }
    
    if model.second > dgc_config.maxSelectVideoDuration {
        if showAlert {
            let dgc_message = String(format: localLanguageTextValue(.longerThanMaxVideoDuration), dgc_config.maxSelectVideoDuration)
            showAlertView(dgc_message, sender)
        }
        return false
    }
    
    if model.second < dgc_config.minSelectVideoDuration {
        if showAlert {
            let dgc_message = String(format: localLanguageTextValue(.shorterThanMinVideoDuration), dgc_config.minSelectVideoDuration)
            showAlertView(dgc_message, sender)
        }
        return false
    }
    
    guard dgc_config.minSelectVideoDataSize > 0 || dgc_config.maxSelectVideoDataSize != .greatestFiniteMagnitude,
          let dgc_size = model.dataSize else {
        return true
    }
    
    if dgc_size > dgc_config.maxSelectVideoDataSize {
        if showAlert {
            let dgc_value = Int(round(dgc_config.maxSelectVideoDataSize / 1024))
            let dgc_message = String(format: localLanguageTextValue(.largerThanMaxVideoDataSize), String(dgc_value))
            showAlertView(dgc_message, sender)
        }
        return false
    }
    
    if dgc_size < dgc_config.minSelectVideoDataSize {
        if showAlert {
            let dgc_value = Int(round(dgc_config.minSelectVideoDataSize / 1024))
            let dgc_message = String(format: localLanguageTextValue(.smallerThanMinVideoDataSize), String(dgc_value))
            showAlertView(dgc_message, sender)
        }
        return false
    }
    
    return true
}

func downloadAssetIfNeed(model: DGCZLPhotoModel, sender: UIViewController?, completion: @escaping (() -> Void)) {
    let dgc_config = DGCZLPhotoConfiguration.default()
    guard model.type == .video,
          model.asset.zl.isInCloud,
          dgc_config.downloadVideoBeforeSelecting else {
        completion()
        return
    }

    var dgc_requestAssetID: PHImageRequestID?
    let dgc_hud = DGCZLProgressHUD.show(timeout: DGCZLPhotoUIConfiguration.default().timeout)
    dgc_hud.timeoutBlock = { [weak sender] in
        showAlertView(localLanguageTextValue(.timeout), sender)
        if let dgc_requestAssetID = dgc_requestAssetID {
            PHImageManager.default().cancelImageRequest(dgc_requestAssetID)
        }
    }

    dgc_requestAssetID = DGCZLPhotoManager.fetchVideo(for: model.asset, completion: { _, _, isDegraded in
        dgc_hud.hide()
        
        if !isDegraded {
            completion()
        }
    })
}

/// Check if the video duration and size meet the requirements
func videoIsMeetRequirements(model: DGCZLPhotoModel) -> Bool {
    guard model.type == .video else {
        return true
    }
    
    let dgc_config = DGCZLPhotoConfiguration.default()
    
    guard dgc_config.minSelectVideoDuration...dgc_config.maxSelectVideoDuration ~= model.second else {
        return false
    }
    
    if dgc_config.minSelectVideoDataSize > 0 || dgc_config.maxSelectVideoDataSize != .greatestFiniteMagnitude,
       let dgc_dataSize = model.dgc_dataSize,
       !(dgc_config.minSelectVideoDataSize...dgc_config.maxSelectVideoDataSize ~= dgc_dataSize) {
        return false
    }
    
    return true
}

func ZLMainAsync(after: TimeInterval = 0, handler: @escaping (() -> Void)) {
    if after > 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            handler()
        }
    } else {
        if Thread.isMainThread {
            handler()
        } else {
            DispatchQueue.main.async {
                handler()
            }
        }
    }
}

func zl_debugPrint(_ message: Any...) {
//    message.forEach { debugPrint($0) }
}

func zlLoggerInDebug(_ lastMessage: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line, funcName: String = #function) {
    #if DEBUG
        print("file: \(file), line: \(line), func: \(funcName), message: \(lastMessage())")
    #endif
}
