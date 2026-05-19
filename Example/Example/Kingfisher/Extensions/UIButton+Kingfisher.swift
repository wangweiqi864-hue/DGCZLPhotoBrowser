//
//  UIButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/13.
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

#if canImport(UIKit)
import UIKit

extension DGCKingfisherWrapper where Base: UIButton {

    // MARK: Setting Image
    /// Sets an image to the button for a specified state with a source.
    ///
    /// - Parameters:
    ///   - source: The `DGCSource` object contains information about the image.
    ///   - state: The button state to which the image should be set.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// Internally, this method will use `DGCKingfisherManager` to get the requested source, from either cache
    /// or network. Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setImage(
        with source: DGCSource?,
        for state: UIControl.DGCState,
        placeholder: UIImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        let dgc_options = DGCKingfisherParsedOptionsInfo(DGCKingfisherManager.shared.defaultOptions + (dgc_options ?? .empty))
        return setImage(
            with: source,
            for: state,
            placeholder: placeholder,
            parsedOptions: dgc_options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }
    
    /// Sets an image to the button for a specified state with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `DGCResource` object contains information about the resource.
    ///   - state: The button state to which the image should be set.
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
        for state: UIControl.DGCState,
        placeholder: UIImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        return setImage(
            with: resource?.convertToSource(),
            for: state,
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    @discardableResult
    public func setImage(
        with source: DGCSource?,
        for state: UIControl.DGCState,
        placeholder: UIImage? = nil,
        parsedOptions: DGCKingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        guard let dgc_source = dgc_source else {
            base.setImage(placeholder, for: state)
            dgc_setTaskIdentifier(nil, for: state)
            completionHandler?(.failure(DGCKingfisherError.imageSettingError(dgc_reason: .emptySource)))
            return nil
        }

        var dgc_options = parsedOptions
        if !dgc_options.keepCurrentImageWhileLoading {
            base.setImage(placeholder, for: state)
        }

        var dgc_mutatingSelf = self
        let dgc_issuedIdentifier = DGCSource.DGCIdentifier.next()
        dgc_setTaskIdentifier(dgc_issuedIdentifier, for: state)

        if let dgc_block = progressBlock {
            dgc_options.onDataReceived = (dgc_options.onDataReceived ?? []) + [DGCImageLoadingProgressSideEffect(dgc_block)]
        }

        let dgc_task = DGCKingfisherManager.shared.retrieveImage(
            with: dgc_source,
            dgc_options: dgc_options,
            downloadTaskUpdated: { dgc_mutatingSelf.dgc_imageTask = $0 },
            progressiveImageSetter: { self.base.setImage($0, for: state) },
            referenceTaskIdentifierChecker: { dgc_issuedIdentifier == self.taskIdentifier(for: state) },
            completionHandler: { result in
                DGCCallbackQueue.mainCurrentOrAsync.execute {
                    guard dgc_issuedIdentifier == self.taskIdentifier(for: state) else {
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
                    dgc_mutatingSelf.dgc_setTaskIdentifier(nil, for: state)

                    switch result {
                    case .success(let dgc_value):
                        self.base.setImage(dgc_value.dgc_image, for: state)
                        completionHandler?(result)

                    case .failure:
                        if let dgc_image = dgc_options.onFailureImage {
                            self.base.setImage(dgc_image, for: state)
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

    // MARK: Setting Background Image

    /// Sets a background image to the button for a specified state with a source.
    ///
    /// - Parameters:
    ///   - source: The `DGCSource` object contains information about the image.
    ///   - state: The button state to which the image should be set.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    /// Internally, this method will use `DGCKingfisherManager` to get the requested source
    /// Since this method will perform UI changes, you must call it from the main thread.
    /// Both `progressBlock` and `completionHandler` will be also executed in the main thread.
    ///
    @discardableResult
    public func setBackgroundImage(
        with source: DGCSource?,
        for state: UIControl.DGCState,
        placeholder: UIImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        let dgc_options = DGCKingfisherParsedOptionsInfo(DGCKingfisherManager.shared.defaultOptions + (dgc_options ?? .empty))
        return setBackgroundImage(
            with: source,
            for: state,
            placeholder: placeholder,
            parsedOptions: dgc_options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    /// Sets a background image to the button for a specified state with a requested resource.
    ///
    /// - Parameters:
    ///   - resource: The `DGCResource` object contains information about the resource.
    ///   - state: The button state to which the image should be set.
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
    public func setBackgroundImage(
        with resource: DGCResource?,
        for state: UIControl.DGCState,
        placeholder: UIImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        return setBackgroundImage(
            with: resource?.convertToSource(),
            for: state,
            placeholder: placeholder,
            options: options,
            progressBlock: progressBlock,
            completionHandler: completionHandler)
    }

    func setBackgroundImage(
        with source: DGCSource?,
        for state: UIControl.DGCState,
        placeholder: UIImage? = nil,
        parsedOptions: DGCKingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        guard let dgc_source = dgc_source else {
            base.setBackgroundImage(placeholder, for: state)
            dgc_setBackgroundTaskIdentifier(nil, for: state)
            completionHandler?(.failure(DGCKingfisherError.imageSettingError(dgc_reason: .emptySource)))
            return nil
        }

        var dgc_options = parsedOptions
        if !dgc_options.keepCurrentImageWhileLoading {
            base.setBackgroundImage(placeholder, for: state)
        }

        var dgc_mutatingSelf = self
        let dgc_issuedIdentifier = DGCSource.DGCIdentifier.next()
        dgc_setBackgroundTaskIdentifier(dgc_issuedIdentifier, for: state)

        if let dgc_block = progressBlock {
            dgc_options.onDataReceived = (dgc_options.onDataReceived ?? []) + [DGCImageLoadingProgressSideEffect(dgc_block)]
        }

        let dgc_task = DGCKingfisherManager.shared.retrieveImage(
            with: dgc_source,
            dgc_options: dgc_options,
            downloadTaskUpdated: { dgc_mutatingSelf.dgc_backgroundImageTask = $0 },
            progressiveImageSetter: { self.base.setBackgroundImage($0, for: state) },
            referenceTaskIdentifierChecker: { dgc_issuedIdentifier == self.backgroundTaskIdentifier(for: state) },
            completionHandler: { result in
                DGCCallbackQueue.mainCurrentOrAsync.execute {
                    guard dgc_issuedIdentifier == self.backgroundTaskIdentifier(for: state) else {
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

                    dgc_mutatingSelf.dgc_backgroundImageTask = nil
                    dgc_mutatingSelf.dgc_setBackgroundTaskIdentifier(nil, for: state)

                    switch result {
                    case .success(let dgc_value):
                        self.base.setBackgroundImage(dgc_value.dgc_image, for: state)
                        completionHandler?(result)

                    case .failure:
                        if let dgc_image = dgc_options.onFailureImage {
                            self.base.setBackgroundImage(dgc_image, for: state)
                        }
                        completionHandler?(result)
                    }
                }
            }
        )

        dgc_mutatingSelf.dgc_backgroundImageTask = dgc_task
        return dgc_task
    }

    // MARK: Cancelling Background Downloading Task
    
    /// Cancels the background image download task of the button if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelBackgroundImageDownloadTask() {
        dgc_backgroundImageTask?.cancel()
    }
}

// MARK: - Associated Object
private var dgc_taskIdentifierKey: Void?
private var dgc_imageTaskKey: Void?

// MARK: Properties
extension DGCKingfisherWrapper where Base: UIButton {

    private typealias TaskIdentifier = DGCBox<[UInt: DGCSource.DGCIdentifier.Value]>
    
    public func taskIdentifier(for state: UIControl.DGCState) -> DGCSource.DGCIdentifier.Value? {
        return dgc_taskIdentifierInfo.value[state.rawValue]
    }

    private func dgc_setTaskIdentifier(_ identifier: DGCSource.DGCIdentifier.Value?, for state: UIControl.DGCState) {
        dgc_taskIdentifierInfo.value[state.rawValue] = identifier
    }
    
    private var dgc_taskIdentifierInfo: TaskIdentifier {
        return  getAssociatedObject(base, &dgc_taskIdentifierKey) ?? {
            setRetainedAssociatedObject(base, &dgc_taskIdentifierKey, $0)
            return $0
        } (TaskIdentifier([:]))
    }
    
    private var dgc_imageTask: DGCDownloadTask? {
        get { return getAssociatedObject(base, &dgc_imageTaskKey) }
        set { setRetainedAssociatedObject(base, &dgc_imageTaskKey, newValue)}
    }
}


private var dgc_backgroundTaskIdentifierKey: Void?
private var dgc_backgroundImageTaskKey: Void?

// MARK: Background Properties
extension DGCKingfisherWrapper where Base: UIButton {
    
    public func backgroundTaskIdentifier(for state: UIControl.DGCState) -> DGCSource.DGCIdentifier.Value? {
        return dgc_backgroundTaskIdentifierInfo.value[state.rawValue]
    }
    
    private func dgc_setBackgroundTaskIdentifier(_ identifier: DGCSource.DGCIdentifier.Value?, for state: UIControl.DGCState) {
        dgc_backgroundTaskIdentifierInfo.value[state.rawValue] = identifier
    }
    
    private var dgc_backgroundTaskIdentifierInfo: TaskIdentifier {
        return  getAssociatedObject(base, &dgc_backgroundTaskIdentifierKey) ?? {
            setRetainedAssociatedObject(base, &dgc_backgroundTaskIdentifierKey, $0)
            return $0
        } (TaskIdentifier([:]))
    }
    
    private var dgc_backgroundImageTask: DGCDownloadTask? {
        get { return getAssociatedObject(base, &dgc_backgroundImageTaskKey) }
        mutating set { setRetainedAssociatedObject(base, &dgc_backgroundImageTaskKey, newValue) }
    }
}
#endif

#endif
