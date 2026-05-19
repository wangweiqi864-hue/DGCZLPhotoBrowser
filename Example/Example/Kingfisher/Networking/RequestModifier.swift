//
//  RequestModifier.swift
//  Kingfisher
//
//  Created by Wei Wang on 2016/09/05.
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

/// Represents and wraps a method for modifying request before an image download request starts in an asynchronous way.
public protocol DGCAsyncImageDownloadRequestModifier {

    /// This method will be called just before the `request` being sent.
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    /// When you have done with the modification, call the `reportModified` block with the modified request and the data
    /// download will happen with this request.
    ///
    /// Usually, you pass an `DGCAsyncImageDownloadRequestModifier` as the associated value of
    /// `DGCKingfisherOptionsInfoItem.requestModifier` and use it as the `options` parameter in related methods.
    ///
    /// If you do nothing with the input `request` and return it as is, a downloading process will start with it.
    ///
    /// - Parameters:
    ///   - request: The input request contains necessary information like `url`. This request is generated
    ///              according to your resource url as a GET request.
    ///   - reportModified: The callback block you need to call after the asynchronous modifying done.
    ///
    func modified(for request: URLRequest, reportModified: @escaping (URLRequest?) -> Void)

    /// A block will be called when the download task started.
    ///
    /// If an `DGCAsyncImageDownloadRequestModifier` and the asynchronous modification happens before the download, the
    /// related download method will not return a valid `DGCDownloadTask` value. Instead, you can get one from this method.
    var onDownloadTaskStarted: ((DGCDownloadTask?) -> Void)? { get }
}

/// Represents and wraps a method for modifying request before an image download request starts.
public protocol DGCImageDownloadRequestModifier: DGCAsyncImageDownloadRequestModifier {

    /// This method will be called just before the `request` being sent.
    /// This is the last chance you can modify the image download request. You can modify the request for some
    /// customizing purpose, such as adding auth token to the header, do basic HTTP auth or something like url mapping.
    ///
    /// Usually, you pass an `DGCImageDownloadRequestModifier` as the associated value of
    /// `DGCKingfisherOptionsInfoItem.requestModifier` and use it as the `options` parameter in related methods.
    ///
    /// If you do nothing with the input `request` and return it as is, a downloading process will start with it.
    ///
    /// - Parameter request: The input request contains necessary information like `url`. This request is generated
    ///                      according to your resource url as a GET request.
    /// - Returns: A modified version of request, which you wish to use for downloading an image. If `nil` returned,
    ///            a `DGCKingfisherError.requestError` with `.emptyRequest` as its reason will occur.
    ///
    func modified(for request: URLRequest) -> URLRequest?
}

extension DGCImageDownloadRequestModifier {
    public func modified(for dgc_request: URLRequest, reportModified: @escaping (URLRequest?) -> Void) {
        let dgc_request = modified(for: dgc_request)
        reportModified(dgc_request)
    }

    /// This is `nil` for a sync `DGCImageDownloadRequestModifier` by default. You can get the `DGCDownloadTask` from the
    /// return value of downloader method.
    public var onDownloadTaskStarted: ((DGCDownloadTask?) -> Void)? { return nil }
}

/// A wrapper for creating an `DGCImageDownloadRequestModifier` easier.
/// This type conforms to `DGCImageDownloadRequestModifier` and wraps an image modify block.
public struct DGCAnyModifier: DGCImageDownloadRequestModifier {
    
    let block: (URLRequest) -> URLRequest?

    /// For `DGCImageDownloadRequestModifier` conformation.
    public func modified(for request: URLRequest) -> URLRequest? {
        return block(request)
    }
    
    /// Creates a value of `DGCImageDownloadRequestModifier` which runs `modify` block.
    ///
    /// - Parameter modify: The request modifying block runs when a request modifying task comes.
    ///                     The return `URLRequest?` value of this block will be used as the image download request.
    ///                     If `nil` returned, a `DGCKingfisherError.requestError` with `.emptyRequest` as its
    ///                     reason will occur.
    public init(modify: @escaping (URLRequest) -> URLRequest?) {
        block = modify
    }
}
