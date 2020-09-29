//
//  SelectorView.swift
//  Triage
//
//  Created by Francis Li on 3/22/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class SelectorButton: UIButton {
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var titleRect = super.titleRect(forContentRect: contentRect)
        titleRect.origin.x = 14
        titleRect.origin.y = floor((contentRect.height - titleRect.height) / 2)
        return titleRect
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var imageRect = super.imageRect(forContentRect: contentRect)
        imageRect.origin.x = contentRect.width - imageRect.width - 16
        imageRect.origin.y = floor((contentRect.height - imageRect.height) / 2)
        return imageRect
    }
}

@objc protocol SelectorViewDelegate {
    @objc optional func selectorView(_ view: SelectorView, didSelectButtonAtIndex index: Int)
}

class SelectorView: UIView {
    private let stackView = UIStackView()
    weak var delegate: SelectorViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        addShadow(withOffset: CGSize(width: 0, height: 4), radius: 3, color: .black, opacity: 0.1)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    private func buttonBackgroundImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 2), false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 2))
        let scale = UIScreen.main.scale
        let width = 1 / scale
        context.setLineWidth(width)
        context.setStrokeColor(UIColor.lowPriorityGrey.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: 0))
        context.addLine(to: CGPoint(x: 1, y: 0))
        context.strokePath()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image.resizableImage(withCapInsets: UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0))
    }

    func addButton(title: String) {
        let button = SelectorButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setBackgroundImage(buttonBackgroundImage(), for: .normal)
        button.setBackgroundImage(UIImage.resizableImage(withColor: .lowPriorityGrey, cornerRadius: 0), for: .highlighted)
        button.titleLabel?.font = .copySRegular
        button.setTitleColor(.mainGrey, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(button)
        NSLayoutConstraint.activate([button.heightAnchor.constraint(equalToConstant: 44)])
    }

    @objc func buttonPressed(_ button: UIButton) {
        if let index = stackView.arrangedSubviews.firstIndex(of: button) {
            delegate?.selectorView?(self, didSelectButtonAtIndex: index)
        }
    }
}
