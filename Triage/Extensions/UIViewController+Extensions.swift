//
//  UIViewController+Extensions.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import PRKit
import UIKit

extension UIViewController: AuthViewControllerDelegate, ReportContainerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    @IBInspectable var isModal: Bool {
        get {
            if #available(iOS 13.0, *) {
                return isModalInPresentation
            } else {
                return true
            }
        }
        set {
            if #available(iOS 13.0, *) {
                isModalInPresentation = newValue
            }
        }
    }

    func presentAlert(error: Error, completion: (() -> Void)? = nil) {
        presentAlert(title: "Error.title".localized, message: error.localizedDescription, completion: completion)
    }

    func presentAlert(title: String?, message: String?, completion: (() -> Void)? = nil) {
        let vc = ModalViewController()
        vc.titleText = title
        vc.messageText = message
        vc.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (_) in
            completion?()
        }))
        presentAnimated(vc)
    }

    func presentUnexpectedErrorAlert() {
        presentAlert(title: "Error.title".localized, message: "Error.unexpected".localized)
    }

    func logout() {
        REDApiClient.shared?.logout {
            REDApiClient.shared = nil
            REDRealm.disconnect()
            REDRealm.deleteAll()
        }
        PRApiClient.shared.logout { [weak self] in
            AppRealm.disconnectScene()
            AppRealm.disconnectIncidents()
            AppRealm.deleteAll()
            AppSettings.logout()
            DispatchQueue.main.async { [weak self] in
                self?.presentLogin()
            }
        }
    }

    func presentLogin() {
        if let vc = UIStoryboard(name: "Auth", bundle: nil).instantiateInitialViewController() as? AuthViewController {
            vc.delegate = self
            presentAnimated(vc)
        }
    }

    func presentAnimated(_ vc: UIViewController) {
        if vc as? UIAlertController == nil {
            vc.presentationController?.delegate = self
        }
        present(vc, animated: true, completion: { [weak self] in
            self?.didPresentAnimated()
        })
    }

    @objc func didPresentAnimated() {

    }

    @IBAction func dismissAnimated() {
        dismiss(animated: true, completion: { [weak self] in
            self?.didDismissPresentation()
        })
    }

    @objc func didDismissPresentation() {

    }

    @objc func newReportCancelled() {
        dismissAnimated()
    }

    func presentNewReport(incident: Incident?, pin: String? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        let report = Report.newRecord()
        report.pin = pin
        report.incident = incident
        if let scene = incident?.scene {
            report.scene = Scene(clone: scene)
        }
        report.response?.incidentNumber = incident?.number
        let realm = AppRealm.open()
        if let vehicleId = AppSettings.vehicleId {
            if let dispatch = incident?.dispatches.first(where: { $0.vehicleId == vehicleId }) {
                report.time?.unitNotifiedByDispatch = dispatch.dispatchedAt
            }
            if let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
                report.response?.unitNumber = vehicle.number
                report.response?.callSign = vehicle.callSign
            }
        }
        presentReport(report: report, animated: animated, completion: completion)
    }

    func presentReport(report: Report, animated: Bool = true, completion: (() -> Void)? = nil) {
        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "ReportContainer")
        if let vc = vc as? ReportContainerViewController {
            vc.delegate = self
            vc.incident = report.incident
            vc.report = report
            _ = vc.view
            if report.realm == nil {
                vc.commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                                                     style: .plain,
                                                                     target: self,
                                                                     action: #selector(newReportCancelled))
            } else {
                vc.commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized,
                                                                     style: .plain,
                                                                     target: self,
                                                                     action: #selector(dismissAnimated))
            }
        }
        let navVC = NavigationController(rootViewController: vc)
        navVC.isNavigationBarHidden = true
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: animated) {
            completion?()
        }
    }

    func incidentPressed(_ incident: Incident) {
        if let scene = incident.scene, scene.isMCI {
            let sceneId = scene.canonicalId ?? scene.id
            if scene.isActive {
                let vc = ModalViewController()
                vc.messageText = "ActiveScene.message".localized
                vc.isDismissedOnAction = false
                vc.addAction(UIAlertAction(title: "Button.joinScene".localized, style: .destructive, handler: { (_) in
                    AppRealm.joinScene(sceneId: scene.id) { (_) in
                        DispatchQueue.main.async {
                            vc.dismissAnimated()
                            AppSettings.sceneId = sceneId
                            AppDelegate.enterScene(id: sceneId)
                        }
                    }
                }))
                vc.addAction(UIAlertAction(title: "Button.viewScene".localized, style: .default, handler: { (_) in
                    vc.dismissAnimated()
                    AppSettings.sceneId = sceneId
                    AppDelegate.enterScene(id: sceneId)
                }))
                vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
                presentAnimated(vc)
            } else {
                AppSettings.sceneId = sceneId
                AppDelegate.enterScene(id: sceneId)
            }
        } else {
            let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Reports")
            if let vc = vc as? ReportsViewController {
                vc.incident = incident
                vc.modalPresentationStyle = .overCurrentContext
            }
            present(vc, animated: true)
        }
    }

    // MARK: - AuthViewControllerDelegate

    func authViewControllerDidLogin(_ vc: AuthViewController) {
        dismissAnimated()
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        didDismissPresentation()
    }

    // MARK: - ReportContainerViewControllerDelegate

    @objc func reportContainerViewControllerDidSave(_ vc: ReportContainerViewController) {

    }
}
