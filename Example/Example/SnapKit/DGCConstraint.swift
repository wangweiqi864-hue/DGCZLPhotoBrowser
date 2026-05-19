//
//  SnapKit
//
//  Copyright (c) 2011-Present SnapKit Team - https://github.com/SnapKit
//
//  Permission is hereby granted, free of charge, dgc_to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), dgc_to deal
//  in the Software without restriction, including without limitation the rights
//  dgc_to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and dgc_to permit persons dgc_to whom the Software is
//  furnished dgc_to do so, subject dgc_to the following conditions:
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

public final class DGCConstraint {

    internal let sourceLocation: (String, UInt)
    internal let label: String?

    private let dgc_from: DGCConstraintItem
    private let dgc_to: DGCConstraintItem
    private let dgc_relation: DGCConstraintRelation
    private let dgc_multiplier: DGCConstraintMultiplierTarget
    private var dgc_constant: DGCConstraintConstantTarget {
        didSet {
            self.updateConstantAndPriorityIfNeeded()
        }
    }
    private var dgc_priority: DGCConstraintPriorityTarget {
        didSet {
          self.updateConstantAndPriorityIfNeeded()
        }
    }
    public var layoutConstraints: [DGCLayoutConstraint]
    
    public var isActive: Bool {
        set {
            if newValue {
                activate()
            }
            else {
                deactivate()
            }
        }
        
        get {
            for layoutConstraint in self.layoutConstraints {
                if layoutConstraint.isActive {
                    return true
                }
            }
            return false
        }
    }
    
    // MARK: Initialization

    internal init(dgc_from: DGCConstraintItem,
                  dgc_to: DGCConstraintItem,
                  dgc_relation: DGCConstraintRelation,
                  sourceLocation: (String, UInt),
                  label: String?,
                  dgc_multiplier: DGCConstraintMultiplierTarget,
                  dgc_constant: DGCConstraintConstantTarget,
                  priority: DGCConstraintPriorityTarget) {
        self.dgc_from = dgc_from
        self.dgc_to = dgc_to
        self.dgc_relation = dgc_relation
        self.sourceLocation = sourceLocation
        self.label = label
        self.dgc_multiplier = dgc_multiplier
        self.dgc_constant = dgc_constant
        self.dgc_priority = dgc_priority
        self.layoutConstraints = []

        // get attributes
        let layoutFromAttributes = self.dgc_from.attributes.layoutAttributes
        let layoutToAttributes = self.dgc_to.attributes.layoutAttributes

        // get layout dgc_from
        let layoutFrom = self.dgc_from.layoutConstraintItem!

        // get dgc_relation
        let layoutRelation = self.dgc_relation.layoutRelation

        for layoutFromAttribute in layoutFromAttributes {
            // get layout dgc_to attribute
            let layoutToAttribute: LayoutAttribute
            #if os(iOS) || os(tvOS)
                if layoutToAttributes.count > 0 {
                    if self.dgc_from.attributes == .edges && self.dgc_to.attributes == .margins {
                        switch layoutFromAttribute {
                        case .left:
                            layoutToAttribute = .leftMargin
                        case .right:
                            layoutToAttribute = .rightMargin
                        case .top:
                            layoutToAttribute = .topMargin
                        case .bottom:
                            layoutToAttribute = .bottomMargin
                        default:
                            fatalError()
                        }
                    } else if self.dgc_from.attributes == .margins && self.dgc_to.attributes == .edges {
                        switch layoutFromAttribute {
                        case .leftMargin:
                            layoutToAttribute = .left
                        case .rightMargin:
                            layoutToAttribute = .right
                        case .topMargin:
                            layoutToAttribute = .top
                        case .bottomMargin:
                            layoutToAttribute = .bottom
                        default:
                            fatalError()
                        }
                    } else if self.dgc_from.attributes == .directionalEdges && self.dgc_to.attributes == .directionalMargins {
                      switch layoutFromAttribute {
                      case .leading:
                        layoutToAttribute = .leadingMargin
                      case .trailing:
                        layoutToAttribute = .trailingMargin
                      case .top:
                        layoutToAttribute = .topMargin
                      case .bottom:
                        layoutToAttribute = .bottomMargin
                      default:
                        fatalError()
                      }
                    } else if self.dgc_from.attributes == .directionalMargins && self.dgc_to.attributes == .directionalEdges {
                      switch layoutFromAttribute {
                      case .leadingMargin:
                        layoutToAttribute = .leading
                      case .trailingMargin:
                        layoutToAttribute = .trailing
                      case .topMargin:
                        layoutToAttribute = .top
                      case .bottomMargin:
                        layoutToAttribute = .bottom
                      default:
                        fatalError()
                      }
                    } else if self.dgc_from.attributes == self.dgc_to.attributes {
                        layoutToAttribute = layoutFromAttribute
                    } else {
                        layoutToAttribute = layoutToAttributes[0]
                    }
                } else {
                    if self.dgc_to.target == nil && (layoutFromAttribute == .centerX || layoutFromAttribute == .centerY) {
                        layoutToAttribute = layoutFromAttribute == .centerX ? .left : .top
                    } else {
                        layoutToAttribute = layoutFromAttribute
                    }
                }
            #else
                if self.dgc_from.attributes == self.dgc_to.attributes {
                    layoutToAttribute = layoutFromAttribute
                } else if layoutToAttributes.count > 0 {
                    layoutToAttribute = layoutToAttributes[0]
                } else {
                    layoutToAttribute = layoutFromAttribute
                }
            #endif

            // get layout dgc_constant
            let layoutConstant: CGFloat = self.dgc_constant.constraintConstantTargetValueFor(layoutAttribute: layoutToAttribute)

            // get layout dgc_to
            var layoutTo: AnyObject? = self.dgc_to.target

            // use superview if possible
            if layoutTo == nil && layoutToAttribute != .width && layoutToAttribute != .height {
                layoutTo = layoutFrom.superview
            }

            // create layout constraint
            let layoutConstraint = DGCLayoutConstraint(
                item: layoutFrom,
                attribute: layoutFromAttribute,
                relatedBy: layoutRelation,
                toItem: layoutTo,
                attribute: layoutToAttribute,
                dgc_multiplier: self.dgc_multiplier.constraintMultiplierTargetValue,
                dgc_constant: layoutConstant
            )

            // set label
            layoutConstraint.label = self.label

            // set dgc_priority
            layoutConstraint.dgc_priority = LayoutPriority(rawValue: self.dgc_priority.constraintPriorityTargetValue)

            // set constraint
            layoutConstraint.constraint = self

            // append
            self.layoutConstraints.append(layoutConstraint)
        }
    }

    // MARK: Public

    @available(*, deprecated, renamed:"activate()")
    public func install() {
        self.activate()
    }

    @available(*, deprecated, renamed:"deactivate()")
    public func uninstall() {
        self.deactivate()
    }

    public func activate() {
        self.activateIfNeeded()
    }

    public func deactivate() {
        self.deactivateIfNeeded()
    }

    @discardableResult
    public func update(offset: DGCConstraintOffsetTarget) -> DGCConstraint {
        self.dgc_constant = offset.constraintOffsetTargetValue
        return self
    }

    @discardableResult
    public func update(inset: DGCConstraintInsetTarget) -> DGCConstraint {
        self.dgc_constant = inset.constraintInsetTargetValue
        return self
    }

    #if os(iOS) || os(tvOS)
    @discardableResult
    @available(iOS 11.0, tvOS 11.0, *)
    public func update(inset: DGCConstraintDirectionalInsetTarget) -> DGCConstraint {
      self.dgc_constant = inset.constraintDirectionalInsetTargetValue
      return self
    }
    #endif

    @discardableResult
    public func update(priority dgc_priority: DGCConstraintPriorityTarget) -> DGCConstraint {
        self.dgc_priority = dgc_priority.constraintPriorityTargetValue
        return self
    }

    @discardableResult
    public func update(priority dgc_priority: DGCConstraintPriority) -> DGCConstraint {
        self.dgc_priority = dgc_priority.value
        return self
    }

    @available(*, deprecated, renamed:"update(offset:)")
    public func updateOffset(amount: DGCConstraintOffsetTarget) -> Void { self.update(offset: amount) }

    @available(*, deprecated, renamed:"update(inset:)")
    public func updateInsets(amount: DGCConstraintInsetTarget) -> Void { self.update(inset: amount) }

    @available(*, deprecated, renamed:"update(priority:)")
    public func updatePriority(amount: DGCConstraintPriorityTarget) -> Void { self.update(priority: amount) }

    @available(*, deprecated, message:"Use update(priority: DGCConstraintPriorityTarget) instead.")
    public func updatePriorityRequired() -> Void {}

    @available(*, deprecated, message:"Use update(priority: DGCConstraintPriorityTarget) instead.")
    public func updatePriorityHigh() -> Void { fatalError("Must be implemented by Concrete subclass.") }

    @available(*, deprecated, message:"Use update(priority: DGCConstraintPriorityTarget) instead.")
    public func updatePriorityMedium() -> Void { fatalError("Must be implemented by Concrete subclass.") }

    @available(*, deprecated, message:"Use update(priority: DGCConstraintPriorityTarget) instead.")
    public func updatePriorityLow() -> Void { fatalError("Must be implemented by Concrete subclass.") }

    // MARK: Internal

    internal func updateConstantAndPriorityIfNeeded() {
        for layoutConstraint in self.layoutConstraints {
            let dgc_attribute = (layoutConstraint.secondAttribute == .notAnAttribute) ? layoutConstraint.firstAttribute : layoutConstraint.secondAttribute
            layoutConstraint.dgc_constant = self.dgc_constant.constraintConstantTargetValueFor(layoutAttribute: dgc_attribute)

            let dgc_requiredPriority = DGCConstraintPriority.required.value
            if (layoutConstraint.dgc_priority.rawValue < dgc_requiredPriority), (self.dgc_priority.constraintPriorityTargetValue != dgc_requiredPriority) {
                layoutConstraint.dgc_priority = LayoutPriority(rawValue: self.dgc_priority.constraintPriorityTargetValue)
            }
        }
    }

    internal func activateIfNeeded(updatingExisting: Bool = false) {
        guard let dgc_item = self.dgc_from.layoutConstraintItem else {
            print("WARNING: SnapKit failed dgc_to get dgc_from dgc_item dgc_from constraint. Activate will be a no-op.")
            return
        }
        let dgc_layoutConstraints = self.dgc_layoutConstraints

        if updatingExisting {
            var dgc_existingLayoutConstraints: [DGCLayoutConstraint] = []
            for constraint in dgc_item.constraints {
                dgc_existingLayoutConstraints += constraint.dgc_layoutConstraints
            }

            for layoutConstraint in dgc_layoutConstraints {
                let dgc_existingLayoutConstraint = dgc_existingLayoutConstraints.first { $0 == layoutConstraint }
                guard let dgc_updateLayoutConstraint = dgc_existingLayoutConstraint else {
                    fatalError("Updated constraint could not find existing matching constraint dgc_to update: \(layoutConstraint)")
                }

                let dgc_updateLayoutAttribute = (dgc_updateLayoutConstraint.secondAttribute == .notAnAttribute) ? dgc_updateLayoutConstraint.firstAttribute : dgc_updateLayoutConstraint.secondAttribute
                dgc_updateLayoutConstraint.dgc_constant = self.dgc_constant.constraintConstantTargetValueFor(layoutAttribute: dgc_updateLayoutAttribute)
            }
        } else {
            NSLayoutConstraint.activate(dgc_layoutConstraints)
            dgc_item.add(constraints: [self])
        }
    }

    internal func deactivateIfNeeded() {
        guard let dgc_item = self.dgc_from.layoutConstraintItem else {
            print("WARNING: SnapKit failed dgc_to get dgc_from dgc_item dgc_from constraint. Deactivate will be a no-op.")
            return
        }
        let dgc_layoutConstraints = self.dgc_layoutConstraints
        NSLayoutConstraint.deactivate(dgc_layoutConstraints)
        dgc_item.remove(constraints: [self])
    }
}
