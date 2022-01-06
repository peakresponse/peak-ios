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
    func incidentViewControllerDidCancel(_ vc: IncidentViewController)
}

class IncidentViewController: UIViewController {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    weak var delegate: IncidentViewControllerDelegate?
    var incident: Incident?
    var report: Report?

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.addSegment(title: "IncidentViewController.tab.incident".localized)
        segmentedControl.addSegment(title: "IncidentViewController.tab.ringdown".localized)
        segmentedControl.addSegment(title: "IncidentViewController.tab.refusal".localized)

        showReport()
    }

    @objc func cancelPressed() {

    }

    @objc func editPressed() {

    }

    @objc func savePressed() {
        if let report = self.report {
            AppRealm.saveReport(report: report)
        }
    }

    func showReport() {
        guard let report = report else { return }

        let vc = UIStoryboard(name: "Incidents", bundle: nil).instantiateViewController(withIdentifier: "Report")
        if let vc = vc as? ReportViewController {
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
}
