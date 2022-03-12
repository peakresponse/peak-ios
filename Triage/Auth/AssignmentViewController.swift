//
//  AssignmentViewController.swift
//  Triage
//
//  Created by Francis Li on 10/21/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import Keyboardy
import PRKit
import RealmSwift

@objc protocol AssignmentViewControllerDelegate {
    @objc optional func assignmentViewController(_ vc: AssignmentViewController, didCreate assignmentId: String)
}

class AssignmentViewController: UIViewController, CheckboxDelegate, CommandFooterDelegate,
                                PRKit.FormFieldDelegate, KeyboardAwareScrollViewController {
    @IBOutlet weak var welcomeHeader: WelcomeHeader!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var otherTextField: PRKit.TextField!
    @IBOutlet weak var otherTextFieldWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var commandFooter: CommandFooter!
    @IBOutlet weak var continueButton: PRKit.Button!
    @IBOutlet weak var skipButton: PRKit.Button!

    weak var delegate: AssignmentViewControllerDelegate?

    var checkboxes: [Checkbox] = []
    var notificationToken: NotificationToken?
    var results: Results<Vehicle>?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if view.traitCollection.horizontalSizeClass == .regular {
            otherTextFieldWidthConstraint.isActive = false
            let widthConstraint = otherTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.5)
            widthConstraint.isActive = true
            otherTextFieldWidthConstraint = widthConstraint
        }
        commandFooterDidUpdateLayout(commandFooter, isOverlapping: commandFooter.isOverlapping)

        otherTextField.isHidden = true
        continueButton.isEnabled = false

        guard let userId = AppSettings.userId, let agencyId = AppSettings.agencyId else {
            return
        }

        let realm = AppRealm.open()
        if let user = realm.object(ofType: User.self, forPrimaryKey: userId) {
            let nameAndPosition = "\(user.position ?? "") \(user.fullName)".trimmingCharacters(in: .whitespaces)
            welcomeHeader.labelText = String(format: "AssignmentViewController.welcome".localized, nameAndPosition)
            welcomeHeader.imageURL = user.iconUrl
        }

        results = realm.objects(Vehicle.self)
            .filter("createdByAgencyId=%@", agencyId)
            .sorted(by: [SortDescriptor(keyPath: "number", ascending: true)])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }

        AppRealm.getVehicles { [weak self] (error) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.activityIndicatorView.stopAnimating()
                self.otherTextField.isHidden = false
                if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Vehicle>>) {
        switch changes {
        case .initial:
            fallthrough
        case .update:
            addCheckboxes()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func addCheckboxes() {
        // remove all existing views
        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }
        checkboxes.removeAll()

        guard let results = results else { return }
        // re-add all
        let columns = view.traitCollection.horizontalSizeClass == .regular ? 4 : 2
        var stackView: UIStackView?
        let count = results.count
        for i in 0..<count {
            let vehicle = results[i]
            if i % columns == 0 {
                let newStackView = UIStackView()
                newStackView.translatesAutoresizingMaskIntoConstraints = false
                newStackView.axis = .horizontal
                newStackView.spacing = 20
                newStackView.distribution = .fillEqually
                containerView.addSubview(newStackView)
                NSLayoutConstraint.activate([
                    newStackView.topAnchor.constraint(equalTo: stackView?.bottomAnchor ?? containerView.topAnchor, constant: 30),
                    newStackView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                    newStackView.rightAnchor.constraint(equalTo: containerView.rightAnchor)
                ])
                stackView = newStackView
            }
            let checkbox = Checkbox()
            checkbox.tag = i
            checkbox.delegate = self
            checkbox.labelText = "\(vehicle.number ?? "")"
            stackView?.addArrangedSubview(checkbox)
            checkboxes.append(checkbox)
        }
        if count % columns > 0 {
            for _ in 0..<(columns - count % columns) {
                stackView?.addArrangedSubview(UIView())
            }
        }
        if let bottomAnchor = stackView?.bottomAnchor {
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    @IBAction func skipPressed() {
        createAssignment(number: nil, vehicleId: nil)
    }

    @IBAction func continuePressed() {
        var number: String?
        var vehicleId: String?
        if let text = otherTextField.text, !text.isEmpty {
            number = text
        } else {
            for checkbox in checkboxes {
                if checkbox.isChecked {
                    let vehicle = results?[checkbox.tag]
                    vehicleId = vehicle?.id
                    break
                }
            }
        }
        createAssignment(number: number, vehicleId: vehicleId)
    }

    func createAssignment(number: String?, vehicleId: String?) {
        commandFooter.isLoading = true
        AppRealm.createAssignment(number: number, vehicleId: vehicleId) { [weak self] (assignment, error) in
            let assignmentId = assignment?.id
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.commandFooter.isLoading = false
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    AppSettings.assignmentId = assignmentId
                    self.delegate?.assignmentViewController?(self, didCreate: assignmentId ?? "")
                }
            }
        }
    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        if isChecked {
            for otherCheckbox in checkboxes {
                if otherCheckbox != checkbox {
                    otherCheckbox.isChecked = false
                }
            }
            otherTextField.text = nil
            _ = otherTextField.resignFirstResponder()
        }
        continueButton.isEnabled = isChecked
    }

    // MARK: - CommandFooterDelegate

    func commandFooterDidUpdateLayout(_ commandFooter: CommandFooter, isOverlapping: Bool) {
        scrollViewBottomConstraint.isActive = false
        var constraint: NSLayoutConstraint
        if isOverlapping {
            constraint = scrollView.bottomAnchor.constraint(equalTo: commandFooter.topAnchor)
            constraint.isActive = true
        } else {
            constraint = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            constraint.isActive = true
        }
        scrollViewBottomConstraint = constraint
    }

    // MARK: - FormFieldDelegate

    func formFieldDidChange(_ field: PRKit.FormField) {
        if !(field.text?.isEmpty ?? true) {
            for checkbox in checkboxes {
                checkbox.isChecked = false
            }
            continueButton.isEnabled = true
        } else {
            continueButton.isEnabled = false
        }
    }

    // MARK: - KeyboardStateDelegate

    public func keyboardTransitionAnimation(_ state: KeyboardState) {
        switch state {
        case .activeWithHeight(let height):
            scrollViewBottomConstraint.constant = -height + (commandFooter.isOverlapping ? commandFooter.frame.height : 0)
        case .hidden:
            scrollViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }
}
