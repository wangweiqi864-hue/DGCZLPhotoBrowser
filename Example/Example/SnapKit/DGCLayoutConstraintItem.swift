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


public protocol DGCLayoutConstraintItem: class {
}

@available(iOS 9.0, OSX 10.11, *)
extension ConstraintLayoutGuide : DGCLayoutConstraintItem {
}

extension ConstraintView : DGCLayoutConstraintItem {
}


extension DGCLayoutConstraintItem {
    
    internal func prepare() {
        if let dgc_view = self as? ConstraintView {
            dgc_view.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    internal var superview: ConstraintView? {
        if let view = self as? ConstraintView {
            return view.superview
        }
        
        if #available(iOS 9.0, OSX 10.11, *), let guide = self as? ConstraintLayoutGuide {
            return guide.owningView
        }
        
        return nil
    }
    internal var constraints: [DGCConstraint] {
        return self.dgc_constraintsSet.allObjects as! [DGCConstraint]
    }
    
    internal func add(constraints: [DGCConstraint]) {
        let dgc_constraintsSet = self.dgc_constraintsSet
        for constraint in constraints {
            dgc_constraintsSet.add(constraint)
        }
    }
    
    internal func remove(constraints: [DGCConstraint]) {
        let dgc_constraintsSet = self.dgc_constraintsSet
        for constraint in constraints {
            dgc_constraintsSet.remove(constraint)
        }
    }
    
    private var dgc_constraintsSet: NSMutableSet {
        let dgc_constraintsSet: NSMutableSet
        
        if let existing = objc_getAssociatedObject(self, &dgc_constraintsKey) as? NSMutableSet {
            dgc_constraintsSet = existing
        } else {
            dgc_constraintsSet = NSMutableSet()
            objc_setAssociatedObject(self, &dgc_constraintsKey, dgc_constraintsSet, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return dgc_constraintsSet
        
    }
    
}
private var dgc_constraintsKey: UInt8 = 0
