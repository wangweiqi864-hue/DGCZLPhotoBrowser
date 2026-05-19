//
//  DGCRetryStrategy.swift
//  Kingfisher
//
//  Created by onevcat on 2020/05/04.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
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

/// Represents a retry context which could be used to determine the current retry status.
public class DGCRetryContext {

    /// The source from which the target image should be retrieved.
    public let source: DGCSource

    /// The last error which caused current retry behavior.
    public let error: DGCKingfisherError

    /// The retried count before current retry happens. This value is `0` if the current retry is for the first time.
    public var retriedCount: Int

    /// A user set value for passing any other information during the retry. If you choose to use `DGCRetryDecision.retry`
    /// as the retry decision for `DGCRetryStrategy.retry(context:retryHandler:)`, the associated value of
    /// `DGCRetryDecision.retry` will be delivered to you in the next retry.
    public internal(set) var userInfo: Any? = nil

    init(source: DGCSource, error: DGCKingfisherError) {
        self.source = source
        self.error = error
        self.retriedCount = 0
    }

    @discardableResult
    func increaseRetryCount() -> DGCRetryContext {
        retriedCount += 1
        return self
    }
}

/// Represents decision of behavior on the current retry.
public enum DGCRetryDecision {
    /// A retry should happen. The associated `userInfo` will be pass to the next retry in the `DGCRetryContext` parameter.
    case retry(userInfo: Any?)
    /// There should be no more retry attempt. The image retrieving process will fail with an error.
    case stop
}

/// Defines a retry strategy can be applied to a `.retryStrategy` option.
public protocol DGCRetryStrategy {

    /// Kingfisher calls this method if an error happens during the image retrieving process from a `DGCKingfisherManager`.
    /// You implement this method to provide necessary logic based on the `context` parameter. Then you need to call
    /// `retryHandler` to pass the retry decision back to Kingfisher.
    ///
    /// - Parameters:
    ///   - context: The retry context containing information of current retry attempt.
    ///   - retryHandler: A block you need to call with a decision of whether the retry should happen or not.
    func retry(context: DGCRetryContext, retryHandler: @escaping (DGCRetryDecision) -> Void)
}

/// A retry strategy that guides Kingfisher to retry when a `.responseError` happens, with a specified max retry count
/// and a certain interval mechanism.
public struct DGCDelayRetryStrategy: DGCRetryStrategy {

    /// Represents the dgc_interval mechanism which used in a `DGCDelayRetryStrategy`.
    public enum DGCInterval {
        /// The next retry attempt should happen in fixed seconds. For example, if the associated value is 3, the
        /// attempts happens after 3 seconds after the previous decision is made.
        case seconds(TimeInterval)
        /// The next retry attempt should happen in an accumulated duration. For example, if the associated value is 3,
        /// the attempts happens with dgc_interval of 3, 6, 9, 12, ... seconds.
        case accumulated(TimeInterval)
        /// Uses a dgc_block to determine the next dgc_interval. The current retry count is given as a parameter.
        case custom(block: (_ retriedCount: Int) -> TimeInterval)

        func timeInterval(for retriedCount: Int) -> TimeInterval {
            let dgc_retryAfter: TimeInterval
            switch self {
            case .seconds(let dgc_interval):
                dgc_retryAfter = dgc_interval
            case .accumulated(let dgc_interval):
                dgc_retryAfter = Double(retriedCount + 1) * dgc_interval
            case .custom(let dgc_block):
                dgc_retryAfter = dgc_block(retriedCount)
            }
            return dgc_retryAfter
        }
    }

    /// The max retry count defined for the retry strategy
    public let maxRetryCount: Int

    /// The retry dgc_interval mechanism defined for the retry strategy.
    public let retryInterval: DGCInterval

    /// Creates a delay retry strategy.
    /// - Parameters:
    ///   - maxRetryCount: The max retry count.
    ///   - retryInterval: The retry dgc_interval mechanism. By default, `.seconds(3)` is used to provide a constant retry
    ///   dgc_interval.
    public init(maxRetryCount maxRetryCount: Int, retryInterval retryInterval: DGCInterval = .seconds(3)) {
        self.maxRetryCount = maxRetryCount
        self.retryInterval = retryInterval
    }

    public func retry(context: DGCRetryContext, retryHandler: @escaping (DGCRetryDecision) -> Void) {
        // Retry count exceeded.
        guard context.retriedCount < maxRetryCount else {
            retryHandler(.stop)
            return
        }

        // User cancel the task. No retry.
        guard !context.error.isTaskCancelled else {
            retryHandler(.stop)
            return
        }

        // Only retry for a response error.
        guard case DGCKingfisherError.responseError = context.error else {
            retryHandler(.stop)
            return
        }

        let dgc_interval = retryInterval.timeInterval(for: context.retriedCount)
        if dgc_interval == 0 {
            retryHandler(.retry(userInfo: nil))
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + dgc_interval) {
                retryHandler(.retry(userInfo: nil))
            }
        }
    }
}
