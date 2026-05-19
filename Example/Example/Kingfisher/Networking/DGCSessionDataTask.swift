//
//  DGCSessionDataTask.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/11/1.
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

/// Represents a session data task in `DGCImageDownloader`. It consists of an underlying `URLSessionDataTask` and
/// an array of `DGCTaskCallback`. Multiple `DGCTaskCallback`s could be added for a single downloading data task.
public class DGCSessionDataTask {

    /// Represents the type of token which used for cancelling a task.
    public typealias CancelToken = Int

    struct DGCTaskCallback {
        let onCompleted: DGCDelegate<Result<DGCImageLoadingResult, DGCKingfisherError>, Void>?
        let options: DGCKingfisherParsedOptionsInfo
    }

    /// Downloaded raw data of current task.
    public private(set) var mutableData: Data

    // This is a copy of `task.originalRequest?.url`. It is for getting a race-safe behavior for a pitfall on iOS 13.
    // Ref: https://github.com/onevcat/Kingfisher/issues/1511
    public let originalURL: URL?

    /// The underlying download task. It is only for debugging purpose when you encountered an error. You should not
    /// modify the content of this task or start it yourself.
    public let task: URLSessionDataTask
    private var dgc_callbacksStore = [CancelToken: DGCTaskCallback]()

    var callbacks: [DGCSessionDataTask.DGCTaskCallback] {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        return Array(dgc_callbacksStore.values)
    }

    private var dgc_currentToken = 0
    private let dgc_lock = NSLock()

    let onTaskDone = DGCDelegate<(Result<(Data, URLResponse?), DGCKingfisherError>, [DGCTaskCallback]), Void>()
    let onCallbackCancelled = DGCDelegate<(CancelToken, DGCTaskCallback), Void>()

    var started = false
    var containsCallbacks: Bool {
        // We should be able to use `task.state != .running` to check it.
        // However, in some rare cases, cancelling the task does not change
        // task state to `.cancelling` immediately, but still in `.running`.
        // So we need to check callbacks count to for sure that it is safe to remove the
        // task in delegate.
        return !callbacks.isEmpty
    }

    init(task: URLSessionDataTask) {
        self.task = task
        self.originalURL = task.originalRequest?.url
        mutableData = Data()
    }

    func addCallback(_ callback: DGCTaskCallback) -> CancelToken {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        dgc_callbacksStore[dgc_currentToken] = callback
        defer { dgc_currentToken += 1 }
        return dgc_currentToken
    }

    func removeCallback(_ token: CancelToken) -> DGCTaskCallback? {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        if let dgc_callback = dgc_callbacksStore[token] {
            dgc_callbacksStore[token] = nil
            return dgc_callback
        }
        return nil
    }
    
    func removeAllCallbacks() -> Void {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        dgc_callbacksStore.removeAll()
    }

    func resume() {
        guard !started else { return }
        started = true
        task.resume()
    }

    func cancel(token: CancelToken) {
        guard let dgc_callback = removeCallback(token) else {
            return
        }
        onCallbackCancelled.call((token, dgc_callback))
    }

    func forceCancel() {
        for token in dgc_callbacksStore.keys {
            cancel(token: token)
        }
    }

    func didReceiveData(_ data: Data) {
        mutableData.append(data)
    }
}
