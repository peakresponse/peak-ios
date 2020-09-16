//
//  NewSceneViewController.swift
//  Triage
//
//  Created by Francis Li on 9/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import UIKit

class NewSceneViewController: UIViewController, FormFieldDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var locationView: SceneLocationView!
    @IBOutlet weak var nameField: FormField!
    @IBOutlet weak var descField: FormMultilineField!
    @IBOutlet weak var approxPatientsField: FormField!
    @IBOutlet weak var urgencyField: FormMultilineField!
    @IBOutlet weak var startAndFillLaterButton: UIButton!
    
    private var fields: [BaseField]!
    private var inputToolbar: UIToolbar!

    private var locationManager: CLLocationManager!
    private var scene: Scene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = Scene()
        scene.createdAt = Date()

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestLocation()
        
        if let title = startAndFillLaterButton.title(for: .normal) {
            var attributedTitle = NSAttributedString(string: title, attributes: [
                .font: UIFont.copySBold,
                .underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)
            ])
            startAndFillLaterButton.setAttributedTitle(attributedTitle, for: .normal)
            attributedTitle = NSAttributedString(string: title, attributes: [
                .font: UIFont.copySBold,
                .underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue),
                .foregroundColor: UIColor.lowPriorityGrey
            ])
            startAndFillLaterButton.setAttributedTitle(attributedTitle, for: .highlighted)
        }
        
        approxPatientsField.textField.keyboardType = .numberPad

        fields = [nameField, descField, approxPatientsField, urgencyField]

        let prevItem = UIBarButtonItem(image: UIImage(named: "ChevronUp"), style: .plain, target: self, action: #selector(inputPrevPressed))
        prevItem.width = 44
        let nextItem = UIBarButtonItem(image: UIImage(named: "ChevronDown"), style: .plain, target: self, action: #selector(inputNextPressed))
        nextItem.width = 44
        inputToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        inputToolbar.setItems([
            prevItem,
            nextItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: NSLocalizedString("InputAccessoryView.done", comment: ""), style: .plain, target: self, action: #selector(inputDonePressed))
        ], animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let defaultNotificationCenter = NotificationCenter.default
        defaultNotificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    private func refresh() {
        locationView.configure(from: scene)
    }
    
    @IBAction func startPressed() {
        AppRealm.createScene(scene: scene) { [weak self] (scene, error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else if let scene = scene {
                DispatchQueue.main.async {
                    AppRealm.open().refresh()
                    AppDelegate.enterScene(id: scene.id)
                }
            }
        }
    }

    override var inputAccessoryView: UIView? {
        return inputToolbar
    }
    
    @objc func inputPrevPressed() {
        if let index = fields.firstIndex(where: {$0.isFirstResponder}) {
            if index > 0 {
                _ = fields[index - 1].becomeFirstResponder()
            } else {
                _ = fields[index].resignFirstResponder()
            }
        }
    }

    @objc func inputNextPressed() {
        if let index = fields.firstIndex(where: {$0.isFirstResponder}) {
            if index < (fields.count - 1) {
                _ = fields[index + 1].becomeFirstResponder()
            } else {
                _ = fields[index].resignFirstResponder()
            }
        }
    }

    @objc func inputDonePressed() {
        if let index = fields.firstIndex(where: {$0.isFirstResponder}) {
            _ = fields[index].resignFirstResponder()
        }
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25, animations: {
                let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
                self.scrollView.contentInset = insets
                self.scrollView.scrollIndicatorInsets = insets
            }) { (completed) in
                for field in self.fields {
                    if field.isFirstResponder {
                        self.scrollView.scrollRectToVisible(self.scrollView.convert(field.bounds, from: field), animated: true)
                        break
                    }
                }
            }
        }
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25) {
            self.scrollView.contentInset = .zero
            self.scrollView.scrollIndicatorInsets = .zero
        }
    }

    // MARK: - FormFieldDelegate
    
    func formFieldDidChange(_ field: BaseField) {
        if let attributeKey = field.attributeKey {
            switch field.attributeKey {
            case "approxPatients":
                scene.approxPatients.value = Int(field.text ?? "")
            default:
                scene.setValue(field.text, forKey: attributeKey)
            }
        }
    }
    
    func formFieldShouldReturn(_ field: BaseField) -> Bool {
        if let index = fields.firstIndex(where: {$0 == field}), index < (fields.count - 1) {
            _ = fields[index + 1].becomeFirstResponder()
        } else {
            field.resignFirstResponder()
        }
        return false
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            scene.lat = String(format: "%.6f", location.coordinate.latitude)
            scene.lng = String(format: "%.6f", location.coordinate.longitude)
            let task = ApiClient.shared.geocode(lat: scene.lat!, lng: scene.lng!) { [weak self] (data, error) in
                if let error = error {
                    print(error)
                } else {
                    self?.scene.zip = data?["zip"] as? String
                    DispatchQueue.main.async { [weak self] in
                        self?.refresh()
                    }
                }
            }
            task.resume()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}
