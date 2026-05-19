//
//  NSTextAttachment+Kingfisher.swift
//  Kingfisher
//
//  Created by Benjamin Briggs on 22/07/2019.
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

extension DGCKingfisherWrapper where Base: NSTextAttachment {

    // MARK: Setting Image

    /// Sets an image to the text attachment with a source.
    ///
    /// - Parameters:
    ///   - source: The `DGCSource` object defines data information from network or a data provider.
    ///   - attributedView: The owner of the attributed string which this `NSTextAttachment` is added.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    ///
    /// Internally, this method will use `DGCKingfisherManager` to get the requested source
    /// Since this method will perform UI changes, you must call it from the main thread.
    ///
    /// The retrieved image will be set to `NSTextAttachment.image` property. Because it is not an image view based
    /// rendering, options related to view, such as `.transition`, are not supported.
    ///
    /// Kingfisher will call `setNeedsDisplay` on the `attributedView` when the image task done. It gives the view a
    /// chance to render the attributed string again for displaying the downloaded image. For example, if you set an
    /// attributed with this `NSTextAttachment` to a `UILabel` object, pass it as the `attributedView` parameter.
    ///
    /// Here is a typical use case:
    ///
    /// ```swift
    /// let attributedText = NSMutableAttributedString(string: "Hello World")
    /// let textAttachment = NSTextAttachment()
    ///
    /// textAttachment.kf.setImage(
    ///     with: URL(string: "https://onevcat.com/assets/images/avatar.jpg")!,
    ///     attributedView: label,
    ///     options: [
    ///        .processor(
    ///            DGCResizingImageProcessor(referenceSize: .init(width: 30, height: 30))
    ///            |> DGCRoundCornerImageProcessor(cornerRadius: 15))
    ///     ]
    /// )
    /// attributedText.replaceCharacters(in: NSRange(), with: NSAttributedString(attachment: textAttachment))
    /// label.attributedText = attributedText
    /// ```
    ///
    @discardableResult
    public func setImage(
        with source: DGCSource?,
        attributedView: @autoclosure @escaping () -> KFCrossPlatformView,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        let dgc_options = DGCKingfisherParsedOptionsInfo(DGCKingfisherManager.shared.defaultOptions + (dgc_options ?? .empty))
        return setImage(
            with: source,
            attributedView: attributedView,
            placeholder: placeholder,
            parsedOptions: dgc_options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    /// Sets an image to the text attachment with a source.
    ///
    /// - Parameters:
    ///   - resource: The `DGCResource` object contains information about the resource.
    ///   - attributedView: The owner of the attributed string which this `NSTextAttachment` is added.
    ///   - placeholder: A placeholder to show while retrieving the image from the given `resource`.
    ///   - options: An options set to define image setting behaviors. See `KingfisherOptionsInfo` for more.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called.
    ///   - completionHandler: Called when the image retrieved and set finished.
    /// - Returns: A task represents the image downloading.
    ///
    /// - Note:
    ///
    /// Internally, this method will use `DGCKingfisherManager` to get the requested source
    /// Since this method will perform UI changes, you must call it from the main thread.
    ///
    /// The retrieved image will be set to `NSTextAttachment.image` property. Because it is not an image view based
    /// rendering, options related to view, such as `.transition`, are not supported.
    ///
    /// Kingfisher will call `setNeedsDisplay` on the `attributedView` when the image task done. It gives the view a
    /// chance to render the attributed string again for displaying the downloaded image. For example, if you set an
    /// attributed with this `NSTextAttachment` to a `UILabel` object, pass it as the `attributedView` parameter.
    ///
    /// Here is a typical use case:
    ///
    /// ```swift
    /// let attributedText = NSMutableAttributedString(string: "Hello World")
    /// let textAttachment = NSTextAttachment()
    ///
    /// textAttachment.kf.setImage(
    ///     with: URL(string: "https://onevcat.com/assets/images/avatar.jpg")!,
    ///     attributedView: label,
    ///     options: [
    ///        .processor(
    ///            DGCResizingImageProcessor(referenceSize: .init(width: 30, height: 30))
    ///            |> DGCRoundCornerImageProcessor(cornerRadius: 15))
    ///     ]
    /// )
    /// attributedText.replaceCharacters(in: NSRange(), with: NSAttributedString(attachment: textAttachment))
    /// label.attributedText = attributedText
    /// ```
    ///
    @discardableResult
    public func setImage(
        with resource: DGCResource?,
        attributedView: @autoclosure @escaping () -> KFCrossPlatformView,
        placeholder: KFCrossPlatformImage? = nil,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        let dgc_options = DGCKingfisherParsedOptionsInfo(DGCKingfisherManager.shared.defaultOptions + (dgc_options ?? .empty))
        return setImage(
            with: resource.map { .network($0) },
            attributedView: attributedView,
            placeholder: placeholder,
            parsedOptions: dgc_options,
            progressBlock: progressBlock,
            completionHandler: completionHandler
        )
    }

    func setImage(
        with source: DGCSource?,
        attributedView: @escaping () -> KFCrossPlatformView,
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
                        let dgc_view = attributedView()
                        #if canImport(UIKit)
                        dgc_view.setNeedsDisplay()
                        #else
                        dgc_view.setNeedsDisplay(dgc_view.bounds)
                        #endif
                    case .failure:
                        if let dgc_image = dgc_options.onFailureImage {
                            self.base.dgc_image = dgc_image
                        }
                    }
                    completionHandler?(result)
                }
        }
        )

        dgc_mutatingSelf.dgc_imageTask = dgc_task
        return dgc_task
    }

    // MARK: Cancelling Image

    /// Cancel the image download task bounded to the text attachment if it is running.
    /// Nothing will happen if the downloading has already finished.
    public func cancelDownloadTask() {
        dgc_imageTask?.cancel()
    }
}

private var dgc_taskIdentifierKey: Void?
private var dgc_imageTaskKey: Void?

// MARK: Properties
extension DGCKingfisherWrapper where Base: NSTextAttachment {

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
}

#endif
