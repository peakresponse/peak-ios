//
//  ReportContainerViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit

protocol ReportContainerViewControllerDelegate: NSObject {
    func reportContainerViewControllerDidSave(_ vc: ReportContainerViewController)
}

class ReportContainerViewController: UIViewController, ReportViewControllerDelegate, RingdownViewControllerDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    weak var delegate: ReportContainerViewControllerDelegate?
    var incident: Incident?
    var report: Report?
    var leftBarButtonItem: UIBarButtonItem?
    var editBarButtonItem: UIBarButtonItem?
    var transferBarButtonItem: UIBarButtonItem?
    var saveBarButtonItem: UIBarButtonItem?
    var cancelBarButtonItem: UIBarButtonItem?
    var deleteBarButtonItem: UIBarButtonItem?

    var cachedViewControllers: [UIViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background

        segmentedControl.addSegment(title: "ReportContainerViewController.tab.incident".localized)
        segmentedControl.addSegment(title: "ReportContainerViewController.tab.ringdown".localized)

        editBarButtonItem = UIBarButtonItem(title: "NavigationBar.edit".localized,
                                            style: .done,
                                            target: self,
                                            action: #selector(editPressed))
        transferBarButtonItem = UIBarButtonItem(title: "NavigationBar.transfer".localized,
                                                style: .done,
                                                target: self,
                                                action: #selector(transferPressed))
        saveBarButtonItem = UIBarButtonItem(title: "NavigationBar.save".localized,
                                            style: .done,
                                            target: self,
                                            action: #selector(savePressed))
        cancelBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                              style: .plain,
                                               target: self,
                                               action: #selector(cancelPressed))

        deleteBarButtonItem = UIBarButtonItem(title: "NavigationBar.delete".localized, style: .plain, target: self, action: #selector(deletePressed))
        deleteBarButtonItem?.tintColor = .destructiveText

        showReport()
    }

    @IBAction func segmentedControlChanged(_ sender: SegmentedControl) {
        removeCurrentViewController()
        switch segmentedControl.selectedIndex {
        case 0:
            showReport()
        case 1:
            showRingdown()
        default:
            break
        }
    }

    @objc func deletePressed() {
        let vc = ModalViewController()
        vc.isDismissedOnAction = false
        vc.messageText = "ReportContainerViewController.modal.confirmDelete".localized
        vc.addAction(UIAlertAction(title: "Button.delete".localized, style: .destructive, handler: { [weak self] (_) in
            guard let self = self else { return }
            if let vc = self.children[0] as? ReportViewController {
                if let report = vc.newReport {
                    report.deletedAt = Date()
                    self.savePressed()
                }
            }
            vc.dismissAnimated()
            self.dismissAnimated()
        }))
        vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
        presentAnimated(vc)
    }

    @objc func cancelPressed() {
        segmentedControl.isHidden = AppSettings.routedUrl?.isEmpty ?? true
        segmentedControl.isEnabled = true
        commandHeader.leftBarButtonItem = leftBarButtonItem
        commandHeader.centerBarButtonItem = nil
        commandHeader.rightBarButtonItem = editBarButtonItem
        if let vc = children[0] as? ReportViewController {
            vc.setEditing(false, animated: true)
            vc.resetFormFields()
            vc.scrollView.setContentOffset(.zero, animated: true)
        }
    }

    @objc func editPressed() {
        segmentedControl.isHidden = true
        segmentedControl.isEnabled = false
        leftBarButtonItem = commandHeader.leftBarButtonItem
        commandHeader.leftBarButtonItem = cancelBarButtonItem
        if report?.scene?.isMCI ?? false {
            commandHeader.centerBarButtonItem = deleteBarButtonItem
        }
        commandHeader.rightBarButtonItem = saveBarButtonItem
        if let vc = children[0] as? ReportViewController {
            if vc.scrollView.contentOffset.y > (segmentedControl.frame.height + 20) {
                vc.scrollView.contentOffset.y -= segmentedControl.frame.height + 20
            }
            vc.setEditing(true, animated: true)
        }
    }

    @objc func transferPressed() {
        guard let report = report else { return }
        let newReport = Report(transfer: report)
        let realm = AppRealm.open()
        if let vehicleId = AppSettings.vehicleId {
            if let dispatch = incident?.dispatches.first(where: { $0.vehicleId == vehicleId }) {
                newReport.time?.unitNotifiedByDispatch = dispatch.dispatchedAt
            }
            if let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
                newReport.response?.unitNumber = vehicle.number
                newReport.response?.callSign = vehicle.callSign
            }
        }
        self.report = newReport
        removeCurrentViewController()
        cachedViewControllers = []
        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(dismissAnimated))
        showReport()
    }

    @objc func savePressed() {
        if let vc = children[0] as? ReportViewController {
            if let report = vc.newReport {
                // special case handling for MCI reports
                if let scene = report.scene, scene.isMCI {
                    // require a triage priority
                    let priority = report.patient?.priority
                    if priority == nil || priority == TriagePriority.unknown.rawValue {
                        let modal = ModalViewController()
                        modal.messageText = "ReportContainerViewController.modal.priorityRequired".localized
                        modal.addAction(UIAlertAction(title: "Button.ok".localized, style: .default))
                        vc.presentAnimated(modal)
                        return
                    }
                    // update the scene to the latest
                    if let canonical = scene.canonical, let current = canonical.current {
                        report.scene = Scene(clone: current)
                    }
                }
                AppRealm.saveReport(report: report)
                if let canonicalId = report.canonicalId {
                    self.report = AppRealm.open().object(ofType: Report.self, forPrimaryKey: canonicalId)
                    self.incident = self.report?.incident
                    vc.report = self.report
                }
            }
            vc.setEditing(false, animated: true)
            vc.scrollView.setContentOffset(.zero, animated: true)
        }
        commandHeader.centerBarButtonItem = nil
        commandHeader.rightBarButtonItem = editBarButtonItem
        segmentedControl.isHidden = AppSettings.routedUrl?.isEmpty ?? true
        segmentedControl.isEnabled = true
        delegate?.reportContainerViewControllerDidSave(self)
    }

    func removeCurrentViewController() {
        if children.count > 0 {
            let vc = children[0]
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
    }

    func showReport() {
        guard let report = report else { return }
        var vc: UIViewController
        if cachedViewControllers.count > 0 {
            vc = cachedViewControllers[0]
        } else {
            vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Report")
            if let vc = vc as? ReportViewController {
                vc.delegate = self
                vc.report = report
                vc.isEditing = report.realm == nil
            }
            cachedViewControllers.append(vc)
        }
        addChild(vc)
        containerView.addSubview(vc.view)
        vc.view.frame = containerView.bounds
        vc.didMove(toParent: self)

        activityIndicatorView.isHidden = true
        segmentedControl.isHidden = report.realm == nil ? true : (AppSettings.routedUrl?.isEmpty ?? true)
        containerView.isHidden = false

        if vc.isEditing {
            commandHeader.rightBarButtonItem = saveBarButtonItem
        } else {
            let realm = AppRealm.open()
            if report.scene?.isMCI ?? false {
                if let scene = report.scene?.canonical as? Scene, scene.isResponder(userId: AppSettings.userId) {
                    commandHeader.rightBarButtonItem = editBarButtonItem
                } else {
                    commandHeader.rightBarButtonItem = nil
                    if let vc = vc as? ReportViewController {
                        vc.disableEditing()
                    }
                }
            } else if let vehicleId = AppSettings.vehicleId,
               let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId),
               vehicle.number == report.response?.unitNumber {
                commandHeader.rightBarButtonItem = editBarButtonItem
            } else {
                commandHeader.rightBarButtonItem = transferBarButtonItem
                segmentedControl.isHidden = true
                if let vc = vc as? ReportViewController {
                    vc.disableEditing()
                }
            }
        }
    }

    func showRingdown() {
        commandHeader.rightBarButtonItem = nil

        var vc: UIViewController
        if cachedViewControllers.count > 1 {
            vc = cachedViewControllers[1]
        } else {
            vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Ringdown")
            if let vc = vc as? RingdownViewController {
                vc.delegate = self
                vc.report = report
            }
            if cachedViewControllers.count > 0 {
                cachedViewControllers.append(vc)
            }
        }
        addChild(vc)
        containerView.addSubview(vc.view)
        vc.view.frame = containerView.bounds
        vc.didMove(toParent: self)

        let realm = AppRealm.open()
        if report?.scene?.isMCI ?? false {
            if let scene = report?.scene?.canonical as? Scene {
                vc.isEditing = scene.isResponder(userId: AppSettings.userId)
            } else {
                vc.isEditing = false
            }
        } else if let vehicleId = AppSettings.vehicleId,
                  let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
            vc.isEditing = vehicle.number == report?.response?.unitNumber
        } else {
            vc.isEditing = false
        }
    }

    // MARK: - ReportViewControllerDelegate

    func reportViewControllerNeedsEditing(_ vc: ReportViewController) {
        editPressed()
    }

    func reportViewControllerNeedsSave(_ vc: ReportViewController) {
        savePressed()
    }

    // MARK: - RingdownViewControllerDelegate

    func ringdownViewControllerDidSaveReport(_ vc: RingdownViewController) {
        if let vc = cachedViewControllers[0] as? ReportViewController {
            vc.report = AppRealm.open().object(ofType: Report.self, forPrimaryKey: vc.report.id)
            vc.resetFormFields()
        }
    }
}
