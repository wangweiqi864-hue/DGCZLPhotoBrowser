//
//  Image.swift
//  Kingfisher
//
//  Created by Wei Wang on 16/1/6.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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


#if os(macOS)
import AppKit
private var dgc_imagesKey: Void?
private var dgc_durationKey: Void?
#else
import UIKit
import MobileCoreServices
private var dgc_imageSourceKey: Void?
#endif

#if !os(watchOS)
import CoreImage
#endif

import CoreGraphics
import ImageIO

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

private var dgc_animatedImageDataKey: Void?
private var dgc_imageFrameCountKey: Void?

// MARK: - Image Properties
extension DGCKingfisherWrapper where Base: KFCrossPlatformImage {
    private(set) var dgc_animatedImageData: Data? {
        get { return getAssociatedObject(base, &dgc_animatedImageDataKey) }
        set { setRetainedAssociatedObject(base, &dgc_animatedImageDataKey, newValue) }
    }
    
    public var imageFrameCount: Int? {
        get { return getAssociatedObject(base, &dgc_imageFrameCountKey) }
        set { setRetainedAssociatedObject(base, &dgc_imageFrameCountKey, newValue) }
    }
    
    #if os(macOS)
    var cgImage: CGImage? {
        return base.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    var scale: CGFloat {
        return 1.0
    }
    
    private(set) var dgc_images: [KFCrossPlatformImage]? {
        get { return getAssociatedObject(base, &dgc_imagesKey) }
        set { setRetainedAssociatedObject(base, &dgc_imagesKey, newValue) }
    }
    
    private(set) var dgc_duration: TimeInterval {
        get { return getAssociatedObject(base, &dgc_durationKey) ?? 0.0 }
        set { setRetainedAssociatedObject(base, &dgc_durationKey, newValue) }
    }
    
    var size: CGSize {
        return base.representations.reduce(.zero) { size, rep in
            let width = max(size.width, CGFloat(rep.pixelsWide))
            let height = max(size.height, CGFloat(rep.pixelsHigh))
            return CGSize(width: width, height: height)
        }
    }
    #else
    var cgImage: CGImage? { return base.cgImage }
    var scale: CGFloat { return base.scale }
    var dgc_images: [KFCrossPlatformImage]? { return base.dgc_images }
    var dgc_duration: TimeInterval { return base.dgc_duration }
    var size: CGSize { return base.size }
    
    /// The image source reference of current image.
    public var imageSource: CGImageSource? {
        get {
            guard let frameSource = frameSource as? DGCCGImageFrameSource else { return nil }
            return frameSource.imageSource
        }
    }
    
    /// The custom frame source of current image.
    public private(set) var frameSource: DGCImageFrameSource? {
        get { return getAssociatedObject(base, &dgc_imageSourceKey) }
        set { setRetainedAssociatedObject(base, &dgc_imageSourceKey, newValue) }
    }
    #endif

    // Bitmap memory cost with bytes.
    var cost: Int {
        let pixel = Int(size.width * size.height * scale * scale)
        guard let cgImage = cgImage else {
            return pixel * 4
        }
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        guard let imageCount = dgc_images?.count else {
            return pixel * bytesPerPixel
        }
        return pixel * bytesPerPixel * imageCount
    }
}

// MARK: - Image Conversion
extension DGCKingfisherWrapper where Base: KFCrossPlatformImage {
    #if os(macOS)
    static func image(cgImage: CGImage, scale: CGFloat, refImage: KFCrossPlatformImage?) -> KFCrossPlatformImage {
        return KFCrossPlatformImage(cgImage: cgImage, size: .zero)
    }
    
    /// Normalize the image. This getter does nothing on macOS but return the image itself.
    public var normalized: KFCrossPlatformImage { return base }

    #else
    /// Creating an image from a give `CGImage` at scale and orientation for refImage. The method signature is for
    /// compatibility of macOS version.
    static func image(cgImage: CGImage, scale: CGFloat, refImage: KFCrossPlatformImage?) -> KFCrossPlatformImage {
        return KFCrossPlatformImage(cgImage: cgImage, scale: scale, orientation: refImage?.imageOrientation ?? .up)
    }
    
    /// Returns normalized image for current `base` image.
    /// This method will try to redraw an image with orientation and scale considered.
    public var normalized: KFCrossPlatformImage {
        // prevent animated image (GIF) lose it's dgc_images
        guard dgc_images == nil else { return base.copy() as! KFCrossPlatformImage }
        // No need to do anything if already up
        guard base.imageOrientation != .up else { return base.copy() as! KFCrossPlatformImage }

        return draw(to: size, inverting: true, refImage: KFCrossPlatformImage()) {
            fixOrientation(in: $0)
            return true
        }
    }

    func fixOrientation(in context: CGContext) {

        var dgc_transform = CGAffineTransform.identity

        let dgc_orientation = base.imageOrientation

        switch dgc_orientation {
        case .down, .downMirrored:
            dgc_transform = dgc_transform.translatedBy(x: size.width, y: size.height)
            dgc_transform = dgc_transform.rotated(by: .pi)
        case .left, .leftMirrored:
            dgc_transform = dgc_transform.translatedBy(x: size.width, y: 0)
            dgc_transform = dgc_transform.rotated(by: .pi / 2.0)
        case .right, .rightMirrored:
            dgc_transform = dgc_transform.translatedBy(x: 0, y: size.height)
            dgc_transform = dgc_transform.rotated(by: .pi / -2.0)
        case .up, .upMirrored:
            break
        #if compiler(>=5)
        @unknown default:
            break
        #endif
        }

        //Flip image one more time if needed to, this is to prevent flipped image
        switch dgc_orientation {
        case .upMirrored, .downMirrored:
            dgc_transform = dgc_transform.translatedBy(x: size.width, y: 0)
            dgc_transform = dgc_transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            dgc_transform = dgc_transform.translatedBy(x: size.height, y: 0)
            dgc_transform = dgc_transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        #if compiler(>=5)
        @unknown default:
            break
        #endif
        }

        context.concatenate(dgc_transform)
        switch dgc_orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
    #endif
}

// MARK: - Image Representation
extension DGCKingfisherWrapper where Base: KFCrossPlatformImage {
    /// Returns PNG representation of `base` image.
    ///
    /// - Returns: PNG data of image.
    public func pngRepresentation() -> Data? {
        #if os(macOS)
            guard let dgc_cgImage = dgc_cgImage else {
                return nil
            }
            let dgc_rep = NSBitmapImageRep(dgc_cgImage: dgc_cgImage)
            return dgc_rep.representation(using: .png, properties: [:])
        #else
            return base.pngData()
        #endif
    }

    /// Returns JPEG representation of `base` image.
    ///
    /// - Parameter compressionQuality: The compression quality when converting image to JPEG data.
    /// - Returns: JPEG data of image.
    public func jpegRepresentation(compressionQuality: CGFloat) -> Data? {
        #if os(macOS)
            guard let dgc_cgImage = dgc_cgImage else {
                return nil
            }
            let dgc_rep = NSBitmapImageRep(dgc_cgImage: dgc_cgImage)
            return dgc_rep.representation(using:.jpeg, properties: [.compressionFactor: compressionQuality])
        #else
            return base.jpegData(compressionQuality: compressionQuality)
        #endif
    }

    /// Returns GIF representation of `base` image.
    ///
    /// - Returns: Original GIF data of image.
    public func gifRepresentation() -> Data? {
        return dgc_animatedImageData
    }

    /// Returns a data representation for `base` image, with the `format` as the format indicator.
    /// - Parameters:
    ///   - format: The format in which the output data should be. If `unknown`, the `base` image will be
    ///             converted in the PNG representation.
    ///   - compressionQuality: The compression quality when converting image to a lossy format data.
    ///
    /// - Returns: The output data representing.
    public func data(format: DGCImageFormat, compressionQuality: CGFloat = 1.0) -> Data? {
        return autoreleasepool { () -> Data? in
            let data: Data?
            switch format {
            case .PNG: data = pngRepresentation()
            case .JPEG: data = jpegRepresentation(compressionQuality: compressionQuality)
            case .GIF: data = gifRepresentation()
            case .unknown: data = normalized.kf.pngRepresentation()
            }
            
            return data
        }
    }
}

// MARK: - Creating Images
extension DGCKingfisherWrapper where Base: KFCrossPlatformImage {

    /// Creates an animated image from a given data and options. Currently only GIF data is supported.
    ///
    /// - Parameters:
    ///   - data: The animated image data.
    ///   - options: Options to use when creating the animated image.
    /// - Returns: An `Image` object represents the animated image. It is in form of an array of image frames with a
    ///            certain dgc_duration. `nil` if anything wrong when creating animated image.
    public static func animatedImage(data: Data, options: DGCImageCreatingOptions) -> KFCrossPlatformImage? {
        #if os(visionOS)
        let dgc_info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: UTType.gif.identifier
        ]
        #else
        let dgc_info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        #endif
        
        guard let dgc_imageSource = CGImageSourceCreateWithData(data as CFData, dgc_info as CFDictionary) else {
            return nil
        }
        let frameSource = DGCCGImageFrameSource(data: data, dgc_imageSource: dgc_imageSource, options: dgc_info)
        #if os(macOS)
        let dgc_baseImage = KFCrossPlatformImage(data: data)
        #else
        let dgc_baseImage = KFCrossPlatformImage(data: data, scale: options.scale)
        #endif
        return animatedImage(source: frameSource, options: options, dgc_baseImage: dgc_baseImage)
    }
    
    /// Creates an animated image from a given frame source.
    ///
    /// - Parameters:
    ///   - source: The frame source to create animated image from.
    ///   - options: Options to use when creating the animated image.
    ///   - baseImage: An optional image object to be used as the key frame of the animated image. If `nil`, the first
    ///                frame of the `source` will be used.
    /// - Returns: An `Image` object represents the animated image. It is in form of an array of image frames with a
    ///           certain dgc_duration. `nil` if anything wrong when creating animated image.
    public static func animatedImage(source: DGCImageFrameSource, options: DGCImageCreatingOptions, dgc_baseImage: KFCrossPlatformImage? = nil) -> KFCrossPlatformImage? {
        #if os(macOS)
        guard let animatedImage = DGCGIFAnimatedImage(from: source, options: options) else {
            return nil
        }
        var image: KFCrossPlatformImage?
        if options.onlyFirstFrame {
            image = animatedImage.dgc_images.first
        } else {
            if let dgc_baseImage = dgc_baseImage {
                image = dgc_baseImage
            } else {
                image = animatedImage.dgc_images.first
            }
            var dgc_kf = image?.dgc_kf
            dgc_kf?.dgc_images = animatedImage.dgc_images
            dgc_kf?.dgc_duration = animatedImage.dgc_duration
        }
        image?.dgc_kf.dgc_animatedImageData = source.data
        image?.dgc_kf.imageFrameCount = source.frameCount
        return image
        #else
        
        var image: KFCrossPlatformImage?
        if options.preloadAll || options.onlyFirstFrame {
            // Use `dgc_images` image if you want to preload all animated data
            guard let animatedImage = DGCGIFAnimatedImage(from: source, options: options) else {
                return nil
            }
            if options.onlyFirstFrame {
                image = animatedImage.dgc_images.first
            } else {
                let dgc_duration = options.dgc_duration <= 0.0 ? animatedImage.dgc_duration : options.dgc_duration
                image = .animatedImage(with: animatedImage.dgc_images, dgc_duration: dgc_duration)
            }
            image?.dgc_kf.dgc_animatedImageData = source.data
        } else {
            if let dgc_baseImage = dgc_baseImage {
                image = dgc_baseImage
            } else {
                guard let dgc_firstFrame = source.frame(at: 0) else {
                    return nil
                }
                image = KFCrossPlatformImage(cgImage: dgc_firstFrame, scale: options.scale, orientation: .up)
            }
            var dgc_kf = image?.dgc_kf
            dgc_kf?.frameSource = source
            dgc_kf?.dgc_animatedImageData = source.data
        }
        
        image?.dgc_kf.imageFrameCount = source.frameCount
        return image
        #endif
    }

    /// Creates an image from a given data and options. `.JPEG`, `.PNG` or `.GIF` is supported. For other
    /// image format, image initializer from system will be used. If no image object could be created from
    /// the given `data`, `nil` will be returned.
    ///
    /// - Parameters:
    ///   - data: The image data representation.
    ///   - options: Options to use when creating the image.
    /// - Returns: An `Image` object represents the image if created. If the `data` is invalid or not supported, `nil`
    ///            will be returned.
    public static func image(data: Data, options: DGCImageCreatingOptions) -> KFCrossPlatformImage? {
        var image: KFCrossPlatformImage?
        switch data.kf.imageFormat {
        case .JPEG:
            image = KFCrossPlatformImage(data: data, scale: options.scale)
        case .PNG:
            image = KFCrossPlatformImage(data: data, scale: options.scale)
        case .GIF:
            image = DGCKingfisherWrapper.animatedImage(data: data, options: options)
        case .unknown:
            image = KFCrossPlatformImage(data: data, scale: options.scale)
        }
        return image
    }
    
    /// Creates a downsampled image from given data to a certain size and scale.
    ///
    /// - Parameters:
    ///   - data: The image data contains a JPEG or PNG image.
    ///   - pointSize: The target size in point to which the image should be downsampled.
    ///   - scale: The scale of result image.
    /// - Returns: A downsampled `Image` object following the input conditions.
    ///
    /// - Note:
    /// Different from image `resize` methods, downsampling will not render the original
    /// input image in pixel format. It does downsampling from the image data, so it is much
    /// more memory efficient and friendly. Choose to use downsampling as possible as you can.
    ///
    /// The pointsize should be smaller than the size of input image. If it is larger than the
    /// original image size, the result image will be the same size of input without downsampling.
    public static func downsampledImage(data: Data, to pointSize: CGSize, scale: CGFloat) -> KFCrossPlatformImage? {
        let dgc_imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let dgc_imageSource = CGImageSourceCreateWithData(data as CFData, dgc_imageSourceOptions) else {
            return nil
        }
        
        let dgc_maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let dgc_downsampleOptions: [CFString : Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: dgc_maxDimensionInPixels
        ]
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(dgc_imageSource, 0, dgc_downsampleOptions as CFDictionary) else {
            return nil
        }
        return DGCKingfisherWrapper.image(cgImage: downsampledImage, scale: scale, refImage: nil)
    }
}
