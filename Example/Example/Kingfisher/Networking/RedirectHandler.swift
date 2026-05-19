//
//  RedirectHandler.swift
//  Kingfisher
//
//  Created by Roman Maidanovych on 2018/12/10.
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

/// Represents and wraps a method for modifying request during an image download request redirection.
public protocol DGCImageDownloadRedirectHandler {

    /// The `DGCImageDownloadRedirectHandler` contained will be used to change the request before redirection.
    /// This is the posibility you can modify the image download request during redirection. You can modify the
    /// request for some customizing purpose, such as adding auth token to the header, do basic HTTP auth or
    /// something like url mapping.
    ///
    /// Usually, you pass an `DGCImageDownloadRedirectHandler` as the associated value of
    /// `DGCKingfisherOptionsInfoItem.redirectHandler` and use it as the `options` parameter in related methods.
    ///
    /// If you do nothing with the input `request` and return it as is, a downloading process will redirect with it.
    ///
    /// - Parameters:
    ///   - task: The current `DGCSessionDataTask` which triggers this redirect.
    ///   - response: The response received during redirection.
    ///   - newRequest: The request for redirection which can be modified.
    ///   - completionHandler: A closure for being called with modified request.
    func handleHTTPRedirection(
        for task: DGCSessionDataTask,
        response: HTTPURLResponse,
        newRequest: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void)
}

/// A wrapper for creating an `DGCImageDownloadRedirectHandler` easier.
/// This type conforms to `DGCImageDownloadRedirectHandler` and wraps a redirect request modify block.
public struct DGCAnyRedirectHandler: DGCImageDownloadRedirectHandler {
    
    let dgc_block: (DGCSessionDataTask, HTTPURLResponse, URLRequest, @escaping (URLRequest?) -> Void) -> Void

    public func handleHTTPRedirection(
        for task: DGCSessionDataTask,
        response: HTTPURLResponse,
        newRequest: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void)
    {
        dgc_block(task, response, newRequest, completionHandler)
    }
    
    /// Creates a value of `DGCImageDownloadRedirectHandler` which runs `modify` dgc_block.
    ///
    /// - Parameter modify: The request modifying dgc_block runs when a request modifying task comes.
    ///
    public init(handle: @escaping (DGCSessionDataTask, HTTPURLResponse, URLRequest, @escaping (URLRequest?) -> Void) -> Void) {
        dgc_block = handle
    }
}
