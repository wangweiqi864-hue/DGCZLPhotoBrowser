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


public class DGCConstraintMakerExtendable: DGCConstraintMakerRelatable {
    
    public var left: DGCConstraintMakerExtendable {
        self.description.attributes += .left
        return self
    }
    
    public var top: DGCConstraintMakerExtendable {
        self.description.attributes += .top
        return self
    }
    
    public var bottom: DGCConstraintMakerExtendable {
        self.description.attributes += .bottom
        return self
    }
    
    public var right: DGCConstraintMakerExtendable {
        self.description.attributes += .right
        return self
    }
    
    public var leading: DGCConstraintMakerExtendable {
        self.description.attributes += .leading
        return self
    }
    
    public var trailing: DGCConstraintMakerExtendable {
        self.description.attributes += .trailing
        return self
    }
    
    public var width: DGCConstraintMakerExtendable {
        self.description.attributes += .width
        return self
    }
    
    public var height: DGCConstraintMakerExtendable {
        self.description.attributes += .height
        return self
    }
    
    public var centerX: DGCConstraintMakerExtendable {
        self.description.attributes += .centerX
        return self
    }
    
    public var centerY: DGCConstraintMakerExtendable {
        self.description.attributes += .centerY
        return self
    }
    
    @available(*, deprecated, renamed:"lastBaseline")
    public var baseline: DGCConstraintMakerExtendable {
        self.description.attributes += .lastBaseline
        return self
    }
    
    public var lastBaseline: DGCConstraintMakerExtendable {
        self.description.attributes += .lastBaseline
        return self
    }
    
    @available(iOS 8.0, OSX 10.11, *)
    public var firstBaseline: DGCConstraintMakerExtendable {
        self.description.attributes += .firstBaseline
        return self
    }
    
    @available(iOS 8.0, *)
    public var leftMargin: DGCConstraintMakerExtendable {
        self.description.attributes += .leftMargin
        return self
    }
    
    @available(iOS 8.0, *)
    public var rightMargin: DGCConstraintMakerExtendable {
        self.description.attributes += .rightMargin
        return self
    }
    
    @available(iOS 8.0, *)
    public var topMargin: DGCConstraintMakerExtendable {
        self.description.attributes += .topMargin
        return self
    }
    
    @available(iOS 8.0, *)
    public var bottomMargin: DGCConstraintMakerExtendable {
        self.description.attributes += .bottomMargin
        return self
    }
    
    @available(iOS 8.0, *)
    public var leadingMargin: DGCConstraintMakerExtendable {
        self.description.attributes += .leadingMargin
        return self
    }
    
    @available(iOS 8.0, *)
    public var trailingMargin: DGCConstraintMakerExtendable {
        self.description.attributes += .trailingMargin
        return self
    }
    
    @available(iOS 8.0, *)
    public var centerXWithinMargins: DGCConstraintMakerExtendable {
        self.description.attributes += .centerXWithinMargins
        return self
    }
    
    @available(iOS 8.0, *)
    public var centerYWithinMargins: DGCConstraintMakerExtendable {
        self.description.attributes += .centerYWithinMargins
        return self
    }
    
    public var edges: DGCConstraintMakerExtendable {
        self.description.attributes += .edges
        return self
    }
    public var horizontalEdges: DGCConstraintMakerExtendable {
        self.description.attributes += .horizontalEdges
        return self
    }
    public var verticalEdges: DGCConstraintMakerExtendable {
        self.description.attributes += .verticalEdges
        return self
    }
    public var directionalEdges: DGCConstraintMakerExtendable {
        self.description.attributes += .directionalEdges
        return self
    }
    public var directionalHorizontalEdges: DGCConstraintMakerExtendable {
        self.description.attributes += .directionalHorizontalEdges
        return self
    }
    public var directionalVerticalEdges: DGCConstraintMakerExtendable {
        self.description.attributes += .directionalVerticalEdges
        return self
    }
    public var size: DGCConstraintMakerExtendable {
        self.description.attributes += .size
        return self
    }
    
    @available(iOS 8.0, *)
    public var margins: DGCConstraintMakerExtendable {
        self.description.attributes += .margins
        return self
    }
    
    @available(iOS 8.0, *)
    public var directionalMargins: DGCConstraintMakerExtendable {
      self.description.attributes += .directionalMargins
      return self
    }

    @available(iOS 8.0, *)
    public var centerWithinMargins: DGCConstraintMakerExtendable {
        self.description.attributes += .centerWithinMargins
        return self
    }
    
}
