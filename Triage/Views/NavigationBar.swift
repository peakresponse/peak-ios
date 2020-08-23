//
//  NavigationBar.swift
//  Triage
//
//  Created by Francis Li on 8/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@IBDesignable
class NavigationBar: UIView {
    @IBOutlet var navigationItem: UINavigationItem? {
        willSet {
            removeObservers()
        }
        didSet {
            addObservers()
            updateButtons()
        }
    }

    @IBInspectable var barTintColor: UIColor? {
        get { return backgroundColor }
        set { backgroundColor = newValue }
    }
    override var tintColor: UIColor! {
        didSet { updateButtons() }
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
        backgroundColor = .greyPeakBlue
        tintColor = .white
        addShadow(withOffset: CGSize(width: 0, height: 6), radius: 20, color: .black, opacity: 0.1)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 38)
        ])
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateButtons()
    }

    deinit {
        removeObservers()
    }
    
    private func removeObservers() {
        if let navigationItem = navigationItem {
            navigationItem.removeObserver(self, forKeyPath: "leftBarButtonItem")
            navigationItem.removeObserver(self, forKeyPath: "leftBarButtonItems")
            navigationItem.removeObserver(self, forKeyPath: "rightBarButtonItem")
            navigationItem.removeObserver(self, forKeyPath: "rightBarButtonItems")
        }
    }

    private func addObservers() {
        if let navigationItem = navigationItem {
            navigationItem.addObserver(self, forKeyPath: "leftBarButtonItem", options: [], context: nil)
            navigationItem.addObserver(self, forKeyPath: "leftBarButtonItems", options: [], context: nil)
            navigationItem.addObserver(self, forKeyPath: "rightBarButtonItem", options: [], context: nil)
            navigationItem.addObserver(self, forKeyPath: "rightBarButtonItems", options: [], context: nil)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        updateButtons()
    }
    
    private func view(for item: UIBarButtonItem) -> UIView? {
        var view = item.customView
        if let subview = view {
            /// clone the view- for some reason, this is necessary or the view will be removed by some other system action handling the navigation item
            guard let subview = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(NSKeyedArchiver.archivedData(withRootObject: subview, requiringSecureCoding: false)) as? UIView else { return nil }
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(subview)
            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalTo: subview.widthAnchor),
                containerView.heightAnchor.constraint(equalTo: subview.heightAnchor)
            ])
            view = containerView
        } else {
            let button = UIButton(type: .custom)
            button.titleLabel?.font = .copySBold
            button.setTitleColor(tintColor, for: .normal)
            button.setTitleColor(tintColor.colorWithBrightnessMultiplier(multiplier: 0.4), for: .highlighted)
            button.setTitle(item.title, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            if let target = item.target, let action = item.action {
                button.addTarget(target, action: action, for: .touchUpInside)
            }
            view = button
        }
        return view
    }

    private func updateButtons() {
        for view in subviews {
            view.removeFromSuperview()
        }
        if let navigationItem = navigationItem {
            if let leftBarButtonItems = navigationItem.leftBarButtonItems {
                var prevView: UIView?
                for item in leftBarButtonItems {
                    if let view = self.view(for: item) {
                        addSubview(view)
                        NSLayoutConstraint.activate([
                            view.centerYAnchor.constraint(equalTo: centerYAnchor),
                            view.leftAnchor.constraint(equalTo: prevView?.rightAnchor ?? leftAnchor, constant: 22)
                        ])
                        prevView = view
                    }
                }
            }
            if let rightBarButtonItems = navigationItem.rightBarButtonItems {
                var prevView: UIView?
                for item in rightBarButtonItems {
                    if let view = self.view(for: item) {
                        addSubview(view)
                        NSLayoutConstraint.activate([
                            view.centerYAnchor.constraint(equalTo: centerYAnchor),
                            view.rightAnchor.constraint(equalTo: prevView?.leftAnchor ?? rightAnchor, constant: -22)
                        ])
                        prevView = view
                    }
                }
            }
        }
    }
}
