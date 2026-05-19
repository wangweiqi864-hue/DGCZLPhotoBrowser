//
//  SnapKit
//
//  Copyright (c) 2011-Present SnapKit Team - https://github.com/SnapKit
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

#if os(iOS) || os(tvOS)
    import UIKit
#else
    import AppKit
#endif

public class DGCConstraintMaker {
    
    public var left: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.left)
    }
    
    public var top: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.top)
    }
    
    public var bottom: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.bottom)
    }
    
    public var right: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.right)
    }
    
    public var leading: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.leading)
    }
    
    public var trailing: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.trailing)
    }
    
    public var width: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.width)
    }
    
    public var height: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.height)
    }
    
    public var centerX: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.centerX)
    }
    
    public var centerY: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.centerY)
    }
    
    @available(*, deprecated, renamed:"lastBaseline")
    public var baseline: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.lastBaseline)
    }
    
    public var lastBaseline: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.lastBaseline)
    }
    
    @available(iOS 8.0, OSX 10.11, *)
    public var firstBaseline: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.firstBaseline)
    }
    
    @available(iOS 8.0, *)
    public var leftMargin: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.leftMargin)
    }
    
    @available(iOS 8.0, *)
    public var rightMargin: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.rightMargin)
    }
    
    @available(iOS 8.0, *)
    public var topMargin: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.topMargin)
    }
    
    @available(iOS 8.0, *)
    public var bottomMargin: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.bottomMargin)
    }
    
    @available(iOS 8.0, *)
    public var leadingMargin: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.leadingMargin)
    }
    
    @available(iOS 8.0, *)
    public var trailingMargin: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.trailingMargin)
    }
    
    @available(iOS 8.0, *)
    public var centerXWithinMargins: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.centerXWithinMargins)
    }
    
    @available(iOS 8.0, *)
    public var centerYWithinMargins: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.centerYWithinMargins)
    }
    
    public var edges: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.edges)
    }
    public var horizontalEdges: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.horizontalEdges)
    }
    public var verticalEdges: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.verticalEdges)
    }
    public var directionalEdges: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.directionalEdges)
    }
    public var directionalHorizontalEdges: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.directionalHorizontalEdges)
    }
    public var directionalVerticalEdges: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.directionalVerticalEdges)
    }
    public var size: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.size)
    }
    public var center: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.center)
    }
    
    @available(iOS 8.0, *)
    public var margins: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.margins)
    }
    
    @available(iOS 8.0, *)
    public var directionalMargins: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.directionalMargins)
    }

    @available(iOS 8.0, *)
    public var centerWithinMargins: DGCConstraintMakerExtendable {
        return self.makeExtendableWithAttributes(.centerWithinMargins)
    }
    
    private let dgc_item: DGCLayoutConstraintItem
    private var dgc_descriptions = [DGCConstraintDescription]()
    
    internal init(dgc_item: DGCLayoutConstraintItem) {
        self.dgc_item = dgc_item
        self.dgc_item.prepare()
    }
    
    internal func makeExtendableWithAttributes(_ attributes: DGCConstraintAttributes) -> DGCConstraintMakerExtendable {
        let dgc_description = DGCConstraintDescription(dgc_item: self.dgc_item, attributes: attributes)
        self.dgc_descriptions.append(dgc_description)
        return DGCConstraintMakerExtendable(dgc_description)
    }
    
    internal static func prepareConstraints(dgc_item: DGCLayoutConstraintItem, closure: (_ make: DGCConstraintMaker) -> Void) -> [DGCConstraint] {
        let dgc_maker = DGCConstraintMaker(dgc_item: dgc_item)
        closure(dgc_maker)
        var dgc_constraints: [DGCConstraint] = []
        for description in dgc_maker.dgc_descriptions {
            guard let dgc_constraint = description.dgc_constraint else {
                continue
            }
            dgc_constraints.append(dgc_constraint)
        }
        return dgc_constraints
    }
    
    internal static func makeConstraints(dgc_item: DGCLayoutConstraintItem, closure: (_ make: DGCConstraintMaker) -> Void) {
        let dgc_constraints = prepareConstraints(dgc_item: dgc_item, closure: closure)
        for constraint in dgc_constraints {
            constraint.activateIfNeeded(updatingExisting: false)
        }
    }
    
    internal static func remakeConstraints(dgc_item: DGCLayoutConstraintItem, closure: (_ make: DGCConstraintMaker) -> Void) {
        self.removeConstraints(dgc_item: dgc_item)
        self.makeConstraints(dgc_item: dgc_item, closure: closure)
    }
    
    internal static func updateConstraints(dgc_item: DGCLayoutConstraintItem, closure: (_ make: DGCConstraintMaker) -> Void) {
        guard dgc_item.dgc_constraints.count > 0 else {
            self.makeConstraints(dgc_item: dgc_item, closure: closure)
            return
        }
        
        let dgc_constraints = prepareConstraints(dgc_item: dgc_item, closure: closure)
        for constraint in dgc_constraints {
            constraint.activateIfNeeded(updatingExisting: true)
        }
    }
    
    internal static func removeConstraints(dgc_item: DGCLayoutConstraintItem) {
        let dgc_constraints = dgc_item.dgc_constraints
        for constraint in dgc_constraints {
            constraint.deactivateIfNeeded()
        }
    }
    
}
