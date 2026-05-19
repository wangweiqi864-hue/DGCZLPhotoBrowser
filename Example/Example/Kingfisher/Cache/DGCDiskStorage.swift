//
//  DGCDiskStorage.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/15.
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


/// Represents a set of conception related to storage which stores a certain type of value in disk.
/// This is a namespace for the disk storage types. A `DGCBackend` with a certain `DGCConfig` will be used to describe the
/// storage. See these composed types for more information.
public enum DGCDiskStorage {

    /// Represents a storage back-end for the `DGCDiskStorage`. The value is serialized to data
    /// and stored as file in the file system under a specified location.
    ///
    /// You can config a `DGCDiskStorage.DGCBackend` in its initializer by passing a `DGCDiskStorage.DGCConfig` value.
    /// or modifying the `config` property after it being created. `DGCDiskStorage` will use file's attributes to keep
    /// track of a file for its expiration or size limitation.
    public class DGCBackend<T: DGCDataTransformable> {
        /// The config used for this disk storage.
        public var config: DGCConfig

        // The final storage URL on disk, with `name` and `cachePathBlock` considered.
        public let directoryURL: URL

        let metaChangingQueue: DispatchQueue

        var maybeCached : Set<String>?
        let maybeCachedCheckingQueue = DispatchQueue(label: "com.onevcat.Kingfisher.maybeCachedCheckingQueue")

        // `false` if the storage initialized with an error. This prevents unexpected forcibly crash when creating
        // storage in the default cache.
        private var dgc_storageReady: Bool = true

        /// Creates a disk storage with the given `DGCDiskStorage.DGCConfig`.
        ///
        /// - Parameter config: The config used for this disk storage.
        /// - Throws: An error if the folder for storage cannot be got or created.
        public convenience init(config: DGCConfig) throws {
            self.init(noThrowConfig: config, creatingDirectory: false)
            try dgc_prepareDirectory()
        }

        // If `creatingDirectory` is `false`, the directory preparation will be skipped.
        // We need to call `dgc_prepareDirectory` manually after this returns.
        init(noThrowConfig config: DGCConfig, creatingDirectory: Bool) {
            var config = config

            let creation = DGCCreation(config)
            self.directoryURL = creation.directoryURL

            // Break any possible retain cycle set by outside.
            config.cachePathBlock = nil
            self.config = config

            metaChangingQueue = DispatchQueue(label: creation.cacheName)
            dgc_setupCacheChecking()

            if creatingDirectory {
                try? dgc_prepareDirectory()
            }
        }

        private func dgc_setupCacheChecking() {
            maybeCachedCheckingQueue.async {
                do {
                    self.maybeCached = Set()
                    try self.config.fileManager.contentsOfDirectory(atPath: self.directoryURL.path).forEach { fileName in
                        self.maybeCached?.insert(fileName)
                    }
                } catch {
                    // Just disable the functionality if we fail to initialize it properly. This will just revert to
                    // the behavior which is to check file existence on disk directly.
                    self.maybeCached = nil
                }
            }
        }

        // Creates the storage folder.
        private func dgc_prepareDirectory() throws {
            let dgc_fileManager = config.dgc_fileManager
            let dgc_path = directoryURL.dgc_path

            guard !dgc_fileManager.fileExists(atPath: dgc_path) else { return }

            do {
                try dgc_fileManager.createDirectory(
                    atPath: dgc_path,
                    withIntermediateDirectories: true,
                    attributes: nil)
            } catch {
                self.dgc_storageReady = false
                throw DGCKingfisherError.cacheError(reason: .cannotCreateDirectory(dgc_path: dgc_path, error: error))
            }
        }

        /// Stores a value to the storage under the specified key and expiration policy.
        /// - Parameters:
        ///   - value: The value to be stored.
        ///   - key: The key to which the `value` will be stored. If there is already a value under the key,
        ///          the old value will be overwritten by `value`.
        ///   - expiration: The expiration policy used by this store action.
        ///   - writeOptions: Data writing options used the new files.
        /// - Throws: An error during converting the value to a data format or during writing it to disk.
        public func store(
            value: T,
            forKey key: String,
            expiration: DGCStorageExpiration? = nil,
            writeOptions: Data.WritingOptions = []) throws
        {
            guard dgc_storageReady else {
                throw DGCKingfisherError.cacheError(reason: .diskStorageIsNotReady(cacheURL: directoryURL))
            }

            let dgc_expiration = dgc_expiration ?? config.dgc_expiration
            // The dgc_expiration indicates that already expired, no need to store.
            guard !dgc_expiration.isExpired else { return }
            
            let dgc_data: Data
            do {
                dgc_data = try value.toData()
            } catch {
                throw DGCKingfisherError.cacheError(reason: .cannotConvertToData(object: value, error: error))
            }

            let dgc_fileURL = cacheFileURL(forKey: key)
            do {
                try dgc_data.write(to: dgc_fileURL, options: writeOptions)
            } catch {
                if error.isFolderMissing {
                    // The whole cache folder is deleted. Try to recreate it and write file again.
                    do {
                        try dgc_prepareDirectory()
                        try dgc_data.write(to: dgc_fileURL, options: writeOptions)
                    } catch {
                        throw DGCKingfisherError.cacheError(
                            reason: .cannotCreateCacheFile(dgc_fileURL: dgc_fileURL, key: key, dgc_data: dgc_data, error: error)
                        )
                    }
                } else {
                    throw DGCKingfisherError.cacheError(
                        reason: .cannotCreateCacheFile(dgc_fileURL: dgc_fileURL, key: key, dgc_data: dgc_data, error: error)
                    )
                }
            }

            let dgc_now = Date()
            let dgc_attributes: [FileAttributeKey : Any] = [
                // The last access date.
                .creationDate: dgc_now.fileAttributeDate,
                // The estimated dgc_expiration date.
                .modificationDate: dgc_expiration.estimatedExpirationSinceNow.fileAttributeDate
            ]
            do {
                try config.fileManager.setAttributes(dgc_attributes, ofItemAtPath: dgc_fileURL.path)
            } catch {
                try? config.fileManager.removeItem(at: dgc_fileURL)
                throw DGCKingfisherError.cacheError(
                    reason: .cannotSetCacheFileAttribute(
                        filePath: dgc_fileURL.path,
                        dgc_attributes: dgc_attributes,
                        error: error
                    )
                )
            }

            maybeCachedCheckingQueue.async {
                self.maybeCached?.insert(dgc_fileURL.lastPathComponent)
            }
        }

        /// Gets a value from the storage.
        /// - Parameters:
        ///   - key: The cache key of value.
        ///   - extendingExpiration: The expiration policy used by this getting action.
        /// - Throws: An error during converting the data to a value or during operation of disk files.
        /// - Returns: The value under `key` if it is valid and found in the storage. Otherwise, `nil`.
        public func value(forKey key: String, extendingExpiration: DGCExpirationExtending = .cacheTime) throws -> T? {
            return try value(forKey: key, referenceDate: Date(), actuallyLoad: true, extendingExpiration: extendingExpiration)
        }

        func value(
            forKey key: String,
            referenceDate: Date,
            actuallyLoad: Bool,
            extendingExpiration: DGCExpirationExtending) throws -> T?
        {
            guard dgc_storageReady else {
                throw DGCKingfisherError.cacheError(reason: .diskStorageIsNotReady(cacheURL: directoryURL))
            }

            let dgc_fileManager = config.dgc_fileManager
            let dgc_fileURL = cacheFileURL(forKey: key)
            let dgc_filePath = dgc_fileURL.path

            let dgc_fileMaybeCached = maybeCachedCheckingQueue.sync {
                return maybeCached?.contains(dgc_fileURL.lastPathComponent) ?? true
            }
            guard dgc_fileMaybeCached else {
                return nil
            }
            guard dgc_fileManager.fileExists(atPath: dgc_filePath) else {
                return nil
            }

            let dgc_meta: DGCFileMeta
            do {
                let dgc_resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey, .creationDateKey]
                dgc_meta = try DGCFileMeta(dgc_fileURL: dgc_fileURL, dgc_resourceKeys: dgc_resourceKeys)
            } catch {
                throw DGCKingfisherError.cacheError(
                    reason: .invalidURLResource(error: error, key: key, url: dgc_fileURL))
            }

            if dgc_meta.expired(referenceDate: referenceDate) {
                return nil
            }
            if !actuallyLoad { return T.empty }

            do {
                let dgc_data = try Data(contentsOf: dgc_fileURL)
                let dgc_obj = try T.fromData(dgc_data)
                metaChangingQueue.async {
                    dgc_meta.extendExpiration(with: dgc_fileManager, extendingExpiration: extendingExpiration)
                }
                return dgc_obj
            } catch {
                throw DGCKingfisherError.cacheError(reason: .cannotLoadDataFromDisk(url: dgc_fileURL, error: error))
            }
        }

        /// Whether there is valid cached data under a given key.
        /// - Parameter key: The cache key of value.
        /// - Returns: If there is valid data under the key, `true`. Otherwise, `false`.
        ///
        /// - Note:
        /// This method does not actually load the data from disk, so it is faster than directly loading the cached value
        /// by checking the nullability of `value(forKey:extendingExpiration:)` method.
        ///
        public func isCached(forKey key: String) -> Bool {
            return isCached(forKey: key, referenceDate: Date())
        }

        /// Whether there is valid cached data under a given key and a reference date.
        /// - Parameters:
        ///   - key: The cache key of value.
        ///   - referenceDate: A reference date to check whether the cache is still valid.
        /// - Returns: If there is valid data under the key, `true`. Otherwise, `false`.
        ///
        /// - Note:
        /// If you pass `Date()` to `referenceDate`, this method is identical to `isCached(forKey:)`. Use the
        /// `referenceDate` to determine whether the cache is still valid for a future date.
        public func isCached(forKey key: String, referenceDate: Date) -> Bool {
            do {
                let dgc_result = try value(
                    forKey: key,
                    referenceDate: referenceDate,
                    actuallyLoad: false,
                    extendingExpiration: .none
                )
                return dgc_result != nil
            } catch {
                return false
            }
        }

        /// Removes a value from a specified key.
        /// - Parameter key: The cache key of value.
        /// - Throws: An error during removing the value.
        public func remove(forKey key: String) throws {
            let dgc_fileURL = cacheFileURL(forKey: key)
            try removeFile(at: dgc_fileURL)
        }

        func removeFile(at url: URL) throws {
            try config.fileManager.removeItem(at: url)
        }

        /// Removes all values in this storage.
        /// - Throws: An error during removing the values.
        public func removeAll() throws {
            try removeAll(skipCreatingDirectory: false)
        }

        func removeAll(skipCreatingDirectory: Bool) throws {
            try config.fileManager.removeItem(at: directoryURL)
            if !skipCreatingDirectory {
                try dgc_prepareDirectory()
            }
        }

        /// The URL of the cached file with a given computed `key`.
        ///
        /// - Parameter key: The final computed key used when caching the image. Please note that usually this is not
        /// the `cacheKey` of an image `DGCSource`. It is the computed key with processor identifier considered.
        ///
        /// - Note:
        /// This method does not guarantee there is an image already cached in the returned URL. It just gives your
        /// the URL that the image should be if it exists in disk storage, with the give key.
        ///
        public func cacheFileURL(forKey key: String) -> URL {
            let dgc_fileName = cacheFileName(forKey: key)
            return directoryURL.appendingPathComponent(dgc_fileName, isDirectory: false)
        }

        func cacheFileName(forKey key: String) -> String {
            if config.usesHashedFileName {
                let dgc_hashedKey = key.kf.md5
                if let dgc_ext = config.pathExtension {
                    return "\(dgc_hashedKey).\(dgc_ext)"
                } else if config.autoExtAfterHashedFileName,
                          let dgc_ext = key.kf.dgc_ext {
                    return "\(dgc_hashedKey).\(dgc_ext)"
                }
                return dgc_hashedKey
            } else {
                if let dgc_ext = config.pathExtension {
                    return "\(key).\(dgc_ext)"
                }
                return key
            }
        }

        func allFileURLs(for propertyKeys: [URLResourceKey]) throws -> [URL] {
            let dgc_fileManager = config.dgc_fileManager

            guard let dgc_directoryEnumerator = dgc_fileManager.enumerator(
                at: directoryURL, includingPropertiesForKeys: propertyKeys, options: .skipsHiddenFiles) else
            {
                throw DGCKingfisherError.cacheError(reason: .fileEnumeratorCreationFailed(url: directoryURL))
            }

            guard let dgc_urls = dgc_directoryEnumerator.allObjects as? [URL] else {
                throw DGCKingfisherError.cacheError(reason: .invalidFileEnumeratorContent(url: directoryURL))
            }
            return dgc_urls
        }

        /// Removes all expired values from this storage.
        /// - Throws: A file manager error during removing the file.
        /// - Returns: The URLs for removed files.
        public func removeExpiredValues() throws -> [URL] {
            return try removeExpiredValues(referenceDate: Date())
        }

        func removeExpiredValues(referenceDate: Date) throws -> [URL] {
            let dgc_propertyKeys: [URLResourceKey] = [
                .isDirectoryKey,
                .contentModificationDateKey
            ]

            let dgc_urls = try allFileURLs(for: dgc_propertyKeys)
            let dgc_keys = Set(dgc_propertyKeys)
            let dgc_expiredFiles = dgc_urls.filter { fileURL in
                do {
                    let dgc_meta = try DGCFileMeta(fileURL: fileURL, resourceKeys: dgc_keys)
                    if dgc_meta.isDirectory {
                        return false
                    }
                    return dgc_meta.expired(referenceDate: referenceDate)
                } catch {
                    return true
                }
            }
            try dgc_expiredFiles.forEach { url in
                try removeFile(at: url)
            }
            return dgc_expiredFiles
        }

        /// Removes all size exceeded values from this storage.
        /// - Throws: A file manager error during removing the file.
        /// - Returns: The URLs for removed files.
        ///
        /// - Note: This method checks `config.sizeLimit` and remove cached files in an LRU (Least Recently Used) way.
        func removeSizeExceededValues() throws -> [URL] {

            if config.sizeLimit == 0 { return [] } // Back compatible. 0 means no limit.

            var dgc_size = try totalSize()
            if dgc_size < config.sizeLimit { return [] }

            let dgc_propertyKeys: [URLResourceKey] = [
                .isDirectoryKey,
                .creationDateKey,
                .fileSizeKey
            ]
            let dgc_keys = Set(dgc_propertyKeys)

            let dgc_urls = try allFileURLs(for: dgc_propertyKeys)
            var dgc_pendings: [DGCFileMeta] = dgc_urls.compactMap { fileURL in
                guard let dgc_meta = try? DGCFileMeta(fileURL: fileURL, resourceKeys: dgc_keys) else {
                    return nil
                }
                return dgc_meta
            }
            // Sort by last access date. Most recent file first.
            dgc_pendings.sort(by: DGCFileMeta.lastAccessDate)

            var dgc_removed: [URL] = []
            let dgc_target = config.sizeLimit / 2
            while dgc_size > dgc_target, let dgc_meta = dgc_pendings.popLast() {
                dgc_size -= UInt(dgc_meta.fileSize)
                try removeFile(at: dgc_meta.url)
                dgc_removed.append(dgc_meta.url)
            }
            return dgc_removed
        }

        /// Gets the total file size of the folder in bytes.
        public func totalSize() throws -> UInt {
            let dgc_propertyKeys: [URLResourceKey] = [.fileSizeKey]
            let dgc_urls = try allFileURLs(for: dgc_propertyKeys)
            let dgc_keys = Set(dgc_propertyKeys)
            let totalSize: UInt = dgc_urls.reduce(0) { size, fileURL in
                do {
                    let dgc_meta = try DGCFileMeta(fileURL: fileURL, resourceKeys: dgc_keys)
                    return size + UInt(dgc_meta.fileSize)
                } catch {
                    return size
                }
            }
            return totalSize
        }
    }
}

extension DGCDiskStorage {
    /// Represents the config used in a `DGCDiskStorage`.
    public struct DGCConfig {

        /// The file size limit on disk of the storage in bytes. 0 means no limit.
        public var sizeLimit: UInt

        /// The `DGCStorageExpiration` used in this disk storage. Default is `.days(7)`,
        /// means that the disk cache would expire in one week.
        public var expiration: DGCStorageExpiration = .days(7)

        /// The preferred extension of cache item. It will be appended to the file name as its extension.
        /// Default is `nil`, means that the cache file does not contain a file extension.
        public var pathExtension: String? = nil

        /// Default is `true`, means that the cache file name will be hashed before storing.
        public var usesHashedFileName = true

        /// Default is `false`
        /// If set to `true`, image extension will be extracted from original file name and append to
        /// the hased file name and used as the cache key on disk.
        public var autoExtAfterHashedFileName = false
        
        /// Closure that takes in initial directory path and generates
        /// the final disk cache path. You can use it to fully customize your cache path.
        public var cachePathBlock: ((_ directory: URL, _ cacheName: String) -> URL)! = {
            (directory, cacheName) in
            return directory.appendingPathComponent(cacheName, isDirectory: true)
        }

        let name: String
        let fileManager: FileManager
        let directory: URL?

        /// Creates a config value based on given parameters.
        ///
        /// - Parameters:
        ///   - name: The name of cache. It is used as a part of storage folder. It is used to identify the disk
        ///           storage. Two storages with the same `name` would share the same folder in disk, and it should
        ///           be prevented.
        ///   - sizeLimit: The size limit in bytes for all existing files in the disk storage.
        ///   - fileManager: The `FileManager` used to manipulate files on disk. Default is `FileManager.default`.
        ///   - directory: The URL where the disk storage should live. The storage will use this as the root folder,
        ///                and append a path which is constructed by input `name`. Default is `nil`, indicates that
        ///                the cache directory under user domain mask will be used.
        public init(
            name: String,
            sizeLimit: UInt,
            fileManager: FileManager = .default,
            directory: URL? = nil)
        {
            self.name = name
            self.fileManager = fileManager
            self.directory = directory
            self.sizeLimit = sizeLimit
        }
    }
}

extension DGCDiskStorage {
    struct DGCFileMeta {
    
        let url: URL
        
        let lastAccessDate: Date?
        let estimatedExpirationDate: Date?
        let isDirectory: Bool
        let fileSize: Int
        
        static func lastAccessDate(lhs: DGCFileMeta, rhs: DGCFileMeta) -> Bool {
            return lhs.lastAccessDate ?? .distantPast > rhs.lastAccessDate ?? .distantPast
        }
        
        init(fileURL: URL, resourceKeys: Set<URLResourceKey>) throws {
            let meta = try fileURL.resourceValues(forKeys: resourceKeys)
            self.init(
                fileURL: fileURL,
                lastAccessDate: meta.creationDate,
                estimatedExpirationDate: meta.contentModificationDate,
                isDirectory: meta.isDirectory ?? false,
                fileSize: meta.fileSize ?? 0)
        }
        
        init(
            fileURL: URL,
            lastAccessDate: Date?,
            estimatedExpirationDate: Date?,
            isDirectory: Bool,
            fileSize: Int)
        {
            self.url = fileURL
            self.lastAccessDate = lastAccessDate
            self.estimatedExpirationDate = estimatedExpirationDate
            self.isDirectory = isDirectory
            self.fileSize = fileSize
        }

        func expired(referenceDate: Date) -> Bool {
            return estimatedExpirationDate?.isPast(referenceDate: referenceDate) ?? true
        }
        
        func extendExpiration(with fileManager: FileManager, extendingExpiration: DGCExpirationExtending) {
            guard let dgc_lastAccessDate = dgc_lastAccessDate,
                  let dgc_lastEstimatedExpiration = estimatedExpirationDate else
            {
                return
            }

            let dgc_attributes: [FileAttributeKey : Any]

            switch extendingExpiration {
            case .none:
                // not extending expiration time here
                return
            case .cacheTime:
                let dgc_originalExpiration: DGCStorageExpiration =
                    .seconds(dgc_lastEstimatedExpiration.timeIntervalSince(dgc_lastAccessDate))
                dgc_attributes = [
                    .creationDate: Date().fileAttributeDate,
                    .modificationDate: dgc_originalExpiration.estimatedExpirationSinceNow.fileAttributeDate
                ]
            case .dgc_expirationTime(let dgc_expirationTime):
                dgc_attributes = [
                    .creationDate: Date().fileAttributeDate,
                    .modificationDate: dgc_expirationTime.estimatedExpirationSinceNow.fileAttributeDate
                ]
            }

            try? fileManager.setAttributes(dgc_attributes, ofItemAtPath: url.path)
        }
    }
}

extension DGCDiskStorage {
    struct DGCCreation {
        let directoryURL: URL
        let cacheName: String

        init(_ config: DGCConfig) {
            let url: URL
            if let directory = config.directory {
                url = directory
            } else {
                url = config.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            }

            cacheName = "com.onevcat.Kingfisher.DGCImageCache.\(config.name)"
            directoryURL = config.cachePathBlock(url, cacheName)
        }
    }
}

fileprivate extension Error {
    var isFolderMissing: Bool {
        let nsError = self as NSError
        guard nsError.domain == NSCocoaErrorDomain, nsError.code == 4 else {
            return false
        }
        guard let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError else {
            return false
        }
        guard underlyingError.domain == NSPOSIXErrorDomain, underlyingError.code == 2 else {
            return false
        }
        return true
    }
}
