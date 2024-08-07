//
//  LocationViewController.swift
//  Triage
//
//  Created by Francis Li on 10/21/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation
import PRKit
import UIKit

protocol LocationViewControllerDelegate: AnyObject {
    func locationViewControllerDidChange(_ vc: LocationViewController)
}

class LocationViewController: UIViewController, FormBuilder, KeyboardAwareScrollViewController, LocationHelperDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!

    var formInputAccessoryView: UIView!
    var formComponents: [String: PRKit.FormComponent] = [:]

    weak var delegate: LocationViewControllerDelegate?

    var scene: Scene!
    var newScene: Scene?

    var isDirty = false

    var locationHelper: LocationHelper?
    var isWaitingForLocation = true
    var currentLocation: CLLocationCoordinate2D?
    var spinnerBarButtonItem: UIBarButtonItem?
    var geocodeBarButtonItem: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.backgroundColor = .background

        let locationHelper = LocationHelper()
        locationHelper.delegate = self
        self.locationHelper = locationHelper

        if let leftBarButtonItem = navigationItem.leftBarButtonItem {
            commandHeader.leftBarButtonItem = leftBarButtonItem
        } else {
            let backButton = UIBarButtonItem(title: "Button.back".localized, style: .plain, target: self, action: #selector(backPressed))
            backButton.image = UIImage(named: "ChevronLeft40px", in: PRKitBundle.instance, compatibleWith: nil)
            commandHeader.leftBarButtonItem = backButton
        }

        if let rightBarButtonItem = navigationItem.rightBarButtonItem {
            commandHeader.rightBarButtonItem = rightBarButtonItem
        }

        let spinner = UIActivityIndicatorView.withMediumStyle()
        spinner.color = .base500
        spinner.startAnimating()
        spinnerBarButtonItem = UIBarButtonItem(customView: spinner)
        if commandHeader.rightBarButtonItem == nil {
            commandHeader.rightBarButtonItem = spinnerBarButtonItem
        } else {
            commandHeader.centerBarButtonItem = spinnerBarButtonItem
        }

        geocodeBarButtonItem = UIBarButtonItem(title: "Button.geocode".localized, style: .done, target: self, action: #selector(geocodePressed))

        if traitCollection.horizontalSizeClass == .regular {
            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalToConstant: 690)
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
                containerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
            ])
        }

        formInputAccessoryView = FormInputAccessoryView(rootView: view)

        let (section, cols, colA, colB) = newSection()
        var tag = 1

        addTextField(source: scene, attributeKey: "address1", keyboardType: .default, tag: &tag, to: colA)
        addTextField(source: scene, attributeKey: "address2", keyboardType: .default, tag: &tag, to: colB)
        addTextField(source: scene, attributeKey: "zip", keyboardType: .numbersAndPunctuation, tag: &tag, to: colA)
        addTextField(source: scene, attributeKey: "cityId",
                     attributeType: .custom(CityKeyboard()),
                     tag: &tag, to: colA)
        addTextField(source: scene, attributeKey: "stateId",
                     attributeType: .custom(SearchKeyboard(source: StateKeyboardSource(), isMultiSelect: false)),
                     tag: &tag, to: colB)

        section.addArrangedSubview(cols)
        containerView.addArrangedSubview(section)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationHelper?.requestLocation()
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    @objc func backPressed() {
        if isDirty {
            delegate?.locationViewControllerDidChange(self)
        }
        navigationController?.popViewController(animated: true)
    }

    @objc func geocodePressed() {
        if let currentLocation = currentLocation {
            if commandHeader.rightBarButtonItem == geocodeBarButtonItem {
                commandHeader.rightBarButtonItem = spinnerBarButtonItem
            } else if commandHeader.centerBarButtonItem == geocodeBarButtonItem {
                commandHeader.centerBarButtonItem = spinnerBarButtonItem
            }
            AppRealm.geocode(location: currentLocation) { [weak self] (data, error) in
                guard let self = self else { return }
                DispatchQueue.main.async { [weak self] in
                    if self?.commandHeader.rightBarButtonItem == self?.spinnerBarButtonItem {
                        self?.commandHeader.rightBarButtonItem = self?.geocodeBarButtonItem
                    } else if self?.commandHeader.centerBarButtonItem == self?.spinnerBarButtonItem {
                        self?.commandHeader.centerBarButtonItem = self?.geocodeBarButtonItem
                    }
                }
                if let error = error {
                    DispatchQueue.main.async { [weak self] in
                        self?.presentAlert(error: error)
                    }
                } else if let data = data {
                    var attributeKeys: [String] = []
                    if let address1 = data["address1"] as? String {
                        self.newScene?.address1 = address1
                        attributeKeys.append("address1")
                    }
                    if let cityId = data["cityId"] as? String {
                        self.newScene?.cityId = cityId
                        attributeKeys.append("cityId")
                    }
                    if let stateId = data["stateId"] as? String {
                        self.newScene?.stateId = stateId
                        attributeKeys.append("stateId")
                        DispatchQueue.main.async { [weak self] in
                            if let cityField = self?.formComponents["cityId"] as? PRKit.FormField, let inputView = cityField.inputView as? CityKeyboard {
                                inputView.stateId = self?.newScene?.stateId
                            }
                        }
                    }
                    if let zip = data["zip"] as? String {
                        self.newScene?.zip = zip
                        attributeKeys.append("zip")
                    }
                    self.isDirty = self.isDirty || !attributeKeys.isEmpty
                    DispatchQueue.main.async { [weak self] in
                        self?.refreshFormFields(attributeKeys: attributeKeys)
                    }
                }
            }
        }
    }

    func setGeocodeButton() {
        if commandHeader.rightBarButtonItem == spinnerBarButtonItem {
            if !isWaitingForLocation {
                commandHeader.rightBarButtonItem = isEditing && currentLocation != nil ? geocodeBarButtonItem : nil
            }
        } else if commandHeader.centerBarButtonItem == spinnerBarButtonItem {
            if !isWaitingForLocation {
                commandHeader.centerBarButtonItem = isEditing && currentLocation != nil ? geocodeBarButtonItem : nil
            }
        } else if commandHeader.rightBarButtonItem == nil {
            commandHeader.rightBarButtonItem = isEditing && currentLocation != nil ? geocodeBarButtonItem : nil
        } else {
            commandHeader.centerBarButtonItem = isEditing && currentLocation != nil ? geocodeBarButtonItem : nil
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        for formField in formComponents.values {
            formField.isEditing = editing
            formField.isEnabled = editing
            formField.target = newScene
            if !editing {
                _ = formField.resignFirstResponder()
            }
        }
        setGeocodeButton()
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        if let field = component as? PRKit.FormField, let attributeKey = field.attributeKey, let target = field.target {
            target.setValue(field.attributeValue, forKeyPath: attributeKey)
            if attributeKey == "cityId" {
                if let cityId = newScene?.cityId, let city = AppRealm.open().object(ofType: City.self, forPrimaryKey: cityId) {
                    newScene?.stateId = city.stateNumeric
                    refreshFormFields(attributeKeys: ["stateId"])
                }
                if let cityField = formComponents["cityId"] as? PRKit.FormField, let inputView = cityField.inputView as? CityKeyboard {
                    inputView.stateId = newScene?.stateId
                }
            } else if attributeKey == "stateId" {
                if let stateId = newScene?.stateId, let cityId = newScene?.cityId, let city = AppRealm.open().object(ofType: City.self, forPrimaryKey: cityId),
                   stateId != city.stateNumeric {
                    newScene?.cityId = nil
                    refreshFormFields(attributeKeys: ["cityId"])
                }
                if let cityField = formComponents["cityId"] as? PRKit.FormField, let inputView = cityField.inputView as? CityKeyboard {
                    inputView.stateId = newScene?.stateId
                }
            }
            isDirty = true
        }
    }

    func formField(_ field: PRKit.FormField, wantsToPresent vc: UIViewController) {
        presentAnimated(vc)
    }

    // MARK: - LocationHelperDelegate

    func locationHelper(_ helper: LocationHelper, didUpdateLocations locations: [CLLocation]) {
        isWaitingForLocation = false
        if locations.count > 0 {
            currentLocation = locations.first?.coordinate
            if let cityField = formComponents["cityId"] as? PRKit.FormField, let inputView = cityField.inputView as? CityKeyboard {
                inputView.currentLocation = currentLocation
            }
        }
        setGeocodeButton()
    }

    func locationHelper(_ helper: LocationHelper, didFailWithError error: Error) {
        isWaitingForLocation = false
        setGeocodeButton()
    }
}
