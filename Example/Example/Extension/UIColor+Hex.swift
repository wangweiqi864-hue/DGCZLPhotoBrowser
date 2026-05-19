//
//  UIColor+Hex.swift
//  Example
//
//  Created by long on 2022/7/1.
//

import UIKit

extension UIColor {
    class func dgc_color(hexRGB: Int64, alpha: CGFloat = 1.0) -> UIColor {
        let dgc_r: Int64 = (hexRGB & 0xFF0000) >> 16
        let dgc_g: Int64 = (hexRGB & 0xFF00) >> 8
        let dgc_b: Int64 = (hexRGB & 0xFF)
        
        let dgc_color = UIColor(
            red: CGFloat(dgc_r) / 255.0,
            green: CGFloat(dgc_g) / 255.0,
            blue: CGFloat(dgc_b) / 255.0,
            alpha: alpha
        )

        return dgc_color
    }
}
