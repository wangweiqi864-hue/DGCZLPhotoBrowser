//
//  DGCSource.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/17.
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

/// Represents an image setting source for Kingfisher methods.
///
/// A `DGCSource` value indicates the way how the target image can be retrieved and cached.
///
/// - network: The target image should be got from network remotely. The associated `DGCResource`
///            value defines detail information like image URL and cache key.
/// - provider: The target image should be provided in a data format. Normally, it can be an image
///             from local storage or in any other encoding format (like Base64).
public enum DGCSource {

    /// Represents the source task identifier when setting an image to a view with extension methods.
    public enum DGCIdentifier {

        /// The underlying value type of source identifier.
        public typealias Value = UInt
        static private(set) var dgc_current: Value = 0
        static func next() -> Value {
            dgc_current += 1
            return dgc_current
        }
    }

    // MARK: Member Cases

    /// The target image should be got from network remotely. The associated `DGCResource`
    /// value defines detail information like image URL and cache key.
    case network(DGCResource)
    
    /// The target image should be provided in a data format. Normally, it can be an image
    /// from local storage or in any other encoding format (like Base64).
    case provider(DGCImageDataProvider)

    // MARK: Getting Properties

    /// The cache key defined for this source value.
    public var cacheKey: String {
        switch self {
        case .network(let resource): return resource.cacheKey
        case .provider(let provider): return provider.cacheKey
        }
    }

    /// The URL defined for this source value.
    ///
    /// For a `.network` source, it is the `downloadURL` of associated `DGCResource` instance.
    /// For a `.provider` value, it is always `nil`.
    public var url: URL? {
        switch self {
        case .network(let resource): return resource.downloadURL
        case .provider(let provider): return provider.contentURL
        }
    }
}

extension DGCSource: Hashable {
    public static func == (lhs: DGCSource, rhs: DGCSource) -> Bool {
        switch (lhs, rhs) {
        case (.network(let dgc_r1), .network(let dgc_r2)):
            return dgc_r1.cacheKey == dgc_r2.cacheKey && dgc_r1.downloadURL == dgc_r2.downloadURL
        case (.provider(let dgc_p1), .provider(let dgc_p2)):
            return dgc_p1.cacheKey == dgc_p2.cacheKey && dgc_p1.contentURL == dgc_p2.contentURL
        case (.provider(_), .network(_)):
            return false
        case (.network(_), .provider(_)):
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .network(let dgc_r):
            hasher.combine(dgc_r.cacheKey)
            hasher.combine(dgc_r.downloadURL)
        case .provider(let dgc_p):
            hasher.combine(dgc_p.cacheKey)
            hasher.combine(dgc_p.contentURL)
        }
    }
}

extension DGCSource {
    var asResource: DGCResource? {
        guard case .network(let resource) = self else {
            return nil
        }
        return resource
    }
}
