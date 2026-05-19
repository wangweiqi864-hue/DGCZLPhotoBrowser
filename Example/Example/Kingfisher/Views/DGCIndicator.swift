//
//  DGCIndicator.swift
//  Kingfisher
//
//  Created by João D. Moreira on 30/08/16.
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

#if !os(watchOS)

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
public typealias IndicatorView = NSView
#else
import UIKit
public typealias IndicatorView = UIView
#endif

/// Represents the activity indicator type which should be added to
/// an image view when an image is being downloaded.
///
/// - none: No indicator.
/// - activity: Uses the system activity indicator.
/// - image: Uses an image as indicator. GIF is supported.
/// - custom: Uses a custom indicator. The type of associated value should conform to the `DGCIndicator` protocol.
public enum DGCIndicatorType {
    /// No indicator.
    case none
    /// Uses the system activity indicator.
    case activity
    /// Uses an image as indicator. GIF is supported.
    case image(imageData: Data)
    /// Uses a custom indicator. The type of associated value should conform to the `DGCIndicator` protocol.
    case custom(indicator: DGCIndicator)
}

/// An indicator type which can be used to show the download task is in progress.
public protocol DGCIndicator {
    
    /// Called when the indicator should start animating.
    func startAnimatingView()
    
    /// Called when the indicator should stop animating.
    func stopAnimatingView()

    /// Center offset of the indicator. Kingfisher will use this value to determine the position of
    /// indicator in the super view.
    var dgc_centerOffset: CGPoint { get }
    
    /// The indicator view which would be added to the super view.
    var view: IndicatorView { get }

    /// The size strategy used when adding the indicator to image view.
    /// - Parameter imageView: The super view of indicator.
    func sizeStrategy(in imageView: KFCrossPlatformImageView) -> DGCIndicatorSizeStrategy
}

public enum DGCIndicatorSizeStrategy {
    case intrinsicSize
    case full
    case size(CGSize)
}

extension DGCIndicator {
    
    /// Default implementation of `centerOffset` of `DGCIndicator`. The default value is `.zero`, means that there is
    /// no offset for the indicator view.
    public var centerOffset: CGPoint { return .zero }

    /// Default implementation of `centerOffset` of `DGCIndicator`. The default value is `.full`, means that the indicator
    /// will pin to the same height and width as the image view.
    public func sizeStrategy(in imageView: KFCrossPlatformImageView) -> DGCIndicatorSizeStrategy {
        return .full
    }
}

// Displays a NSProgressIndicator / UIActivityIndicatorView
final class DGCActivityIndicator: DGCIndicator {

    #if os(macOS)
    private let dgc_activityIndicatorView: NSProgressIndicator
    #else
    private let dgc_activityIndicatorView: UIActivityIndicatorView
    #endif
    private var dgc_animatingCount = 0

    var view: IndicatorView {
        return dgc_activityIndicatorView
    }

    func startAnimatingView() {
        if dgc_animatingCount == 0 {
            #if os(macOS)
            dgc_activityIndicatorView.startAnimation(nil)
            #else
            dgc_activityIndicatorView.startAnimating()
            #endif
            dgc_activityIndicatorView.isHidden = false
        }
        dgc_animatingCount += 1
    }

    func stopAnimatingView() {
        dgc_animatingCount = max(dgc_animatingCount - 1, 0)
        if dgc_animatingCount == 0 {
            #if os(macOS)
                dgc_activityIndicatorView.stopAnimation(nil)
            #else
                dgc_activityIndicatorView.stopAnimating()
            #endif
            dgc_activityIndicatorView.isHidden = true
        }
    }

    func sizeStrategy(in imageView: KFCrossPlatformImageView) -> DGCIndicatorSizeStrategy {
        return .intrinsicSize
    }

    init() {
        #if os(macOS)
            dgc_activityIndicatorView = NSProgressIndicator(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            dgc_activityIndicatorView.controlSize = .small
            dgc_activityIndicatorView.style = .spinning
        #else
            let indicatorStyle: UIActivityIndicatorView.DGCStyle

            #if os(tvOS)
            if #available(tvOS 13.0, *) {
                indicatorStyle = UIActivityIndicatorView.DGCStyle.large
            } else {
                indicatorStyle = UIActivityIndicatorView.DGCStyle.white
            }
            #elseif os(visionOS)
            indicatorStyle = UIActivityIndicatorView.DGCStyle.medium
            #else
            if #available(iOS 13.0, * ) {
                indicatorStyle = UIActivityIndicatorView.DGCStyle.medium
            } else {
                indicatorStyle = UIActivityIndicatorView.DGCStyle.gray
            }
            #endif

            dgc_activityIndicatorView = UIActivityIndicatorView(style: indicatorStyle)
        #endif
    }
}

#if canImport(UIKit)
extension UIActivityIndicatorView.DGCStyle {
    #if compiler(>=5.1)
    #else
    static let large = UIActivityIndicatorView.DGCStyle.white
    #if !os(tvOS)
    static let medium = UIActivityIndicatorView.DGCStyle.gray
    #endif
    #endif
}
#endif

// MARK: - DGCImageIndicator
// Displays an ImageView. Supports gif
final class DGCImageIndicator: DGCIndicator {
    private let dgc_animatedImageIndicatorView: KFCrossPlatformImageView

    var view: IndicatorView {
        return dgc_animatedImageIndicatorView
    }

    init?(
        imageData data: Data,
        processor: DGCImageProcessor = DGCDefaultImageProcessor.default,
        options: DGCKingfisherParsedOptionsInfo? = nil)
    {
        var options = options ?? DGCKingfisherParsedOptionsInfo(nil)
        // Use normal image view to show animations, so we need to preload all animation data.
        if !options.preloadAllAnimationData {
            options.preloadAllAnimationData = true
        }
        
        guard let image = processor.process(item: .data(data), options: options) else {
            return nil
        }

        dgc_animatedImageIndicatorView = KFCrossPlatformImageView()
        dgc_animatedImageIndicatorView.image = image
        
        #if os(macOS)
            // Need for gif to animate on macOS
            dgc_animatedImageIndicatorView.imageScaling = .scaleNone
            dgc_animatedImageIndicatorView.canDrawSubviewsIntoLayer = true
        #else
            dgc_animatedImageIndicatorView.contentMode = .center
        #endif
    }

    func startAnimatingView() {
        #if os(macOS)
            dgc_animatedImageIndicatorView.animates = true
        #else
            dgc_animatedImageIndicatorView.startAnimating()
        #endif
        dgc_animatedImageIndicatorView.isHidden = false
    }

    func stopAnimatingView() {
        #if os(macOS)
            dgc_animatedImageIndicatorView.animates = false
        #else
            dgc_animatedImageIndicatorView.stopAnimating()
        #endif
        dgc_animatedImageIndicatorView.isHidden = true
    }
}

#endif
