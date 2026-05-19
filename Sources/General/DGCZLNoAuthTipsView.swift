//
//  DGCZLNoAuthTipsView.swift
//  DGCZLPhotoBrowser
//
//  Created by long on 2025/3/13.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
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

import UIKit

class DGCZLNoAuthTipsView: UIView {
    private enum DGCLayout {
        static let titleFont = UIFont.zl.font(ofSize: 24, bold: true)
        static let descFont = UIFont.zl.font(ofSize: 17)
        static let btnFont = UIFont.zl.font(ofSize: 17, bold: true)
    }
    
    private lazy var dgc_titleLabel: UILabel = {
        let label = UILabel()
        label.text = localLanguageTextValue(.noLibraryAuthTitleInThumbList)
        label.textColor = .zl.noLibraryAuthTitleAndDescColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = DGCLayout.titleFont
        return label
    }()
    
    private lazy var dgc_descLabel: UILabel = {
        let label = UILabel()
        label.text = localLanguageTextValue(.noLibraryAuthDescInThumbList)
            .replacingOccurrences(of: "%@", with: getAppName())
        label.textColor = .zl.noLibraryAuthTitleAndDescColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = DGCLayout.descFont
        return label
    }()
    
    private lazy var dgc_gotoSettingControl: UIControl = {
        let control = UIControl()
        control.zl.setCornerRadius(6)
        control.backgroundColor = .zl.bottomToolViewBtnNormalBgColor
        control.addTarget(self, action: #selector(dgc_gotoSetting), for: .touchUpInside)
        return control
    }()
    
    private lazy var dgc_gotoSettingLabel: UILabel = {
        let label = UILabel()
        label.text = localLanguageTextValue(.gotoSystemSettingInThumbList)
        label.textColor = .zl.noLibraryAuthGotoSettingBtnTitleColor
        label.font = DGCLayout.btnFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        dgc_setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var dgc_insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *), deviceIsFringeScreen() {
            dgc_insets = safeAreaInsets
        }
        let dgc_totalLRInset = dgc_insets.left + dgc_insets.right
        
        let dgc_titleY = zl.height / 4.6
        let dgc_titleH = ceil(
            (dgc_titleLabel.text ?? "").zl.boundingRect(
                font: DGCLayout.titleFont,
                limitSize: CGSize(width: zl.width - 40 - dgc_totalLRInset, height: .greatestFiniteMagnitude),
                lineBreakMode: .byWordWrapping
            ).height
        )
        dgc_titleLabel.frame = CGRect(x: 20 + dgc_totalLRInset / 2, y: dgc_titleY, width: zl.width - 40 - dgc_totalLRInset, height: dgc_titleH)
        
        let dgc_descY = dgc_titleLabel.zl.bottom + 18
        let dgc_descH = ceil(
            (dgc_descLabel.text ?? "").zl.boundingRect(
                font: DGCLayout.descFont,
                limitSize: CGSize(width: zl.width - 40 - dgc_totalLRInset, height: .greatestFiniteMagnitude),
                lineBreakMode: .byWordWrapping
            ).height
        )
        dgc_descLabel.frame = CGRect(x: 20 + dgc_totalLRInset / 2, y: dgc_descY, width: zl.width - 40 - dgc_totalLRInset, height: dgc_descH)
        
        var dgc_controlSize = CGSize.zero
        let dgc_settingLabelSize = (dgc_gotoSettingLabel.text ?? "").zl.boundingRect(
            font: DGCLayout.btnFont,
            limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            lineBreakMode: .byWordWrapping
        )
        
        let dgc_maxSettingLabelW: CGFloat = 250
        
        if dgc_settingLabelSize.width <= 170 {
            dgc_controlSize.width = 200
        } else if (171...dgc_maxSettingLabelW) ~= dgc_settingLabelSize.width {
            dgc_controlSize.width = dgc_settingLabelSize.width + 30
        } else {
            dgc_controlSize.width = 280
        }
        
        let dgc_settingLabelHeight = ceil(
            (dgc_gotoSettingLabel.text ?? "").zl.boundingRect(
                font: DGCLayout.btnFont,
                limitSize: CGSize(width: min(dgc_settingLabelSize.width, dgc_maxSettingLabelW), height: CGFloat.greatestFiniteMagnitude),
                lineBreakMode: .byWordWrapping
            ).height
        )
        
        if dgc_settingLabelHeight > ceil(DGCLayout.btnFont.lineHeight) {
            dgc_controlSize.height = max(dgc_settingLabelHeight + 30, 50)
        } else {
            dgc_controlSize.height = 50
        }
        
        dgc_gotoSettingControl.frame = CGRect(
            x: zl.centerX - dgc_controlSize.width / 2,
            y: zl.height - dgc_controlSize.height - 40,
            width: dgc_controlSize.width,
            height: dgc_controlSize.height
        )
        
        dgc_gotoSettingLabel.frame = CGRect(
            x: (dgc_controlSize.width - min(dgc_maxSettingLabelW, dgc_settingLabelSize.width)) / 2,
            y: 0,
            width: min(dgc_maxSettingLabelW, dgc_settingLabelSize.width),
            height: dgc_controlSize.height
        )
    }
    
    private func dgc_setupUI() {
        addSubview(dgc_titleLabel)
        addSubview(dgc_descLabel)
        addSubview(dgc_gotoSettingControl)
        dgc_gotoSettingControl.addSubview(dgc_gotoSettingLabel)
    }
    
    @objc private func dgc_gotoSetting() {
        guard let dgc_url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(dgc_url) else {
            return
        }
        
        UIApplication.shared.open(dgc_url, options: [:], completionHandler: nil)
    }
}
