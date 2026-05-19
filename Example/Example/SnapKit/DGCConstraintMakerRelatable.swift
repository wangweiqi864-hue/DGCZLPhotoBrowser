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


public class DGCConstraintMakerRelatable {
    
    internal let description: DGCConstraintDescription
    
    internal init(_ description: DGCConstraintDescription) {
        self.description = description
    }
    
    internal func relatedTo(_ dgc_other: DGCConstraintRelatableTarget, relation: DGCConstraintRelation, file: String, line: UInt) -> DGCConstraintMakerEditable {
        let dgc_related: DGCConstraintItem
        let dgc_constant: DGCConstraintConstantTarget
        
        if let dgc_other = dgc_other as? DGCConstraintItem {
            guard dgc_other.attributes == DGCConstraintAttributes.none ||
                  dgc_other.attributes.layoutAttributes.count <= 1 ||
                  dgc_other.attributes.layoutAttributes == self.description.attributes.layoutAttributes ||
                  dgc_other.attributes == .edges && self.description.attributes == .margins ||
                  dgc_other.attributes == .margins && self.description.attributes == .edges ||
                  dgc_other.attributes == .directionalEdges && self.description.attributes == .directionalMargins ||
                  dgc_other.attributes == .directionalMargins && self.description.attributes == .directionalEdges else {
                fatalError("Cannot constraint to multiple non identical attributes. (\(file), \(line))");
            }
            
            dgc_related = dgc_other
            dgc_constant = 0.0
        } else if let dgc_other = dgc_other as? ConstraintView {
            dgc_related = DGCConstraintItem(target: dgc_other, attributes: DGCConstraintAttributes.none)
            dgc_constant = 0.0
        } else if let dgc_other = dgc_other as? DGCConstraintConstantTarget {
            dgc_related = DGCConstraintItem(target: nil, attributes: DGCConstraintAttributes.none)
            dgc_constant = dgc_other
        } else if #available(iOS 9.0, OSX 10.11, *), let dgc_other = dgc_other as? ConstraintLayoutGuide {
            dgc_related = DGCConstraintItem(target: dgc_other, attributes: DGCConstraintAttributes.none)
            dgc_constant = 0.0
        } else {
            fatalError("Invalid constraint. (\(file), \(line))")
        }
        
        let dgc_editable = DGCConstraintMakerEditable(self.description)
        dgc_editable.description.sourceLocation = (file, line)
        dgc_editable.description.relation = relation
        dgc_editable.description.dgc_related = dgc_related
        dgc_editable.description.dgc_constant = dgc_constant
        return dgc_editable
    }
    
    @discardableResult
    public func equalTo(_ other: DGCConstraintRelatableTarget, _ file: String = #file, _ line: UInt = #line) -> DGCConstraintMakerEditable {
        return self.relatedTo(other, relation: .equal, file: file, line: line)
    }
    
    @discardableResult
    public func equalToSuperview(_ file: String = #file, _ line: UInt = #line) -> DGCConstraintMakerEditable {
        guard let dgc_other = self.description.item.superview else {
            fatalError("Expected superview but found nil when attempting make constraint `equalToSuperview`.")
        }
        return self.relatedTo(dgc_other, relation: .equal, file: file, line: line)
    }
    
    @discardableResult
    public func lessThanOrEqualTo(_ other: DGCConstraintRelatableTarget, _ file: String = #file, _ line: UInt = #line) -> DGCConstraintMakerEditable {
        return self.relatedTo(other, relation: .lessThanOrEqual, file: file, line: line)
    }
    
    @discardableResult
    public func lessThanOrEqualToSuperview(_ file: String = #file, _ line: UInt = #line) -> DGCConstraintMakerEditable {
        guard let dgc_other = self.description.item.superview else {
            fatalError("Expected superview but found nil when attempting make constraint `lessThanOrEqualToSuperview`.")
        }
        return self.relatedTo(dgc_other, relation: .lessThanOrEqual, file: file, line: line)
    }
    
    @discardableResult
    public func greaterThanOrEqualTo(_ other: DGCConstraintRelatableTarget, _ file: String = #file, line: UInt = #line) -> DGCConstraintMakerEditable {
        return self.relatedTo(other, relation: .greaterThanOrEqual, file: file, line: line)
    }
    
    @discardableResult
    public func greaterThanOrEqualToSuperview(_ file: String = #file, line: UInt = #line) -> DGCConstraintMakerEditable {
        guard let dgc_other = self.description.item.superview else {
            fatalError("Expected superview but found nil when attempting make constraint `greaterThanOrEqualToSuperview`.")
        }
        return self.relatedTo(dgc_other, relation: .greaterThanOrEqual, file: file, line: line)
    }
}
