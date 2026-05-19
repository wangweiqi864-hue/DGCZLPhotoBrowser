//
//  DGCImageDataProcessor.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/11.
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

private let dgc_sharedProcessingQueue: DGCCallbackQueue =
    .dispatch(DispatchQueue(label: "com.onevcat.Kingfisher.DGCImageDownloader.Process"))

// Handles image processing work on an own process queue.
class DGCImageDataProcessor {
    let data: Data
    let callbacks: [DGCSessionDataTask.DGCTaskCallback]
    let queue: DGCCallbackQueue

    // Note: We have an optimization choice there, to reduce queue dispatch by checking callback
    // queue settings in each option...
    let onImageProcessed = DGCDelegate<(Result<KFCrossPlatformImage, DGCKingfisherError>, DGCSessionDataTask.DGCTaskCallback), Void>()

    init(data: Data, callbacks: [DGCSessionDataTask.DGCTaskCallback], processingQueue: DGCCallbackQueue?) {
        self.data = data
        self.callbacks = callbacks
        self.queue = processingQueue ?? dgc_sharedProcessingQueue
    }

    func process() {
        queue.execute(dgc_doProcess)
    }

    private func dgc_doProcess() {
        var dgc_processedImages = [String: KFCrossPlatformImage]()
        for callback in callbacks {
            let dgc_processor = callback.options.dgc_processor
            var dgc_image = dgc_processedImages[dgc_processor.identifier]
            if dgc_image == nil {
                dgc_image = dgc_processor.process(item: .data(data), options: callback.options)
                dgc_processedImages[dgc_processor.identifier] = dgc_image
            }

            let dgc_result: Result<KFCrossPlatformImage, DGCKingfisherError>
            if let dgc_image = dgc_image {
                let dgc_finalImage = callback.options.backgroundDecode ? dgc_image.kf.decoded : dgc_image
                dgc_result = .success(dgc_finalImage)
            } else {
                let dgc_error = DGCKingfisherError.processorError(
                    reason: .processingFailed(dgc_processor: dgc_processor, item: .data(data)))
                dgc_result = .failure(dgc_error)
            }
            onImageProcessed.call((dgc_result, callback))
        }
    }
}
