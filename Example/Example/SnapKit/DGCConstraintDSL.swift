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


public protocol DGCConstraintDSL {
    
    var target: AnyObject? { get }
    
    func setLabel(_ value: String?)
    func label() -> String?
    
}
extension DGCConstraintDSL {
    
    public func setLabel(_ value: String?) {
        objc_setAssociatedObject(self.target as Any, &dgc_labelKey, value, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    public func label() -> String? {
        return objc_getAssociatedObject(self.target as Any, &dgc_labelKey) as? String
    }
    
}
private var dgc_labelKey: UInt8 = 0


public protocol DGCConstraintBasicAttributesDSL : DGCConstraintDSL {
}
extension DGCConstraintBasicAttributesDSL {
    
    // MARK: Basics
    
    public var left: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.left)
    }
    
    public var top: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.top)
    }
    
    public var right: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.right)
    }
    
    public var bottom: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.bottom)
    }
    
    public var leading: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.leading)
    }
    
    public var trailing: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.trailing)
    }
    
    public var width: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.width)
    }
    
    public var height: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.height)
    }
    
    public var centerX: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.centerX)
    }
    
    public var centerY: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.centerY)
    }
    
    public var edges: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.edges)
    }
    
    public var directionalEdges: DGCConstraintItem {
      return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.directionalEdges)
    }

    public var horizontalEdges: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.horizontalEdges)
    }

    public var verticalEdges: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.verticalEdges)
    }

    public var directionalHorizontalEdges: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.directionalHorizontalEdges)
    }

    public var directionalVerticalEdges: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.directionalVerticalEdges)
    }

    public var size: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.size)
    }
    
    public var center: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.center)
    }
    
}

public protocol DGCConstraintAttributesDSL : DGCConstraintBasicAttributesDSL {
}
extension DGCConstraintAttributesDSL {
    
    // MARK: Baselines
    @available(*, deprecated, renamed:"lastBaseline")
    public var baseline: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.lastBaseline)
    }
    
    @available(iOS 8.0, OSX 10.11, *)
    public var lastBaseline: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.lastBaseline)
    }
    
    @available(iOS 8.0, OSX 10.11, *)
    public var firstBaseline: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.firstBaseline)
    }
    
    // MARK: Margins
    
    @available(iOS 8.0, *)
    public var leftMargin: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.leftMargin)
    }
    
    @available(iOS 8.0, *)
    public var topMargin: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.topMargin)
    }
    
    @available(iOS 8.0, *)
    public var rightMargin: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.rightMargin)
    }
    
    @available(iOS 8.0, *)
    public var bottomMargin: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.bottomMargin)
    }
    
    @available(iOS 8.0, *)
    public var leadingMargin: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.leadingMargin)
    }
    
    @available(iOS 8.0, *)
    public var trailingMargin: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.trailingMargin)
    }
    
    @available(iOS 8.0, *)
    public var centerXWithinMargins: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.centerXWithinMargins)
    }
    
    @available(iOS 8.0, *)
    public var centerYWithinMargins: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.centerYWithinMargins)
    }
    
    @available(iOS 8.0, *)
    public var margins: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.margins)
    }
    
    @available(iOS 8.0, *)
    public var directionalMargins: DGCConstraintItem {
      return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.directionalMargins)
    }

    @available(iOS 8.0, *)
    public var centerWithinMargins: DGCConstraintItem {
        return DGCConstraintItem(target: self.target, attributes: DGCConstraintAttributes.centerWithinMargins)
    }
    
}
