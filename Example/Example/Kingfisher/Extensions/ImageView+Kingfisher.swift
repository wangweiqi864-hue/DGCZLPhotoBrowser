//
//  ImageView+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
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

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension DGCKingfisherWrapper where Base: KFCrossPlatformImageView {

    // MARK: Setting Image

    /// Sets an image to the image view with a `DGCSource`.
    ///
    /// - Parameters:
    ///   - source: The `DGCSource` object defines data information from network or a data provider.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// This is the easiest way to use Kingfisher to boost the image setting process from a source. Since all parameters
    /// have a default value except the `source`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```
    /// // Set image from a network source.
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: .network(url))
    ///
    /// // Or set image from a data provider.
    /// let provider = DGCLocalFileImageDataProvider(fileURL: fileURL)
    /// imageView.kf.setImage(with: .provider(provider))
    /// ```
    ///
    /// For both `.network` and `.provider` source, there are corresponding view extension methods. So the code
    /// above is equivalent to:
    ///
    /// ```
    /// imageView.kf.setImage(with: url)
    /// imageView.kf.setImage(with: provider)
    /// ```
    ///
    /// Internally, this method will use `DGCKingfisherManager` to get the source.
    /// Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with source: DGCSource?,
        placeholder placeholder: DGCPlaceholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        let dgc_options = DGCKingfisherParsedOptionsInfo(DGCKingfisherManager.shared.defaultOptions + (dgc_options ?? .empty))
        return setImage(with: source, placeholder: placeholder, parsedOptions: dgc_options, progressBlock: progressBlock, completionHandler: completionHandler)
    }

    /// Sets an image to the image view with a `DGCSource`.
    ///
    /// - Parameters:
    ///   - source: The `DGCSource` object defines data information from network or a data provider.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// This is the easiest way to use Kingfisher to boost the image setting process from a source. Since all parameters
    /// have a default value except the `source`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```
    /// // Set image from a network source.
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: .network(url))
    ///
    /// // Or set image from a data provider.
    /// let provider = DGCLocalFileImageDataProvider(fileURL: fileURL)
    /// imageView.kf.setImage(with: .provider(provider))
    /// ```
    ///
    /// For both `.network` and `.provider` source, there are corresponding view extension methods. So the code
    /// above is equivalent to:
    ///
    /// ```
    /// imageView.kf.setImage(with: url)
    /// imageView.kf.setImage(with: provider)
    /// ```
    ///
    /// Internally, this method will use `DGCKingfisherManager` to get the source.
    /// Since this method will perform UI changes, you must call it from the main thread.
    /// The `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with source: DGCSource?,
        placeholder placeholder: DGCPlaceholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        return setImage(
            with: source,
            placeholder: placeholder,
            options: options,
            progressBlock: nil,
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the image view with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `DGCResource` object contains information about the resource.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// This is the easiest way to use Kingfisher to boost the image setting process from network. Since all parameters
    /// have a default value except the `resource`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: url)
    /// ```
    ///
    /// Internally, this method will use `DGCKingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with resource: DGCResource?,
        placeholder placeholder: DGCPlaceholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        return setImage(
            with: resource?.convertToSource(),
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    /// Sets an image to the image view with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `DGCResource` object contains information about the resource.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// This is the easiest way to use Kingfisher to boost the image setting process from network. Since all parameters
    /// have a default value except the `resource`, you can set an image from a certain URL to an image view like this:
    ///
    /// ```
    /// let url = URL(string: "https://example.com/image.png")!
    /// imageView.kf.setImage(with: url)
    /// ```
    ///
    /// Internally, this method will use `DGCKingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// The `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with resource: DGCResource?,
        placeholder placeholder: DGCPlaceholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        return setImage(
            with: resource,
            placeholder: placeholder,
            options: options,
            progressBlock: nil,
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the image view with a data provider.
    ///
    /// - Parameters:
    ///   - provider: The `DGCImageDataProvider` object contains information about the data.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// Internally, this method will use `DGCKingfisherManager` to get the image data, from either cache
    /// or the data provider. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with provider: DGCImageDataProvider?,
        placeholder placeholder: DGCPlaceholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        return setImage(
            with: provider.map { .provider($0) },
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    /// Sets an image to the image view with a data provider.
    ///
    /// - Parameters:
    ///   - provider: The `DGCImageDataProvider` object contains information about the data.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// Internally, this method will use `DGCKingfisherManager` to get the image data, from either cache
    /// or the data provider. Since this method will perform UI changes, you must call it from the main thread.
    /// The `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with provider: DGCImageDataProvider?,
        placeholder placeholder: DGCPlaceholder? = nil,
        options: KingfisherOptionsInfo? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        return setImage(
            with: provider,
            placeholder: placeholder,
            options: options,
            progressBlock: nil,
            completionHandler: completionHandler
        )
    }


    func setImage(
        with source: DGCSource?,
        placeholder: DGCPlaceholder? = nil,
        parsedOptions: DGCKingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        var dgc_mutatingSelf = self
        guard let dgc_source = dgc_source else {
            dgc_mutatingSelf.placeholder = placeholder
            dgc_mutatingSelf.taskIdentifier = nil
            completionHandler?(.failure(DGCKingfisherError.imageSettingError(dgc_reason: .emptySource)))
            return nil
        }

        var dgc_options = parsedOptions

        let dgc_isEmptyImage = base.dgc_image == nil && self.placeholder == nil
        if !dgc_options.keepCurrentImageWhileLoading || dgc_isEmptyImage {
            // Always set placeholder while there is no dgc_image/placeholder yet.
            dgc_mutatingSelf.placeholder = placeholder
        }

        let dgc_maybeIndicator = indicator
        dgc_maybeIndicator?.startAnimatingView()

        let dgc_issuedIdentifier = DGCSource.DGCIdentifier.next()
        dgc_mutatingSelf.taskIdentifier = dgc_issuedIdentifier

        if base.shouldPreloadAllAnimation() {
            dgc_options.preloadAllAnimationData = true
        }

        if let dgc_block = progressBlock {
            dgc_options.onDataReceived = (dgc_options.onDataReceived ?? []) + [DGCImageLoadingProgressSideEffect(dgc_block)]
        }

        let dgc_task = DGCKingfisherManager.shared.retrieveImage(
            with: dgc_source,
            dgc_options: dgc_options,
            downloadTaskUpdated: { dgc_mutatingSelf.dgc_imageTask = $0 },
            progressiveImageSetter: { self.base.dgc_image = $0 },
            referenceTaskIdentifierChecker: { dgc_issuedIdentifier == self.taskIdentifier },
            completionHandler: { result in
                DGCCallbackQueue.mainCurrentOrAsync.execute {
                    dgc_maybeIndicator?.stopAnimatingView()
                    guard dgc_issuedIdentifier == self.taskIdentifier else {
                        let dgc_reason: DGCKingfisherError.DGCImageSettingErrorReason
                        do {
                            let dgc_value = try result.get()
                            dgc_reason = .notCurrentSourceTask(result: dgc_value, dgc_error: nil, dgc_source: dgc_source)
                        } catch {
                            dgc_reason = .notCurrentSourceTask(result: nil, dgc_error: dgc_error, dgc_source: dgc_source)
                        }
                        let dgc_error = DGCKingfisherError.imageSettingError(dgc_reason: dgc_reason)
                        completionHandler?(.failure(dgc_error))
                        return
                    }

                    dgc_mutatingSelf.dgc_imageTask = nil
                    dgc_mutatingSelf.taskIdentifier = nil

                    switch result {
                    case .success(let dgc_value):
                        guard self.dgc_needsTransition(dgc_options: dgc_options, cacheType: dgc_value.cacheType) else {
                            dgc_mutatingSelf.placeholder = nil
                            self.base.dgc_image = dgc_value.dgc_image
                            completionHandler?(result)
                            return
                        }

                        self.dgc_makeTransition(dgc_image: dgc_value.dgc_image, transition: dgc_options.transition) {
                            completionHandler?(result)
                        }

                    case .failure:
                        if let dgc_image = dgc_options.onFailureImage {
                            dgc_mutatingSelf.placeholder = nil
                            self.base.dgc_image = dgc_image
                        }
                        completionHandler?(result)
                    }
                }
            }
        )
        dgc_mutatingSelf.dgc_imageTask = dgc_task
        return dgc_task
    }

    // MARK: Cancelling Downloading Task

    /// Cancels the image download task of the image view if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelDownloadTask() {
        dgc_imageTask?.cancel()
    }

    private func dgc_needsTransition(options: DGCKingfisherParsedOptionsInfo, cacheType: DGCCacheType) -> Bool {
        switch options.transition {
        case .none:
            return false
        #if os(macOS)
        case .fade: // Fade is only a placeholder for SwiftUI on macOS.
            return false
        #else
        default:
            if options.forceTransition { return true }
            if cacheType == .none { return true }
            return false
        #endif
        }
    }

    private func dgc_makeTransition(image: KFCrossPlatformImage, transition: DGCImageTransition, done: @escaping () -> Void) {
        #if !os(macOS)
        // Force hiding the indicator without transition first.
        UIView.transition(
            with: self.base,
            duration: 0.0,
            options: [],
            animations: { self.indicator?.stopAnimatingView() },
            completion: { _ in
                var dgc_mutatingSelf = self
                dgc_mutatingSelf.placeholder = nil
                UIView.transition(
                    with: self.base,
                    duration: transition.duration,
                    options: [transition.animationOptions, .allowUserInteraction],
                    animations: { transition.animations?(self.base, image) },
                    completion: { finished in
                        transition.completion?(finished)
                        done()
                    }
                )
            }
        )
        #else
        done()
        #endif
    }
}

// MARK: - Associated Object
private var dgc_taskIdentifierKey: Void?
private var dgc_indicatorKey: Void?
private var dgc_indicatorTypeKey: Void?
private var dgc_placeholderKey: Void?
private var dgc_imageTaskKey: Void?

extension DGCKingfisherWrapper where Base: KFCrossPlatformImageView {

    // MARK: Properties
    public private(set) var taskIdentifier: DGCSource.DGCIdentifier.Value? {
        get {
            let box: DGCBox<DGCSource.DGCIdentifier.Value>? = getAssociatedObject(base, &dgc_taskIdentifierKey)
            return box?.value
        }
        set {
            let box = newValue.map { DGCBox($0) }
            setRetainedAssociatedObject(base, &dgc_taskIdentifierKey, box)
        }
    }

    /// Holds which indicator type is going to be used.
    /// Default is `.none`, means no indicator will be shown while downloading.
    public var indicatorType: DGCIndicatorType {
        get {
            return getAssociatedObject(base, &dgc_indicatorTypeKey) ?? .none
        }
        
        set {
            switch newValue {
            case .none: indicator = nil
            case .activity: indicator = DGCActivityIndicator()
            case .image(let data): indicator = DGCImageIndicator(imageData: data)
            case .custom(let anIndicator): indicator = anIndicator
            }

            setRetainedAssociatedObject(base, &dgc_indicatorTypeKey, newValue)
        }
    }
    
    /// Holds any type that conforms to the protocol `DGCIndicator`.
    /// The protocol `DGCIndicator` has a `view` property that will be shown when loading an image.
    /// It will be `nil` if `indicatorType` is `.none`.
    public private(set) var indicator: DGCIndicator? {
        get {
            let box: DGCBox<DGCIndicator>? = getAssociatedObject(base, &dgc_indicatorKey)
            return box?.value
        }
        
        set {
            // Remove previous
            if let previousIndicator = indicator {
                previousIndicator.view.removeFromSuperview()
            }
            
            // Add new
            if let newIndicator = newValue {
                // Set default indicator layout
                let view = newIndicator.view
                
                base.addSubview(view)
                view.translatesAutoresizingMaskIntoConstraints = false
                view.centerXAnchor.constraint(
                    equalTo: base.centerXAnchor, constant: newIndicator.centerOffset.x).isActive = true
                view.centerYAnchor.constraint(
                    equalTo: base.centerYAnchor, constant: newIndicator.centerOffset.y).isActive = true

                switch newIndicator.sizeStrategy(in: base) {
                case .intrinsicSize:
                    break
                case .full:
                    view.heightAnchor.constraint(equalTo: base.heightAnchor, constant: 0).isActive = true
                    view.widthAnchor.constraint(equalTo: base.widthAnchor, constant: 0).isActive = true
                case .size(let size):
                    view.heightAnchor.constraint(equalToConstant: size.height).isActive = true
                    view.widthAnchor.constraint(equalToConstant: size.width).isActive = true
                }
                
                newIndicator.view.isHidden = true
            }

            // Save in associated object
            // Wrap newValue with DGCBox to workaround an issue that Swift does not recognize
            // and casting protocol for associate object correctly. https://github.com/onevcat/Kingfisher/issues/872
            setRetainedAssociatedObject(base, &dgc_indicatorKey, newValue.map(DGCBox.init))
        }
    }
    
    private var dgc_imageTask: DGCDownloadTask? {
        get { return getAssociatedObject(base, &dgc_imageTaskKey) }
        set { setRetainedAssociatedObject(base, &dgc_imageTaskKey, newValue)}
    }

    /// Represents the `DGCPlaceholder` used for this image view. A `DGCPlaceholder` will be shown in the view while
    /// it is downloading an image.
    public private(set) var placeholder: DGCPlaceholder? {
        get { return getAssociatedObject(base, &dgc_placeholderKey) }
        set {
            if let previousPlaceholder = placeholder {
                previousPlaceholder.remove(from: base)
            }
            
            if let newPlaceholder = newValue {
                newPlaceholder.add(to: base)
            } else {
                base.image = nil
            }
            setRetainedAssociatedObject(base, &dgc_placeholderKey, newValue)
        }
    }
}


extension KFCrossPlatformImageView {
    @objc func shouldPreloadAllAnimation() -> Bool { return true }
}

#endif
