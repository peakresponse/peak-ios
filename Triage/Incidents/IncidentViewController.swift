//
//  IncidentViewController.swift
//  Triage
//
//  Created by Francis Li on 11/4/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit

class IncidentViewController: UIViewController {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    var incidentId: String?
    var incident: Incident?
    var report: Report?

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentedControl.addSegment(title: "IncidentViewController.tab.incident".localized)
        segmentedControl.addSegment(title: "IncidentViewController.tab.ringdown".localized)
        segmentedControl.addSegment(title: "IncidentViewController.tab.refusal".localized)

        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(cancelPressed))

        guard let incidentId = incidentId else { return }

        let realm = AppRealm.open()
        incident = realm.object(ofType: Incident.self, forPrimaryKey: incidentId)

        guard let incident = incident else { return }

        if incident.reportsCount == 0 {
            let report = Report.newRecord()
            report.incident = incident
            report.scene = incident.scene
            report.response?.incidentNumber = incident.number
            if let assignmentId = AppSettings.assignmentId,
               let assignment = realm.object(ofType: Assignment.self, forPrimaryKey: assignmentId) {
                if let dispatch = incident.dispatches.first(where: { $0.vehicleId == assignment.vehicleId }) {
                    report.time?.unitNotifiedByDispatch = dispatch.dispatchedAt
                }
                if let vehicleId = assignment.vehicleId, let vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId) {
                    report.response?.unitNumber = vehicle.number
                }
            }
            showReport(report)
        }
    }

    @objc func cancelPressed() {
        dismissAnimated()
    }

    @objc func editPressed() {

    }

    @objc func savePressed() {
        if let report = self.report {
            AppRealm.saveReport(report: report)
        }
    }

    func showReport(_ report: Report) {
        self.report = report

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
