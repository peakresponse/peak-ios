//
//  SceneViewController.swift
//  Triage
//
//  Created by Francis Li on 3/14/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

class SceneViewController: UIViewController, PRKit.FormFieldDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!

    func initSceneCommandHeader() {
        commandHeader.isUserHidden = false
        commandHeader.isSearchHidden = false
        commandHeader.searchField.returnKeyType = .done
        commandHeader.searchField.delegate = self
        commandHeader.stackView.spacing = 10

        let sceneButton = PRKit.Button()
        sceneButton.size = .small
        sceneButton.style = .secondary
        sceneButton.setTitle("#", for: .normal)
        sceneButton.addTarget(self, action: #selector(scenePressed(_:)), for: .touchUpInside)
        commandHeader.centerBarButtonItem = UIBarButtonItem(customView: sceneButton)

        var contentEdgeInsets = sceneButton.contentEdgeInsets
        contentEdgeInsets.left = 6
        contentEdgeInsets.right = 6
        sceneButton.contentEdgeInsets = contentEdgeInsets
        sceneButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        if let superview = sceneButton.superview {
            sceneButton.widthAnchor.constraint(equalTo: superview.widthAnchor).isActive = true
        }

        let realm = AppRealm.open()
        if let userId = AppSettings.userId {
            let user = realm.object(ofType: User.self, forPrimaryKey: userId)
            AppCache.cachedImage(from: user?.iconUrl) { [weak self] (image, _) in
                let image = image?.rounded()
                DispatchQueue.main.async { [weak self] in
                    self?.commandHeader.userImage = image
                }
            }
            var userLabelText = user?.fullName
            if let assignmentId = AppSettings.assignmentId,
               let assignment = realm.object(ofType: Assignment.self, forPrimaryKey: assignmentId),
               let vehicleId = assignment.vehicleId,
               let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
                userLabelText = "\(vehicle.number ?? "")"
            }
            commandHeader.userLabelText = userLabelText
        }
        if let sceneId = AppSettings.sceneId {
            let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
            if let incident = scene?.incident.first {
                sceneButton.setTitle("#\(incident.number ?? "")", for: .normal)
            }
        }
    }

    func performQuery() {

    }

    @objc func scenePressed(_ sender: PRKit.Button) {
        let vc = UIStoryboard(name: "Scenes", bundle: nil).instantiateViewController(withIdentifier: "ResponderRoles")
        if let vc = vc as? SceneOverviewViewController {
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized, style: .plain, target: self, action: #selector(dismissAnimated))
        }
        presentAnimated(vc)
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        performQuery()
    }

    func formFieldShouldBeginEditing(_ field: PRKit.FormField) -> Bool {
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            for subview in commandHeader.stackView.arrangedSubviews {
                if subview != field {
                    subview.isHidden = true
                }
            }
        }
        return true
    }

    func formFieldShouldReturn(_ field: PRKit.FormField) -> Bool {
        field.resignFirstResponder()
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            for subview in commandHeader.stackView.arrangedSubviews {
                if subview != field {
                    subview.isHidden = false
                }
            }
        }
        return false
    }
}
