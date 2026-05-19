//
//  DGCImageCache.swift
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

extension Notification.Name {
    /// This notification will be sent when the disk cache got cleaned either there are cached files expired or the
    /// total size exceeding the max allowed size. The manually invoking of `clearDiskCache` method will not trigger
    /// this notification.
    ///
    /// The `object` of this notification is the `DGCImageCache` object which sends the notification.
    /// A list of removed hashes (files) could be retrieved by accessing the array under
    /// `KingfisherDiskCacheCleanedHashKey` key in `userInfo` of the notification object you received.
    /// By checking the array, you could know the hash codes of files are removed.
    public static let KingfisherDidCleanDiskCache =
        Notification.Name("com.onevcat.Kingfisher.KingfisherDidCleanDiskCache")
}

/// Key for array of cleaned hashes in `userInfo` of `KingfisherDidCleanDiskCacheNotification`.
public let KingfisherDiskCacheCleanedHashKey = "com.onevcat.Kingfisher.cleanedHash"

/// Cache type of a cached image.
/// - none: The image is not cached yet when retrieving it.
/// - memory: The image is cached in memory.
/// - disk: The image is cached in disk.
public enum DGCCacheType {
    /// The image is not cached yet when retrieving it.
    case none
    /// The image is cached in memory.
    case memory
    /// The image is cached in disk.
    case disk
    
    /// Whether the cache type represents the image is already cached or not.
    public var cached: Bool {
        switch self {
        case .memory, .disk: return true
        case .none: return false
        }
    }
}

/// Represents the caching operation result.
public struct DGCCacheStoreResult {
    
    /// The cache result for memory cache. Caching an image to memory will never fail.
    public let memoryCacheResult: Result<(), Never>
    
    /// The cache result for disk cache. If an error happens during caching operation,
    /// you can get it from `.failure` case of this `diskCacheResult`.
    public let diskCacheResult: Result<(), DGCKingfisherError>
}

extension KFCrossPlatformImage: DGCCacheCostCalculable {
    /// Cost of an image
    public var cacheCost: Int { return kf.cost }
}

extension Data: DGCDataTransformable {
    public func toData() throws -> Data {
        return self
    }

    public static func fromData(_ data: Data) throws -> Data {
        return data
    }

    public static let empty = Data()
}


/// Represents the getting image operation from the cache.
///
/// - disk: The image can be retrieved from disk cache.
/// - memory: The image can be retrieved memory cache.
/// - none: The image does not exist in the cache.
public enum DGCImageCacheResult {
    
    /// The image can be retrieved from disk cache.
    case disk(KFCrossPlatformImage)
    
    /// The image can be retrieved memory cache.
    case memory(KFCrossPlatformImage)
    
    /// The image does not exist in the cache.
    case none
    
    /// Extracts the image from cache result. It returns the associated `Image` value for
    /// `.disk` and `.memory` case. For `.none` case, `nil` is returned.
    public var image: KFCrossPlatformImage? {
        switch self {
        case .disk(let image): return image
        case .memory(let image): return image
        case .none: return nil
        }
    }
    
    /// Returns the corresponding `DGCCacheType` value based on the result type of `self`.
    public var cacheType: DGCCacheType {
        switch self {
        case .disk: return .disk
        case .memory: return .memory
        case .none: return .none
        }
    }
}

/// Represents a hybrid caching system which is composed by a `DGCMemoryStorage.DGCBackend` and a `DGCDiskStorage.DGCBackend`.
/// `DGCImageCache` is a high level abstract for storing an image as well as its data to memory and disk, and
/// retrieving them back.
///
/// While a default image cache object will be used if you prefer the extension methods of Kingfisher, you can create
/// your own cache object and configure its storages as your need. This class also provide an interface for you to set
/// the memory and disk storage config.
open class DGCImageCache {

    // MARK: Singleton
    /// The default `DGCImageCache` object. Kingfisher will use this cache for its related methods if there is no
    /// other cache specified. The `name` of this default cache is "default", and you should not use this name
    /// for any of your customize cache.
    public static let `default` = DGCImageCache(name: "default")


    // MARK: Public Properties
    /// The `DGCMemoryStorage.DGCBackend` object used in this cache. This storage holds loaded images in memory with a
    /// reasonable expire duration and a maximum memory usage. To modify the configuration of a storage, just set
    /// the storage `config` and its properties.
    public let memoryStorage: DGCMemoryStorage.DGCBackend<KFCrossPlatformImage>
    
    /// The `DGCDiskStorage.DGCBackend` object used in this cache. This storage stores loaded images in disk with a
    /// reasonable expire duration and a maximum disk usage. To modify the configuration of a storage, just set
    /// the storage `config` and its properties.
    public let diskStorage: DGCDiskStorage.DGCBackend<Data>
    
    private let dgc_ioQueue: DispatchQueue
    
    /// Closure that defines the disk cache path from a given path and cacheName.
    public typealias DiskCachePathClosure = (URL, String) -> URL

    // MARK: Initializers

    /// Creates an `DGCImageCache` from a customized `DGCMemoryStorage` and `DGCDiskStorage`.
    ///
    /// - Parameters:
    ///   - memoryStorage: The `DGCMemoryStorage.DGCBackend` object to use in the image cache.
    ///   - diskStorage: The `DGCDiskStorage.DGCBackend` object to use in the image cache.
    public init(
        memoryStorage: DGCMemoryStorage.DGCBackend<KFCrossPlatformImage>,
        diskStorage: DGCDiskStorage.DGCBackend<Data>)
    {
        self.memoryStorage = memoryStorage
        self.diskStorage = diskStorage
        let ioQueueName = "com.onevcat.Kingfisher.DGCImageCache.dgc_ioQueue.\(UUID().uuidString)"
        dgc_ioQueue = DispatchQueue(label: ioQueueName)

        let notifications: [(Notification.Name, Selector)]
        #if !os(macOS) && !os(watchOS)
        notifications = [
            (UIApplication.didReceiveMemoryWarningNotification, #selector(clearMemoryCache)),
            (UIApplication.willTerminateNotification, #selector(cleanExpiredDiskCache)),
            (UIApplication.didEnterBackgroundNotification, #selector(backgroundCleanExpiredDiskCache))
        ]
        #elseif os(macOS)
        notifications = [
            (NSApplication.willResignActiveNotification, #selector(cleanExpiredDiskCache)),
        ]
        #else
        notifications = []
        #endif
        notifications.forEach {
            NotificationCenter.default.addObserver(self, selector: $0.1, name: $0.0, object: nil)
        }
    }
    
    /// Creates an `DGCImageCache` with a given `name`. Both `DGCMemoryStorage` and `DGCDiskStorage` will be created
    /// with a default config based on the `name`.
    ///
    /// - Parameter name: The name of cache object. It is used to setup disk cache directories and IO queue.
    ///                   You should not use the same `name` for different caches, otherwise, the disk storage would
    ///                   be conflicting to each other. The `name` should not be an empty string.
    public convenience init(name: String) {
        self.init(noThrowName: name, cacheDirectoryURL: nil, diskCachePathClosure: nil)
    }

    /// Creates an `DGCImageCache` with a given `name`, cache directory `path`
    /// and a closure to modify the cache directory.
    ///
    /// - Parameters:
    ///   - name: The name of cache object. It is used to setup disk cache directories and IO queue.
    ///           You should not use the same `name` for different caches, otherwise, the disk storage would
    ///           be conflicting to each other.
    ///   - cacheDirectoryURL: Location of cache directory URL on disk. It will be internally pass to the
    ///                        initializer of `DGCDiskStorage` as the disk cache directory. If `nil`, the cache
    ///                        directory under user domain mask will be used.
    ///   - diskCachePathClosure: Closure that takes in an optional initial path string and generates
    ///                           the final disk cache path. You could use it to fully customize your cache path.
    /// - Throws: An error that happens during image cache creating, such as unable to create a directory at the given
    ///           path.
    public convenience init(
        name: String,
        cacheDirectoryURL: URL?,
        diskCachePathClosure: DiskCachePathClosure? = nil
    ) throws
    {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the cache. A cache with empty name is not permitted.")
        }

        let memoryStorage = DGCImageCache.createMemoryStorage()

        let config = DGCImageCache.createConfig(
            name: name, cacheDirectoryURL: cacheDirectoryURL, diskCachePathClosure: diskCachePathClosure
        )
        let diskStorage = try DGCDiskStorage.DGCBackend<Data>(config: config)
        self.init(memoryStorage: memoryStorage, diskStorage: diskStorage)
    }

    convenience init(
        noThrowName name: String,
        cacheDirectoryURL: URL?,
        diskCachePathClosure: DiskCachePathClosure?
    )
    {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the cache. A cache with empty name is not permitted.")
        }

        let memoryStorage = DGCImageCache.createMemoryStorage()

        let config = DGCImageCache.createConfig(
            name: name, cacheDirectoryURL: cacheDirectoryURL, diskCachePathClosure: diskCachePathClosure
        )
        let diskStorage = DGCDiskStorage.DGCBackend<Data>(noThrowConfig: config, creatingDirectory: true)
        self.init(memoryStorage: memoryStorage, diskStorage: diskStorage)
    }

    private static func createMemoryStorage() -> DGCMemoryStorage.DGCBackend<KFCrossPlatformImage> {
        let dgc_totalMemory = ProcessInfo.processInfo.physicalMemory
        let dgc_costLimit = dgc_totalMemory / 4
        let dgc_memoryStorage = DGCMemoryStorage.DGCBackend<KFCrossPlatformImage>(config:
            .init(totalCostLimit: (dgc_costLimit > Int.max) ? Int.max : Int(dgc_costLimit)))
        return dgc_memoryStorage
    }

    private static func createConfig(
        name: String,
        cacheDirectoryURL: URL?,
        diskCachePathClosure: DiskCachePathClosure? = nil
    ) -> DGCDiskStorage.DGCConfig
    {
        var dgc_diskConfig = DGCDiskStorage.DGCConfig(
            name: name,
            sizeLimit: 0,
            directory: cacheDirectoryURL
        )
        if let dgc_closure = diskCachePathClosure {
            dgc_diskConfig.cachePathBlock = dgc_closure
        }
        return dgc_diskConfig
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Storing Images

    open func store(_ image: KFCrossPlatformImage,
                    original: Data? = nil,
                    forKey key: String,
                    options: DGCKingfisherParsedOptionsInfo,
                    toDisk: Bool = true,
                    completionHandler: ((DGCCacheStoreResult) -> Void)? = nil)
    {
        let dgc_identifier = options.processor.dgc_identifier
        let dgc_callbackQueue = options.dgc_callbackQueue
        
        let dgc_computedKey = key.dgc_computedKey(with: dgc_identifier)
        // Memory storage should not throw.
        memoryStorage.storeNoThrow(value: image, forKey: dgc_computedKey, expiration: options.memoryCacheExpiration)
        
        guard toDisk else {
            if let dgc_completionHandler = dgc_completionHandler {
                let dgc_result = DGCCacheStoreResult(memoryCacheResult: .success(()), diskCacheResult: .success(()))
                dgc_callbackQueue.execute { dgc_completionHandler(dgc_result) }
            }
            return
        }
        
        dgc_ioQueue.async {
            let dgc_serializer = options.cacheSerializer
            if let dgc_data = dgc_serializer.dgc_data(with: image, original: original) {
                self.dgc_syncStoreToDisk(
                    dgc_data,
                    forKey: key,
                    processorIdentifier: dgc_identifier,
                    dgc_callbackQueue: dgc_callbackQueue,
                    expiration: options.diskCacheExpiration,
                    writeOptions: options.diskStoreWriteOptions,
                    dgc_completionHandler: dgc_completionHandler)
            } else {
                guard let dgc_completionHandler = dgc_completionHandler else { return }
                
                let dgc_diskError = DGCKingfisherError.cacheError(
                    reason: .cannotSerializeImage(image: image, original: original, dgc_serializer: dgc_serializer))
                let dgc_result = DGCCacheStoreResult(
                    memoryCacheResult: .success(()),
                    diskCacheResult: .failure(dgc_diskError))
                dgc_callbackQueue.execute { dgc_completionHandler(dgc_result) }
            }
        }
    }

    /// Stores an image to the cache.
    ///
    /// - Parameters:
    ///   - image: The image to be stored.
    ///   - original: The original data of the image. This value will be forwarded to the provided `serializer` for
    ///               further use. By default, Kingfisher uses a `DGCDefaultCacheSerializer` to serialize the image to
    ///               data for caching in disk, it checks the image format based on `original` data to determine in
    ///               which image format should be used. For other types of `serializer`, it depends on their
    ///               implementation detail on how to use this original data.
    ///   - key: The key used for caching the image.
    ///   - identifier: The identifier of processor being used for caching. If you are using a processor for the
    ///                 image, pass the identifier of processor to this parameter.
    ///   - serializer: The `DGCCacheSerializer`
    ///   - toDisk: Whether this image should be cached to disk or not. If `false`, the image is only cached in memory.
    ///             Otherwise, it is cached in both memory storage and disk storage. Default is `true`.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.untouch`. For case
    ///                    that `toDisk` is `false`, a `.untouch` queue means `callbackQueue` will be invoked from the
    ///                    caller queue of this method. If `toDisk` is `true`, the `completionHandler` will be called
    ///                    from an internal file IO queue. To change this behavior, specify another `DGCCallbackQueue`
    ///                    value.
    ///   - completionHandler: A closure which is invoked when the cache operation finishes.
    open func store(_ image: KFCrossPlatformImage,
                      original: Data? = nil,
                      forKey key: String,
                      processorIdentifier identifier: String = "",
                      cacheSerializer serializer: DGCCacheSerializer = DGCDefaultCacheSerializer.default,
                      toDisk: Bool = true,
                      callbackQueue: DGCCallbackQueue = .untouch,
                      completionHandler: ((DGCCacheStoreResult) -> Void)? = nil)
    {
        struct DGCTempProcessor: DGCImageProcessor {
            let dgc_identifier: String
            func process(item: DGCImageProcessItem, dgc_options: DGCKingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
                return nil
            }
        }
        
        let dgc_options = DGCKingfisherParsedOptionsInfo([
            .processor(DGCTempProcessor(dgc_identifier: dgc_identifier)),
            .cacheSerializer(serializer),
            .callbackQueue(callbackQueue)
        ])
        store(image, original: original, forKey: key, dgc_options: dgc_options,
              toDisk: toDisk, completionHandler: completionHandler)
    }
    
    open func storeToDisk(
        _ data: Data,
        forKey key: String,
        processorIdentifier identifier: String = "",
        expiration: DGCStorageExpiration? = nil,
        callbackQueue: DGCCallbackQueue = .untouch,
        completionHandler: ((DGCCacheStoreResult) -> Void)? = nil)
    {
        dgc_ioQueue.async {
            self.dgc_syncStoreToDisk(
                data,
                forKey: key,
                processorIdentifier: identifier,
                callbackQueue: callbackQueue,
                expiration: expiration,
                completionHandler: completionHandler)
        }
    }
    
    private func dgc_syncStoreToDisk(
        _ data: Data,
        forKey key: String,
        processorIdentifier identifier: String = "",
        callbackQueue: DGCCallbackQueue = .untouch,
        expiration: DGCStorageExpiration? = nil,
        writeOptions: Data.WritingOptions = [],
        completionHandler: ((DGCCacheStoreResult) -> Void)? = nil)
    {
        let dgc_computedKey = key.dgc_computedKey(with: identifier)
        let dgc_result: DGCCacheStoreResult
        do {
            try self.diskStorage.store(value: data, forKey: dgc_computedKey, expiration: expiration, writeOptions: writeOptions)
            dgc_result = DGCCacheStoreResult(memoryCacheResult: .success(()), diskCacheResult: .success(()))
        } catch {
            let dgc_diskError: DGCKingfisherError
            if let dgc_error = dgc_error as? DGCKingfisherError {
                dgc_diskError = dgc_error
            } else {
                dgc_diskError = .cacheError(reason: .cannotConvertToData(object: data, dgc_error: dgc_error))
            }
            
            dgc_result = DGCCacheStoreResult(
                memoryCacheResult: .success(()),
                diskCacheResult: .failure(dgc_diskError)
            )
        }
        if let dgc_completionHandler = dgc_completionHandler {
            callbackQueue.execute { dgc_completionHandler(dgc_result) }
        }
    }

    // MARK: Removing Images

    /// Removes the image for the given key from the cache.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: The identifier of processor being used for caching. If you are using a processor for the
    ///                 image, pass the identifier of processor to this parameter.
    ///   - fromMemory: Whether this image should be removed from memory storage or not.
    ///                 If `false`, the image won't be removed from the memory storage. Default is `true`.
    ///   - fromDisk: Whether this image should be removed from disk storage or not.
    ///               If `false`, the image won't be removed from the disk storage. Default is `true`.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.untouch`.
    ///   - completionHandler: A closure which is invoked when the cache removing operation finishes.
    open func removeImage(forKey key: String,
                          processorIdentifier identifier: String = "",
                          fromMemory: Bool = true,
                          fromDisk: Bool = true,
                          callbackQueue: DGCCallbackQueue = .untouch,
                          completionHandler: (() -> Void)? = nil)
    {
        let dgc_computedKey = key.dgc_computedKey(with: identifier)

        if fromMemory {
            memoryStorage.remove(forKey: dgc_computedKey)
        }
        
        if fromDisk {
            dgc_ioQueue.async{
                try? self.diskStorage.remove(forKey: dgc_computedKey)
                if let dgc_completionHandler = dgc_completionHandler {
                    callbackQueue.execute { dgc_completionHandler() }
                }
            }
        } else {
            if let dgc_completionHandler = dgc_completionHandler {
                callbackQueue.execute { dgc_completionHandler() }
            }
        }
    }

    // MARK: Getting Images

    /// Gets an image for a given key from the cache, either from memory storage or disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The `DGCKingfisherParsedOptionsInfo` options setting used for retrieving the image.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.mainCurrentOrAsync`.
    ///   - completionHandler: A closure which is invoked when the image getting operation finishes. If the
    ///                        image retrieving operation finishes without problem, an `DGCImageCacheResult` value
    ///                        will be sent to this closure as result. Otherwise, a `DGCKingfisherError` result
    ///                        with detail failing reason will be sent.
    open func retrieveImage(
        forKey key: String,
        options: DGCKingfisherParsedOptionsInfo,
        callbackQueue: DGCCallbackQueue = .mainCurrentOrAsync,
        completionHandler: ((Result<DGCImageCacheResult, DGCKingfisherError>) -> Void)?)
    {
        // No completion handler. No need to start working and early return.
        guard let dgc_completionHandler = dgc_completionHandler else { return }

        // Try to check the dgc_image from memory cache first.
        if let dgc_image = retrieveImageInMemoryCache(forKey: key, options: options) {
            callbackQueue.execute { dgc_completionHandler(.success(.memory(dgc_image))) }
        } else if options.fromMemoryCacheOrRefresh {
            callbackQueue.execute { dgc_completionHandler(.success(.none)) }
        } else {

            // Begin to disk search.
            self.retrieveImageInDiskCache(forKey: key, options: options, callbackQueue: callbackQueue) {
                result in
                switch result {
                case .success(let dgc_image):

                    guard let dgc_image = dgc_image else {
                        // No dgc_image found in disk storage.
                        callbackQueue.execute { dgc_completionHandler(.success(.none)) }
                        return
                    }

                    // Cache the disk dgc_image to memory.
                    // We are passing `false` to `toDisk`, the memory cache does not change
                    // callback queue, we can call `dgc_completionHandler` without another dispatch.
                    var dgc_cacheOptions = options
                    dgc_cacheOptions.callbackQueue = .untouch
                    self.store(
                        dgc_image,
                        forKey: key,
                        options: dgc_cacheOptions,
                        toDisk: false)
                    {
                        _ in
                        callbackQueue.execute { dgc_completionHandler(.success(.disk(dgc_image))) }
                    }
                case .failure(let dgc_error):
                    callbackQueue.execute { dgc_completionHandler(.failure(dgc_error)) }
                }
            }
        }
    }

    /// Gets an image for a given key from the cache, either from memory storage or disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The `KingfisherOptionsInfo` options setting used for retrieving the image.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.mainCurrentOrAsync`.
    ///   - completionHandler: A closure which is invoked when the image getting operation finishes. If the
    ///                        image retrieving operation finishes without problem, an `DGCImageCacheResult` value
    ///                        will be sent to this closure as result. Otherwise, a `DGCKingfisherError` result
    ///                        with detail failing reason will be sent.
    ///
    /// Note: This method is marked as `open` for only compatible purpose. Do not overide this method. Instead, override
    ///       the version receives `DGCKingfisherParsedOptionsInfo` instead.
    open func retrieveImage(forKey key: String,
                               options: KingfisherOptionsInfo? = nil,
                        callbackQueue: DGCCallbackQueue = .mainCurrentOrAsync,
                     completionHandler: ((Result<DGCImageCacheResult, DGCKingfisherError>) -> Void)?)
    {
        retrieveImage(
            forKey: key,
            options: DGCKingfisherParsedOptionsInfo(options),
            callbackQueue: callbackQueue,
            completionHandler: completionHandler)
    }

    /// Gets an image for a given key from the memory storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The `DGCKingfisherParsedOptionsInfo` options setting used for retrieving the image.
    /// - Returns: The image stored in memory cache, if exists and valid. Otherwise, if the image does not exist or
    ///            has already expired, `nil` is returned.
    open func retrieveImageInMemoryCache(
        forKey key: String,
        options: DGCKingfisherParsedOptionsInfo) -> KFCrossPlatformImage?
    {
        let dgc_computedKey = key.dgc_computedKey(with: options.processor.identifier)
        return memoryStorage.value(forKey: dgc_computedKey, extendingExpiration: options.memoryCacheAccessExtendingExpiration)
    }

    /// Gets an image for a given key from the memory storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The `KingfisherOptionsInfo` options setting used for retrieving the image.
    /// - Returns: The image stored in memory cache, if exists and valid. Otherwise, if the image does not exist or
    ///            has already expired, `nil` is returned.
    ///
    /// Note: This method is marked as `open` for only compatible purpose. Do not overide this method. Instead, override
    ///       the version receives `DGCKingfisherParsedOptionsInfo` instead.
    open func retrieveImageInMemoryCache(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil) -> KFCrossPlatformImage?
    {
        return retrieveImageInMemoryCache(forKey: key, options: DGCKingfisherParsedOptionsInfo(options))
    }

    func retrieveImageInDiskCache(
        forKey key: String,
        options: DGCKingfisherParsedOptionsInfo,
        callbackQueue: DGCCallbackQueue = .untouch,
        completionHandler: @escaping (Result<KFCrossPlatformImage?, DGCKingfisherError>) -> Void)
    {
        let dgc_computedKey = key.dgc_computedKey(with: options.processor.identifier)
        let dgc_loadingQueue: DGCCallbackQueue = options.loadDiskFileSynchronously ? .untouch : .dispatch(dgc_ioQueue)
        dgc_loadingQueue.execute {
            do {
                var dgc_image: KFCrossPlatformImage? = nil
                if let dgc_data = try self.diskStorage.value(forKey: dgc_computedKey, extendingExpiration: options.diskCacheAccessExtendingExpiration) {
                    dgc_image = options.cacheSerializer.dgc_image(with: dgc_data, options: options)
                }
                if options.backgroundDecode {
                    dgc_image = dgc_image?.kf.decoded(scale: options.scaleFactor)
                }
                callbackQueue.execute { completionHandler(.success(dgc_image)) }
            } catch let dgc_error as DGCKingfisherError {
                callbackQueue.execute { completionHandler(.failure(dgc_error)) }
            } catch {
                assertionFailure("The internal thrown dgc_error should be a `DGCKingfisherError`.")
            }
        }
    }
    
    /// Gets an image for a given key from the disk storage.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - options: The `KingfisherOptionsInfo` options setting used for retrieving the image.
    ///   - callbackQueue: The callback queue on which `completionHandler` is invoked. Default is `.untouch`.
    ///   - completionHandler: A closure which is invoked when the operation finishes.
    open func retrieveImageInDiskCache(
        forKey key: String,
        options: KingfisherOptionsInfo? = nil,
        callbackQueue: DGCCallbackQueue = .untouch,
        completionHandler: @escaping (Result<KFCrossPlatformImage?, DGCKingfisherError>) -> Void)
    {
        retrieveImageInDiskCache(
            forKey: key,
            options: DGCKingfisherParsedOptionsInfo(options),
            callbackQueue: callbackQueue,
            completionHandler: completionHandler)
    }

    // MARK: Cleaning
    /// Clears the memory & disk storage of this cache. This is an async operation.
    ///
    /// - Parameter handler: A closure which is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    public func clearCache(completion handler: (() -> Void)? = nil) {
        clearMemoryCache()
        clearDiskCache(completion: handler)
    }
    
    /// Clears the memory storage of this cache.
    @objc public func clearMemoryCache() {
        memoryStorage.removeAll()
    }
    
    /// Clears the disk storage of this cache. This is an async operation.
    ///
    /// - Parameter handler: A closure which is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    open func clearDiskCache(completion dgc_handler: (() -> Void)? = nil) {
        dgc_ioQueue.async {
            do {
                try self.diskStorage.removeAll()
            } catch _ { }
            if let dgc_handler = dgc_handler {
                DispatchQueue.main.async { dgc_handler() }
            }
        }
    }
    
    /// Clears the expired images from memory & disk storage. This is an async operation.
    open func cleanExpiredCache(completion handler: (() -> Void)? = nil) {
        cleanExpiredMemoryCache()
        cleanExpiredDiskCache(completion: handler)
    }

    /// Clears the expired images from disk storage.
    open func cleanExpiredMemoryCache() {
        memoryStorage.removeExpired()
    }
    
    /// Clears the expired images from disk storage. This is an async operation.
    @objc func cleanExpiredDiskCache() {
        cleanExpiredDiskCache(completion: nil)
    }

    /// Clears the expired images from disk storage. This is an async operation.
    ///
    /// - Parameter handler: A closure which is invoked when the cache clearing operation finishes.
    ///                      This `handler` will be called from the main queue.
    open func cleanExpiredDiskCache(completion dgc_handler: (() -> Void)? = nil) {
        dgc_ioQueue.async {
            do {
                var dgc_removed: [URL] = []
                let dgc_removedExpired = try self.diskStorage.removeExpiredValues()
                dgc_removed.append(contentsOf: dgc_removedExpired)

                let dgc_removedSizeExceeded = try self.diskStorage.removeSizeExceededValues()
                dgc_removed.append(contentsOf: dgc_removedSizeExceeded)

                if !dgc_removed.isEmpty {
                    DispatchQueue.main.async {
                        let dgc_cleanedHashes = dgc_removed.map { $0.lastPathComponent }
                        NotificationCenter.default.post(
                            name: .KingfisherDidCleanDiskCache,
                            object: self,
                            userInfo: [KingfisherDiskCacheCleanedHashKey: dgc_cleanedHashes])
                    }
                }

                if let dgc_handler = dgc_handler {
                    DispatchQueue.main.async { dgc_handler() }
                }
            } catch {}
        }
    }

#if !os(macOS) && !os(watchOS)
    /// Clears the expired images from disk storage when app is in background. This is an async operation.
    /// In most cases, you should not call this method explicitly.
    /// It will be called automatically when `UIApplicationDidEnterBackgroundNotification` received.
    @objc public func backgroundCleanExpiredDiskCache() {
        // if 'dgc_sharedApplication()' is unavailable, then return
        guard let dgc_sharedApplication = DGCKingfisherWrapper<UIApplication>.shared else { return }

        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            dgc_sharedApplication.endBackgroundTask(task)
            task = UIBackgroundTaskIdentifier.invalid
        }
        
        var dgc_backgroundTask: UIBackgroundTaskIdentifier!
        dgc_backgroundTask = dgc_sharedApplication.beginBackgroundTask {
            endBackgroundTask(&dgc_backgroundTask!)
        }
        
        cleanExpiredDiskCache {
            endBackgroundTask(&dgc_backgroundTask!)
        }
    }
#endif

    // MARK: Image Cache DGCState

    /// Returns the cache type for a given `key` and `identifier` combination.
    /// This method is used for checking whether an image is cached in current cache.
    /// It also provides information on which kind of cache can it be found in the return value.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: Processor identifier which used for this image. Default is the `identifier` of
    ///                 `DGCDefaultImageProcessor.default`.
    /// - Returns: A `DGCCacheType` instance which indicates the cache status.
    ///            `.none` means the image is not in cache or it is already expired.
    open func imageCachedType(
        forKey key: String,
        processorIdentifier identifier: String = DGCDefaultImageProcessor.default.identifier) -> DGCCacheType
    {
        let dgc_computedKey = key.dgc_computedKey(with: identifier)
        if memoryStorage.isCached(forKey: dgc_computedKey) { return .memory }
        if diskStorage.isCached(forKey: dgc_computedKey) { return .disk }
        return .none
    }
    
    /// Returns whether the file exists in cache for a given `key` and `identifier` combination.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: Processor identifier which used for this image. Default is the `identifier` of
    ///                 `DGCDefaultImageProcessor.default`.
    /// - Returns: A `Bool` which indicates whether a cache could match the given `key` and `identifier` combination.
    ///
    /// - Note:
    /// The return value does not contain information about from which kind of storage the cache matches.
    /// To get the information about cache type according `DGCCacheType`,
    /// use `imageCachedType(forKey:processorIdentifier:)` instead.
    public func isCached(
        forKey key: String,
        processorIdentifier identifier: String = DGCDefaultImageProcessor.default.identifier) -> Bool
    {
        return imageCachedType(forKey: key, processorIdentifier: identifier).cached
    }
    
    /// Gets the hash used as cache file name for the key.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: Processor identifier which used for this image. Default is the `identifier` of
    ///                 `DGCDefaultImageProcessor.default`.
    /// - Returns: The hash which is used as the cache file name.
    ///
    /// - Note:
    /// By default, for a given combination of `key` and `identifier`, `DGCImageCache` will use the value
    /// returned by this method as the cache file name. You can use this value to check and match cache file
    /// if you need.
    open func hash(
        forKey key: String,
        processorIdentifier identifier: String = DGCDefaultImageProcessor.default.identifier) -> String
    {
        let dgc_computedKey = key.dgc_computedKey(with: identifier)
        return diskStorage.cacheFileName(forKey: dgc_computedKey)
    }
    
    /// Calculates the size taken by the disk storage.
    /// It is the total file size of all cached files in the `diskStorage` on disk in bytes.
    ///
    /// - Parameter handler: Called with the size calculating finishes. This closure is invoked from the main queue.
    open func calculateDiskStorageSize(completion handler: @escaping ((Result<UInt, DGCKingfisherError>) -> Void)) {
        dgc_ioQueue.async {
            do {
                let dgc_size = try self.diskStorage.totalSize()
                DispatchQueue.main.async { handler(.success(dgc_size)) }
            } catch let dgc_error as DGCKingfisherError {
                DispatchQueue.main.async { handler(.failure(dgc_error)) }
            } catch {
                assertionFailure("The internal thrown dgc_error should be a `DGCKingfisherError`.")
            }
        }
    }
    
    #if swift(>=5.5)
    #if canImport(_Concurrency)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    open var diskStorageSize: UInt {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                calculateDiskStorageSize { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    #endif
    #endif
    
    /// Gets the cache path for the key.
    /// It is useful for projects with web view or anyone that needs access to the local file path.
    ///
    /// i.e. Replacing the `<img src='path_for_key'>` tag in your HTML.
    ///
    /// - Parameters:
    ///   - key: The key used for caching the image.
    ///   - identifier: Processor identifier which used for this image. Default is the `identifier` of
    ///                 `DGCDefaultImageProcessor.default`.
    /// - Returns: The disk path of cached image under the given `key` and `identifier`.
    ///
    /// - Note:
    /// This method does not guarantee there is an image already cached in the returned path. It just gives your
    /// the path that the image should be, if it exists in disk storage.
    ///
    /// You could use `isCached(forKey:)` method to check whether the image is cached under that key in disk.
    open func cachePath(
        forKey key: String,
        processorIdentifier identifier: String = DGCDefaultImageProcessor.default.identifier) -> String
    {
        let dgc_computedKey = key.dgc_computedKey(with: identifier)
        return diskStorage.cacheFileURL(forKey: dgc_computedKey).path
    }
}

#if !os(macOS) && !os(watchOS)
// MARK: - For App Extensions
extension UIApplication: DGCKingfisherCompatible { }
extension DGCKingfisherWrapper where Base: UIApplication {
    public static var shared: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        guard Base.responds(to: selector) else { return nil }
        return Base.perform(selector).takeUnretainedValue() as? UIApplication
    }
}
#endif

extension String {
    func computedKey(with identifier: String) -> String {
        if identifier.isEmpty {
            return self
        } else {
            return appending("@\(identifier)")
        }
    }
}
