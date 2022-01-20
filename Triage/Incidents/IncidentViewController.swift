//
//  IncidentViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit

protocol IncidentViewControllerDelegate: NSObject {
    func incidentViewControllerDidSave(_ vc: IncidentViewController)
}

class IncidentViewController: UIViewController, ReportViewControllerDelegate {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    weak var delegate: IncidentViewControllerDelegate?
    var incident: Incident?
    var report: Report?
    var leftBarButtonItem: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.addSegment(title: "IncidentViewController.tab.incident".localized)
        segmentedControl.addSegment(title: "IncidentViewController.tab.ringdown".localized)
        segmentedControl.addSegment(title: "IncidentViewController.tab.refusal".localized)

        showReport()
    }

    @objc func cancelPressed() {
        commandHeader.leftBarButtonItem = leftBarButtonItem
        commandHeader.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.edit".localized,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(editPressed))
        if let vc = children[0] as? ReportViewController {
            vc.setEditing(false, animated: true)
            vc.resetFormFields()
            vc.scrollView.setContentOffset(.zero, animated: true)
        }
    }

    @objc func editPressed() {
        leftBarButtonItem = commandHeader.leftBarButtonItem
        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                                          style: .plain,
                                                           target: self,
                                                           action: #selector(cancelPressed))
        commandHeader.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.save".localized,
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(savePressed))
        if let vc = children[0] as? ReportViewController {
            vc.setEditing(true, animated: true)
        }
    }

    @objc func savePressed() {
        if let vc = children[0] as? ReportViewController {
            if let report = vc.newReport {
                AppRealm.saveReport(report: report)
            }
            vc.setEditing(false, animated: true)
            vc.scrollView.setContentOffset(.zero, animated: true)
        }
        commandHeader.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.edit".localized,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(editPressed))
        segmentedControl.isHidden = false
        delegate?.incidentViewControllerDidSave(self)
    }

    func showReport() {
        guard let report = report else { return }

        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Report")
        if let vc = vc as? ReportViewController {
            vc.delegate = self
            vc.report = report
            vc.isEditing = report.realm == nil
        }
        addChild(vc)
        containerView.addSubview(vc.view)
        vc.view.frame = containerView.bounds
        vc.didMove(toParent: self)

        activityIndicatorView.isHidden = true
        segmentedControl.isHidden = report.realm == nil ? true : false
        containerView.isHidden = false

        if vc.isEditing {
            commandHeader.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.save".localized,
                                                               style: .done,
                                                               target: self,
                                                               action: #selector(savePressed))
        } else {
            commandHeader.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.edit".localized,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(editPressed))
        }
    }

    // MARK: - ReportViewController

    func reportViewControllerNeedsEditing(_ vc: ReportViewController) {
        editPressed()
    }
}
