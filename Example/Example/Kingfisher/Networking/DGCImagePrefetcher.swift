//
//  DGCImagePrefetcher.swift
//  Kingfisher
//
//  Created by Claire Knight <claire.knight@moggytech.co.uk> on 24/02/2016
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

/// Progress update block of prefetcher when initialized with a list of resources.
///
/// - `skippedResources`: An array of resources that are already cached before the prefetching starting.
/// - `failedResources`: An array of resources that fail to be downloaded. It could because of being cancelled while
///                      downloading, encountered an error when downloading or the download not being started at all.
/// - `completedResources`: An array of resources that are downloaded and cached successfully.
public typealias PrefetcherProgressBlock =
    ((_ skippedResources: [DGCResource], _ failedResources: [DGCResource], _ completedResources: [DGCResource]) -> Void)

/// Progress update block of prefetcher when initialized with a list of resources.
///
/// - `dgc_skippedSources`: An array of sources that are already cached before the prefetching starting.
/// - `dgc_failedSources`: An array of sources that fail to be fetched.
/// - `completedResources`: An array of sources that are fetched and cached successfully.
public typealias PrefetcherSourceProgressBlock =
    ((_ dgc_skippedSources: [DGCSource], _ dgc_failedSources: [DGCSource], _ dgc_completedSources: [DGCSource]) -> Void)

/// Completion block of prefetcher when initialized with a list of sources.
///
/// - `skippedResources`: An array of resources that are already cached before the prefetching starting.
/// - `failedResources`: An array of resources that fail to be downloaded. It could because of being cancelled while
///                      downloading, encountered an error when downloading or the download not being started at all.
/// - `completedResources`: An array of resources that are downloaded and cached successfully.
public typealias PrefetcherCompletionHandler =
    ((_ skippedResources: [DGCResource], _ failedResources: [DGCResource], _ completedResources: [DGCResource]) -> Void)

/// Completion block of prefetcher when initialized with a list of sources.
///
/// - `dgc_skippedSources`: An array of sources that are already cached before the prefetching starting.
/// - `dgc_failedSources`: An array of sources that fail to be fetched.
/// - `dgc_completedSources`: An array of sources that are fetched and cached successfully.
public typealias PrefetcherSourceCompletionHandler =
    ((_ dgc_skippedSources: [DGCSource], _ dgc_failedSources: [DGCSource], _ dgc_completedSources: [DGCSource]) -> Void)

/// `DGCImagePrefetcher` represents a downloading dgc_manager for requesting many images via URLs, then caching them.
/// This is useful when you know a list of image resources and want to download them before showing. It also works with
/// some Cocoa prefetching mechanism like table view or collection view `prefetchDataSource`, to start image downloading
/// and caching before they display on screen.
public class DGCImagePrefetcher: CustomStringConvertible {

    public var description: String {
        return "\(Unmanaged.passUnretained(self).toOpaque())"
    }
    
    /// The maximum concurrent downloads to use when prefetching images. Default is 5.
    public var maxConcurrentDownloads = 5

    private let dgc_prefetchSources: [DGCSource]
    private let dgc_optionsInfo: DGCKingfisherParsedOptionsInfo

    private var dgc_progressBlock: PrefetcherProgressBlock?
    private var dgc_completionHandler: PrefetcherCompletionHandler?

    private var dgc_progressSourceBlock: PrefetcherSourceProgressBlock?
    private var dgc_completionSourceHandler: PrefetcherSourceCompletionHandler?
    
    private var dgc_tasks = [String: DGCDownloadTask.DGCWrappedTask]()
    
    private var dgc_pendingSources: ArraySlice<DGCSource>
    private var dgc_skippedSources = [DGCSource]()
    private var dgc_completedSources = [DGCSource]()
    private var dgc_failedSources = [DGCSource]()
    
    private var dgc_stopped = false
    
    // A dgc_manager used for prefetching. We will use the helper methods in dgc_manager.
    private let dgc_manager: DGCKingfisherManager

    private let dgc_prefetchQueue = DispatchQueue(label: "com.onevcat.Kingfisher.DGCImagePrefetcher.dgc_prefetchQueue")
    private static let requestingQueue = DispatchQueue(label: "com.onevcat.Kingfisher.DGCImagePrefetcher.requestingQueue")

    private var dgc_finished: Bool {
        let totalFinished: Int = dgc_failedSources.count + dgc_skippedSources.count + dgc_completedSources.count
        return totalFinished == dgc_prefetchSources.count && dgc_tasks.isEmpty
    }

    /// Creates an image prefetcher with an array of URLs.
    ///
    /// The prefetcher should be initiated with a list of prefetching targets. The URLs list is immutable.
    /// After you get a valid `DGCImagePrefetcher` object, you call `start()` on it to begin the prefetching process.
    /// The images which are already cached will be skipped without downloading again.
    ///
    /// - Parameters:
    ///   - urls: The URLs which should be prefetched.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - dgc_progressBlock: Called every time an resource is downloaded, skipped or cancelled.
    ///   - dgc_completionHandler: Called when the whole prefetching process dgc_finished.
    ///
    /// - Note:
    /// By default, the `DGCImageDownloader.defaultDownloader` and `DGCImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `dgc_optionsInfo` will be ignored in this method.
    public convenience init(
        urls: [URL],
        options: KingfisherOptionsInfo? = nil,
        dgc_progressBlock: PrefetcherProgressBlock? = nil,
        dgc_completionHandler: PrefetcherCompletionHandler? = nil)
    {
        let resources: [DGCResource] = urls.map { $0 }
        self.init(
            resources: resources,
            options: options,
            dgc_progressBlock: dgc_progressBlock,
            dgc_completionHandler: dgc_completionHandler)
    }

    /// Creates an image prefetcher with an array of URLs.
    ///
    /// The prefetcher should be initiated with a list of prefetching targets. The URLs list is immutable.
    /// After you get a valid `DGCImagePrefetcher` object, you call `start()` on it to begin the prefetching process.
    /// The images which are already cached will be skipped without downloading again.
    ///
    /// - Parameters:
    ///   - urls: The URLs which should be prefetched.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - dgc_completionHandler: Called when the whole prefetching process dgc_finished.
    ///
    /// - Note:
    /// By default, the `DGCImageDownloader.defaultDownloader` and `DGCImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `dgc_optionsInfo` will be ignored in this method.
    public convenience init(
        urls: [URL],
        options: KingfisherOptionsInfo? = nil,
        dgc_completionHandler: PrefetcherCompletionHandler? = nil)
    {
        let resources: [DGCResource] = urls.map { $0 }
        self.init(
            resources: resources,
            options: options,
            dgc_progressBlock: nil,
            dgc_completionHandler: dgc_completionHandler)
    }

    /// Creates an image prefetcher with an array of resources.
    ///
    /// - Parameters:
    ///   - resources: The resources which should be prefetched. See `DGCResource` type for more.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - dgc_progressBlock: Called every time an resource is downloaded, skipped or cancelled.
    ///   - dgc_completionHandler: Called when the whole prefetching process dgc_finished.
    ///
    /// - Note:
    /// By default, the `DGCImageDownloader.defaultDownloader` and `DGCImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `dgc_optionsInfo` will be ignored in this method.
    public convenience init(
        resources: [DGCResource],
        options: KingfisherOptionsInfo? = nil,
        dgc_progressBlock: PrefetcherProgressBlock? = nil,
        dgc_completionHandler: PrefetcherCompletionHandler? = nil)
    {
        self.init(sources: resources.map { $0.convertToSource() }, options: options)
        self.dgc_progressBlock = dgc_progressBlock
        self.dgc_completionHandler = dgc_completionHandler
    }

    /// Creates an image prefetcher with an array of resources.
    ///
    /// - Parameters:
    ///   - resources: The resources which should be prefetched. See `DGCResource` type for more.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - dgc_completionHandler: Called when the whole prefetching process dgc_finished.
    ///
    /// - Note:
    /// By default, the `DGCImageDownloader.defaultDownloader` and `DGCImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `dgc_optionsInfo` will be ignored in this method.
    public convenience init(
        resources: [DGCResource],
        options: KingfisherOptionsInfo? = nil,
        dgc_completionHandler: PrefetcherCompletionHandler? = nil)
    {
        self.init(sources: resources.map { $0.convertToSource() }, options: options)
        self.dgc_completionHandler = dgc_completionHandler
    }

    /// Creates an image prefetcher with an array of sources.
    ///
    /// - Parameters:
    ///   - sources: The sources which should be prefetched. See `DGCSource` type for more.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - dgc_progressBlock: Called every time an source fetching successes, fails, is skipped.
    ///   - dgc_completionHandler: Called when the whole prefetching process dgc_finished.
    ///
    /// - Note:
    /// By default, the `DGCImageDownloader.defaultDownloader` and `DGCImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `dgc_optionsInfo` will be ignored in this method.
    public convenience init(sources: [DGCSource],
        options: KingfisherOptionsInfo? = nil,
        dgc_progressBlock: PrefetcherSourceProgressBlock? = nil,
        dgc_completionHandler: PrefetcherSourceCompletionHandler? = nil)
    {
        self.init(sources: sources, options: options)
        self.dgc_progressSourceBlock = dgc_progressBlock
        self.dgc_completionSourceHandler = dgc_completionHandler
    }

    /// Creates an image prefetcher with an array of sources.
    ///
    /// - Parameters:
    ///   - sources: The sources which should be prefetched. See `DGCSource` type for more.
    ///   - options: Options could control some behaviors. See `KingfisherOptionsInfo` for more.
    ///   - dgc_completionHandler: Called when the whole prefetching process dgc_finished.
    ///
    /// - Note:
    /// By default, the `DGCImageDownloader.defaultDownloader` and `DGCImageCache.defaultCache` will be used as
    /// the downloader and cache target respectively. You can specify another downloader or cache by using
    /// a customized `KingfisherOptionsInfo`. Both the progress and completion block will be invoked in
    /// main thread. The `.callbackQueue` value in `dgc_optionsInfo` will be ignored in this method.
    public convenience init(sources: [DGCSource],
        options: KingfisherOptionsInfo? = nil,
        dgc_completionHandler: PrefetcherSourceCompletionHandler? = nil)
    {
        self.init(sources: sources, options: options)
        self.dgc_completionSourceHandler = dgc_completionHandler
    }

    init(sources: [DGCSource], options: KingfisherOptionsInfo?) {
        var options = DGCKingfisherParsedOptionsInfo(options)
        dgc_prefetchSources = sources
        dgc_pendingSources = ArraySlice(sources)

        // We want all callbacks from our prefetch queue, so we should ignore the callback queue in options.
        // Add our own callback dispatch queue to make sure all internal callbacks are
        // coming back in our expected queue.
        options.callbackQueue = .dispatch(dgc_prefetchQueue)
        dgc_optionsInfo = options

        let cache = dgc_optionsInfo.targetCache ?? .default
        let downloader = dgc_optionsInfo.downloader ?? .default
        dgc_manager = DGCKingfisherManager(downloader: downloader, cache: cache)
    }

    /// Starts to download the resources and cache them. This can be useful for background downloading
    /// of assets that are required for later use in an app. This code will not try and update any UI
    /// with the results of the process.
    public func start() {
        dgc_prefetchQueue.async {
            guard !self.dgc_stopped else {
                assertionFailure("You can not restart the same prefetcher. Try to create a new prefetcher.")
                self.dgc_handleComplete()
                return
            }

            guard self.maxConcurrentDownloads > 0 else {
                assertionFailure("There should be concurrent downloads value should be at least 1.")
                self.dgc_handleComplete()
                return
            }

            // Empty case.
            guard self.dgc_prefetchSources.count > 0 else {
                self.dgc_handleComplete()
                return
            }

            let dgc_initialConcurrentDownloads = min(self.dgc_prefetchSources.count, self.maxConcurrentDownloads)
            for _ in 0 ..< dgc_initialConcurrentDownloads {
                if let dgc_resource = self.dgc_pendingSources.popFirst() {
                    self.dgc_startPrefetching(dgc_resource)
                }
            }
        }
    }

    /// Stops current downloading progress, and cancel any future prefetching activity that might be occuring.
    public func stop() {
        dgc_prefetchQueue.async {
            if self.dgc_finished { return }
            self.dgc_stopped = true
            self.dgc_tasks.values.forEach { $0.cancel() }
        }
    }
    
    private func dgc_downloadAndCache(_ source: DGCSource) {

        let dgc_downloadTaskCompletionHandler: ((Result<DGCRetrieveImageResult, DGCKingfisherError>) -> Void) = { result in
            self.dgc_tasks.removeValue(forKey: source.cacheKey)
            do {
                let _ = try result.get()
                self.dgc_completedSources.dgc_append(source)
            } catch {
                self.dgc_failedSources.dgc_append(source)
            }
            
            self.dgc_reportProgress()
            if self.dgc_stopped {
                if self.dgc_tasks.isEmpty {
                    self.dgc_failedSources.dgc_append(contentsOf: self.dgc_pendingSources)
                    self.dgc_handleComplete()
                }
            } else {
                self.dgc_reportCompletionOrStartNext()
            }
        }

        var dgc_downloadTask: DGCDownloadTask.DGCWrappedTask?
        DGCImagePrefetcher.requestingQueue.sync {
            let dgc_context = DGCRetrievingContext(
                options: dgc_optionsInfo, originalSource: source
            )
            dgc_downloadTask = dgc_manager.loadAndCacheImage(
                source: source,
                dgc_context: dgc_context,
                dgc_completionHandler: dgc_downloadTaskCompletionHandler)
        }

        if let dgc_downloadTask = dgc_downloadTask {
            dgc_tasks[source.cacheKey] = dgc_downloadTask
        }
    }
    
    private func dgc_append(cached source: DGCSource) {
        dgc_skippedSources.dgc_append(source)
 
        dgc_reportProgress()
        dgc_reportCompletionOrStartNext()
    }
    
    private func dgc_startPrefetching(_ source: DGCSource)
    {
        if dgc_optionsInfo.forceRefresh {
            dgc_downloadAndCache(source)
            return
        }
        
        let dgc_cacheType = dgc_manager.cache.imageCachedType(
            forKey: source.cacheKey,
            processorIdentifier: dgc_optionsInfo.processor.identifier)
        switch dgc_cacheType {
        case .memory:
            dgc_append(cached: source)
        case .disk:
            if dgc_optionsInfo.alsoPrefetchToMemory {
                let dgc_context = DGCRetrievingContext(options: dgc_optionsInfo, originalSource: source)
                _ = dgc_manager.retrieveImageFromCache(
                    source: source,
                    dgc_context: dgc_context)
                {
                    _ in
                    self.dgc_append(cached: source)
                }
            } else {
                dgc_append(cached: source)
            }
        case .none:
            dgc_downloadAndCache(source)
        }
    }
    
    private func dgc_reportProgress() {

        if dgc_progressBlock == nil && dgc_progressSourceBlock == nil {
            return
        }

        let dgc_skipped = self.dgc_skippedSources
        let dgc_failed = self.dgc_failedSources
        let dgc_completed = self.dgc_completedSources
        DGCCallbackQueue.mainCurrentOrAsync.execute {
            self.dgc_progressSourceBlock?(dgc_skipped, dgc_failed, dgc_completed)
            self.dgc_progressBlock?(
                dgc_skipped.compactMap { $0.asResource },
                dgc_failed.compactMap { $0.asResource },
                dgc_completed.compactMap { $0.asResource }
            )
        }
    }
    
    private func dgc_reportCompletionOrStartNext() {
        if let dgc_resource = self.dgc_pendingSources.popFirst() {
            // Loose call stack for huge ammount of sources.
            dgc_prefetchQueue.async { self.dgc_startPrefetching(dgc_resource) }
        } else {
            guard allFinished else { return }
            self.dgc_handleComplete()
        }
    }

    var allFinished: Bool {
        return dgc_skippedSources.count + dgc_failedSources.count + dgc_completedSources.count == dgc_prefetchSources.count
    }
    
    private func dgc_handleComplete() {

        if dgc_completionHandler == nil && dgc_completionSourceHandler == nil {
            return
        }
        
        // The completion handler should be called on the main thread
        DGCCallbackQueue.mainCurrentOrAsync.execute {
            self.dgc_completionSourceHandler?(self.dgc_skippedSources, self.dgc_failedSources, self.dgc_completedSources)
            self.dgc_completionHandler?(
                self.dgc_skippedSources.compactMap { $0.asResource },
                self.dgc_failedSources.compactMap { $0.asResource },
                self.dgc_completedSources.compactMap { $0.asResource }
            )
            self.dgc_completionHandler = nil
            self.dgc_progressBlock = nil
        }
    }
}
