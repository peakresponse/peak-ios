//
//  FilterView.swift
//  Triage
//
//  Created by Francis Li on 4/7/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol FilterViewDelegate {
    @objc optional func filterView(_ filterView: FilterView, didChangeSearch text: String?)
    @objc optional func filterView(_ filterView: FilterView, didPressButton button: UIButton)
}

class FilterView: UIView, UITextFieldDelegate {
    @IBOutlet weak var textField: TextField!
    @IBOutlet weak var button: DropdownButton!

    weak var delegate: FilterViewDelegate?
    var searchDebounceTimer: Timer?

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 28)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    deinit {
        searchDebounceTimer?.invalidate()
    }
    
    private func commonInit() {
        loadNib()
        backgroundColor = .clear
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        delegate?.filterView?(self, didPressButton: button)
    }
    
    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textFieldShouldClear(textField)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] (timer) in
            guard let self = self else { return }
            self.delegate?.filterView?(self, didChangeSearch: textField.text)
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
