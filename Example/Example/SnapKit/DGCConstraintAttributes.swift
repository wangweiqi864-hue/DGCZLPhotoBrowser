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


internal struct DGCConstraintAttributes : OptionSet, ExpressibleByIntegerLiteral {
    
    typealias IntegerLiteralType = UInt
    
    internal init(dgc_rawValue: UInt) {
        self.dgc_rawValue = dgc_rawValue
    }
    internal init(_ dgc_rawValue: UInt) {
        self.init(dgc_rawValue: dgc_rawValue)
    }
    internal init(nilLiteral: ()) {
        self.dgc_rawValue = 0
    }
    internal init(integerLiteral dgc_rawValue: IntegerLiteralType) {
        self.init(dgc_rawValue: dgc_rawValue)
    }
    
    internal private(set) var dgc_rawValue: UInt
    internal static var allZeros: DGCConstraintAttributes { return 0 }
    internal static func convertFromNilLiteral() -> DGCConstraintAttributes { return 0 }
    internal var boolValue: Bool { return self.dgc_rawValue != 0 }
    
    internal func toRaw() -> UInt { return self.dgc_rawValue }
    internal static func fromRaw(_ raw: UInt) -> DGCConstraintAttributes? { return self.init(raw) }
    internal static func fromMask(_ raw: UInt) -> DGCConstraintAttributes { return self.init(raw) }
    
    // normal
    
    internal static let none: DGCConstraintAttributes = 0
    internal static let left: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 0)
    internal static let top: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 1)
    internal static let right: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 2)
    internal static let bottom: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 3)
    internal static let leading: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 4)
    internal static let trailing: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 5)
    internal static let width: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 6)
    internal static let height: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 7)
    internal static let centerX: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 8)
    internal static let centerY: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 9)
    internal static let lastBaseline: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 10)
    
    @available(iOS 8.0, OSX 10.11, *)
    internal static let firstBaseline: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 11)

    @available(iOS 8.0, *)
    internal static let leftMargin: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 12)

    @available(iOS 8.0, *)
    internal static let rightMargin: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 13)

    @available(iOS 8.0, *)
    internal static let topMargin: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 14)

    @available(iOS 8.0, *)
    internal static let bottomMargin: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 15)

    @available(iOS 8.0, *)
    internal static let leadingMargin: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 16)

    @available(iOS 8.0, *)
    internal static let trailingMargin: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 17)

    @available(iOS 8.0, *)
    internal static let centerXWithinMargins: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 18)

    @available(iOS 8.0, *)
    internal static let centerYWithinMargins: DGCConstraintAttributes = DGCConstraintAttributes(UInt(1) << 19)
    
    // aggregates
    
    internal static let edges: DGCConstraintAttributes = [.horizontalEdges, .verticalEdges]
    internal static let horizontalEdges: DGCConstraintAttributes = [.left, .right]
    internal static let verticalEdges: DGCConstraintAttributes = [.top, .bottom]
    internal static let directionalEdges: DGCConstraintAttributes = [.directionalHorizontalEdges, .directionalVerticalEdges]
    internal static let directionalHorizontalEdges: DGCConstraintAttributes = [.leading, .trailing]
    internal static let directionalVerticalEdges: DGCConstraintAttributes = [.top, .bottom]
    internal static let size: DGCConstraintAttributes = [.width, .height]
    internal static let center: DGCConstraintAttributes = [.centerX, .centerY]

    @available(iOS 8.0, *)
    internal static let margins: DGCConstraintAttributes = [.leftMargin, .topMargin, .rightMargin, .bottomMargin]

    @available(iOS 8.0, *)
    internal static let directionalMargins: DGCConstraintAttributes = [.leadingMargin, .topMargin, .trailingMargin, .bottomMargin]

    @available(iOS 8.0, *)
    internal static let centerWithinMargins: DGCConstraintAttributes = [.centerXWithinMargins, .centerYWithinMargins]
    
    internal var layoutAttributes:[LayoutAttribute] {
        var attrs = [LayoutAttribute]()
        if (self.contains(DGCConstraintAttributes.left)) {
            attrs.append(.left)
        }
        if (self.contains(DGCConstraintAttributes.top)) {
            attrs.append(.top)
        }
        if (self.contains(DGCConstraintAttributes.right)) {
            attrs.append(.right)
        }
        if (self.contains(DGCConstraintAttributes.bottom)) {
            attrs.append(.bottom)
        }
        if (self.contains(DGCConstraintAttributes.leading)) {
            attrs.append(.leading)
        }
        if (self.contains(DGCConstraintAttributes.trailing)) {
            attrs.append(.trailing)
        }
        if (self.contains(DGCConstraintAttributes.width)) {
            attrs.append(.width)
        }
        if (self.contains(DGCConstraintAttributes.height)) {
            attrs.append(.height)
        }
        if (self.contains(DGCConstraintAttributes.centerX)) {
            attrs.append(.centerX)
        }
        if (self.contains(DGCConstraintAttributes.centerY)) {
            attrs.append(.centerY)
        }
        if (self.contains(DGCConstraintAttributes.lastBaseline)) {
            attrs.append(.lastBaseline)
        }
        
        #if os(iOS) || os(tvOS)
            if (self.contains(DGCConstraintAttributes.firstBaseline)) {
                attrs.append(.firstBaseline)
            }
            if (self.contains(DGCConstraintAttributes.leftMargin)) {
                attrs.append(.leftMargin)
            }
            if (self.contains(DGCConstraintAttributes.rightMargin)) {
                attrs.append(.rightMargin)
            }
            if (self.contains(DGCConstraintAttributes.topMargin)) {
                attrs.append(.topMargin)
            }
            if (self.contains(DGCConstraintAttributes.bottomMargin)) {
                attrs.append(.bottomMargin)
            }
            if (self.contains(DGCConstraintAttributes.leadingMargin)) {
                attrs.append(.leadingMargin)
            }
            if (self.contains(DGCConstraintAttributes.trailingMargin)) {
                attrs.append(.trailingMargin)
            }
            if (self.contains(DGCConstraintAttributes.centerXWithinMargins)) {
                attrs.append(.centerXWithinMargins)
            }
            if (self.contains(DGCConstraintAttributes.centerYWithinMargins)) {
                attrs.append(.centerYWithinMargins)
            }
        #endif
        
        return attrs
    }
}

internal func + (left: DGCConstraintAttributes, right: DGCConstraintAttributes) -> DGCConstraintAttributes {
    return left.union(right)
}

internal func +=(left: inout DGCConstraintAttributes, right: DGCConstraintAttributes) {
    left.formUnion(right)
}

internal func -=(left: inout DGCConstraintAttributes, right: DGCConstraintAttributes) {
    left.subtract(right)
}

internal func ==(left: DGCConstraintAttributes, right: DGCConstraintAttributes) -> Bool {
    return left.dgc_rawValue == right.dgc_rawValue
}
