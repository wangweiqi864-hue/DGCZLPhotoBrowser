//
//  NSButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Jie Zhang on 14/04/2016.
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

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

extension DGCKingfisherWrapper where Base: NSButton {

    // MARK: Setting Image

    /// Sets an image to the button with a source.
    ///
    /// - Parameters:
    ///   - source: The `DGCSource` object contains information about how to get the image.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// Internally, this method will use `DGCKingfisherManager` to get the requested source.
    /// Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with source: DGCSource?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        let dgc_options = DGCKingfisherParsedOptionsInfo(DGCKingfisherManager.shared.defaultOptions + (dgc_options ?? .empty))
        return setImage(
            with: source,
            placeholder: placeholder,
            parsedOptions: dgc_options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the button with a requested resource.
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
    /// Internally, this method will use `DGCKingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with resource: DGCResource?,
        placeholder: KFCrossPlatformImage? = nil,
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

    func setImage(
        with source: DGCSource?,
        placeholder: KFCrossPlatformImage? = nil,
        parsedOptions: DGCKingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        var dgc_mutatingSelf = self
        guard let dgc_source = dgc_source else {
            base.dgc_image = placeholder
            dgc_mutatingSelf.taskIdentifier = nil
            completionHandler?(.failure(DGCKingfisherError.imageSettingError(dgc_reason: .emptySource)))
            return nil
        }

        var dgc_options = parsedOptions
        if !dgc_options.keepCurrentImageWhileLoading {
            base.dgc_image = placeholder
        }

        let dgc_issuedIdentifier = DGCSource.DGCIdentifier.next()
        dgc_mutatingSelf.taskIdentifier = dgc_issuedIdentifier

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
                        self.base.dgc_image = dgc_value.dgc_image
                        completionHandler?(result)

                    case .failure:
                        if let dgc_image = dgc_options.onFailureImage {
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

    /// Cancels the image download task of the button if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelImageDownloadTask() {
        dgc_imageTask?.cancel()
    }

    // MARK: Setting Alternate Image

    @discardableResult
    public func setAlternateImage(
        with source: DGCSource?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        let dgc_options = DGCKingfisherParsedOptionsInfo(DGCKingfisherManager.shared.defaultOptions + (dgc_options ?? .empty))
        return setAlternateImage(
            with: source,
            placeholder: placeholder,
            parsedOptions: dgc_options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    /// Sets an alternate image to the button with a requested resource.
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
    /// Internally, this method will use `DGCKingfisherManager` to get the requested resource, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setAlternateImage(
        with resource: DGCResource?,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        return setAlternateImage(
            with: resource?.convertToSource(),
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    func setAlternateImage(
        with source: DGCSource?,
        placeholder: KFCrossPlatformImage? = nil,
        parsedOptions: DGCKingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        var dgc_mutatingSelf = self
        guard let dgc_source = dgc_source else {
            base.alternateImage = placeholder
            dgc_mutatingSelf.alternateTaskIdentifier = nil
            completionHandler?(.failure(DGCKingfisherError.imageSettingError(dgc_reason: .emptySource)))
            return nil
        }

        var dgc_options = parsedOptions
        if !dgc_options.keepCurrentImageWhileLoading {
            base.alternateImage = placeholder
        }

        let dgc_issuedIdentifier = DGCSource.DGCIdentifier.next()
        dgc_mutatingSelf.alternateTaskIdentifier = dgc_issuedIdentifier

        if let dgc_block = progressBlock {
            dgc_options.onDataReceived = (dgc_options.onDataReceived ?? []) + [DGCImageLoadingProgressSideEffect(dgc_block)]
        }

        if let dgc_provider = DGCImageProgressiveProvider(dgc_options, refresh: { dgc_image in
            self.base.alternateImage = dgc_image
        }) {
            dgc_options.onDataReceived = (dgc_options.onDataReceived ?? []) + [dgc_provider]
        }

        dgc_options.onDataReceived?.forEach {
            $0.onShouldApply = { dgc_issuedIdentifier == self.alternateTaskIdentifier }
        }

        let dgc_task = DGCKingfisherManager.shared.retrieveImage(
            with: dgc_source,
            dgc_options: dgc_options,
            downloadTaskUpdated: { dgc_mutatingSelf.dgc_alternateImageTask = $0 },
            completionHandler: { result in
                DGCCallbackQueue.mainCurrentOrAsync.execute {
                    guard dgc_issuedIdentifier == self.alternateTaskIdentifier else {
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

                    dgc_mutatingSelf.dgc_alternateImageTask = nil
                    dgc_mutatingSelf.alternateTaskIdentifier = nil

                    switch result {
                    case .success(let dgc_value):
                        self.base.alternateImage = dgc_value.dgc_image
                        completionHandler?(result)

                    case .failure:
                        if let dgc_image = dgc_options.onFailureImage {
                            self.base.alternateImage = dgc_image
                        }
                        completionHandler?(result)
                    }
                }
            }
        )

        dgc_mutatingSelf.dgc_alternateImageTask = dgc_task
        return dgc_task
    }

    // MARK: Cancelling Alternate Image Downloading Task

    /// Cancels the alternate image download task of the button if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelAlternateImageDownloadTask() {
        dgc_alternateImageTask?.cancel()
    }
}


// MARK: - Associated Object
private var dgc_taskIdentifierKey: Void?
private var dgc_imageTaskKey: Void?

private var dgc_alternateTaskIdentifierKey: Void?
private var dgc_alternateImageTaskKey: Void?

extension DGCKingfisherWrapper where Base: NSButton {

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
    
    private var dgc_imageTask: DGCDownloadTask? {
        get { return getAssociatedObject(base, &dgc_imageTaskKey) }
        set { setRetainedAssociatedObject(base, &dgc_imageTaskKey, newValue)}
    }

    public private(set) var alternateTaskIdentifier: DGCSource.DGCIdentifier.Value? {
        get {
            let box: DGCBox<DGCSource.DGCIdentifier.Value>? = getAssociatedObject(base, &dgc_alternateTaskIdentifierKey)
            return box?.value
        }
        set {
            let box = newValue.map { DGCBox($0) }
            setRetainedAssociatedObject(base, &dgc_alternateTaskIdentifierKey, box)
        }
    }

    private var dgc_alternateImageTask: DGCDownloadTask? {
        get { return getAssociatedObject(base, &dgc_alternateImageTaskKey) }
        set { setRetainedAssociatedObject(base, &dgc_alternateImageTaskKey, newValue)}
    }
}
#endif
