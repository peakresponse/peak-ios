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

class ReportContainerViewController: UIViewController, ReportViewControllerDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    weak var delegate: ReportContainerViewControllerDelegate?
    var incident: Incident?
    var report: Report?
    var leftBarButtonItem: UIBarButtonItem?
    var editBarButtonItem: UIBarButtonItem?
    var saveBarButtonItem: UIBarButtonItem?
    var cancelBarButtonItem: UIBarButtonItem?

    var cachedViewControllers: [UIViewController] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.addSegment(title: "ReportContainerViewController.tab.incident".localized)
        segmentedControl.addSegment(title: "ReportContainerViewController.tab.ringdown".localized)

        editBarButtonItem = UIBarButtonItem(title: "NavigationBar.edit".localized,
                                            style: .done,
                                            target: self,
                                            action: #selector(editPressed))
        saveBarButtonItem = UIBarButtonItem(title: "NavigationBar.save".localized,
                                            style: .done,
                                            target: self,
                                            action: #selector(savePressed))
        cancelBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                              style: .plain,
                                               target: self,
                                               action: #selector(cancelPressed))

        showReport()
    }

    @IBAction func segmentedControlChanged(_ sender: SegmentedControl) {
        removeCurrentViewController()
        switch segmentedControl.selectedIndex {
        case 0:
            commandHeader.rightBarButtonItem = editBarButtonItem
            showReport()
        case 1:
            commandHeader.rightBarButtonItem = nil
            showRingdown()
        default:
            break
        }
    }

    @objc func cancelPressed() {
        segmentedControl.isEnabled = true
        commandHeader.leftBarButtonItem = leftBarButtonItem
        commandHeader.rightBarButtonItem = editBarButtonItem
        if let vc = children[0] as? ReportViewController {
            vc.setEditing(false, animated: true)
            vc.resetFormFields()
            vc.scrollView.setContentOffset(.zero, animated: true)
        }
    }

    @objc func editPressed() {
        segmentedControl.isEnabled = false
        leftBarButtonItem = commandHeader.leftBarButtonItem
        commandHeader.leftBarButtonItem = cancelBarButtonItem
        commandHeader.rightBarButtonItem = saveBarButtonItem
        if let vc = children[0] as? ReportViewController {
            vc.setEditing(true, animated: true)
        }
    }

    @objc func savePressed() {
        if let vc = children[0] as? ReportViewController {
            if let report = vc.newReport {
                AppRealm.saveReport(report: report)
                if let canonicalId = report.canonicalId {
                    self.report = AppRealm.open().object(ofType: Report.self, forPrimaryKey: canonicalId)
                    vc.report = self.report
                }
            }
            vc.setEditing(false, animated: true)
            vc.scrollView.setContentOffset(.zero, animated: true)
        }
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
            commandHeader.rightBarButtonItem = editBarButtonItem
        }
    }

    func showRingdown() {
        var vc: UIViewController
        if cachedViewControllers.count > 1 {
            vc = cachedViewControllers[1]
        } else {
            vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Ringdown")
            if let vc = vc as? RingdownViewController {
                vc.report = report
            }
        }
        addChild(vc)
        containerView.addSubview(vc.view)
        vc.view.frame = containerView.bounds
        vc.didMove(toParent: self)
    }

    // MARK: - ReportViewController

    func reportViewControllerNeedsEditing(_ vc: ReportViewController) {
        editPressed()
    }
}
