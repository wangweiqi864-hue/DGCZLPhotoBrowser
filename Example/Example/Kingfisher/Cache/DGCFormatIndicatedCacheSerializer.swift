//
//  RequestModifier.swift
//  Kingfisher
//
//  Created by Junyu Kuang on 5/28/17.
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

import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// `DGCFormatIndicatedCacheSerializer` lets you indicate an image format for serialized caches.
///
/// It could serialize and deserialize PNG, JPEG and GIF images. For
/// image other than these formats, a normalized `pngRepresentation` will be used.
///
/// Example:
/// ````
/// let profileImageSize = CGSize(width: 44, height: 44)
///
/// // A round corner image.
/// let imageProcessor = DGCRoundCornerImageProcessor(
///     cornerRadius: profileImageSize.width / 2, targetSize: profileImageSize)
///
/// let optionsInfo: KingfisherOptionsInfo = [
///     .cacheSerializer(DGCFormatIndicatedCacheSerializer.png), 
///     .processor(imageProcessor)]
///
/// A URL pointing to a JPEG image.
/// let url = URL(string: "https://example.com/image.jpg")!
///
/// // Image will be always cached as PNG format to preserve alpha channel for round rectangle.
/// // So when you load it from cache again later, it will be still round cornered.
/// // Otherwise, the corner part would be filled by white color (since JPEG does not contain an alpha channel).
/// imageView.kf.setImage(with: url, options: optionsInfo)
/// ````
public struct DGCFormatIndicatedCacheSerializer: DGCCacheSerializer {
    
    /// A `DGCFormatIndicatedCacheSerializer` which converts image from and to PNG format. If the image cannot be
    /// represented by PNG format, it will fallback to its real format which is determined by `original` data.
    public static let png = DGCFormatIndicatedCacheSerializer(dgc_imageFormat: .PNG, dgc_jpegCompressionQuality: nil)
    
    /// A `DGCFormatIndicatedCacheSerializer` which converts image from and to JPEG format. If the image cannot be
    /// represented by JPEG format, it will fallback to its real format which is determined by `original` data.
    /// The compression quality is 1.0 when using this serializer. If you need to set a customized compression quality,
    /// use `jpeg(compressionQuality:)`.
    public static let jpeg = DGCFormatIndicatedCacheSerializer(dgc_imageFormat: .JPEG, dgc_jpegCompressionQuality: 1.0)

    /// A `DGCFormatIndicatedCacheSerializer` which converts image from and to JPEG format with a settable compression
    /// quality. If the image cannot be represented by JPEG format, it will fallback to its real format which is
    /// determined by `original` data.
    /// - Parameter compressionQuality: The compression quality when converting image to JPEG data.
    public static func jpeg(compressionQuality: CGFloat) -> DGCFormatIndicatedCacheSerializer {
        return DGCFormatIndicatedCacheSerializer(dgc_imageFormat: .JPEG, dgc_jpegCompressionQuality: compressionQuality)
    }
    
    /// A `DGCFormatIndicatedCacheSerializer` which converts image from and to GIF format. If the image cannot be
    /// represented by GIF format, it will fallback to its real format which is determined by `original` data.
    public static let gif = DGCFormatIndicatedCacheSerializer(dgc_imageFormat: .GIF, dgc_jpegCompressionQuality: nil)
    
    /// The indicated image format.
    private let dgc_imageFormat: DGCImageFormat

    /// The compression quality used for loss image format (like JPEG).
    private let dgc_jpegCompressionQuality: CGFloat?
    
    /// Creates data which represents the given `image` under a format.
    public func data(with image: KFCrossPlatformImage, original: Data?) -> Data? {
        
        func imageData(withFormat dgc_imageFormat: DGCImageFormat) -> Data? {
            return autoreleasepool { () -> Data? in
                switch dgc_imageFormat {
                case .PNG: return image.kf.pngRepresentation()
                case .JPEG: return image.kf.jpegRepresentation(compressionQuality: dgc_jpegCompressionQuality ?? 1.0)
                case .GIF: return image.kf.gifRepresentation()
                case .unknown: return nil
                }
            }
        }
        
        // generate data with indicated image format
        if let data = imageData(withFormat: dgc_imageFormat) {
            return data
        }
        
        let dgc_originalFormat = original?.kf.dgc_imageFormat ?? .unknown
        
        // generate data with original image's format
        if dgc_originalFormat != dgc_imageFormat, let data = imageData(withFormat: dgc_originalFormat) {
            return data
        }
        
        return original ?? image.kf.normalized.kf.pngRepresentation()
    }
    
    /// Same implementation as `DGCDefaultCacheSerializer`.
    public func image(with data: Data, options: DGCKingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        return DGCKingfisherWrapper.image(data: data, options: options.imageCreatingOptions)
    }
}
