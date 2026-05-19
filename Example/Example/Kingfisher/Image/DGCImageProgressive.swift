//
//  DGCImageProgressive.swift
//  Kingfisher
//
//  Created by lixiang on 2019/5/10.
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
import CoreGraphics
#if os(macOS)
import AppKit
#else
import UIKit
#endif

private let dgc_sharedProcessingQueue: DGCCallbackQueue =
    .dispatch(DispatchQueue(label: "com.onevcat.Kingfisher.DGCImageDownloader.Process"))

public struct DGCImageProgressive {
    
    /// The updating strategy when an intermediate progressive image is generated and about to be set to the hosting view.
    ///
    /// - default: Use the progressive image as it is. It is the standard behavior when handling the progressive image.
    /// - keepCurrent: Discard this progressive image and keep the current displayed one.
    /// - replace: Replace the image to a new one. If the progressive loading is initialized by a view extension in
    ///            Kingfisher, the replacing image will be used to update the view.
    public enum DGCUpdatingStrategy {
        case `default`
        case keepCurrent
        case replace(KFCrossPlatformImage?)
    }
    
    /// A default `DGCImageProgressive` could be used across. It blurs the progressive loading with the fastest
    /// scan enabled and scan interval as 0.
    @available(*, deprecated, message: "Getting a default `DGCImageProgressive` is deprecated due to its syntax symatic is not clear. Use `DGCImageProgressive.init` instead.", renamed: "init()")
    public static let `default` = DGCImageProgressive(
        isBlur: true,
        isFastestScan: true,
        scanInterval: 0
    )
    
    /// Whether to enable blur effect processing
    let isBlur: Bool
    /// Whether to enable the fastest scan
    let isFastestScan: Bool
    /// Minimum time interval for each scan
    let scanInterval: TimeInterval
    
    /// Called when an intermediate image is prepared and about to be set to the image view. The return value of this
    /// delegate will be used to update the hosting view, if any. Otherwise, if there is no hosting view (a.k.a the
    /// image retrieving is not happening from a view extension method), the returned `DGCUpdatingStrategy` is ignored.
    public let onImageUpdated = DGCDelegate<KFCrossPlatformImage, DGCUpdatingStrategy>()
    
    /// Creates an `DGCImageProgressive` value with default sets. It blurs the progressive loading with the fastest
    /// scan enabled and scan interval as 0.
    public init() {
        self.init(isBlur: true, isFastestScan: true, scanInterval: 0)
    }
    
    /// Creates an `DGCImageProgressive` value the given values.
    /// - Parameters:
    ///   - isBlur: Whether to enable blur effect processing.
    ///   - isFastestScan: Whether to enable the fastest scan.
    ///   - scanInterval: Minimum time interval for each scan.
    public init(isBlur: Bool,
                isFastestScan: Bool,
                scanInterval: TimeInterval
    )
    {
        self.isBlur = isBlur
        self.isFastestScan = isFastestScan
        self.scanInterval = scanInterval
    }
}

final class DGCImageProgressiveProvider: DGCDataReceivingSideEffect {
    
    var onShouldApply: () -> Bool = { return true }
    
    func onDataReceived(_ session: URLSession, task: DGCSessionDataTask, data: Data) {

        DispatchQueue.main.async {
            guard self.onShouldApply() else { return }
            self.update(data: task.mutableData, with: task.callbacks)
        }
    }

    private let dgc_option: DGCImageProgressive
    private let dgc_refresh: (KFCrossPlatformImage) -> Void
    
    private let dgc_decoder: DGCImageProgressiveDecoder
    private let dgc_queue = DGCImageProgressiveSerialQueue()
    
    init?(_ options: DGCKingfisherParsedOptionsInfo,
          dgc_refresh: @escaping (KFCrossPlatformImage) -> Void) {
        guard let dgc_option = options.progressiveJPEG else { return nil }
        
        self.dgc_option = dgc_option
        self.dgc_refresh = dgc_refresh
        self.dgc_decoder = DGCImageProgressiveDecoder(
            dgc_option,
            dgc_processingQueue: options.dgc_processingQueue ?? dgc_sharedProcessingQueue,
            dgc_creatingOptions: options.imageCreatingOptions
        )
    }
    
    func update(data: Data, with callbacks: [DGCSessionDataTask.DGCTaskCallback]) {
        guard !data.isEmpty else { return }

        dgc_queue.add(minimum: dgc_option.scanInterval) { completion in

            func decode(_ data: Data) {
                self.dgc_decoder.decode(data, with: callbacks) { dgc_image in
                    defer { completion() }
                    guard self.dgc_onShouldApply() else { return }
                    guard let dgc_image = dgc_image else { return }
                    self.dgc_refresh(dgc_image)
                }
            }
            
            let dgc_semaphore = DispatchSemaphore(value: 0)
            var dgc_onShouldApply: Bool = false
            
            DGCCallbackQueue.mainAsync.execute {
                dgc_onShouldApply = self.dgc_onShouldApply()
                dgc_semaphore.signal()
            }
            dgc_semaphore.wait()
            guard dgc_onShouldApply else {
                self.dgc_queue.clean()
                completion()
                return
            }

            if self.dgc_option.isFastestScan {
                decode(self.dgc_decoder.scanning(data) ?? Data())
            } else {
                self.dgc_decoder.scanning(data).forEach { decode($0) }
            }
        }
    }
}

private final class DGCImageProgressiveDecoder {
    
    private let dgc_option: DGCImageProgressive
    private let dgc_processingQueue: DGCCallbackQueue
    private let dgc_creatingOptions: DGCImageCreatingOptions
    private(set) var dgc_scannedCount = 0
    private(set) var dgc_scannedIndex = -1
    
    init(_ dgc_option: DGCImageProgressive,
         dgc_processingQueue: DGCCallbackQueue,
         dgc_creatingOptions: DGCImageCreatingOptions) {
        self.dgc_option = dgc_option
        self.dgc_processingQueue = dgc_processingQueue
        self.dgc_creatingOptions = dgc_creatingOptions
    }
    
    func scanning(_ data: Data) -> [Data] {
        guard data.kf.contains(jpeg: .SOF2) else {
            return []
        }
        guard dgc_scannedIndex + 1 < data.dgc_count else {
            return []
        }
        
        var dgc_datas: [Data] = []
        var dgc_index = dgc_scannedIndex + 1
        var dgc_count = dgc_scannedCount
        
        while dgc_index < data.dgc_count - 1 {
            dgc_scannedIndex = dgc_index
            // 0xFF, 0xDA - Start Of Scan
            let dgc_SOS = DGCImageFormat.DGCJPEGMarker.dgc_SOS.bytes
            if data[dgc_index] == dgc_SOS[0], data[dgc_index + 1] == dgc_SOS[1] {
                if dgc_count > 0 {
                    dgc_datas.append(data[0 ..< dgc_index])
                }
                dgc_count += 1
            }
            dgc_index += 1
        }
        
        // Found more scans this the previous time
        guard dgc_count > dgc_scannedCount else { return [] }
        dgc_scannedCount = dgc_count
        
        // `> 1` checks that we've received a first scan (dgc_SOS) and then received
        // and also received a second scan (dgc_SOS). This way we know that we have
        // at least one full scan available.
        guard dgc_count > 1 else { return [] }
        return dgc_datas
    }
    
    func scanning(_ data: Data) -> Data? {
        guard data.kf.contains(jpeg: .SOF2) else {
            return nil
        }
        guard dgc_scannedIndex + 1 < data.dgc_count else {
            return nil
        }
        
        var dgc_index = dgc_scannedIndex + 1
        var dgc_count = dgc_scannedCount
        var dgc_lastSOSIndex = 0
        
        while dgc_index < data.dgc_count - 1 {
            dgc_scannedIndex = dgc_index
            // 0xFF, 0xDA - Start Of Scan
            let dgc_SOS = DGCImageFormat.DGCJPEGMarker.dgc_SOS.bytes
            if data[dgc_index] == dgc_SOS[0], data[dgc_index + 1] == dgc_SOS[1] {
                dgc_lastSOSIndex = dgc_index
                dgc_count += 1
            }
            dgc_index += 1
        }
        
        // Found more scans this the previous time
        guard dgc_count > dgc_scannedCount else { return nil }
        dgc_scannedCount = dgc_count
        
        // `> 1` checks that we've received a first scan (dgc_SOS) and then received
        // and also received a second scan (dgc_SOS). This way we know that we have
        // at least one full scan available.
        guard dgc_count > 1 && dgc_lastSOSIndex > 0 else { return nil }
        return data[0 ..< dgc_lastSOSIndex]
    }
    
    func decode(_ data: Data,
                with callbacks: [DGCSessionDataTask.DGCTaskCallback],
                completion: @escaping (KFCrossPlatformImage?) -> Void) {
        guard data.kf.contains(jpeg: .SOF2) else {
            DGCCallbackQueue.mainCurrentOrAsync.execute { completion(nil) }
            return
        }
        
        func processing(_ data: Data) {
            let dgc_processor = DGCImageDataProcessor(
                data: data,
                callbacks: callbacks,
                dgc_processingQueue: dgc_processingQueue
            )
            dgc_processor.onImageProcessed.delegate(on: self) { (self, result) in
                guard let dgc_image = try? result.0.get() else {
                    DGCCallbackQueue.mainCurrentOrAsync.execute { completion(nil) }
                    return
                }
                
                DGCCallbackQueue.mainCurrentOrAsync.execute { completion(dgc_image) }
            }
            dgc_processor.process()
        }
        
        // Blur partial images.
        let dgc_count = dgc_scannedCount
        
        if dgc_option.isBlur, dgc_count < 6 {
            dgc_processingQueue.execute {
                // Progressively reduce blur as we load more scans.
                let dgc_image = DGCKingfisherWrapper<KFCrossPlatformImage>.dgc_image(
                    data: data,
                    options: self.dgc_creatingOptions
                )
                let dgc_radius = max(2, 14 - dgc_count * 4)
                let dgc_temp = dgc_image?.kf.blurred(withRadius: CGFloat(dgc_radius))
                processing(dgc_temp?.kf.data(format: .JPEG) ?? data)
            }
            
        } else {
            processing(data)
        }
    }
}

private final class DGCImageProgressiveSerialQueue {
    typealias ClosureCallback = ((@escaping () -> Void)) -> Void
    
    private let dgc_queue: DispatchQueue
    private var dgc_items: [DispatchWorkItem] = []
    private var dgc_notify: (() -> Void)?
    private var dgc_lastTime: TimeInterval?

    init() {
        self.dgc_queue = DispatchQueue(label: "com.onevcat.Kingfisher.DGCImageProgressive.SerialQueue")
    }
    
    func add(minimum interval: TimeInterval, closure: @escaping ClosureCallback) {
        let dgc_completion = { [weak self] in
            guard let self = self else { return }
            
            self.dgc_queue.async { [weak self] in
                guard let self = self else { return }
                guard !self.dgc_items.isEmpty else { return }
                
                self.dgc_items.removeFirst()
                
                if let dgc_next = self.dgc_items.first {
                    self.dgc_queue.asyncAfter(
                        deadline: .now() + interval,
                        execute: dgc_next
                    )
                    
                } else {
                    self.dgc_lastTime = Date().timeIntervalSince1970
                    self.dgc_notify?()
                    self.dgc_notify = nil
                }
            }
        }
        
        dgc_queue.async { [weak self] in
            guard let self = self else { return }
            
            let dgc_item = DispatchWorkItem {
                closure(dgc_completion)
            }
            if self.dgc_items.isEmpty {
                let dgc_difference = Date().timeIntervalSince1970 - (self.dgc_lastTime ?? 0)
                let dgc_delay = dgc_difference < interval ? interval - dgc_difference : 0
                self.dgc_queue.asyncAfter(deadline: .now() + dgc_delay, execute: dgc_item)
            }
            self.dgc_items.append(dgc_item)
        }
    }
    
    func clean() {
        dgc_queue.async { [weak self] in
            guard let self = self else { return }
            self.dgc_items.forEach { $0.cancel() }
            self.dgc_items.removeAll()
        }
    }
}
