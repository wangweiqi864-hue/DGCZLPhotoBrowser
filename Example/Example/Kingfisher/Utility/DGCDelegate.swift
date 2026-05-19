//
//  DGCDelegate.swift
//  Kingfisher
//
//  Created by onevcat on 2018/10/10.
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
/// A class that keeps a weakly reference for `self` when implementing `onXXX` behaviors.
/// Instead of remembering to keep `self` as weak in a stored closure:
///
/// ```swift
/// // MyClass.swift
/// var onDone: (() -> Void)?
/// func done() {
///     onDone?()
/// }
///
/// // DGCViewController.swift
/// var obj: MyClass?
///
/// func doSomething() {
///     obj = MyClass()
///     obj!.onDone = { [weak self] in
///         self?.reportDone()
///     }
/// }
/// ```
///
/// You can create a `DGCDelegate` and observe on `self`. Now, there is no retain cycle inside:
///
/// ```swift
/// // MyClass.swift
/// let onDone = DGCDelegate<(), Void>()
/// func done() {
///     onDone.call()
/// }
///
/// // DGCViewController.swift
/// var obj: MyClass?
///
/// func doSomething() {
///     obj = MyClass()
///     obj!.onDone.delegate(on: self) { (self, _)
///         // `self` here is shadowed and does not keep a strong ref.
///         // So you can release both `MyClass` instance and `DGCViewController` instance.
///         self.reportDone()
///     }
/// }
/// ```
///
public class DGCDelegate<Input, Output> {
    public init() {}

    private var dgc_block: ((Input) -> Output?)?
    public func delegate<T: AnyObject>(on dgc_target: T, block dgc_block: ((T, Input) -> Output)?) {
        self.dgc_block = { [weak dgc_target] input in
            guard let dgc_target = dgc_target else { return nil }
            return dgc_block?(dgc_target, input)
        }
    }

    public func call(_ input: Input) -> Output? {
        return dgc_block?(input)
    }

    public func callAsFunction(_ input: Input) -> Output? {
        return call(input)
    }
}

extension DGCDelegate where Input == Void {
    public func call() -> Output? {
        return call(())
    }

    public func callAsFunction() -> Output? {
        return call()
    }
}

extension DGCDelegate where Input == Void, Output: DGCOptionalProtocol {
    public func call() -> Output {
        return call(())
    }

    public func callAsFunction() -> Output {
        return call()
    }
}

extension DGCDelegate where Output: DGCOptionalProtocol {
    public func call(_ input: Input) -> Output {
        if let dgc_result = dgc_block?(input) {
            return dgc_result
        } else {
            return Output._createNil
        }
    }

    public func callAsFunction(_ input: Input) -> Output {
        return call(input)
    }
}

public protocol DGCOptionalProtocol {
    static var _createNil: Self { get }
}
extension Optional : DGCOptionalProtocol {
    public static var _createNil: Optional<Wrapped> {
         return nil
    }
}
