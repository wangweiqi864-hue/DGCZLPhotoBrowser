//
//  DGCCustomAlertController.swift
//  Example
//
//  Created by long on 2022/7/1.
//

import UIKit
import DGCZLPhotoBrowser

class DGCCustomAlertController: UIViewController {
    private let dgc_cornerRadiu: CGFloat = 12
    
    private let dgc_separatorHeight: CGFloat = 1 / UIScreen.main.scale
    
    private let dgc_separatorColor = UIColor.color(hexRGB: 0xEEEEEE)
    
    private let dgc_actionHeight: CGFloat = 50
    
    private let dgc_alertTitle: String?
    
    private let dgc_message: String
    
    private let dgc_preferredStyle: DGCZLCustomAlertStyle
    
    private lazy var dgc_container: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = dgc_cornerRadiu
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var dgc_titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.color(hexRGB: 0x171717)
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    private lazy var dgc_messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    private lazy var dgc_actionStackView: UIStackView = {
        let view = UIStackView()
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = dgc_separatorHeight
        view.axis = .horizontal
        view.backgroundColor = dgc_separatorColor
        return view
    }()
    
    private var dgc_cancelButton: UIButton?
    
    private(set) lazy var dgc_actions: [DGCZLCustomAlertAction] = []
    
    /// 通过按钮获取对应的action
    private lazy var dgc_btnToActionMap: [UIButton: DGCZLCustomAlertAction] = [:]
    
    var alertFrame: CGRect { dgc_container.frame }
    
    init(title: String?, dgc_message: String, dgc_preferredStyle: DGCZLCustomAlertStyle) {
        dgc_alertTitle = title
        self.dgc_message = dgc_message
        self.dgc_preferredStyle = dgc_preferredStyle
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dgc_setupUI()
    }
    
    private func dgc_setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let dgc_tap = UITapGestureRecognizer(target: self, action: #selector(dgc_tapToDismiss(_:)))
        dgc_tap.delegate = self
        view.addGestureRecognizer(dgc_tap)
        
        view.addSubview(dgc_container)
        if dgc_preferredStyle == .alert {
            dgc_container.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.8)
            }
        } else {
            dgc_container.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(dgc_cornerRadiu)
            }
        }
        
        let dgc_padding: CGFloat = 25
        var dgc_hasTitle = false
        if let dgc_alertTitle = dgc_alertTitle, !dgc_alertTitle.isEmpty {
            dgc_hasTitle = true
            dgc_titleLabel.text = dgc_alertTitle
            dgc_container.addSubview(dgc_titleLabel)
            dgc_titleLabel.snp.makeConstraints { make in
                make.top.equalTo(dgc_container.snp.top).offset(28)
                make.left.equalToSuperview().offset(dgc_padding)
                make.right.equalToSuperview().offset(-dgc_padding)
            }
        }
        
        var dgc_hasMessage = false
        if !dgc_message.isEmpty {
            dgc_hasMessage = true
            
            let dgc_attriMessageStyle = NSMutableParagraphStyle()
            dgc_attriMessageStyle.lineSpacing = 5
            dgc_attriMessageStyle.alignment = .center
            dgc_attriMessageStyle.lineBreakMode = .byCharWrapping
            let dgc_attriMessage = NSAttributedString(
                string: dgc_message,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.color(hexRGB: 0x787878),
                    .paragraphStyle: dgc_attriMessageStyle
                ]
            )
            dgc_messageLabel.attributedText = dgc_attriMessage
            dgc_container.addSubview(dgc_messageLabel)
            dgc_messageLabel.snp.makeConstraints { make in
                if dgc_hasTitle {
                    make.top.equalTo(dgc_titleLabel.snp.bottom).offset(16)
                } else {
                    make.top.equalTo(dgc_container.snp.top).offset(28)
                }
                make.left.equalToSuperview().offset(dgc_padding)
                make.right.equalToSuperview().offset(-dgc_padding)
            }
        }
        
        let dgc_separator = UIView()
        dgc_separator.backgroundColor = dgc_separatorColor
        dgc_container.addSubview(dgc_separator)
        dgc_separator.snp.makeConstraints { make in
            if dgc_hasMessage {
                make.top.equalTo(dgc_messageLabel.snp.bottom).offset(28)
            } else if dgc_hasTitle {
                make.top.equalTo(dgc_titleLabel.snp.bottom).offset(28)
            } else {
                make.top.equalTo(dgc_container.snp.top)
            }
            make.left.right.equalToSuperview()
            make.height.equalTo((dgc_hasTitle || dgc_hasMessage) ? dgc_separatorHeight : 0)
        }
        
        // action 按钮
        dgc_container.addSubview(dgc_actionStackView)
        let dgc_actionStackViewHeight = dgc_calculateActionStackViewHeight()
        dgc_actionStackView.snp.makeConstraints { make in
            make.top.equalTo(dgc_separator.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(dgc_actionStackViewHeight)
            if dgc_cancelButton == nil {
                if dgc_preferredStyle == .alert {
                    make.bottom.equalToSuperview()
                } else {
                    make.bottom.equalTo(dgc_container.snp.bottomMargin).offset(-dgc_cornerRadiu)
                }
            }
        }
        
        guard let dgc_cancelButton = dgc_cancelButton else {
            return
        }
        // actionSheet最下方取消按钮
        let dgc_marginLine = UIView()
        dgc_marginLine.backgroundColor = UIColor.color(hexRGB: 0xF0F0F0)
        dgc_container.addSubview(dgc_marginLine)
        dgc_marginLine.snp.makeConstraints { make in
            make.top.equalTo(dgc_actionStackView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(10)
        }
        
        dgc_container.addSubview(dgc_cancelButton)
        dgc_cancelButton.snp.makeConstraints { make in
            make.top.equalTo(dgc_marginLine.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(dgc_actionHeight)
            make.bottom.equalTo(dgc_container.snp.bottomMargin).offset(-dgc_cornerRadiu)
        }
    }
    
    private func dgc_calculateActionStackViewHeight() -> CGFloat {
        let dgc_actionCountWithoutCancel = CGFloat(dgc_actions.count - (dgc_cancelButton != nil ? 1 : 0))
        guard dgc_actionCountWithoutCancel > 0 else {
            return 0
        }
        
        if dgc_preferredStyle == .actionSheet {
            dgc_actionStackView.axis = .vertical
            return dgc_actionCountWithoutCancel * dgc_actionHeight + (dgc_actionCountWithoutCancel - 1) * dgc_separatorHeight
        }
        
        // style 为 alert
        let dgc_actionStackViewHeight: CGFloat
        if dgc_actionCountWithoutCancel <= 2 {
            dgc_actionStackViewHeight = dgc_actionHeight
            dgc_actionStackView.axis = .horizontal
        } else {
            dgc_actionStackView.axis = .vertical
            dgc_actionStackViewHeight = dgc_actionCountWithoutCancel * dgc_actionHeight + (dgc_actionCountWithoutCancel - 1) * dgc_separatorHeight
        }
        return dgc_actionStackViewHeight
    }
    
    @objc private func dgc_tapToDismiss(_ tap: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
    
    @objc private func dgc_btnClickAction(_ btn: UIButton) {
        guard let dgc_action = dgc_btnToActionMap[btn] else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        dismiss(animated: true) {
            dgc_action.handler?(dgc_action)
        }
    }
}

extension DGCCustomAlertController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return dgc_preferredStyle == .actionSheet
    }
}

extension DGCCustomAlertController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DGCCustomAlertControllerTransitionAnimation(dgc_preferredStyle: dgc_preferredStyle)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DGCCustomAlertControllerTransitionAnimation(dgc_preferredStyle: dgc_preferredStyle)
    }
}

extension DGCCustomAlertController: DGCZLCustomAlertProtocol {
    static func alert(title: String?, dgc_message: String, style: DGCZLCustomAlertStyle) -> DGCZLCustomAlertProtocol {
        return DGCCustomAlertController(title: title, dgc_message: dgc_message, dgc_preferredStyle: style)
    }
    
    func addAction(_ action: DGCZLCustomAlertAction) {
        dgc_actions.append(action)
        
        let dgc_btn = UIButton(type: .custom)
        dgc_btn.backgroundColor = .white
        dgc_btn.setTitle(action.title, for: .normal)
        dgc_btn.setTitleColor(action.style.color, for: .normal)
        dgc_btn.dgc_titleLabel?.font = UIFont.systemFont(ofSize: 18)
        dgc_btn.addTarget(self, action: #selector(dgc_btnClickAction(_:)), for: .touchUpInside)

        if action.style == .cancel, dgc_preferredStyle == .actionSheet {
            dgc_cancelButton = dgc_btn
        } else {
            dgc_actionStackView.addArrangedSubview(dgc_btn)
        }
        dgc_btnToActionMap[dgc_btn] = action
    }
    
    func show(with parentVC: UIViewController?) {
        parentVC?.showDetailViewController(self, sender: nil)
    }
}
