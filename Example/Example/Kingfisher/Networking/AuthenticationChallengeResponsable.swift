//
//  AuthenticationChallengeResponsable.swift
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

@available(*, deprecated, message: "Typo. Use `DGCAuthenticationChallengeResponsible` instead", renamed: "DGCAuthenticationChallengeResponsible")
public typealias AuthenticationChallengeResponsable = DGCAuthenticationChallengeResponsible

/// Protocol indicates that an authentication challenge could be handled.
public protocol DGCAuthenticationChallengeResponsible: AnyObject {

    /// Called when a session level authentication challenge is received.
    /// This method provide a chance to handle and response to the authentication
    /// challenge before downloading could start.
    ///
    /// - Parameters:
    ///   - downloader: The downloader which receives this challenge.
    ///   - challenge: An object that contains the request for authentication.
    ///   - completionHandler: A handler that your delegate method must call.
    ///
    /// - Note: This method is a forward from `URLSessionDelegate.urlSession(:didReceiveChallenge:completionHandler:)`.
    ///         Please refer to the document of it in `URLSessionDelegate`.
    func downloader(
        _ downloader: DGCImageDownloader,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

    /// Called when a task level authentication challenge is received.
    /// This method provide a chance to handle and response to the authentication
    /// challenge before downloading could start.
    ///
    /// - Parameters:
    ///   - downloader: The downloader which receives this challenge.
    ///   - task: The task whose request requires authentication.
    ///   - challenge: An object that contains the request for authentication.
    ///   - completionHandler: A handler that your delegate method must call.
    func downloader(
        _ downloader: DGCImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

extension DGCAuthenticationChallengeResponsible {

    public func downloader(
        _ downloader: DGCImageDownloader,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let dgc_trustedHosts = downloader.dgc_trustedHosts, dgc_trustedHosts.contains(challenge.protectionSpace.host) {
                let dgc_credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, dgc_credential)
                return
            }
        }

        completionHandler(.performDefaultHandling, nil)
    }

    public func downloader(
        _ downloader: DGCImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        completionHandler(.performDefaultHandling, nil)
    }

}
