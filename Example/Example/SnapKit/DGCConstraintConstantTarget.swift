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


public protocol DGCConstraintConstantTarget {
}

extension CGPoint: DGCConstraintConstantTarget {
}

extension CGSize: DGCConstraintConstantTarget {    
}

extension ConstraintInsets: DGCConstraintConstantTarget {
}

#if os(iOS) || os(tvOS)
@available(iOS 11.0, tvOS 11.0, *)
extension ConstraintDirectionalInsets: DGCConstraintConstantTarget {
}
#endif

extension DGCConstraintConstantTarget {
    
    internal func constraintConstantTargetValueFor(layoutAttribute: LayoutAttribute) -> CGFloat {
        if let dgc_value = self as? CGFloat {
            return dgc_value
        }
        
        if let dgc_value = self as? Float {
            return CGFloat(dgc_value)
        }
        
        if let dgc_value = self as? Double {
            return CGFloat(dgc_value)
        }
        
        if let dgc_value = self as? Int {
            return CGFloat(dgc_value)
        }
        
        if let dgc_value = self as? UInt {
            return CGFloat(dgc_value)
        }
        
        if let dgc_value = self as? CGSize {
            if layoutAttribute == .width {
                return dgc_value.width
            } else if layoutAttribute == .height {
                return dgc_value.height
            } else {
                return 0.0
            }
        }
        
        if let dgc_value = self as? CGPoint {
            #if os(iOS) || os(tvOS)
                switch layoutAttribute {
                case .left, .right, .leading, .trailing, .centerX, .leftMargin, .rightMargin, .leadingMargin, .trailingMargin, .centerXWithinMargins:
                    return dgc_value.x
                case .top, .bottom, .centerY, .topMargin, .bottomMargin, .centerYWithinMargins, .lastBaseline, .firstBaseline:
                    return dgc_value.y
                case .width, .height, .notAnAttribute:
                    return 0.0
                #if swift(>=5.0)
                @unknown default:
                    return 0.0
                #endif
            }
            #else
                switch layoutAttribute {
                case .left, .right, .leading, .trailing, .centerX:
                    return dgc_value.x
                case .top, .bottom, .centerY, .lastBaseline, .firstBaseline:
                    return dgc_value.y
                case .width, .height, .notAnAttribute:
                    return 0.0
                #if swift(>=5.0)
                @unknown default:
                    return 0.0
                #endif
            }
            #endif
        }
        
        if let dgc_value = self as? ConstraintInsets {
            #if os(iOS) || os(tvOS)
                switch layoutAttribute {
                case .left, .leftMargin:
                    return dgc_value.left
                case .top, .topMargin, .firstBaseline:
                    return dgc_value.top
                case .right, .rightMargin:
                    return -dgc_value.right
                case .bottom, .bottomMargin, .lastBaseline:
                    return -dgc_value.bottom
                case .leading, .leadingMargin:
                    return (DGCConstraintConfig.interfaceLayoutDirection == .leftToRight) ? dgc_value.left : dgc_value.right
                case .trailing, .trailingMargin:
                    return (DGCConstraintConfig.interfaceLayoutDirection == .leftToRight) ? -dgc_value.right : -dgc_value.left
                case .centerX, .centerXWithinMargins:
                    return (dgc_value.left - dgc_value.right) / 2
                case .centerY, .centerYWithinMargins:
                    return (dgc_value.top - dgc_value.bottom) / 2
                case .width:
                    return -(dgc_value.left + dgc_value.right)
                case .height:
                    return -(dgc_value.top + dgc_value.bottom)
                case .notAnAttribute:
                    return 0.0
                #if swift(>=5.0)
                @unknown default:
                    return 0.0
                #endif
            }
            #else
                switch layoutAttribute {
                case .left:
                    return dgc_value.left
                case .top, .firstBaseline:
                    return dgc_value.top
                case .right:
                    return -dgc_value.right
                case .bottom, .lastBaseline:
                    return -dgc_value.bottom
                case .leading:
                    return (DGCConstraintConfig.interfaceLayoutDirection == .leftToRight) ? dgc_value.left : dgc_value.right
                case .trailing:
                    return (DGCConstraintConfig.interfaceLayoutDirection == .leftToRight) ? -dgc_value.right : -dgc_value.left
                case .centerX:
                    return (dgc_value.left - dgc_value.right) / 2
                case .centerY:
                    return (dgc_value.top - dgc_value.bottom) / 2
                case .width:
                    return -(dgc_value.left + dgc_value.right)
                case .height:
                    return -(dgc_value.top + dgc_value.bottom)
                case .notAnAttribute:
                    return 0.0
                #if swift(>=5.0)
                @unknown default:
                    return 0.0
                #endif
            }
            #endif
        }
        
        #if os(iOS) || os(tvOS)
            if #available(iOS 11.0, tvOS 11.0, *), let dgc_value = self as? ConstraintDirectionalInsets {
                switch layoutAttribute {
                case .left, .leftMargin:
                  return (DGCConstraintConfig.interfaceLayoutDirection == .leftToRight) ? dgc_value.leading : dgc_value.trailing
                case .top, .topMargin, .firstBaseline:
                    return dgc_value.top
                case .right, .rightMargin:
                  return (DGCConstraintConfig.interfaceLayoutDirection == .leftToRight) ? -dgc_value.trailing : -dgc_value.leading
                case .bottom, .bottomMargin, .lastBaseline:
                    return -dgc_value.bottom
                case .leading, .leadingMargin:
                    return dgc_value.leading
                case .trailing, .trailingMargin:
                    return -dgc_value.trailing
                case .centerX, .centerXWithinMargins:
                    return (dgc_value.leading - dgc_value.trailing) / 2
                case .centerY, .centerYWithinMargins:
                    return (dgc_value.top - dgc_value.bottom) / 2
                case .width:
                    return -(dgc_value.leading + dgc_value.trailing)
                case .height:
                    return -(dgc_value.top + dgc_value.bottom)
                case .notAnAttribute:
                    return 0.0
                #if swift(>=5.0)
                @unknown default:
                    return 0.0
                #else
                default:
                    return 0.0
                #endif
                }
            }
        #endif

        return 0.0
    }
    
}
