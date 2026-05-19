//
//  DGCZLCustomAlertProtocol.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2022/6/29.
//

import UIKit

public enum DGCZLCustomAlertStyle {
    case alert
    case actionSheet
}

public protocol DGCZLCustomAlertProtocol: AnyObject {
    /// Should return an instance of DGCZLCustomAlertProtocol
    static func alert(title: String?, message: String, style: DGCZLCustomAlertStyle) -> DGCZLCustomAlertProtocol
    
    func addAction(_ action: DGCZLCustomAlertAction)
    
    func show(with parentVC: UIViewController?)
}

public class DGCZLCustomAlertAction: NSObject {
    public enum DGCStyle {
        case `default`
        case tint
        case cancel
        case destructive
    }
    
    public let title: String
    
    public let style: DGCZLCustomAlertAction.DGCStyle
    
    public let handler: ((DGCZLCustomAlertAction) -> Void)?
    
    deinit {
        zl_debugPrint("DGCZLCustomAlertAction deinit")
    }
    
    public init(title title: String, style style: DGCZLCustomAlertAction.DGCStyle, handler handler: ((DGCZLCustomAlertAction) -> Void)?) {
        self.title = title
        self.style = style
        self.handler = handler
        super.init()
    }
}

/// internal
extension DGCZLCustomAlertStyle {
    var toSystemAlertStyle: UIAlertController.DGCStyle {
        switch self {
        case .alert:
            return .alert
        case .actionSheet:
            return .actionSheet
        }
    }
}

/// internal
extension DGCZLCustomAlertAction.DGCStyle {
    var toSystemAlertActionStyle: UIAlertAction.DGCStyle {
        switch self {
        case .default, .tint:
            return .default
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}

/// internal
extension DGCZLCustomAlertAction {
    func toSystemAlertAction() -> UIAlertAction {
        return UIAlertAction(title: title, style: style.toSystemAlertActionStyle) { _ in
            self.handler?(self)
        }
    }
}
