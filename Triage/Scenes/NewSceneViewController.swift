//
//  NewSceneViewController.swift
//  Triage
//
//  Created by Francis Li on 9/1/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import UIKit

class NewSceneViewController: UIViewController, FormFieldDelegate, LocationHelperDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var locationView: SceneLocationView!
    @IBOutlet weak var nameField: FormField!
    @IBOutlet weak var descField: FormMultilineField!
    @IBOutlet weak var approxPatientsField: FormField!

    private var fields: [BaseField]!
    private var inputToolbar: UIToolbar!

    private var locationHelper: LocationHelper!
    private var scene: Scene!

    deinit {
        removeKeyboardListener()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addKeyboardListener()

        scene = Scene()
        scene.new()
        scene.createdAt = Date()

        locationHelper = LocationHelper()
        locationHelper.delegate = self
        locationHelper.requestLocation()
        locationView.configure(from: scene)
        locationView.activityIndicatorView.startAnimating()

        approxPatientsField.textField.keyboardType = .numberPad

        fields = [nameField, descField, approxPatientsField]

        let prevItem = UIBarButtonItem(
            image: UIImage(named: "ChevronUp"), style: .plain, target: self, action: #selector(inputPrevPressed))
        prevItem.width = 44
        let nextItem = UIBarButtonItem(
            image: UIImage(named: "ChevronDown"), style: .plain, target: self, action: #selector(inputNextPressed))
        nextItem.width = 44
        inputToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
        inputToolbar.setItems([
            prevItem,
            nextItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(
                title: NSLocalizedString("InputAccessoryView.done", comment: ""), style: .plain, target: self,
                action: #selector(inputDonePressed))
        ], animated: false)
    }

    private func refresh() {
        locationView.configure(from: scene)
    }

    @IBAction func startPressed() {
        AppRealm.createScene(scene: scene) { [weak self] (scene, error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else if let scene = scene, let canonicalId = scene.canonicalId {
                if !scene.hasLatLng {
                    AppRealm.captureLocation(sceneId: canonicalId)
                }
                DispatchQueue.main.async {
                    AppRealm.open().refresh()
                    AppDelegate.enterScene(id: canonicalId)
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

    @objc override func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
            UIView.animate(withDuration: duration, animations: {
                let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
                self.scrollView.contentInset = insets
                self.scrollView.scrollIndicatorInsets = insets
            }, completion: { (_) in
                for field in self.fields where field.isFirstResponder {
                    self.scrollView.scrollRectToVisible(self.scrollView.convert(field.bounds, from: field), animated: true)
                    break
                }
            })
        }
    }

    @objc override func keyboardWillHide(_ notification: NSNotification) {
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
                scene.approxPatientsCount.value = Int(field.text ?? "")
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

    // MARK: - LocationHelperDelegate

    func locationHelper(_ helper: LocationHelper, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            scene.lat = String(format: "%.6f", location.coordinate.latitude)
            scene.lng = String(format: "%.6f", location.coordinate.longitude)
            let task = ApiClient.shared.geocode(lat: scene.lat!, lng: scene.lng!) { [weak self] (_, _, data, error) in
                if let error = error {
                    print(error)
                } else {
                    self?.scene.zip = data?["zip"] as? String
                    DispatchQueue.main.async { [weak self] in
                        self?.locationView.activityIndicatorView.stopAnimating()
                        self?.refresh()
                    }
                }
            }
            task.resume()
        }
    }

    func locationHelper(_ helper: LocationHelper, didFailWithError error: Error) {
        locationView.activityIndicatorView.stopAnimating()
        presentAlert(error: error)
    }
}
