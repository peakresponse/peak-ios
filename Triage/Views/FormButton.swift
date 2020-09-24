//
//  FormButton.swift
//  Triage
//
//  Created by Francis Li on 8/5/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

enum FormButtonSize: String {
    case xxsmall, xsmall, small, medium, large, xlarge
}

enum FormButtonStyle: String {
    case priority, lowPriority
}

class FormIconButton: UIButton {
    weak var formButton: FormButton?

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var rect = super.imageRect(forContentRect: contentRect)
        if let formButton = formButton {
            rect.origin.x = formButton.height / 3
        }
        return rect
    }
}

@IBDesignable
class FormButton: UIControl {
    let button: FormIconButton = FormIconButton()

    @IBInspectable override var isEnabled: Bool {
        get { return button.isEnabled }
        set { button.isEnabled = newValue }
    }
    @IBInspectable var l10nKey: String? {
        get { return nil }
        set { buttonLabel = newValue?.localized }
    }
    @IBInspectable var buttonLabel: String? {
        get { return button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
    }
    @IBInspectable var buttonImage: UIImage? {
        get { return button.image(for: .normal) }
        set {
            button.setImage(newValue, for: .normal)
            button.setImage(newValue?.withTintColor(highlightedButtonColor), for: .highlighted)
        }
    }
    @IBInspectable var buttonColor: UIColor = .greyPeakBlue {
        didSet {
            updateButtonBackgroundImage(color: buttonColor, state: .normal)
        }
    }
    @IBInspectable var highlightedButtonColor: UIColor = .darkPeakBlue {
        didSet {
            updateButtonBackgroundImage(color: highlightedButtonColor, state: .highlighted)
            let buttonImage = self.buttonImage
            self.buttonImage = buttonImage
        }
    }

    var size: FormButtonSize = .small {
        didSet {
            updateButtonStyles()
        }
    }
    @IBInspectable var Size: String {
        get { return size.rawValue }
        set { size = FormButtonSize(rawValue: newValue) ?? .small }
    }
    var style: FormButtonStyle = .priority {
        didSet {
            updateButtonStyles()
        }
    }
    @IBInspectable var Style: String {
        get { return style.rawValue }
        set { style = FormButtonStyle(rawValue: newValue) ?? .priority }
    }

    weak var userData: NSObject?
    
    private var heightConstraint: NSLayoutConstraint!
    var height: CGFloat {
        var height: CGFloat
        switch size {
        case .xxsmall:
            height = 34
        case .xsmall:
            height = 46
        case .small:
            height = 62
        case .medium:
            height = 96
        case .large:
            height = 96
        case .xlarge:
            height = 96
        }
        return height
    }
    var font: UIFont {
        switch size {
        case .xxsmall:
            return .copyXSBold
        case .xsmall:
            return .copySBold
        case .small:
            return .copyMBold
        case .medium:
            return .copyLBold
        default:
            return .copyXLBold
        }
    }

    convenience init(size: FormButtonSize? = nil, style: FormButtonStyle? = nil) {
        self.init()
        self.size = size ?? .small
        self.style = style ?? .priority
        updateButtonStyles()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        button.formButton = self
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addShadow(withOffset: CGSize(width: 0, height: 4), radius: 5, color: .black, opacity: 0.06)
        addSubview(button)
        heightConstraint = button.heightAnchor.constraint(equalToConstant: height)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leftAnchor.constraint(equalTo: leftAnchor),
            button.rightAnchor.constraint(equalTo: rightAnchor),
            heightConstraint,
            bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        updateButtonStyles()
    }

    private func updateButtonBackgroundImage(color: UIColor, state: UIButton.State) {
        switch style {
        case .priority:
            button.setBackgroundImage(UIImage.resizableImage(withColor: color, cornerRadius: height / 2), for: state)
        case .lowPriority:
            button.setBackgroundImage(UIImage.resizableImage(withColor: .clear, cornerRadius: height / 2, borderColor: color, borderWidth: size == .xxsmall ? 1 : 3), for: state)
        }
    }

    private func updateButtonStyles() {
        button.layer.cornerRadius = height / 2
        button.titleLabel?.font = font
        button.tintColor = buttonColor
        switch style {
        case .priority:
            button.setTitleColor(.white, for: .normal)
        case .lowPriority:
            button.setTitleColor(buttonColor, for: .normal)
            button.setTitleColor(highlightedButtonColor, for: .highlighted)
        }
        updateButtonBackgroundImage(color: buttonColor, state: .normal)
        updateButtonBackgroundImage(color: highlightedButtonColor, state: .highlighted)
        heightConstraint.constant = height
    }

    // MARK: - UIControl
    
    override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        button.removeTarget(target, action: action, for: controlEvents)
    }
}
