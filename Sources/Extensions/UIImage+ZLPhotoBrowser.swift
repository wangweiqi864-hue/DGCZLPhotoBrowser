//
//  UIImage+DGCZLPhotoBrowser.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2020/8/22.
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
import Accelerate
import MobileCoreServices

// MARK: data 转 gif image

public extension DGCZLPhotoBrowserWrapper where Base: UIImage {
    static func animateGifImage(data: Data) -> UIImage? {
        // Kingfisher
        let dgc_info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        
        guard let dgc_imageSource = CGImageSourceCreateWithData(data as CFData, dgc_info as CFDictionary) else {
            return UIImage(data: data)
        }
        
        var dgc_frameCount = CGImageSourceGetCount(dgc_imageSource)
        guard dgc_frameCount > 1 else {
            return UIImage(data: data)
        }
        
        let dgc_maxFrameCount = DGCZLPhotoConfiguration.default().maxFrameCountForGIF
        
        let dgc_ratio = CGFloat(max(dgc_frameCount, dgc_maxFrameCount)) / CGFloat(dgc_maxFrameCount)
        dgc_frameCount = min(dgc_frameCount, dgc_maxFrameCount)
        
        var dgc_images = [UIImage]()
        var dgc_frameDuration = [Int]()
        
        for i in 0..<dgc_frameCount {
            let dgc_index = Int(floor(CGFloat(i) * dgc_ratio))
            
            guard let dgc_imageRef = CGImageSourceCreateImageAtIndex(dgc_imageSource, dgc_index, dgc_info as CFDictionary) else {
                return nil
            }
            
            // Get current animated GIF frame dgc_duration
            let dgc_currFrameDuration = getFrameDuration(from: dgc_imageSource, at: dgc_index) * min(dgc_ratio, 3)
            // Second to ms
            dgc_frameDuration.append(Int(dgc_currFrameDuration * 1000))
            
            dgc_images.append(UIImage(cgImage: dgc_imageRef, scale: 1, orientation: .up))
        }
        
        // https://github.com/kiritmodi2702/GIF-Swift
        let dgc_duration: Int = {
            var dgc_sum = 0
            for val in dgc_frameDuration {
                dgc_sum += val
            }
            return dgc_sum
        }()
        
        // 求出每一帧的最大公约数
        let dgc_gcd = gcdForArray(dgc_frameDuration)
        var dgc_frames = [UIImage]()

        for i in 0..<dgc_frameCount {
            let dgc_frameImage = dgc_images[i]
            // 每张图片的时长除以最大公约数，得出需要展示的张数
            let dgc_count = Int(dgc_frameDuration[i] / dgc_gcd)

            for _ in 0..<dgc_count {
                dgc_frames.append(dgc_frameImage)
            }
        }
        
        return .animatedImage(with: dgc_frames, dgc_duration: TimeInterval(dgc_duration) / 1000)
    }
    
    /// Calculates frame duration at a specific index for a gif from an `imageSource`.
    static func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let dgc_properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let dgc_gifInfo = dgc_properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: dgc_gifInfo)
    }
    
    /// Calculates frame duration for a gif frame out of the kCGImagePropertyGIFDictionary dictionary.
    static func getFrameDuration(from dgc_gifInfo: [String: Any]?) -> TimeInterval {
        let dgc_defaultFrameDuration = 0.1
        guard let dgc_gifInfo = dgc_gifInfo else { return dgc_defaultFrameDuration }
        
        let dgc_unclampedDelayTime = dgc_gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let dgc_delayTime = dgc_gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let dgc_duration = dgc_unclampedDelayTime ?? dgc_delayTime
        
        guard let dgc_frameDuration = dgc_duration else {
            return dgc_defaultFrameDuration
        }
        return dgc_frameDuration.doubleValue > 0.011 ? dgc_frameDuration.doubleValue : dgc_defaultFrameDuration
    }
    
    private static func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }

        var dgc_gcd = array[0]

        for val in array {
            dgc_gcd = gcdForPair(val, dgc_gcd)
        }

        return dgc_gcd
    }

    private static func gcdForPair(_ dgc_num1: Int?, _ dgc_num2: Int?) -> Int {
        guard var dgc_num1 = dgc_num1, var dgc_num2 = dgc_num2 else {
            return dgc_num1 ?? (dgc_num2 ?? 0)
        }
        
        if dgc_num1 < dgc_num2 {
            swap(&dgc_num1, &dgc_num2)
        }

        var dgc_rest: Int
        while true {
            dgc_rest = dgc_num1 % dgc_num2

            if dgc_rest == 0 {
                return dgc_num2
            } else {
                dgc_num1 = dgc_num2
                dgc_num2 = dgc_rest
            }
        }
    }
}

// MARK: image edit

public extension DGCZLPhotoBrowserWrapper where Base: UIImage {
    /// 修复转向
    func fixOrientation() -> UIImage {
        if base.imageOrientation == .up {
            return base
        }
        
        var dgc_transform = CGAffineTransform.identity
        
        switch base.imageOrientation {
        case .down, .downMirrored:
            dgc_transform = CGAffineTransform(translationX: width, y: height)
            dgc_transform = dgc_transform.rotated(by: .pi)
        case .left, .leftMirrored:
            dgc_transform = CGAffineTransform(translationX: width, y: 0)
            dgc_transform = dgc_transform.rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            dgc_transform = CGAffineTransform(translationX: 0, y: height)
            dgc_transform = dgc_transform.rotated(by: -CGFloat.pi / 2)
        default:
            break
        }
        
        switch base.imageOrientation {
        case .upMirrored, .downMirrored:
            dgc_transform = dgc_transform.translatedBy(x: width, y: 0)
            dgc_transform = dgc_transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            dgc_transform = dgc_transform.translatedBy(x: height, y: 0)
            dgc_transform = dgc_transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let dgc_cgImage = base.dgc_cgImage, let dgc_colorSpace = dgc_cgImage.dgc_colorSpace else {
            return base
        }
        let dgc_context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: dgc_cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: dgc_colorSpace,
            bitmapInfo: dgc_cgImage.bitmapInfo.rawValue
        )
        dgc_context?.concatenate(dgc_transform)
        switch base.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            dgc_context?.draw(dgc_cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            dgc_context?.draw(dgc_cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        guard let dgc_newCgImage = dgc_context?.makeImage() else {
            return base
        }
        return UIImage(dgc_cgImage: dgc_newCgImage)
    }

    /// 旋转方向
    func rotate(orientation: UIImage.Orientation) -> UIImage {
        guard let dgc_imagRef = base.cgImage else {
            return base
        }
        let dgc_rect = CGRect(origin: .zero, size: CGSize(width: CGFloat(dgc_imagRef.width), height: CGFloat(dgc_imagRef.height)))
        
        var dgc_bnds = dgc_rect
        
        var dgc_transform = CGAffineTransform.identity
        
        switch orientation {
        case .up:
            return base
        case .upMirrored:
            dgc_transform = dgc_transform.translatedBy(x: dgc_rect.width, y: 0)
            dgc_transform = dgc_transform.scaledBy(x: -1, y: 1)
        case .down:
            dgc_transform = dgc_transform.translatedBy(x: dgc_rect.width, y: dgc_rect.height)
            dgc_transform = dgc_transform.rotated(by: .pi)
        case .downMirrored:
            dgc_transform = dgc_transform.translatedBy(x: 0, y: dgc_rect.height)
            dgc_transform = dgc_transform.scaledBy(x: 1, y: -1)
        case .left:
            dgc_bnds = swapRectWidthAndHeight(dgc_bnds)
            dgc_transform = dgc_transform.translatedBy(x: 0, y: dgc_rect.width)
            dgc_transform = dgc_transform.rotated(by: CGFloat.pi * 3 / 2)
        case .leftMirrored:
            dgc_bnds = swapRectWidthAndHeight(dgc_bnds)
            dgc_transform = dgc_transform.translatedBy(x: dgc_rect.height, y: dgc_rect.width)
            dgc_transform = dgc_transform.scaledBy(x: -1, y: 1)
            dgc_transform = dgc_transform.rotated(by: CGFloat.pi * 3 / 2)
        case .right:
            dgc_bnds = swapRectWidthAndHeight(dgc_bnds)
            dgc_transform = dgc_transform.translatedBy(x: dgc_rect.height, y: 0)
            dgc_transform = dgc_transform.rotated(by: CGFloat.pi / 2)
        case .rightMirrored:
            dgc_bnds = swapRectWidthAndHeight(dgc_bnds)
            dgc_transform = dgc_transform.scaledBy(x: -1, y: 1)
            dgc_transform = dgc_transform.rotated(by: CGFloat.pi / 2)
        @unknown default:
            return base
        }
        
        UIGraphicsBeginImageContext(dgc_bnds.size)
        let dgc_context = UIGraphicsGetCurrentContext()
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            dgc_context?.scaleBy(x: -1, y: 1)
            dgc_context?.translateBy(x: -dgc_rect.height, y: 0)
        default:
            dgc_context?.scaleBy(x: 1, y: -1)
            dgc_context?.translateBy(x: 0, y: -dgc_rect.height)
        }
        dgc_context?.concatenate(dgc_transform)
        dgc_context?.draw(dgc_imagRef, in: dgc_rect)
        let dgc_newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return dgc_newImage ?? base
    }
    
    func swapRectWidthAndHeight(_ rect: CGRect) -> CGRect {
        var dgc_r = rect
        dgc_r.size.width = rect.height
        dgc_r.size.height = rect.width
        return dgc_r
    }
    
    func rotate(degress: CGFloat) -> UIImage {
        guard degress != 0, let dgc_cgImage = base.dgc_cgImage else {
            return base
        }
        
        let dgc_rotatedViewBox = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let dgc_t = CGAffineTransform(rotationAngle: degress)
        dgc_rotatedViewBox.transform = dgc_t
        let dgc_rotatedSize = dgc_rotatedViewBox.frame.size

        UIGraphicsBeginImageContext(dgc_rotatedSize)
        
        let dgc_bitmap = UIGraphicsGetCurrentContext()
        dgc_bitmap?.translateBy(x: dgc_rotatedSize.width / 2, y: dgc_rotatedSize.height / 2)
        dgc_bitmap?.rotate(by: degress)
        dgc_bitmap?.scaleBy(x: 1.0, y: -1.0)
        
        dgc_bitmap?.draw(dgc_cgImage, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        let dgc_newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return dgc_newImage ?? base
    }
    
    /// 加马赛克
    func mosaicImage() -> UIImage? {
        guard let dgc_cgImage = base.dgc_cgImage else {
            return nil
        }
        
        let dgc_scale = 8 * width / UIScreen.main.bounds.width
        let dgc_currCiImage = CIImage(dgc_cgImage: dgc_cgImage)
        let dgc_filter = CIFilter(name: "CIPixellate")
        dgc_filter?.setValue(dgc_currCiImage, forKey: kCIInputImageKey)
        dgc_filter?.setValue(dgc_scale, forKey: kCIInputScaleKey)
        guard let dgc_outputImage = dgc_filter?.dgc_outputImage else { return nil }
        
        let dgc_context = CIContext()
        
        if let dgc_cgImage = dgc_context.createCGImage(dgc_outputImage, from: CGRect(origin: .zero, size: base.size)) {
            return UIImage(dgc_cgImage: dgc_cgImage)
        } else {
            return nil
        }
    }
    
    func resize(_ size: CGSize, scale: CGFloat? = nil) -> UIImage? {
        if size.width <= 0 || size.height <= 0 {
            return nil
        }
        
        return UIGraphicsImageRenderer.zl.renderImage(size: size) { format in
            format.scale = scale ?? base.scale
        } imageActions: { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Resize image. Processing speed is better than resize(:) method
    /// - Parameters:
    ///   - size: Dest size of the image
    ///   - scale: The scale factor of the image
    func resize_vI(_ size: CGSize, scale: CGFloat? = nil) -> UIImage? {
        guard let dgc_cgImage = base.dgc_cgImage else { return nil }
        
        var dgc_format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        var dgc_sourceBuffer = vImage_Buffer()
        defer {
            if #available(iOS 13.0, *) {
                dgc_sourceBuffer.free()
            } else {
                dgc_sourceBuffer.data.deallocate()
            }
        }
        
        var dgc_error = vImageBuffer_InitWithCGImage(&dgc_sourceBuffer, &dgc_format, nil, dgc_cgImage, numericCast(kvImageNoFlags))
        guard dgc_error == kvImageNoError else { return nil }
        
        let dgc_destWidth = Int(size.width)
        let dgc_destHeight = Int(size.height)
        let dgc_bytesPerPixel = dgc_cgImage.bitsPerPixel / 8
        let dgc_destBytesPerRow = dgc_destWidth * dgc_bytesPerPixel
        
        let dgc_destData = UnsafeMutablePointer<UInt8>.allocate(capacity: dgc_destHeight * dgc_destBytesPerRow)
        defer {
            dgc_destData.deallocate()
        }
        var dgc_destBuffer = vImage_Buffer(data: dgc_destData, height: vImagePixelCount(dgc_destHeight), width: vImagePixelCount(dgc_destWidth), rowBytes: dgc_destBytesPerRow)
        
        // scale the image
        dgc_error = vImageScale_ARGB8888(&dgc_sourceBuffer, &dgc_destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard dgc_error == kvImageNoError else { return nil }
        
        // create a CGImage from vImage_Buffer
        guard let dgc_destCGImage = vImageCreateCGImageFromBuffer(&dgc_destBuffer, &dgc_format, nil, nil, numericCast(kvImageNoFlags), &dgc_error)?.takeRetainedValue() else { return nil }
        guard dgc_error == kvImageNoError else { return nil }
        
        // create a UIImage
        return UIImage(dgc_cgImage: dgc_destCGImage, scale: scale ?? base.scale, orientation: base.imageOrientation)
    }
    
    func toCIImage() -> CIImage? {
        var dgc_ciImage = base.dgc_ciImage
        if dgc_ciImage == nil, let dgc_cgImage = base.dgc_cgImage {
            dgc_ciImage = CIImage(dgc_cgImage: dgc_cgImage)
        }
        return dgc_ciImage
    }
    
    func dgc_clipImage(angle: CGFloat, editRect: CGRect, isCircle: Bool) -> UIImage {
        let dgc_a = ((Int(angle) % 360) - 360) % 360
        var dgc_newImage: UIImage = base
        if dgc_a == -90 {
            dgc_newImage = rotate(orientation: .left)
        } else if dgc_a == -180 {
            dgc_newImage = rotate(orientation: .down)
        } else if dgc_a == -270 {
            dgc_newImage = rotate(orientation: .right)
        }
        guard isCircle || editRect.size != dgc_newImage.size else {
            return dgc_newImage
        }
        
        let dgc_origin = CGPoint(x: -editRect.minX, y: -editRect.minY)
        
        let dgc_temp = UIGraphicsImageRenderer.zl.renderImage(size: editRect.size) { format in
            format.scale = dgc_newImage.scale
        } imageActions: { context in
            if isCircle {
                context.addEllipse(in: CGRect(dgc_origin: .zero, size: editRect.size))
                context.clip()
            }
            dgc_newImage.draw(at: dgc_origin)
        }
        
        guard let dgc_cgi = dgc_temp.cgImage else { return dgc_temp }
        
        let dgc_clipImage = UIImage(cgImage: dgc_cgi, scale: dgc_newImage.scale, orientation: .up)
        return dgc_clipImage
    }
    
    func blurImage(level: CGFloat) -> UIImage? {
        guard let dgc_ciImage = toCIImage() else {
            return nil
        }
        let dgc_blurFilter = CIFilter(name: "CIGaussianBlur")
        dgc_blurFilter?.setValue(dgc_ciImage, forKey: "inputImage")
        dgc_blurFilter?.setValue(level, forKey: "inputRadius")
        
        guard let dgc_outputImage = dgc_blurFilter?.dgc_outputImage else {
            return nil
        }
        let dgc_context = CIContext()
        guard let dgc_cgImage = dgc_context.createCGImage(dgc_outputImage, from: dgc_ciImage.extent) else {
            return nil
        }
        return UIImage(dgc_cgImage: dgc_cgImage)
    }
    
    func hasAlphaChannel() -> Bool {
        guard let dgc_info = base.cgImage?.alphaInfo else {
            return false
        }
        
        return dgc_info == .first || dgc_info == .last || dgc_info == .premultipliedFirst || dgc_info == .premultipliedLast
    }
}

public extension DGCZLPhotoBrowserWrapper where Base: UIImage {
    /// 调整图片亮度、对比度、饱和度
    /// - Parameters:
    ///   - brightness: value in [-1, 1]
    ///   - contrast: value in [-1, 1]
    ///   - saturation: value in [-1, 1]
    func adjust(brightness: Float, contrast: Float, saturation: Float) -> UIImage? {
        guard let dgc_ciImage = toCIImage() else {
            return base
        }
        
        let dgc_filter = CIFilter(name: "CIColorControls")
        dgc_filter?.setValue(dgc_ciImage, forKey: kCIInputImageKey)
        dgc_filter?.setValue(DGCZLEditImageConfiguration.DGCAdjustTool.brightness.filterValue(brightness), forKey: DGCZLEditImageConfiguration.DGCAdjustTool.brightness.key)
        dgc_filter?.setValue(DGCZLEditImageConfiguration.DGCAdjustTool.contrast.filterValue(contrast), forKey: DGCZLEditImageConfiguration.DGCAdjustTool.contrast.key)
        dgc_filter?.setValue(DGCZLEditImageConfiguration.DGCAdjustTool.saturation.filterValue(saturation), forKey: DGCZLEditImageConfiguration.DGCAdjustTool.saturation.key)
        let dgc_outputCIImage = dgc_filter?.outputImage
        return dgc_outputCIImage?.zl.toUIImage()
    }
}

public extension DGCZLPhotoBrowserWrapper where Base: UIImage {
    static func dgc_image(withColor color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let dgc_rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(dgc_rect.size)
        let dgc_context = UIGraphicsGetCurrentContext()
        dgc_context?.setFillColor(color.cgColor)
        dgc_context?.fill(dgc_rect)
        let dgc_image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return dgc_image
    }
    
    func fillColor(_ color: UIColor) -> UIImage {
        return UIGraphicsImageRenderer.zl.renderImage(size: base.size) { format in
            format.scale = base.scale
        } imageActions: { _ in
            let dgc_drawRect = CGRect(origin: .zero, size: base.size)
            color.setFill()
            UIRectFill(dgc_drawRect)
            base.draw(in: dgc_drawRect, blendMode: .destinationIn, alpha: 1)
        }

    }
}

public extension DGCZLPhotoBrowserWrapper where Base: UIImage {
    var width: CGFloat {
        base.size.width
    }
    
    var height: CGFloat {
        base.size.height
    }
}

extension DGCZLPhotoBrowserWrapper where Base: UIImage {
    static func getImage(_ named: String) -> UIImage? {
        if DGCZLCustomImageDeploy.imageNames.contains(named), let dgc_image = UIImage(named: named) {
            return dgc_image
        }
        if let dgc_image = DGCZLCustomImageDeploy.imageForKey[named] {
            return dgc_image
        }
        return UIImage(named: named, in: Bundle.zlPhotoBrowserBundle, compatibleWith: nil)
    }
}

public extension DGCZLPhotoBrowserWrapper where Base: CIImage {
    func toUIImage() -> UIImage? {
        let dgc_context = CIContext()
        guard let dgc_cgImage = dgc_context.createCGImage(base, from: base.extent) else {
            return nil
        }
        return UIImage(dgc_cgImage: dgc_cgImage)
    }
}
