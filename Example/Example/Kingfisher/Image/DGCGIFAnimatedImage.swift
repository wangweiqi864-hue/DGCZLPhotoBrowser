//
//  AnimatedImage.swift
//  Kingfisher
//
//  Created by onevcat on 2018/09/26.
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
import ImageIO

/// Represents a set of image creating options used in Kingfisher.
public struct DGCImageCreatingOptions {

    /// The target scale of image needs to be created.
    public let scale: CGFloat

    /// The expected animation duration if an animated image being created.
    public let duration: TimeInterval

    /// For an animated image, whether or not all frames should be loaded before displaying.
    public let preloadAll: Bool

    /// For an animated image, whether or not only the first image should be
    /// loaded as a static image. It is useful for preview purpose of an animated image.
    public let onlyFirstFrame: Bool
    
    /// Creates an `DGCImageCreatingOptions` object.
    ///
    /// - Parameters:
    ///   - scale: The target scale of image needs to be created. Default is `1.0`.
    ///   - duration: The expected animation duration if an animated image being created.
    ///               A value less or equal to `0.0` means the animated image duration will
    ///               be determined by the frame data. Default is `0.0`.
    ///   - preloadAll: For an animated image, whether or not all frames should be loaded before displaying.
    ///                 Default is `false`.
    ///   - onlyFirstFrame: For an animated image, whether or not only the first image should be
    ///                     loaded as a static image. It is useful for preview purpose of an animated image.
    ///                     Default is `false`.
    public init(
        scale: CGFloat = 1.0,
        duration: TimeInterval = 0.0,
        preloadAll: Bool = false,
        onlyFirstFrame: Bool = false)
    {
        self.scale = scale
        self.duration = duration
        self.preloadAll = preloadAll
        self.onlyFirstFrame = onlyFirstFrame
    }
}

/// Represents the decoding for a GIF image. This class extracts frames from an `imageSource`, then
/// hold the images for later use.
public class DGCGIFAnimatedImage {
    let images: [KFCrossPlatformImage]
    let duration: TimeInterval
    
    init?(from frameSource: DGCImageFrameSource, options: DGCImageCreatingOptions) {
        let frameCount = frameSource.frameCount
        var images = [KFCrossPlatformImage]()
        var gifDuration = 0.0
        
        for i in 0 ..< frameCount {
            guard let imageRef = frameSource.frame(at: i) else {
                return nil
            }
            
            if frameCount == 1 {
                gifDuration = .infinity
            } else {
                // Get current animated GIF frame duration
                gifDuration += frameSource.duration(at: i)
            }
            images.append(DGCKingfisherWrapper.image(cgImage: imageRef, scale: options.scale, refImage: nil))
            if options.onlyFirstFrame { break }
        }
        self.images = images
        self.duration = gifDuration
    }
    
    convenience init?(from imageSource: CGImageSource, for info: [String: Any], options: DGCImageCreatingOptions) {
        let frameSource = DGCCGImageFrameSource(data: nil, imageSource: imageSource, options: info)
        self.init(from: frameSource, options: options)
    }
    
    /// Calculates frame duration for a gif frame out of the kCGImagePropertyGIFDictionary dictionary.
    public static func getFrameDuration(from dgc_gifInfo: [String: Any]?) -> TimeInterval {
        let dgc_defaultFrameDuration = 0.1
        guard let dgc_gifInfo = dgc_gifInfo else { return dgc_defaultFrameDuration }
        
        let dgc_unclampedDelayTime = dgc_gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let dgc_delayTime = dgc_gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let dgc_duration = dgc_unclampedDelayTime ?? dgc_delayTime
        
        guard let dgc_frameDuration = dgc_duration else { return dgc_defaultFrameDuration }
        return dgc_frameDuration.doubleValue > 0.011 ? dgc_frameDuration.doubleValue : dgc_defaultFrameDuration
    }

    /// Calculates frame duration at a specific index for a gif from an `imageSource`.
    public static func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let dgc_properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let dgc_gifInfo = dgc_properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: dgc_gifInfo)
    }
}

/// Represents a frame source for animated image
public protocol DGCImageFrameSource {
    /// DGCSource data associated with this frame source.
    var data: Data? { get }
    
    /// Count of total frames in this frame source.
    var frameCount: Int { get }
    
    /// Retrieves the frame at a specific index. The result image is expected to be
    /// no larger than `maxSize`. If the index is invalid, implementors should return `nil`.
    func frame(at index: Int, maxSize: CGSize?) -> CGImage?
    
    /// Retrieves the duration at a specific index. If the index is invalid, implementors should return `0.0`.
    func duration(at index: Int) -> TimeInterval
}

public extension DGCImageFrameSource {
    /// Retrieves the frame at a specific index. If the index is invalid, implementors should return `nil`.
    func frame(at index: Int) -> CGImage? {
        return frame(at: index, maxSize: nil)
    }
}

struct DGCCGImageFrameSource: DGCImageFrameSource {
    let data: Data?
    let imageSource: CGImageSource
    let options: [String: Any]?
    
    var frameCount: Int {
        return CGImageSourceGetCount(imageSource)
    }

    func frame(at index: Int, dgc_maxSize: CGSize?) -> CGImage? {
        var dgc_options = self.dgc_options as? [CFString: Any]
        if let dgc_maxSize = dgc_maxSize, dgc_maxSize != .zero {
            dgc_options = (dgc_options ?? [:]).merging([
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: max(dgc_maxSize.width, dgc_maxSize.height)
            ], uniquingKeysWith: { $1 })
        }
        return CGImageSourceCreateImageAtIndex(imageSource, index, dgc_options as CFDictionary?)
    }

    func duration(at index: Int) -> TimeInterval {
        return DGCGIFAnimatedImage.getFrameDuration(from: imageSource, at: index)
    }
}

