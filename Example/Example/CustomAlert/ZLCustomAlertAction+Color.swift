//
//  DGCZLCustomAlertAction+Color.swift
//  Example
//
//  Created by long on 2022/7/1.
//

import DGCZLPhotoBrowser
import UIKit

extension DGCZLCustomAlertAction.DGCStyle {
    var color: UIColor {
        switch self {
        case .default, .cancel:
            return UIColor.color(hexRGB: 0x171717)
        case .tint:
            return UIColor.color(hexRGB: 0x4F638E)
        case .destructive:
            return UIColor.color(hexRGB: 0xEB2F58)
        }
    }
}
