//
//  RingdownViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit
import RealmSwift

class RingdownViewController: UIViewController, CheckboxDelegate, FormViewController, KeyboardAwareScrollViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!

    @IBOutlet weak var checkboxesView: UIStackView!
    @IBOutlet weak var code2Checkbox: Checkbox!
    @IBOutlet weak var code3Checkbox: Checkbox!
    var codeCheckboxes: [Checkbox]!
    @IBOutlet weak var stableCheckbox: Checkbox!
    @IBOutlet weak var unstableCheckbox: Checkbox!
    var stabilityCheckboxes: [Checkbox]!

    weak var statusSection: FormSection!

    var formInputAccessoryView: UIView!
    var formFields: [PRKit.FormField] = []

    var results: Results<HospitalStatusUpdate>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        codeCheckboxes = [code2Checkbox, code3Checkbox]
        code3Checkbox.isEnabled = false
        stabilityCheckboxes = [stableCheckbox, unstableCheckbox]

        let (section, cols, _, _) = newSection()
        section.addArrangedSubview(checkboxesView)

        let hr = PixelRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
        section.addArrangedSubview(hr)

        section.addArrangedSubview(cols)
        containerView.addArrangedSubview(section)
        self.statusSection = section

        let realm = VLRealm.open()
        results = realm.objects(HospitalStatusUpdate.self)
            .sorted(by: [SortDescriptor(keyPath: "sortSequenceNumber", ascending: true)])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<HospitalStatusUpdate>>) {
        switch changes {
        case .initial:
            if let results = results {
                for update in results {
                    let facilityView = RingdownFacilityView()
                    facilityView.update(from: update)
                    facilityView.tag = update.sortSequenceNumber ?? 0
                    let col = ((update.sortSequenceNumber ?? 1) - 1).isMultiple(of: 2) ? statusSection.colA : statusSection.colB
                    col?.addArrangedSubview(facilityView)
                    let hr = PixelRuleView()
                    hr.translatesAutoresizingMaskIntoConstraints = false
                    hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
                    col?.addArrangedSubview(hr)
                }
            }
        case .update(let results, _, let insertions, let modifications):
            for index in insertions {
                let update = results[index]
                let facilityView = RingdownFacilityView()
                facilityView.update(from: update)
                let col = ((update.sortSequenceNumber ?? 1) - 1).isMultiple(of: 2) ? statusSection.colA : statusSection.colB
                col?.addArrangedSubview(facilityView)
                let hr = PixelRuleView()
                hr.translatesAutoresizingMaskIntoConstraints = false
                hr.heightAnchor.constraint(equalToConstant: 1).isActive = true
                col?.addArrangedSubview(hr)
            }
            var facilityViews: [RingdownFacilityView] = []
            FormSection.subviews(&facilityViews, in: statusSection)
            for index in modifications {
                let update = results[index]
                facilityViews[index].update(from: update)
            }
        case .error(let error):
            presentAlert(error: error)
        }
    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        if codeCheckboxes.contains(checkbox) {
            for codeCheckbox in codeCheckboxes {
                if codeCheckbox != checkbox {
                    codeCheckbox.isChecked = false
                }
            }
        } else if stabilityCheckboxes.contains(checkbox) {
            for stabilityCheckbox in stabilityCheckboxes {
                if stabilityCheckbox != checkbox {
                    stabilityCheckbox.isChecked = false
                }
            }
        }
    }
}
