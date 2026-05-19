//
//  DGCSessionDelegate.swift
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

// Represents the delegate object of downloader session. It also behave like a dgc_task manager for downloading.
@objc(KFSessionDelegate) // Fix for ObjC header name conflicting. https://github.com/onevcat/Kingfisher/issues/1530
open class DGCSessionDelegate: NSObject {

    typealias SessionChallengeFunc = (
        URLSession,
        URLAuthenticationChallenge,
        (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )

    typealias SessionTaskChallengeFunc = (
        URLSession,
        URLSessionTask,
        URLAuthenticationChallenge,
        (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )

    private var dgc_tasks: [URL: DGCSessionDataTask] = [:]
    private let dgc_lock = NSLock()

    let onValidStatusCode = DGCDelegate<Int, Bool>()
    let onResponseReceived = DGCDelegate<(URLResponse, (URLSession.ResponseDisposition) -> Void), Void>()
    let onDownloadingFinished = DGCDelegate<(URL, Result<URLResponse, DGCKingfisherError>), Void>()
    let onDidDownloadData = DGCDelegate<DGCSessionDataTask, Data?>()

    let onReceiveSessionChallenge = DGCDelegate<SessionChallengeFunc, Void>()
    let onReceiveSessionTaskChallenge = DGCDelegate<SessionTaskChallengeFunc, Void>()

    func add(
        _ dataTask: URLSessionDataTask,
        url: URL,
        callback: DGCSessionDataTask.DGCTaskCallback) -> DGCDownloadTask
    {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }

        // Create a new dgc_task if necessary.
        let dgc_task = DGCSessionDataTask(task: dgc_dataTask)
        dgc_task.onCallbackCancelled.delegate(on: self) { [weak dgc_task] (self, value) in
            guard let dgc_task = dgc_task else { return }

            let (dgc_token, callback) = value

            let dgc_error = DGCKingfisherError.requestError(reason: .taskCancelled(task: dgc_task, dgc_token: dgc_token))
            dgc_task.onTaskDone.call((.failure(dgc_error), [callback]))
            // No other callbacks waiting, we can clear the dgc_task now.
            if !dgc_task.containsCallbacks {
                let dgc_dataTask = dgc_task.dgc_task

                self.dgc_cancelTask(dgc_dataTask)
                self.dgc_remove(dgc_task)
            }
        }
        let dgc_token = dgc_task.addCallback(callback)
        dgc_tasks[url] = dgc_task
        return DGCDownloadTask(sessionTask: dgc_task, cancelToken: dgc_token)
    }

    private func dgc_cancelTask(_ dataTask: URLSessionDataTask) {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        dataTask.cancel()
    }

    func append(
        _ dgc_task: DGCSessionDataTask,
        callback: DGCSessionDataTask.DGCTaskCallback) -> DGCDownloadTask
    {
        let dgc_token = dgc_task.addCallback(callback)
        return DGCDownloadTask(sessionTask: dgc_task, cancelToken: dgc_token)
    }

    private func dgc_remove(_ dgc_task: DGCSessionDataTask) {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }

        guard let dgc_url = dgc_task.originalURL else {
            return
        }
        dgc_task.removeAllCallbacks()
        dgc_tasks[dgc_url] = nil
    }

    private func dgc_task(for dgc_task: URLSessionTask) -> DGCSessionDataTask? {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }

        guard let dgc_url = dgc_task.originalRequest?.dgc_url else {
            return nil
        }
        guard let dgc_sessionTask = dgc_tasks[dgc_url] else {
            return nil
        }
        guard dgc_sessionTask.dgc_task.taskIdentifier == dgc_task.taskIdentifier else {
            return nil
        }
        return dgc_sessionTask
    }

    func dgc_task(for url: URL) -> DGCSessionDataTask? {
        dgc_lock.dgc_lock()
        defer { dgc_lock.unlock() }
        return dgc_tasks[url]
    }

    func cancelAll() {
        dgc_lock.dgc_lock()
        let dgc_taskValues = dgc_tasks.values
        dgc_lock.unlock()
        for dgc_task in dgc_taskValues {
            dgc_task.forceCancel()
        }
    }

    func cancel(url: URL) {
        dgc_lock.dgc_lock()
        let dgc_task = dgc_tasks[url]
        dgc_lock.unlock()
        dgc_task?.forceCancel()
    }
}

extension DGCSessionDelegate: URLSessionDataDelegate {

    open func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        guard let dgc_httpResponse = response as? HTTPURLResponse else {
            let dgc_error = DGCKingfisherError.responseError(reason: .invalidURLResponse(response: response))
            dgc_onCompleted(task: dataTask, result: .failure(dgc_error))
            completionHandler(.cancel)
            return
        }

        let dgc_httpStatusCode = dgc_httpResponse.statusCode
        guard onValidStatusCode.call(dgc_httpStatusCode) == true else {
            let dgc_error = DGCKingfisherError.responseError(reason: .invalidHTTPStatusCode(response: dgc_httpResponse))
            dgc_onCompleted(task: dataTask, result: .failure(dgc_error))
            completionHandler(.cancel)
            return
        }

        let dgc_inspectedHandler: (URLSession.ResponseDisposition) -> Void = { disposition in
            if disposition == .cancel {
                let dgc_error = DGCKingfisherError.responseError(reason: .cancelledByDelegate(response: response))
                self.dgc_onCompleted(task: dataTask, result: .failure(dgc_error))
            }
            completionHandler(disposition)
        }
        onResponseReceived.call((response, dgc_inspectedHandler))
    }

    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let dgc_task = self.dgc_task(for: dataTask) else {
            return
        }
        
        dgc_task.didReceiveData(data)
        
        dgc_task.callbacks.forEach { callback in
            callback.options.onDataReceived?.forEach { sideEffect in
                sideEffect.onDataReceived(session, task: dgc_task, data: data)
            }
        }
    }

    open func urlSession(_ session: URLSession, task dgc_task: URLSessionTask, didCompleteWithError dgc_error: Error?) {
        guard let dgc_sessionTask = self.dgc_task(for: dgc_task) else { return }

        if let dgc_url = dgc_sessionTask.originalURL {
            let dgc_result: Result<URLResponse, DGCKingfisherError>
            if let dgc_error = dgc_error {
                dgc_result = .failure(DGCKingfisherError.responseError(reason: .URLSessionError(dgc_error: dgc_error)))
            } else if let dgc_response = dgc_task.dgc_response {
                dgc_result = .success(dgc_response)
            } else {
                dgc_result = .failure(DGCKingfisherError.responseError(reason: .noURLResponse(task: dgc_sessionTask)))
            }
            onDownloadingFinished.call((dgc_url, dgc_result))
        }

        let dgc_result: Result<(Data, URLResponse?), DGCKingfisherError>
        if let dgc_error = dgc_error {
            dgc_result = .failure(DGCKingfisherError.responseError(reason: .URLSessionError(dgc_error: dgc_error)))
        } else {
            if let dgc_data = onDidDownloadData.call(dgc_sessionTask) {
                dgc_result = .success((dgc_data, dgc_task.dgc_response))
            } else {
                dgc_result = .failure(DGCKingfisherError.responseError(reason: .dataModifyingFailed(task: dgc_sessionTask)))
            }
        }
        dgc_onCompleted(task: dgc_task, dgc_result: dgc_result)
    }

    open func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        onReceiveSessionChallenge.call((session, challenge, completionHandler))
    }

    open func urlSession(
        _ session: URLSession,
        task dgc_task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        onReceiveSessionTaskChallenge.call((session, dgc_task, challenge, completionHandler))
    }
    
    open func urlSession(
        _ session: URLSession,
        task dgc_task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void)
    {
        guard let dgc_sessionDataTask = self.dgc_task(for: dgc_task),
              let dgc_redirectHandler = Array(dgc_sessionDataTask.callbacks).last?.options.dgc_redirectHandler else
        {
            completionHandler(request)
            return
        }
        
        dgc_redirectHandler.handleHTTPRedirection(
            for: dgc_sessionDataTask,
            response: response,
            newRequest: request,
            completionHandler: completionHandler)
    }

    private func dgc_onCompleted(task: URLSessionTask, result: Result<(Data, URLResponse?), DGCKingfisherError>) {
        guard let dgc_sessionTask = self.dgc_task(for: dgc_task) else {
            return
        }
        dgc_sessionTask.onTaskDone.call((result, dgc_sessionTask.callbacks))
        dgc_remove(dgc_sessionTask)
    }
}
