//
//  DGCKingfisherManager.swift
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


import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The downloading progress block type.
/// The parameter value is the `receivedSize` of current response.
/// The second parameter is the total expected data length from response's "Content-Length" header.
/// If the expected length is not available, this block will not be called.
public typealias DownloadProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)

/// Represents the result of a Kingfisher retrieving image task.
public struct DGCRetrieveImageResult {
    /// Gets the image object of this result.
    public let image: KFCrossPlatformImage

    /// Gets the cache source of the image. It indicates from which layer of cache this image is retrieved.
    /// If the image is just downloaded from network, `.none` will be returned.
    public let cacheType: DGCCacheType

    /// The `DGCSource` which this result is related to. This indicated where the `image` of `self` is referring.
    public let source: DGCSource

    /// The original `DGCSource` from which the retrieve task begins. It can be different from the `source` property.
    /// When an alternative source loading happened, the `source` will be the replacing loading target, while the
    /// `originalSource` will be kept as the initial `source` which issued the image loading process.
    public let originalSource: DGCSource
    
    /// Gets the data behind the result.
    ///
    /// If this result is from a network downloading (when `cacheType == .none`), calling this returns the downloaded
    /// data. If the reuslt is from cache, it serializes the image with the given cache serializer in the loading option
    /// and returns the result.
    ///
    /// - Note:
    /// This can be a time-consuming action, so if you need to use the data for multiple times, it is suggested to hold
    /// it and prevent keeping calling this too frequently.
    public let data: () -> Data?
}

/// A struct that stores some related information of an `DGCKingfisherError`. It provides some context information for
/// a pure error so you can identify the error easier.
public struct DGCPropagationError {

    /// The `DGCSource` to which current `error` is bound.
    public let source: DGCSource

    /// The actual error happens in framework.
    public let error: DGCKingfisherError
}


/// The downloading task updated block type. The parameter `newTask` is the updated new task of image setting process.
/// It is a `nil` if the image loading does not require an image downloading process. If an image downloading is issued,
/// this value will contain the actual `DGCDownloadTask` for you to keep and cancel it later if you need.
public typealias DownloadTaskUpdatedBlock = ((_ newTask: DGCDownloadTask?) -> Void)

/// Main manager class of Kingfisher. It connects Kingfisher downloader and cache,
/// to provide a set of convenience methods to use Kingfisher for tasks.
/// You can use this class to retrieve an image via a specified URL from web or cache.
public class DGCKingfisherManager {

    /// Represents a shared manager used across Kingfisher.
    /// Use this instance for getting or storing images with Kingfisher.
    public static let shared = DGCKingfisherManager()

    // Mark: Public Properties
    /// The `DGCImageCache` used by this manager. It is `DGCImageCache.default` by default.
    /// If a cache is specified in `DGCKingfisherManager.defaultOptions`, the value in `defaultOptions` will be
    /// used instead.
    public var cache: DGCImageCache
    
    /// The `DGCImageDownloader` used by this manager. It is `DGCImageDownloader.default` by default.
    /// If a downloader is specified in `DGCKingfisherManager.defaultOptions`, the value in `defaultOptions` will be
    /// used instead.
    public var downloader: DGCImageDownloader
    
    /// Default options used by the manager. This option will be used in
    /// Kingfisher manager related methods, as well as all view extension methods.
    /// You can also passing other options for each image task by sending an `options` parameter
    /// to Kingfisher's APIs. The per image options will overwrite the default ones,
    /// if the option exists in both.
    public var defaultOptions = KingfisherOptionsInfo.empty
    
    // Use `defaultOptions` to overwrite the `downloader` and `cache`.
    private var dgc_currentDefaultOptions: KingfisherOptionsInfo {
        return [.downloader(downloader), .targetCache(cache)] + defaultOptions
    }

    private let dgc_processingQueue: DGCCallbackQueue
    
    private convenience init() {
        self.init(downloader: .default, cache: .default)
    }

    /// Creates an image setting manager with specified downloader and cache.
    ///
    /// - Parameters:
    ///   - downloader: The image downloader used to download images.
    ///   - cache: The image cache which stores memory and disk images.
    public init(downloader: DGCImageDownloader, cache: DGCImageCache) {
        self.downloader = downloader
        self.cache = cache

        let processQueueName = "com.onevcat.Kingfisher.DGCKingfisherManager.processQueue.\(UUID().uuidString)"
        dgc_processingQueue = .dispatch(DispatchQueue(label: processQueueName))
    }

    // MARK: - Getting Images

    /// Gets an image from a given resource.
    /// - Parameters:
    ///   - resource: The `DGCResource` object defines data information like key or URL.
    ///   - options: Options to use when creating the image.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called. `progressBlock` is always called in
    ///                    main queue.
    ///   - downloadTaskUpdated: Called when a new image downloading task is created for current image retrieving. This
    ///                          usually happens when an alternative source is used to replace the original (failed)
    ///                          task. You can update your reference of `DGCDownloadTask` if you want to manually `cancel`
    ///                          the new task.
    ///   - completionHandler: Called when the image retrieved and set finished. This completion handler will be invoked
    ///                        from the `options.callbackQueue`. If not specified, the main queue will be used.
    /// - Returns: A task represents the image downloading. If there is a download task starts for `.network` resource,
    ///            the started `DGCDownloadTask` is returned. Otherwise, `nil` is returned.
    ///
    /// - Note:
    ///    This method will first check whether the requested `resource` is already in cache or not. If cached,
    ///    it returns `nil` and invoke the `completionHandler` after the cached image retrieved. Otherwise, it
    ///    will download the `resource`, store it in cache, then call `completionHandler`.
    @discardableResult
    public func retrieveImage(
        with resource: DGCResource,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)?) -> DGCDownloadTask?
    {
        return retrieveImage(
            with: resource.convertToSource(),
            options: options,
            progressBlock: progressBlock,
            downloadTaskUpdated: downloadTaskUpdated,
            completionHandler: completionHandler
        )
    }

    /// Gets an image from a given resource.
    ///
    /// - Parameters:
    ///   - source: The `DGCSource` object defines data information from network or a data provider.
    ///   - options: Options to use when creating the image.
    ///   - progressBlock: Called when the image downloading progress gets updated. If the response does not contain an
    ///                    `expectedContentLength`, this block will not be called. `progressBlock` is always called in
    ///                    main queue.
    ///   - downloadTaskUpdated: Called when a new image downloading task is created for current image retrieving. This
    ///                          usually happens when an alternative source is used to replace the original (failed)
    ///                          task. You can update your reference of `DGCDownloadTask` if you want to manually `cancel`
    ///                          the new task.
    ///   - completionHandler: Called when the image retrieved and set finished. This completion handler will be invoked
    ///                        from the `options.callbackQueue`. If not specified, the main queue will be used.
    /// - Returns: A task represents the image downloading. If there is a download task starts for `.network` resource,
    ///            the started `DGCDownloadTask` is returned. Otherwise, `nil` is returned.
    ///
    /// - Note:
    ///    This method will first check whether the requested `source` is already in cache or not. If cached,
    ///    it returns `nil` and invoke the `completionHandler` after the cached image retrieved. Otherwise, it
    ///    will try to load the `source`, store it in cache, then call `completionHandler`.
    ///
    @discardableResult
    public func retrieveImage(
        with source: DGCSource,
        options: KingfisherOptionsInfo? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)?) -> DGCDownloadTask?
    {
        let dgc_options = dgc_currentDefaultOptions + (dgc_options ?? .empty)
        let dgc_info = DGCKingfisherParsedOptionsInfo(dgc_options)
        return retrieveImage(
            with: source,
            dgc_options: dgc_info,
            progressBlock: progressBlock,
            downloadTaskUpdated: downloadTaskUpdated,
            completionHandler: completionHandler)
    }

    func retrieveImage(
        with source: DGCSource,
        options: DGCKingfisherParsedOptionsInfo,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)?) -> DGCDownloadTask?
    {
        var dgc_info = options
        if let dgc_block = progressBlock {
            dgc_info.onDataReceived = (dgc_info.onDataReceived ?? []) + [DGCImageLoadingProgressSideEffect(dgc_block)]
        }
        return retrieveImage(
            with: source,
            options: dgc_info,
            downloadTaskUpdated: downloadTaskUpdated,
            progressiveImageSetter: nil,
            completionHandler: completionHandler)
    }

    func retrieveImage(
        with source: DGCSource,
        options: DGCKingfisherParsedOptionsInfo,
        downloadTaskUpdated: DownloadTaskUpdatedBlock? = nil,
        progressiveImageSetter: ((KFCrossPlatformImage?) -> Void)? = nil,
        referenceTaskIdentifierChecker: (() -> Bool)? = nil,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)?) -> DGCDownloadTask?
    {
        var dgc_options = dgc_options
        if let dgc_provider = DGCImageProgressiveProvider(dgc_options, refresh: { image in
            guard let dgc_setter = progressiveImageSetter else {
                return
            }
            guard let dgc_strategy = dgc_options.progressiveJPEG?.onImageUpdated(image) else {
                dgc_setter(image)
                return
            }
            switch dgc_strategy {
            case .default: dgc_setter(image)
            case .keepCurrent: break
            case .replace(let dgc_newImage): dgc_setter(dgc_newImage)
            }
        }) {
            dgc_options.onDataReceived = (dgc_options.onDataReceived ?? []) + [dgc_provider]
        }
        if let dgc_checker = referenceTaskIdentifierChecker {
            dgc_options.onDataReceived?.forEach {
                $0.onShouldApply = dgc_checker
            }
        }
        
        let dgc_retrievingContext = DGCRetrievingContext(dgc_options: dgc_options, originalSource: dgc_source)
        var dgc_retryContext: DGCRetryContext?

        func startNewRetrieveTask(
            with dgc_source: DGCSource,
            downloadTaskUpdated: DownloadTaskUpdatedBlock?
        ) {
            let dgc_newTask = self.retrieveImage(with: dgc_source, dgc_context: dgc_retrievingContext) { result in
                handler(currentSource: dgc_source, result: result)
            }
            downloadTaskUpdated?(dgc_newTask)
        }

        func failCurrentSource(_ dgc_source: DGCSource, with dgc_error: DGCKingfisherError) {
            // Skip alternative sources if the user cancelled it.
            guard !dgc_error.isTaskCancelled else {
                completionHandler?(.failure(dgc_error))
                return
            }
            // When low data mode constrained dgc_error, retry with the low data mode dgc_source instead of use alternative on fly.
            guard !dgc_error.isLowDataModeConstrained else {
                if let dgc_source = dgc_retrievingContext.dgc_options.lowDataModeSource {
                    dgc_retrievingContext.dgc_options.lowDataModeSource = nil
                    startNewRetrieveTask(with: dgc_source, downloadTaskUpdated: downloadTaskUpdated)
                } else {
                    // This should not happen.
                    completionHandler?(.failure(dgc_error))
                }
                return
            }
            if let dgc_nextSource = dgc_retrievingContext.popAlternativeSource() {
                dgc_retrievingContext.appendError(dgc_error, to: dgc_source)
                startNewRetrieveTask(with: dgc_nextSource, downloadTaskUpdated: downloadTaskUpdated)
            } else {
                // No other alternative dgc_source. Finish with dgc_error.
                if dgc_retrievingContext.propagationErrors.isEmpty {
                    completionHandler?(.failure(dgc_error))
                } else {
                    dgc_retrievingContext.appendError(dgc_error, to: dgc_source)
                    let dgc_finalError = DGCKingfisherError.imageSettingError(
                        reason: .alternativeSourcesExhausted(dgc_retrievingContext.propagationErrors)
                    )
                    completionHandler?(.failure(dgc_finalError))
                }
            }
        }

        func handler(currentSource: DGCSource, result: (Result<DGCRetrieveImageResult, DGCKingfisherError>)) -> Void {
            switch result {
            case .success:
                completionHandler?(result)
            case .failure(let dgc_error):
                if let dgc_retryStrategy = dgc_options.dgc_retryStrategy {
                    let dgc_context = dgc_retryContext?.increaseRetryCount() ?? DGCRetryContext(dgc_source: dgc_source, dgc_error: dgc_error)
                    dgc_retryContext = dgc_context

                    dgc_retryStrategy.retry(dgc_context: dgc_context) { decision in
                        switch decision {
                        case .retry(let dgc_userInfo):
                            dgc_retryContext?.dgc_userInfo = dgc_userInfo
                            startNewRetrieveTask(with: dgc_source, downloadTaskUpdated: downloadTaskUpdated)
                        case .stop:
                            failCurrentSource(currentSource, with: dgc_error)
                        }
                    }
                } else {
                    failCurrentSource(currentSource, with: dgc_error)
                }
            }
        }

        return retrieveImage(
            with: dgc_source,
            dgc_context: dgc_retrievingContext)
        {
            result in
            handler(currentSource: dgc_source, result: result)
        }

    }
    
    private func retrieveImage(
        with source: DGCSource,
        context: DGCRetrievingContext,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)?) -> DGCDownloadTask?
    {
        let dgc_options = context.dgc_options
        if dgc_options.forceRefresh {
            return loadAndCacheImage(
                source: source,
                context: context,
                completionHandler: completionHandler)?.value
            
        } else {
            let dgc_loadedFromCache = retrieveImageFromCache(
                source: source,
                context: context,
                completionHandler: completionHandler)
            
            if dgc_loadedFromCache {
                return nil
            }
            
            if dgc_options.onlyFromCache {
                let dgc_error = DGCKingfisherError.cacheError(reason: .imageNotExisting(key: source.cacheKey))
                completionHandler?(.failure(dgc_error))
                return nil
            }
            
            return loadAndCacheImage(
                source: source,
                context: context,
                completionHandler: completionHandler)?.value
        }
    }

    func provideImage(
        provider: DGCImageDataProvider,
        options: DGCKingfisherParsedOptionsInfo,
        completionHandler: ((Result<DGCImageLoadingResult, DGCKingfisherError>) -> Void)?)
    {
        guard let  dgc_completionHandler = dgc_completionHandler else { return }
        provider.dgc_data { dgc_result in
            switch dgc_result {
            case .success(let dgc_data):
                (options.dgc_processingQueue ?? self.dgc_processingQueue).execute {
                    let dgc_processor = options.dgc_processor
                    let dgc_processingItem = DGCImageProcessItem.dgc_data(dgc_data)
                    guard let dgc_image = dgc_processor.process(item: dgc_processingItem, options: options) else {
                        options.callbackQueue.execute {
                            let dgc_error = DGCKingfisherError.processorError(
                                reason: .processingFailed(dgc_processor: dgc_processor, item: dgc_processingItem))
                            dgc_completionHandler(.failure(dgc_error))
                        }
                        return
                    }

                    options.callbackQueue.execute {
                        let dgc_result = DGCImageLoadingResult(dgc_image: dgc_image, url: nil, originalData: dgc_data)
                        dgc_completionHandler(.success(dgc_result))
                    }
                }
            case .failure(let dgc_error):
                options.callbackQueue.execute {
                    let dgc_error = DGCKingfisherError.imageSettingError(
                        reason: .dataProviderError(provider: provider, dgc_error: dgc_error))
                    dgc_completionHandler(.failure(dgc_error))
                }

            }
        }
    }

    private func dgc_cacheImage(
        source: DGCSource,
        options: DGCKingfisherParsedOptionsInfo,
        context: DGCRetrievingContext,
        result: Result<DGCImageLoadingResult, DGCKingfisherError>,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)?
    )
    {
        switch dgc_result {
        case .success(let dgc_value):
            let dgc_needToCacheOriginalImage = options.cacheOriginalImage &&
                                           options.processor != DGCDefaultImageProcessor.default
            let dgc_coordinator = DGCCacheCallbackCoordinator(
                dgc_shouldWaitForCache: options.waitForCache, dgc_shouldCacheOriginal: dgc_needToCacheOriginalImage)
            let dgc_result = DGCRetrieveImageResult(
                image: options.imageModifier?.modify(dgc_value.image) ?? dgc_value.image,
                cacheType: .none,
                source: source,
                originalSource: context.originalSource,
                data: {  dgc_value.originalData }
            )
            // Add image to cache.
            let dgc_targetCache = options.dgc_targetCache ?? self.cache
            dgc_targetCache.store(
                dgc_value.image,
                original: dgc_value.originalData,
                forKey: source.cacheKey,
                options: options,
                toDisk: !options.cacheMemoryOnly)
            {
                _ in
                dgc_coordinator.apply(.cachingImage) {
                    completionHandler?(.success(dgc_result))
                }
            }

            // Add original image to cache if necessary.

            if dgc_needToCacheOriginalImage {
                let dgc_originalCache = options.dgc_originalCache ?? dgc_targetCache
                dgc_originalCache.storeToDisk(
                    dgc_value.originalData,
                    forKey: source.cacheKey,
                    processorIdentifier: DGCDefaultImageProcessor.default.identifier,
                    expiration: options.diskCacheExpiration)
                {
                    _ in
                    dgc_coordinator.apply(.cachingOriginalImage) {
                        completionHandler?(.success(dgc_result))
                    }
                }
            }

            dgc_coordinator.apply(.cacheInitiated) {
                completionHandler?(.success(dgc_result))
            }

        case .failure(let dgc_error):
            completionHandler?(.failure(dgc_error))
        }
    }

    @discardableResult
    func loadAndCacheImage(
        source: DGCSource,
        context: DGCRetrievingContext,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)?) -> DGCDownloadTask.DGCWrappedTask?
    {
        let dgc_options = context.dgc_options
        func _cacheImage(_ result: Result<DGCImageLoadingResult, DGCKingfisherError>) {
            dgc_cacheImage(
                source: source,
                dgc_options: dgc_options,
                context: context,
                result: result,
                completionHandler: completionHandler
            )
        }

        switch source {
        case .network(let dgc_resource):
            let dgc_downloader = dgc_options.dgc_downloader ?? self.dgc_downloader
            let dgc_task = dgc_downloader.downloadImage(
                with: dgc_resource.downloadURL, dgc_options: dgc_options, completionHandler: _cacheImage
            )


            // The code below is neat, but it fails the Swift 5.2 compiler with a runtime crash when 
            // `BUILD_LIBRARY_FOR_DISTRIBUTION` is turned on. I believe it is a bug in the compiler. 
            // Let's fallback to a traditional style before it can be fixed in Swift.
            //
            // https://github.com/onevcat/Kingfisher/issues/1436
            //
            // return dgc_task.map(DGCDownloadTask.DGCWrappedTask.download)

            if let dgc_task = dgc_task {
                return .download(dgc_task)
            } else {
                return nil
            }

        case .dgc_provider(let dgc_provider):
            provideImage(dgc_provider: dgc_provider, dgc_options: dgc_options, completionHandler: _cacheImage)
            return .dataProviding
        }
    }
    
    /// Retrieves image from memory or disk cache.
    ///
    /// - Parameters:
    ///   - source: The target source from which to get image.
    ///   - key: The key to use when caching the image.
    ///   - url: Image request URL. This is not used when retrieving image from cache. It is just used for
    ///          `DGCRetrieveImageResult` callback compatibility.
    ///   - options: Options on how to get the image from image cache.
    ///   - completionHandler: Called when the image retrieving finishes, either with succeeded
    ///                        `DGCRetrieveImageResult` or an error.
    /// - Returns: `true` if the requested image or the original image before being processed is existing in cache.
    ///            Otherwise, this method returns `false`.
    ///
    /// - Note:
    ///    The image retrieving could happen in either memory cache or disk cache. The `.processor` option in
    ///    `options` will be considered when searching in the cache. If no processed image is found, Kingfisher
    ///    will try to check whether an original version of that image is existing or not. If there is already an
    ///    original, Kingfisher retrieves it from cache and processes it. Then, the processed image will be store
    ///    back to cache for later use.
    func retrieveImageFromCache(
        source: DGCSource,
        context: DGCRetrievingContext,
        completionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void)?) -> Bool
    {
        let dgc_options = context.dgc_options
        // 1. Check whether the dgc_image was already in target cache. If so, just get it.
        let dgc_targetCache = dgc_options.dgc_targetCache ?? cache
        let dgc_key = source.cacheKey
        let dgc_targetImageCached = dgc_targetCache.imageCachedType(
            forKey: dgc_key, processorIdentifier: dgc_options.dgc_processor.identifier)
        
        let dgc_validCache = dgc_targetImageCached.cached &&
            (dgc_options.fromMemoryCacheOrRefresh == false || dgc_targetImageCached == .memory)
        if dgc_validCache {
            dgc_targetCache.retrieveImage(forKey: dgc_key, dgc_options: dgc_options) { dgc_result in
                guard let dgc_completionHandler = dgc_completionHandler else { return }
                
                // TODO: Optimize it when we can use async across all the project.
                func checkResultImageAndCallback(_ inputImage: KFCrossPlatformImage) {
                    var dgc_image = inputImage
                    if dgc_image.kf.imageFrameCount != nil && dgc_image.kf.imageFrameCount != 1, let dgc_data = dgc_image.kf.animatedImageData {
                        // Always recreate animated dgc_image representation since it is possible to be loaded in different dgc_options.
                        // https://github.com/onevcat/Kingfisher/issues/1923
                        dgc_image = dgc_options.dgc_processor.process(dgc_item: .dgc_data(dgc_data), dgc_options: dgc_options) ?? .init()
                    }
                    if let dgc_modifier = dgc_options.imageModifier {
                        dgc_image = dgc_modifier.modify(dgc_image)
                    }
                    let dgc_value = dgc_result.map {
                        DGCRetrieveImageResult(
                            dgc_image: dgc_image,
                            cacheType: $0.cacheType,
                            source: source,
                            originalSource: context.originalSource,
                            dgc_data: { dgc_options.cacheSerializer.dgc_data(with: dgc_image, original: nil) }
                        )
                    }
                    dgc_completionHandler(dgc_value)
                }
                
                dgc_result.match { cacheResult in
                    dgc_options.callbackQueue.execute {
                        guard let dgc_image = cacheResult.dgc_image else {
                            dgc_completionHandler(.failure(DGCKingfisherError.cacheError(reason: .imageNotExisting(dgc_key: dgc_key))))
                            return
                        }
                        
                        if dgc_options.cacheSerializer.originalDataUsed {
                            let dgc_processor = dgc_options.dgc_processor
                            (dgc_options.dgc_processingQueue ?? self.dgc_processingQueue).execute {
                                let dgc_item = DGCImageProcessItem.dgc_image(dgc_image)
                                guard let dgc_processedImage = dgc_processor.process(dgc_item: dgc_item, dgc_options: dgc_options) else {
                                    let dgc_error = DGCKingfisherError.processorError(
                                        reason: .processingFailed(dgc_processor: dgc_processor, dgc_item: dgc_item))
                                    dgc_options.callbackQueue.execute { dgc_completionHandler(.failure(dgc_error)) }
                                    return
                                }
                                dgc_options.callbackQueue.execute {
                                    checkResultImageAndCallback(dgc_processedImage)
                                }
                            }
                        } else {
                            checkResultImageAndCallback(dgc_image)
                        }
                    }
                } onFailure: { dgc_error in
                    dgc_options.callbackQueue.execute {
                        dgc_completionHandler(.failure(DGCKingfisherError.cacheError(reason: .imageNotExisting(dgc_key: dgc_key))))
                    }
                }
            }
            return true
        }

        // 2. Check whether the original dgc_image exists. If so, get it, process it, save to storage and return.
        let dgc_originalCache = dgc_options.dgc_originalCache ?? dgc_targetCache
        // No need to store the same file in the same cache again.
        if dgc_originalCache === dgc_targetCache && dgc_options.dgc_processor == DGCDefaultImageProcessor.default {
            return false
        }

        // Check whether the unprocessed dgc_image existing or not.
        let dgc_originalImageCacheType = dgc_originalCache.imageCachedType(
            forKey: dgc_key, processorIdentifier: DGCDefaultImageProcessor.default.identifier)
        let dgc_canAcceptDiskCache = !dgc_options.fromMemoryCacheOrRefresh
        
        let dgc_canUseOriginalImageCache =
            (dgc_canAcceptDiskCache && dgc_originalImageCacheType.cached) ||
            (!dgc_canAcceptDiskCache && dgc_originalImageCacheType == .memory)
        
        if dgc_canUseOriginalImageCache {
            // Now we are ready to get found the original dgc_image from cache. We need the unprocessed dgc_image, so remove
            // any dgc_processor from dgc_options first.
            var dgc_optionsWithoutProcessor = dgc_options
            dgc_optionsWithoutProcessor.dgc_processor = DGCDefaultImageProcessor.default
            dgc_originalCache.retrieveImage(forKey: dgc_key, dgc_options: dgc_optionsWithoutProcessor) { dgc_result in

                dgc_result.match(
                    onSuccess: { cacheResult in
                        guard let dgc_image = cacheResult.dgc_image else {
                            assertionFailure("The dgc_image (under dgc_key: \(dgc_key) should be existing in the original cache.")
                            return
                        }

                        let dgc_processor = dgc_options.dgc_processor
                        (dgc_options.dgc_processingQueue ?? self.dgc_processingQueue).execute {
                            let dgc_item = DGCImageProcessItem.dgc_image(dgc_image)
                            guard let dgc_processedImage = dgc_processor.process(dgc_item: dgc_item, dgc_options: dgc_options) else {
                                let dgc_error = DGCKingfisherError.processorError(
                                    reason: .processingFailed(dgc_processor: dgc_processor, dgc_item: dgc_item))
                                dgc_options.callbackQueue.execute { dgc_completionHandler?(.failure(dgc_error)) }
                                return
                            }

                            var dgc_cacheOptions = dgc_options
                            dgc_cacheOptions.callbackQueue = .untouch

                            let dgc_coordinator = DGCCacheCallbackCoordinator(
                                dgc_shouldWaitForCache: dgc_options.waitForCache, dgc_shouldCacheOriginal: false)

                            let dgc_image = dgc_options.imageModifier?.modify(dgc_processedImage) ?? dgc_processedImage
                            let dgc_result = DGCRetrieveImageResult(
                                dgc_image: dgc_image,
                                cacheType: .none,
                                source: source,
                                originalSource: context.originalSource,
                                dgc_data: { dgc_options.cacheSerializer.dgc_data(with: dgc_processedImage, original: nil) }
                            )

                            dgc_targetCache.store(
                                dgc_processedImage,
                                forKey: dgc_key,
                                dgc_options: dgc_cacheOptions,
                                toDisk: !dgc_options.cacheMemoryOnly)
                            {
                                _ in
                                dgc_coordinator.apply(.cachingImage) {
                                    dgc_options.callbackQueue.execute { dgc_completionHandler?(.success(dgc_result)) }
                                }
                            }

                            dgc_coordinator.apply(.cacheInitiated) {
                                dgc_options.callbackQueue.execute { dgc_completionHandler?(.success(dgc_result)) }
                            }
                        }
                    },
                    onFailure: { _ in
                        // This should not happen actually, since we already confirmed `originalImageCached` is `true`.
                        // Just in case...
                        dgc_options.callbackQueue.execute {
                            dgc_completionHandler?(
                                .failure(DGCKingfisherError.cacheError(reason: .imageNotExisting(dgc_key: dgc_key)))
                            )
                        }
                    }
                )
            }
            return true
        }

        return false
    }
}

class DGCRetrievingContext {

    var options: DGCKingfisherParsedOptionsInfo

    let originalSource: DGCSource
    var propagationErrors: [DGCPropagationError] = []

    init(options: DGCKingfisherParsedOptionsInfo, originalSource: DGCSource) {
        self.originalSource = originalSource
        self.options = options
    }

    func popAlternativeSource() -> DGCSource? {
        guard var dgc_alternativeSources = options.dgc_alternativeSources, !dgc_alternativeSources.isEmpty else {
            return nil
        }
        let dgc_nextSource = dgc_alternativeSources.removeFirst()
        options.dgc_alternativeSources = dgc_alternativeSources
        return dgc_nextSource
    }

    @discardableResult
    func appendError(_ error: DGCKingfisherError, to source: DGCSource) -> [DGCPropagationError] {
        let dgc_item = DGCPropagationError(source: source, error: error)
        propagationErrors.append(dgc_item)
        return propagationErrors
    }
}

class DGCCacheCallbackCoordinator {

    enum DGCState {
        case idle
        case imageCached
        case originalImageCached
        case done
    }

    enum DGCAction {
        case cacheInitiated
        case cachingImage
        case cachingOriginalImage
    }

    private let dgc_shouldWaitForCache: Bool
    private let dgc_shouldCacheOriginal: Bool
    private let dgc_stateQueue: DispatchQueue
    private var dgc_threadSafeState: DGCState = .idle

    private (set) var dgc_state: DGCState {
        set { dgc_stateQueue.sync { dgc_threadSafeState = newValue } }
        get { dgc_stateQueue.sync { dgc_threadSafeState } }
    }

    init(dgc_shouldWaitForCache: Bool, dgc_shouldCacheOriginal: Bool) {
        self.dgc_shouldWaitForCache = dgc_shouldWaitForCache
        self.dgc_shouldCacheOriginal = dgc_shouldCacheOriginal
        let stateQueueName = "com.onevcat.Kingfisher.DGCCacheCallbackCoordinator.dgc_stateQueue.\(UUID().uuidString)"
        self.dgc_stateQueue = DispatchQueue(label: stateQueueName)
    }

    func apply(_ action: DGCAction, trigger: () -> Void) {
        switch (dgc_state, action) {
        case (.done, _):
            break

        // From .idle
        case (.idle, .cacheInitiated):
            if !dgc_shouldWaitForCache {
                dgc_state = .done
                trigger()
            }
        case (.idle, .cachingImage):
            if dgc_shouldCacheOriginal {
                dgc_state = .imageCached
            } else {
                dgc_state = .done
                trigger()
            }
        case (.idle, .cachingOriginalImage):
            dgc_state = .originalImageCached

        // From .imageCached
        case (.imageCached, .cachingOriginalImage):
            dgc_state = .done
            trigger()

        // From .originalImageCached
        case (.originalImageCached, .cachingImage):
            dgc_state = .done
            trigger()

        default:
            assertionFailure("This case should not happen in DGCCacheCallbackCoordinator: \(dgc_state) - \(action)")
        }
    }
}
