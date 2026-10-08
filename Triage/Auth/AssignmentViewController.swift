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
internal import RealmSwift

@objc protocol AssignmentViewControllerDelegate {
    @objc optional func assignmentViewController(_ vc: AssignmentViewController, didCreate assignmentId: String)
}

class AssignmentViewController: BaseViewController, CheckboxDelegate, PRKit.FormFieldDelegate, KeyboardAwareScrollViewController {
    weak var welcomeHeader: WelcomeHeader!
    weak var activityIndicatorView: UIActivityIndicatorView!
    weak var scrollView: UIScrollView!
    weak var scrollViewBottomConstraint: NSLayoutConstraint!
    weak var label: UILabel!
    weak var containerView: UIView!
    weak var otherTextField: PRKit.TextField!
    weak var otherTextFieldWidthConstraint: NSLayoutConstraint!
    weak var commandFooter: CommandFooter!
    weak var continueButton: PRKit.Button!
    weak var skipButton: PRKit.Button!

    weak var delegate: AssignmentViewControllerDelegate?

    var checkboxes: [Checkbox] = []
    var notificationToken: NotificationToken?
    var results: Results<Vehicle>?

    override init() {
        super.init()
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isModalInPresentation = true
    }

    deinit {
        notificationToken?.invalidate()
    }

    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        let welcomeHeader = WelcomeHeader()
        welcomeHeader.translatesAutoresizingMaskIntoConstraints = false
        welcomeHeader.preservesSuperviewLayoutMargins = true
        headerView.addSubview(welcomeHeader)
        NSLayoutConstraint.activate([
            welcomeHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
            welcomeHeader.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            welcomeHeader.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: welcomeHeader.bottomAnchor),
            welcomeHeader.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            welcomeHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.welcomeHeader = welcomeHeader

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(scrollView)
        let scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: mainView.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            scrollViewBottomConstraint
        ])
        self.scrollView = scrollView
        self.scrollViewBottomConstraint = scrollViewBottomConstraint

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "AssignmentViewController.select".localized
        label.textColor = .text
        label.font = .h4SemiBold
        scrollView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            label.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            label.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        ])
        self.label = label

        let activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.color = .base800
        activityIndicatorView.hidesWhenStopped = true
        scrollView.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30),
            activityIndicatorView.centerXAnchor.constraint(equalTo: label.centerXAnchor)
        ])
        activityIndicatorView.startAnimating()
        self.activityIndicatorView = activityIndicatorView

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .background
        scrollView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: label.bottomAnchor),
            containerView.leftAnchor.constraint(equalTo: label.leftAnchor),
            containerView.rightAnchor.constraint(equalTo: label.rightAnchor)
        ])
        self.containerView = containerView

        let otherTextField = PRKit.TextField()
        otherTextField.translatesAutoresizingMaskIntoConstraints = false
        otherTextField.isHidden = true
        otherTextField.labelText = "AssignmentViewController.other".localized
        scrollView.addSubview(otherTextField)
        let multiplier = view.traitCollection.horizontalSizeClass == .regular ? 0.5 : 1.0
        let otherTextFieldWidthConstraint = otherTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor,
                                                                                  multiplier: multiplier)
        NSLayoutConstraint.activate([
            otherTextField.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 30),
            otherTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor),
            otherTextFieldWidthConstraint,
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: otherTextField.bottomAnchor, constant: 30)
        ])
        self.otherTextField = otherTextField
        self.otherTextFieldWidthConstraint = otherTextFieldWidthConstraint

        let commandFooter = CommandFooter()
        commandFooter.translatesAutoresizingMaskIntoConstraints = false
        commandFooter.preservesSuperviewLayoutMargins = true
        footerView.addSubview(commandFooter)
        NSLayoutConstraint.activate([
            commandFooter.topAnchor.constraint(equalTo: footerView.topAnchor),
            commandFooter.leftAnchor.constraint(equalTo: footerView.leftAnchor),
            commandFooter.rightAnchor.constraint(equalTo: footerView.rightAnchor),
            footerView.bottomAnchor.constraint(equalTo: commandFooter.bottomAnchor)
        ])
        self.commandFooter = commandFooter

        let skipButton = PRKit.Button()
        skipButton.style = .secondary
        skipButton.setTitle("Button.skip".localized, for: .normal)
        skipButton.addTarget(self, action: #selector(skipPressed), for: .touchUpInside)
        commandFooter.addSubview(skipButton)
        self.skipButton = skipButton

        let continueButton = PRKit.Button()
        continueButton.style = .primary
        continueButton.isEnabled = false
        continueButton.setTitle("Button.continue".localized, for: .normal)
        continueButton.addTarget(self, action: #selector(continuePressed), for: .touchUpInside)
        commandFooter.addSubview(continueButton)
        self.continueButton = continueButton

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
        case .initial, .update:
            addCheckboxes()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func addCheckboxes(_ traitCollection: UITraitCollection? = nil) {
        let traitCollection = traitCollection ?? view.traitCollection

        otherTextFieldWidthConstraint.isActive = false
        let multiplier = traitCollection.horizontalSizeClass == .regular ? 0.5 : 1.0
        let widthConstraint = otherTextField.widthAnchor.constraint(equalTo: containerView.widthAnchor,
                                                                    multiplier: multiplier)
        widthConstraint.isActive = true
        self.otherTextFieldWidthConstraint = widthConstraint

        // remove all existing views
        for subview in containerView.subviews {
            subview.removeFromSuperview()
        }
        checkboxes.removeAll()

        guard let results = results else { return }
        // re-add all
        let columns = traitCollection.horizontalSizeClass == .regular ? 4 : 2
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

    override func updateFooterConstraints() {
        super.updateFooterConstraints()
        footerViewConstraints.append(contentsOf: commandFooter.layoutConstraints(for: contentView, in: view))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        addCheckboxes(newCollection)
    }

    @objc func skipPressed() {
        createAssignment(number: nil, vehicleId: nil)
    }

    @objc func continuePressed() {
        var number: String?
        var vehicleId: String?
        if let text = otherTextField.text, !text.isEmpty {
            number = text
        } else {
            for checkbox in checkboxes where checkbox.isChecked {
                let vehicle = results?[checkbox.tag]
                vehicleId = vehicle?.id
                break
            }
        }
        createAssignment(number: number, vehicleId: vehicleId)
    }

    func createAssignment(number: String?, vehicleId: String?) {
        commandFooter.isLoading = true
        AppRealm.createAssignment(number: number, vehicleId: vehicleId) { [weak self] (assignment, error) in
            let assignmentId = assignment?.id
            let vehicleId = assignment?.vehicleId
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.commandFooter.isLoading = false
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    AppSettings.assignmentId = assignmentId
                    AppSettings.vehicleId = vehicleId
                    self.delegate?.assignmentViewController?(self, didCreate: assignmentId ?? "")
                }
            }
        }
    }

    // MARK: - CheckboxDelegate

    func checkbox(_ checkbox: Checkbox, didChange isChecked: Bool) {
        if isChecked {
            for otherCheckbox in checkboxes where otherCheckbox != checkbox {
                otherCheckbox.isChecked = false
            }
            otherTextField.text = nil
            _ = otherTextField.resignFirstResponder()
        }
        continueButton.isEnabled = isChecked
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        if let field = component as? PRKit.FormField, !(field.text?.isEmpty ?? true) {
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
            if height > 0 {
                scrollViewBottomConstraint.constant = -height
            }
        case .hidden:
            scrollViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }
}
