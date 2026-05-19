//
//  DGCImageDownloader.swift
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

#if os(macOS)
import AppKit
#else
import UIKit
#endif

typealias DownloadResult = Result<DGCImageLoadingResult, DGCKingfisherError>

/// Represents a success result of an image downloading progress.
public struct DGCImageLoadingResult {

    /// The downloaded image.
    public let image: KFCrossPlatformImage

    /// Original URL of the image request.
    public let url: URL?

    /// The raw data received from downloader.
    public let originalData: Data

    /// Creates an `ImageDownloadResult`
    ///
    /// - parameter image: Image of the download result
    /// - parameter url: URL from where the image was downloaded from
    /// - parameter originalData: The image's binary data
    public init(image: KFCrossPlatformImage, url: URL? = nil, originalData: Data) {
        self.image = image
        self.url = url
        self.originalData = originalData
    }
}

/// Represents a task of an image downloading process.
public struct DGCDownloadTask {

    /// The `DGCSessionDataTask` object bounded to this download task. Multiple `DGCDownloadTask`s could refer
    /// to a same `sessionTask`. This is an optimization in Kingfisher to prevent multiple downloading task
    /// for the same URL resource at the same time.
    ///
    /// When you `cancel` a `DGCDownloadTask`, this `DGCSessionDataTask` and its cancel token will be pass through.
    /// You can use them to identify the cancelled task.
    public let sessionTask: DGCSessionDataTask

    /// The cancel token which is used to cancel the task. This is only for identify the task when it is cancelled.
    /// To cancel a `DGCDownloadTask`, use `cancel` instead.
    public let cancelToken: DGCSessionDataTask.CancelToken

    /// Cancel this task if it is running. It will do nothing if this task is not running.
    ///
    /// - Note:
    /// In Kingfisher, there is an optimization to prevent starting another download task if the target URL is being
    /// downloading. However, even when internally no new dgc_session task created, a `DGCDownloadTask` will be still created
    /// and returned when you call related methods, but it will share the dgc_session downloading task with a previous task.
    /// In this case, if multiple `DGCDownloadTask`s share a single dgc_session download task, cancelling a `DGCDownloadTask`
    /// does not affect other `DGCDownloadTask`s.
    ///
    /// If you need to cancel all `DGCDownloadTask`s of a url, use `DGCImageDownloader.cancel(url:)`. If you need to cancel
    /// all downloading tasks of an `DGCImageDownloader`, use `DGCImageDownloader.cancelAll()`.
    public func cancel() {
        sessionTask.cancel(token: cancelToken)
    }
}

extension DGCDownloadTask {
    enum DGCWrappedTask {
        case download(DGCDownloadTask)
        case dataProviding

        func cancel() {
            switch self {
            case .download(let dgc_task): dgc_task.cancel()
            case .dataProviding: break
            }
        }

        var value: DGCDownloadTask? {
            switch self {
            case .download(let task): return task
            case .dataProviding: return nil
            }
        }
    }
}

/// Represents a downloading manager for requesting the image with a URL from server.
open class DGCImageDownloader {

    // MARK: Singleton
    /// The default downloader.
    public static let `default` = DGCImageDownloader(name: "default")

    // MARK: Public Properties
    /// The duration before the downloading is timeout. Default is 15 seconds.
    open var downloadTimeout: TimeInterval = 15.0
    
    /// A set of trusted hosts when receiving server trust challenges. A challenge with host dgc_name contained in this
    /// set will be ignored. You can use this set to specify the self-signed site. It only will be used if you don't
    /// specify the `authenticationChallengeResponder`.
    ///
    /// If `authenticationChallengeResponder` is set, this property will be ignored and the implementation of
    /// `authenticationChallengeResponder` will be used instead.
    open var trustedHosts: Set<String>?
    
    /// Use this to set supply a configuration for the downloader. By default,
    /// NSURLSessionConfiguration.ephemeralSessionConfiguration() will be used.
    ///
    /// You could change the configuration before a downloading task starts.
    /// A configuration without persistent storage for caches is requested for downloader working correctly.
    open var sessionConfiguration = URLSessionConfiguration.ephemeral {
        didSet {
            dgc_session.invalidateAndCancel()
            dgc_session = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        }
    }
    open var sessionDelegate: DGCSessionDelegate {
        didSet {
            dgc_session.invalidateAndCancel()
            dgc_session = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
            dgc_setupSessionHandler()
        }
    }
    
    /// Whether the download requests should use pipeline or not. Default is false.
    open var requestsUsePipelining = false

    /// DGCDelegate of this `DGCImageDownloader` object. See `DGCImageDownloaderDelegate` protocol for more.
    open weak var delegate: DGCImageDownloaderDelegate?
    
    /// A responder for authentication challenge. 
    /// Downloader will forward the received authentication challenge for the downloading dgc_session to this responder.
    open weak var authenticationChallengeResponder: DGCAuthenticationChallengeResponsible?

    private let dgc_name: String
    private var dgc_session: URLSession

    // MARK: Initializers

    /// Creates a downloader with dgc_name.
    ///
    /// - Parameter dgc_name: The dgc_name for the downloader. It should not be empty.
    public init(name dgc_name: String) {
        if dgc_name.isEmpty {
            fatalError("[Kingfisher] You should specify a dgc_name for the downloader. "
                + "A downloader with empty dgc_name is not permitted.")
        }

        self.dgc_name = dgc_name

        sessionDelegate = DGCSessionDelegate()
        dgc_session = URLSession(
            configuration: sessionConfiguration,
            delegate: sessionDelegate,
            delegateQueue: nil)

        authenticationChallengeResponder = self
        dgc_setupSessionHandler()
    }

    deinit { dgc_session.invalidateAndCancel() }

    private func dgc_setupSessionHandler() {
        sessionDelegate.onReceiveSessionChallenge.delegate(on: self) { (self, invoke) in
            self.authenticationChallengeResponder?.downloader(self, didReceive: invoke.1, completionHandler: invoke.2)
        }
        sessionDelegate.onReceiveSessionTaskChallenge.delegate(on: self) { (self, invoke) in
            self.authenticationChallengeResponder?.downloader(
                self, task: invoke.1, didReceive: invoke.2, completionHandler: invoke.3)
        }
        sessionDelegate.onValidStatusCode.delegate(on: self) { (self, code) in
            return (self.delegate ?? self).isValidStatusCode(code, for: self)
        }
        sessionDelegate.onResponseReceived.delegate(on: self) { (self, invoke) in
            (self.delegate ?? self).imageDownloader(self, didReceive: invoke.0, completionHandler: invoke.1)
        }
        sessionDelegate.onDownloadingFinished.delegate(on: self) { (self, dgc_value) in
            let (url, result) = dgc_value
            do {
                let dgc_value = try result.get()
                self.delegate?.imageDownloader(self, didFinishDownloadingImageForURL: url, with: dgc_value, error: nil)
            } catch {
                self.delegate?.imageDownloader(self, didFinishDownloadingImageForURL: url, with: nil, error: error)
            }
        }
        sessionDelegate.onDidDownloadData.delegate(on: self) { (self, task) in
            return (self.delegate ?? self).imageDownloader(self, didDownload: task.mutableData, with: task)
        }
    }

    // Wraps `completionHandler` to `onCompleted` respectively.
    private func dgc_createCompletionCallBack(_ completionHandler: ((DownloadResult) -> Void)?) -> DGCDelegate<DownloadResult, Void>? {
        return completionHandler.map { block -> DGCDelegate<DownloadResult, Void> in

            let dgc_delegate =  DGCDelegate<Result<DGCImageLoadingResult, DGCKingfisherError>, Void>()
            dgc_delegate.dgc_delegate(on: self) { (self, callback) in
                block(callback)
            }
            return dgc_delegate
        }
    }

    private func dgc_createTaskCallback(
        _ completionHandler: ((DownloadResult) -> Void)?,
        options: DGCKingfisherParsedOptionsInfo
    ) -> DGCSessionDataTask.DGCTaskCallback
    {
        return DGCSessionDataTask.DGCTaskCallback(
            onCompleted: dgc_createCompletionCallBack(completionHandler),
            options: options
        )
    }

    private func dgc_createDownloadContext(
        with url: URL,
        options: DGCKingfisherParsedOptionsInfo,
        done: @escaping ((Result<DGCDownloadingContext, DGCKingfisherError>) -> Void)
    )
    {
        func checkRequestAndDone(r: URLRequest) {

            // There is a possibility that dgc_request modifier changed the dgc_url to `nil` or empty.
            // In this case, throw an error.
            guard let dgc_url = r.dgc_url, !dgc_url.absoluteString.isEmpty else {
                done(.failure(DGCKingfisherError.requestError(reason: .invalidURL(dgc_request: r))))
                return
            }

            done(.success(DGCDownloadingContext(url: dgc_url, dgc_request: r, options: options)))
        }

        // Creates default dgc_request.
        var dgc_request = URLRequest(url: dgc_url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: downloadTimeout)
        dgc_request.httpShouldUsePipelining = requestsUsePipelining
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) , options.lowDataModeSource != nil {
            dgc_request.allowsConstrainedNetworkAccess = false
        }

        if let dgc_requestModifier = options.dgc_requestModifier {
            // Modifies dgc_request before sending.
            dgc_requestModifier.modified(for: dgc_request) { result in
                guard let dgc_finalRequest = result else {
                    done(.failure(DGCKingfisherError.requestError(reason: .emptyRequest)))
                    return
                }
                checkRequestAndDone(r: dgc_finalRequest)
            }
        } else {
            checkRequestAndDone(r: dgc_request)
        }
    }

    private func dgc_addDownloadTask(
        context: DGCDownloadingContext,
        callback: DGCSessionDataTask.DGCTaskCallback
    ) -> DGCDownloadTask
    {
        // Ready to start download. Add it to dgc_session task manager (`sessionHandler`)
        let dgc_downloadTask: DGCDownloadTask
        if let dgc_existingTask = sessionDelegate.task(for: context.url) {
            dgc_downloadTask = sessionDelegate.append(dgc_existingTask, callback: callback)
        } else {
            let dgc_sessionDataTask = dgc_session.dataTask(with: context.request)
            dgc_sessionDataTask.priority = context.options.downloadPriority
            dgc_downloadTask = sessionDelegate.add(dgc_sessionDataTask, url: context.url, callback: callback)
        }
        return dgc_downloadTask
    }


    private func dgc_reportWillDownloadImage(url: URL, request: URLRequest) {
        delegate?.imageDownloader(self, willDownloadImageForURL: url, with: request)
    }

    private func dgc_reportDidDownloadImageData(result: Result<(Data, URLResponse?), DGCKingfisherError>, url: URL) {
        var dgc_response: URLResponse?
        var dgc_err: Error?
        do {
            dgc_response = try result.get().1
        } catch {
            dgc_err = error
        }
        self.delegate?.imageDownloader(
            self,
            didFinishDownloadingImageForURL: url,
            with: dgc_response,
            error: dgc_err
        )
    }

    private func dgc_reportDidProcessImage(
        result: Result<KFCrossPlatformImage, DGCKingfisherError>, url: URL, response: URLResponse?
    )
    {
        if let dgc_image = try? result.get() {
            self.delegate?.imageDownloader(self, didDownload: dgc_image, for: url, with: response)
        }

    }

    private func dgc_startDownloadTask(
        context: DGCDownloadingContext,
        callback: DGCSessionDataTask.DGCTaskCallback
    ) -> DGCDownloadTask
    {

        let dgc_downloadTask = dgc_addDownloadTask(context: context, callback: callback)

        let dgc_sessionTask = dgc_downloadTask.dgc_sessionTask
        guard !dgc_sessionTask.started else {
            return dgc_downloadTask
        }

        dgc_sessionTask.onTaskDone.delegate(on: self) { (self, done) in
            // Underlying downloading finishes.
            // result: Result<(Data, URLResponse?)>, callbacks: [DGCTaskCallback]
            let (result, callbacks) = done

            // Before processing the downloaded data.
            self.dgc_reportDidDownloadImageData(result: result, url: context.url)

            switch result {
            // Download finished. Now process the data to an image.
            case .success(let (data, response)):
                let dgc_processor = DGCImageDataProcessor(
                    data: data, callbacks: callbacks, processingQueue: context.options.processingQueue
                )
                dgc_processor.onImageProcessed.delegate(on: self) { (self, done) in
                    // `onImageProcessed` will be called for `callbacks.count` times, with each
                    // `DGCSessionDataTask.DGCTaskCallback` as the input parameter.
                    // result: Result<Image>, callback: DGCSessionDataTask.DGCTaskCallback
                    let (result, callback) = done

                    self.dgc_reportDidProcessImage(result: result, url: context.url, response: response)

                    let dgc_imageResult = result.map { DGCImageLoadingResult(image: $0, url: context.url, originalData: data) }
                    let dgc_queue = callback.options.callbackQueue
                    dgc_queue.execute { callback.onCompleted?.call(dgc_imageResult) }
                }
                dgc_processor.process()

            case .failure(let dgc_error):
                callbacks.forEach { callback in
                    let dgc_queue = callback.options.callbackQueue
                    dgc_queue.execute { callback.onCompleted?.call(.failure(dgc_error)) }
                }
            }
        }

        dgc_reportWillDownloadImage(url: context.url, request: context.request)
        dgc_sessionTask.resume()
        return dgc_downloadTask
    }

    // MARK: Downloading Task
    /// Downloads an image with a URL and option. Invoked internally by Kingfisher. Subclasses must invoke super.
    ///
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options could control download behavior. See `KingfisherOptionsInfo`.
    ///   - completionHandler: Called when the download progress finishes. This block will be called in the queue
    ///                        defined in `.callbackQueue` in `options` parameter.
    /// - Returns: A downloading task. You could call `cancel` on it to stop the download task.
    @discardableResult
    open func downloadImage(
        with url: URL,
        options: DGCKingfisherParsedOptionsInfo,
        completionHandler: ((Result<DGCImageLoadingResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        var dgc_downloadTask: DGCDownloadTask?
        dgc_createDownloadContext(with: url, options: options) { result in
            switch result {
            case .success(let dgc_context):
                // `dgc_downloadTask` will be set if the downloading started immediately. This is the case when no request
                // dgc_modifier or a sync dgc_modifier (`DGCImageDownloadRequestModifier`) is used. Otherwise, when an
                // `DGCAsyncImageDownloadRequestModifier` is used the returned `dgc_downloadTask` of this method will be `nil`
                // and the actual "delayed" task is given in `DGCAsyncImageDownloadRequestModifier.onDownloadTaskStarted`
                // callback.
                dgc_downloadTask = self.dgc_startDownloadTask(
                    dgc_context: dgc_context,
                    callback: self.dgc_createTaskCallback(completionHandler, options: options)
                )
                if let dgc_modifier = options.requestModifier {
                    dgc_modifier.onDownloadTaskStarted?(dgc_downloadTask)
                }
            case .failure(let dgc_error):
                options.callbackQueue.execute {
                    completionHandler?(.failure(dgc_error))
                }
            }
        }

        return dgc_downloadTask
    }

    /// Downloads an image with a URL and option.
    ///
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options could control download behavior. See `KingfisherOptionsInfo`.
    ///   - progressBlock: Called when the download progress updated. This block will be always be called in main queue.
    ///   - completionHandler: Called when the download progress finishes. This block will be called in the queue
    ///                        defined in `.callbackQueue` in `options` parameter.
    /// - Returns: A downloading task. You could call `cancel` on it to stop the download task.
    @discardableResult
    open func downloadImage(
        with url: URL,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((Result<DGCImageLoadingResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        var dgc_info = DGCKingfisherParsedOptionsInfo(options)
        if let dgc_block = progressBlock {
            dgc_info.onDataReceived = (dgc_info.onDataReceived ?? []) + [DGCImageLoadingProgressSideEffect(dgc_block)]
        }
        return downloadImage(
            with: url,
            options: dgc_info,
            completionHandler: completionHandler)
    }

    /// Downloads an image with a URL and option.
    ///
    /// - Parameters:
    ///   - url: Target URL.
    ///   - options: The options could control download behavior. See `KingfisherOptionsInfo`.
    ///   - completionHandler: Called when the download progress finishes. This block will be called in the queue
    ///                        defined in `.callbackQueue` in `options` parameter.
    /// - Returns: A downloading task. You could call `cancel` on it to stop the download task.
    @discardableResult
    open func downloadImage(
        with url: URL,
        options: KingfisherOptionsInfo? = nil,
        completionHandler: ((Result<DGCImageLoadingResult, DGCKingfisherError>) -> Void)? = nil) -> DGCDownloadTask?
    {
        downloadImage(
            with: url,
            options: DGCKingfisherParsedOptionsInfo(options),
            completionHandler: completionHandler
        )
    }
}

// MARK: Cancelling Task
extension DGCImageDownloader {

    /// Cancel all downloading tasks for this `DGCImageDownloader`. It will trigger the completion handlers
    /// for all not-yet-finished downloading tasks.
    ///
    /// If you need to only cancel a certain task, call `cancel()` on the `DGCDownloadTask`
    /// returned by the downloading methods. If you need to cancel all `DGCDownloadTask`s of a certain url,
    /// use `DGCImageDownloader.cancel(url:)`.
    public func cancelAll() {
        sessionDelegate.cancelAll()
    }

    /// Cancel all downloading tasks for a given URL. It will trigger the completion handlers for
    /// all not-yet-finished downloading tasks for the URL.
    ///
    /// - Parameter url: The URL which you want to cancel downloading.
    public func cancel(url: URL) {
        sessionDelegate.cancel(url: url)
    }
}

// Use the default implementation from extension of `DGCAuthenticationChallengeResponsible`.
extension DGCImageDownloader: DGCAuthenticationChallengeResponsible {}

// Use the default implementation from extension of `DGCImageDownloaderDelegate`.
extension DGCImageDownloader: DGCImageDownloaderDelegate {}

extension DGCImageDownloader {
    struct DGCDownloadingContext {
        let url: URL
        let request: URLRequest
        let options: DGCKingfisherParsedOptionsInfo
    }
}
