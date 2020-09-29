//
//  TabBar.swift
//  Triage
//
//  Created by Francis Li on 8/6/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

private class TabBarButton: UIButton {
    var item: UITabBarItem? {
        didSet {
            setImage(item?.image, for: .normal)
            setImage(item?.selectedImage, for: .highlighted)
            setImage(item?.selectedImage, for: .selected)
            setImage(item?.selectedImage, for: [.highlighted, .selected])
            setTitle(item?.title, for: .normal)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    convenience init() {
        self.init(type: .custom)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        imageView?.tintColor = .lowPriorityGrey

        titleLabel?.font = .copyXSBold
        titleLabel?.textAlignment = .center
        setTitleColor(.lowPriorityGrey, for: .normal)
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageRect = super.imageRect(forContentRect: contentRect)
        var y: CGFloat = 10
        if let item = item as? TabBarItem, item.isLarge {
            y = 0
        }
        return CGRect(x: floor((contentRect.width - imageRect.width) / 2), y: y, width: imageRect.width, height: imageRect.height)
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleRect = super.titleRect(forContentRect: contentRect)
        let imageRect = self.imageRect(forContentRect: contentRect)
        var py: CGFloat = 8
        if let item = item as? TabBarItem, item.isLarge {
            py = 4
        }
        return CGRect(x: 0, y: imageRect.maxY + py, width: contentRect.width, height: titleRect.height)
    }
}

@objc protocol TabBarDelegate {
    @objc optional func customTabBar(_ tabBar: TabBar, didSelectItem item: UITabBarItem)
}

@IBDesignable
class TabBarItem: UITabBarItem {
    @IBInspectable var isLarge: Bool = false
    @IBInspectable var segueIdentifier: String?
}

@IBDesignable
class PlaceholderTabBar: UITabBar {
    @IBInspectable var height: CGFloat = 76

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = height
        // adjust for safe area
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let insets = window.safeAreaInsets
            sizeThatFits.height += insets.bottom
        }
        return sizeThatFits
    }
}

class TabBar: UIView {
    let stackView = UIStackView()
    weak var tabBar: UITabBar!
    weak var delegate: TabBarDelegate?

    var items: [UITabBarItem]? {
        didSet {
            updateSubviews()
        }
    }
    var selectedItem: UITabBarItem? {
        didSet {
            selectItem()
        }
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
        backgroundColor = .white
        addShadow(withOffset: CGSize(width: 4, height: -4), radius: 20, color: .gray, opacity: 0.2)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }

    private func updateSubviews() {
        // remove any existing views
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        // add subviews for items
        guard let items = items else { return }
        for item in items {
            let itemView = TabBarButton()
            itemView.item = item
            itemView.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(itemView)
        }
    }

    private func selectItem() {
        for itemView in stackView.arrangedSubviews {
            if let itemView = itemView as? TabBarButton {
                itemView.isSelected = itemView.item == selectedItem
            }
        }
    }

    @objc private func buttonPressed(_ sender: TabBarButton) {
        if let item = sender.item {
            if let item = item as? TabBarItem, item.segueIdentifier != nil {
                // noop
            } else {
                selectedItem = item
            }
            delegate?.customTabBar?(self, didSelectItem: item)
        }
    }
}
