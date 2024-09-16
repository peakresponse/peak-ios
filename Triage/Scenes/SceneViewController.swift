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

class SceneViewController: UIViewController, PRKit.CommandHeaderDelegate, PRKit.FormFieldDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!

    func initSceneCommandHeader() {
        commandHeader.delegate = self
        commandHeader.isUserHidden = false
        commandHeader.isSearchHidden = false
        commandHeader.searchField.returnKeyType = .done
        commandHeader.searchFieldDelegate = self
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
            var userLabelText = user?.fullNameLastFirst
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

    // MARK: - CommandHeaderDelegae

    func commandHeaderDidPressUser(_ header: CommandHeader) {
        let realm = AppRealm.open()
        var messageText = ""
        var isActive = false
        var isResponder = false
        var isMGS = false
        if let vehicleId = AppSettings.vehicleId,
           let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
            messageText = vehicle.callSign ?? vehicle.number ?? ""
        }
        if let userId = AppSettings.userId,
           let user = realm.object(ofType: User.self, forPrimaryKey: userId) {
            if messageText != "" {
                messageText = "\(messageText): "
            }
            messageText = "\(messageText)\(user.fullNameLastFirst)"
        }
        if let sceneId = AppSettings.sceneId,
           let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId),
           let responder = scene.responder(userId: AppSettings.userId) {
            isActive = scene.isActive
            isResponder = true
            isMGS = scene.isMgs(userId: AppSettings.userId)
            if let role = responder.role {
                if messageText != "" {
                    messageText = "\(messageText)\n"
                }
                messageText = "\(messageText)\("Responder.role.\(role)".localized)"
            }
        }
        let vc = ModalViewController()
        vc.isDismissedOnAction = false
        vc.messageText = messageText
        var title = "Button.exitScene".localized
        if isActive && isMGS {
            title = "Button.closeScene".localized
        } else if isActive && isResponder {
            title = "Button.leaveScene".localized
        }
        vc.addAction(UIAlertAction(title: title, style: .destructive, handler: { [weak self] (_) in
            guard let self = self else { return }
            vc.dismiss(animated: false)
            if isActive && isMGS {
                let vc = ModalViewController()
                vc.isDismissedOnAction = false
                vc.messageText = "CloseSceneConfirmation.message".localized
                vc.addAction(UIAlertAction(title: "Button.close".localized, style: .destructive, handler: { [weak self] (_) in
                    guard let sceneId = AppSettings.sceneId else { return }
                    AppRealm.endScene(sceneId: sceneId) { [weak self] (error) in
                        DispatchQueue.main.async { [weak self] in
                            vc.dismissAnimated()
                            if let error = error {
                                self?.presentAlert(error: error)
                            } else {
                                _ = AppDelegate.leaveScene()
                            }
                        }
                    }
                }))
                vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
                self.presentAnimated(vc)
            } else if isActive && isResponder {
                let vc = ModalViewController()
                vc.isDismissedOnAction = false
                vc.messageText = "LeaveSceneConfirmation.message".localized
                vc.addAction(UIAlertAction(title: "Button.leave".localized, style: .destructive, handler: { [weak self] (_) in
                    guard let sceneId = AppSettings.sceneId else { return }
                    AppRealm.leaveScene(sceneId: sceneId) { [weak self] (error) in
                        DispatchQueue.main.async { [weak self] in
                            vc.dismissAnimated()
                            if let error = error {
                                self?.presentAlert(error: error)
                            } else {
                                _ = AppDelegate.leaveScene()
                            }
                        }
                    }
                }))
                vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
                self.presentAnimated(vc)
            } else {
                _ = AppDelegate.leaveScene()
            }
        }))
        vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
        presentAnimated(vc)
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        performQuery()
    }
}
