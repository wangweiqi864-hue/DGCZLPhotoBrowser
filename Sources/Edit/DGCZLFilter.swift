//
//  DGCZLFilter.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/10/9.
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

/// DGCFilter code reference from https://github.com/Yummypets/YPImagePicker

public typealias ZLFilterApplierType = (_ image: UIImage) -> UIImage

@objc public enum DGCZLFilterType: Int {
    case normal
    case chrome
    case fade
    case instant
    case process
    case transfer
    case tone
    case linear
    case sepia
    case mono
    case noir
    case tonal
    
    var coreImageFilterName: String {
        switch self {
        case .normal:
            return ""
        case .chrome:
            return "CIPhotoEffectChrome"
        case .fade:
            return "CIPhotoEffectFade"
        case .instant:
            return "CIPhotoEffectInstant"
        case .process:
            return "CIPhotoEffectProcess"
        case .transfer:
            return "CIPhotoEffectTransfer"
        case .tone:
            return "CILinearToSRGBToneCurve"
        case .linear:
            return "CISRGBToneCurveToLinear"
        case .sepia:
            return "CISepiaTone"
        case .mono:
            return "CIPhotoEffectMono"
        case .noir:
            return "CIPhotoEffectNoir"
        case .tonal:
            return "CIPhotoEffectTonal"
        }
    }
}

public class DGCZLFilter: NSObject {
    public var name: String
    
    let applier: ZLFilterApplierType?
    
    @objc public init(name: String, filterType: DGCZLFilterType) {
        self.name = name
        
        if filterType != .normal {
            applier = { image -> UIImage in
                guard let ciImage = image.zl.toCIImage() else {
                    return image
                }
                
                let filter = CIFilter(name: filterType.coreImageFilterName)
                filter?.setValue(ciImage, forKey: kCIInputImageKey)
                guard let outputImage = filter?.outputImage?.zl.toUIImage() else {
                    return image
                }
                return outputImage
            }
        } else {
            applier = nil
        }
    }
    
    /// 可传入 applier 自定义滤镜
    @objc public init(name: String, applier: ZLFilterApplierType?) {
        self.name = name
        self.applier = applier
    }
}

extension DGCZLFilter {
    class func clarendonFilter(image: UIImage) -> UIImage {
        guard let dgc_ciImage = image.zl.toCIImage() else {
            return image
        }
        
        let dgc_backgroundImage = getColorImage(red: 127, green: 187, blue: 227, alpha: Int(255 * 0.2), rect: dgc_ciImage.extent)
        let dgc_outputCIImage = dgc_ciImage.applyingFilter("CIOverlayBlendMode", parameters: [
            "inputBackgroundImage": dgc_backgroundImage
        ])
        .applyingFilter("CIColorControls", parameters: [
            "inputSaturation": 1.35,
            "inputBrightness": 0.05,
            "inputContrast": 1.1
        ])
        guard let dgc_outputImage = dgc_outputCIImage.zl.toUIImage() else {
            return image
        }
        return dgc_outputImage
    }
    
    class func nashvilleFilter(image: UIImage) -> UIImage {
        guard let dgc_ciImage = image.zl.toCIImage() else {
            return image
        }
        
        let dgc_backgroundImage = getColorImage(red: 247, green: 176, blue: 153, alpha: Int(255 * 0.56), rect: dgc_ciImage.extent)
        let dgc_backgroundImage2 = getColorImage(red: 0, green: 70, blue: 150, alpha: Int(255 * 0.4), rect: dgc_ciImage.extent)
        let dgc_outputCIImage = dgc_ciImage
            .applyingFilter("CIDarkenBlendMode", parameters: [
                "inputBackgroundImage": dgc_backgroundImage
            ])
            .applyingFilter("CISepiaTone", parameters: [
                "inputIntensity": 0.2
            ])
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.2,
                "inputBrightness": 0.05,
                "inputContrast": 1.1
            ])
            .applyingFilter("CILightenBlendMode", parameters: [
                "inputBackgroundImage": dgc_backgroundImage2
            ])
        
        guard let dgc_outputImage = dgc_outputCIImage.zl.toUIImage() else {
            return image
        }
        return dgc_outputImage
    }
    
    class func apply1977Filter(image: UIImage) -> UIImage {
        guard let dgc_ciImage = image.zl.toCIImage() else {
            return image
        }
        
        let dgc_filterImage = getColorImage(red: 243, green: 106, blue: 188, alpha: Int(255 * 0.1), rect: dgc_ciImage.extent)
        let dgc_backgroundImage = dgc_ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.3,
                "inputBrightness": 0.1,
                "inputContrast": 1.05
            ])
            .applyingFilter("CIHueAdjust", parameters: [
                "inputAngle": 0.3
            ])
        
        let dgc_outputCIImage = dgc_filterImage
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": dgc_backgroundImage
            ])
            .applyingFilter("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0),
                "inputPoint1": CIVector(x: 0.25, y: 0.20),
                "inputPoint2": CIVector(x: 0.5, y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.80),
                "inputPoint4": CIVector(x: 1, y: 1)
            ])
        
        guard let dgc_outputImage = dgc_outputCIImage.zl.toUIImage() else {
            return image
        }
        return dgc_outputImage
    }
    
    class func toasterFilter(image: UIImage) -> UIImage {
        guard let dgc_ciImage = image.zl.toCIImage() else {
            return image
        }
        
        let dgc_width = dgc_ciImage.extent.dgc_width
        let dgc_height = dgc_ciImage.extent.dgc_height
        let dgc_centerWidth = dgc_width / 2.0
        let dgc_centerHeight = dgc_height / 2.0
        let dgc_radius0 = min(dgc_width / 4.0, dgc_height / 4.0)
        let dgc_radius1 = min(dgc_width / 1.5, dgc_height / 1.5)
        
        let dgc_color0 = getColor(red: 128, green: 78, blue: 15, alpha: 255)
        let dgc_color1 = getColor(red: 79, green: 0, blue: 79, alpha: 255)
        let dgc_circle = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: dgc_centerWidth, y: dgc_centerHeight),
            "inputRadius0": dgc_radius0,
            "inputRadius1": dgc_radius1,
            "inputColor0": dgc_color0,
            "inputColor1": dgc_color1
        ])?.dgc_outputImage?.cropped(to: dgc_ciImage.extent)
        
        let dgc_outputCIImage = dgc_ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.0,
                "inputBrightness": 0.01,
                "inputContrast": 1.1
            ])
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": dgc_circle!
            ])
        
        guard let dgc_outputImage = dgc_outputCIImage.zl.toUIImage() else {
            return image
        }
        return dgc_outputImage
    }
    
    class func getColor(red: Int, green: Int, blue: Int, alpha: Int = 255) -> CIColor {
        return CIColor(
            red: CGFloat(Double(red) / 255.0),
            green: CGFloat(Double(green) / 255.0),
            blue: CGFloat(Double(blue) / 255.0),
            alpha: CGFloat(Double(alpha) / 255.0)
        )
    }
    
    class func getColorImage(red: Int, green: Int, blue: Int, alpha: Int = 255, rect: CGRect) -> CIImage {
        let dgc_color = getColor(red: red, green: green, blue: blue, alpha: alpha)
        return CIImage(dgc_color: dgc_color).cropped(to: rect)
    }
}

public extension DGCZLFilter {
    @objc static let all: [DGCZLFilter] = [.normal, .clarendon, .nashville, .apply1977, .toaster, .chrome, .fade, .instant, .process, .transfer, .tone, .linear, .sepia, .mono, .noir, .tonal]
    
    @objc static let normal = DGCZLFilter(name: "Normal", filterType: .normal)
    
    @objc static let clarendon = DGCZLFilter(name: "Clarendon", applier: DGCZLFilter.clarendonFilter)
    
    @objc static let nashville = DGCZLFilter(name: "Nashville", applier: DGCZLFilter.nashvilleFilter)
    
    @objc static let apply1977 = DGCZLFilter(name: "1977", applier: DGCZLFilter.apply1977Filter)
    
    @objc static let toaster = DGCZLFilter(name: "Toaster", applier: DGCZLFilter.toasterFilter)
    
    @objc static let chrome = DGCZLFilter(name: "Chrome", filterType: .chrome)
    
    @objc static let fade = DGCZLFilter(name: "Fade", filterType: .fade)
    
    @objc static let instant = DGCZLFilter(name: "Instant", filterType: .instant)
    
    @objc static let process = DGCZLFilter(name: "Process", filterType: .process)
    
    @objc static let transfer = DGCZLFilter(name: "Transfer", filterType: .transfer)
    
    @objc static let tone = DGCZLFilter(name: "Tone", filterType: .tone)
    
    @objc static let linear = DGCZLFilter(name: "Linear", filterType: .linear)
    
    @objc static let sepia = DGCZLFilter(name: "Sepia", filterType: .sepia)
    
    @objc static let mono = DGCZLFilter(name: "Mono", filterType: .mono)
    
    @objc static let noir = DGCZLFilter(name: "Noir", filterType: .noir)
    
    @objc static let tonal = DGCZLFilter(name: "Tonal", filterType: .tonal)
}
