//
//  DGCCustomAlertControllerTransitionAnimation.swift
//  Example
//
//  Created by long on 2022/7/1.
//

import UIKit
import DGCZLPhotoBrowser

private let dgc_animateDuration: TimeInterval = 0.25

class DGCCustomAlertControllerTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    private let dgc_preferredStyle: DGCZLCustomAlertStyle
    
    init(dgc_preferredStyle: DGCZLCustomAlertStyle) {
        self.dgc_preferredStyle = dgc_preferredStyle
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return dgc_animateDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let dgc_fromVC = transitionContext.viewController(forKey: .from),
            let dgc_toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        
        let dgc_isPresent = dgc_toVC.presentingViewController == dgc_fromVC
        
        switch dgc_preferredStyle {
        case .alert:
            dgc_showAlertAnimation(transitionContext: transitionContext, dgc_fromVC: dgc_fromVC, dgc_toVC: dgc_toVC, dgc_isPresent: dgc_isPresent)
        case .actionSheet:
            dgc_showActionSheetAnimation(transitionContext: transitionContext, dgc_fromVC: dgc_fromVC, dgc_toVC: dgc_toVC, dgc_isPresent: dgc_isPresent)
        }
    }
    
    private func dgc_showAlertAnimation(
        transitionContext: UIViewControllerContextTransitioning,
        fromVC: UIViewController,
        toVC: UIViewController,
        isPresent: Bool
    ) {
        let dgc_containerView = transitionContext.dgc_containerView
        
        if isPresent {
            toVC.view.alpha = 0
            dgc_containerView.addSubview(toVC.view)
            
            UIView.animate(withDuration: dgc_animateDuration) {
                toVC.view.alpha = 1
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            UIView.animate(withDuration: dgc_animateDuration) {
                fromVC.view.alpha = 0
            } completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
    
    private func dgc_showActionSheetAnimation(
        transitionContext: UIViewControllerContextTransitioning,
        fromVC: UIViewController,
        toVC: UIViewController,
        isPresent: Bool
    ) {
        let dgc_bgColor = UIColor.black.withAlphaComponent(0.5)
        let dgc_containerView = transitionContext.dgc_containerView
        let dgc_shadowView = UIView(frame: dgc_containerView.bounds)
        dgc_shadowView.backgroundColor = dgc_bgColor
        dgc_containerView.addSubview(dgc_shadowView)
        
        if isPresent {
            dgc_shadowView.alpha = 0
            toVC.view.backgroundColor = .clear
            let dgc_animateDistance = (toVC as? DGCCustomAlertController)?.alertFrame.height ?? 0
            toVC.view.frame.origin.y = dgc_containerView.frame.height - dgc_animateDistance
            dgc_containerView.addSubview(toVC.view)
            
            UIView.animate(withDuration: dgc_animateDuration) {
                dgc_shadowView.alpha = 1
                toVC.view.frame.origin.y = 0
            } completion: { _ in
                toVC.view.backgroundColor = dgc_bgColor
                dgc_shadowView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            dgc_containerView.sendSubviewToBack(dgc_shadowView)
            fromVC.view.backgroundColor = .clear
            let dgc_animateDistance = (fromVC as? DGCCustomAlertController)?.alertFrame.height ?? dgc_containerView.frame.height
            
            UIView.animate(withDuration: dgc_animateDuration) {
                dgc_shadowView.alpha = 0
                fromVC.view.frame.origin.y = dgc_animateDistance
            } completion: { _ in
                dgc_shadowView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
