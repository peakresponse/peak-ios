//
//  TransportViewController.swift
//  Triage
//
//  Created by Francis Li on 3/6/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import Foundation
import PRKit
import UIKit

struct TransportCart {
    var reports: [Report] = []
    var responder: Responder?
    var facility: Facility?
}

protocol TransportCartViewController: UIViewController {
    var cart: TransportCart? { get set }
    var collectionView: UICollectionView! { get }
    func updateCart()
    func performQuery(_ searchText: String?)
}

class TransportViewController: SceneViewController, TransportReportsViewControllerDelegate, TransportRespondersViewControllerDelegate,
                               TransportFacilitiesViewControllerDelegate, TransportConfirmViewControllerDelegate {
    @IBOutlet weak var segmentedControl: SegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var overlayView: UIView!

    var cachedViewControllers: [UIViewController?] = [nil, nil, nil]

    var incident: Incident?
    var cart = TransportCart()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tabBarItem.title = "TabBarItem.transport".localized
        tabBarItem.image = UIImage(named: "Transport", in: PRKitBundle.instance, compatibleWith: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background
        overlayView.backgroundColor = .modalBackdrop

        initSceneCommandHeader()

        if incident == nil, let sceneId = AppSettings.sceneId,
           let scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId) {
            incident = scene.incident.first
        }

        segmentedControl.addSegment(title: "TransportViewController.segment.patients".localized)
        segmentedControl.addSegment(title: "TransportViewController.segment.units".localized)
        segmentedControl.addSegment(title: "TransportViewController.segment.hospitals".localized)

        segmentedControlChanged(segmentedControl)
    }

    func removeCurrentViewController() {
        if children.count > 0 {
            let vc = children[0]
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
    }

    @IBAction func segmentedControlChanged(_ sender: SegmentedControl) {
        removeCurrentViewController()
        commandHeader.searchField.clearPressed()
        commandHeader.formFieldShouldReturn(commandHeader.searchField)
        var vc = cachedViewControllers[sender.selectedIndex]
        if vc == nil {
            switch sender.selectedIndex {
            case 0:
                vc = UIStoryboard(name: "Scenes", bundle: nil).instantiateViewController(withIdentifier: "TransportReports")
                if let vc = vc as? TransportReportsViewController {
                    vc.delegate = self
                    vc.incident = incident
                }
                cachedViewControllers[0] = vc
            case 1:
                vc = UIStoryboard(name: "Scenes", bundle: nil).instantiateViewController(withIdentifier: "TransportResponders")
                if let vc = vc as? TransportRespondersViewController {
                    vc.delegate = self
                }
                cachedViewControllers[1] = vc
            case 2:
                vc = UIStoryboard(name: "Scenes", bundle: nil).instantiateViewController(withIdentifier: "TransportFacilities")
                if let vc = vc as? TransportFacilitiesViewController {
                    vc.delegate = self
                    vc.incident = incident
                }
                cachedViewControllers[2] = vc
            default:
                break
            }
        }
        if let vc = vc as? TransportCartViewController {
            addChild(vc)
            containerView.addSubview(vc.view)
            vc.cart = cart
            vc.updateCart()
            vc.performQuery(nil)
            vc.view.frame = containerView.bounds
            vc.didMove(toParent: self)
        }
    }

    override func performQuery() {
        if let vc = children.first as? TransportCartViewController {
            vc.performQuery(commandHeader.searchField.text)
        }
    }

    // MARK: - TransportConfirmViewControllerDelegate

    func transportConfirmViewControllerDidCancel(_ vc: TransportConfirmViewController) {
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.overlayView.alpha = 0
        }, completion: { [weak self] _ in
            self?.overlayView.isHidden = true
        })
        dismissAnimated()
    }

    func transportConfirmViewControllerDidConfirm(_ vc: TransportConfirmViewController) {
        for report in cart.reports {
            let newReport = Report(clone: report)
            newReport.response?.agency = cart.responder?.agency
            newReport.response?.unitNumber = cart.responder?.vehicle?.number ?? cart.responder?.unitNumber
            newReport.response?.callSign = cart.responder?.vehicle?.callSign ?? cart.responder?.callSign
            newReport.disposition?.unitDisposition = UnitDisposition.patientContactMade.rawValue
            newReport.disposition?.patientEvaluationCare = PatientEvaluationCare.patientEvaluatedCareProvided.rawValue
            newReport.disposition?.crewDisposition = CrewDisposition.assumedPrimaryCare.rawValue
            newReport.disposition?.transportDisposition = TransportDisposition.transportByThisUnit.rawValue
            newReport.disposition?.destinationFacility = cart.facility
            AppRealm.saveReport(report: newReport)
            if AppSettings.routedUrl != nil {
                let ringdownReport = Report(clone: newReport)
                let payload = newReport.asRingdownJSON()
                REDRealm.sendRingdown(payload: payload) { (ringdown, _) in
                    if let ringdown = ringdown {
                        ringdownReport.ringdownId = ringdown.id
                        DispatchQueue.main.async {
                            AppRealm.saveReport(report: ringdownReport)
                        }
                    }
                }
            }
        }
        if let responderId = cart.responder?.id {
            AppRealm.markResponderDeparted(responderId: responderId) { _ in
            }
        }
        cart = TransportCart()
        segmentedControl.selectedIndex = 0
        segmentedControlChanged(segmentedControl)
        transportConfirmViewControllerDidCancel(vc)
    }

    // MARK: - TransportFacilitiesViewControllerDelegate

    func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didRemoveReport report: Report?) {
        if let report = report {
            if let index = cart.reports.firstIndex(of: report) {
                cart.reports.remove(at: index)
            }
            vc.cart = cart
            vc.updateCart()
        }
    }

    func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didRemoveResponder responder: Responder?) {
        if let responder = responder {
            if cart.responder == responder {
                cart.responder = nil
            }
            vc.cart = cart
            vc.updateCart()
        }
    }

    func transportFacilitiesViewController(_ vc: TransportFacilitiesViewController, didSelect facility: Facility?) {
        if let facility = facility {
            if cart.facility == facility {
                cart.facility = nil
            } else {
                cart.facility = facility
            }
            vc.cart = cart
        }
    }

    func transportFacilitiesViewControllerDidPressTransport(_ vc: TransportFacilitiesViewController) {
        let vc = UIStoryboard(name: "Scenes", bundle: nil).instantiateViewController(withIdentifier: "TransportConfirm")
        if let vc = vc as? TransportConfirmViewController {
            vc.delegate = self
            vc.cart = cart
        }
        overlayView.alpha = 0
        overlayView.isHidden = false
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.overlayView.alpha = 0.6
        }
        presentAnimated(vc)
    }

    // MARK: - TransportReportsViewControllerDelegate

    func transportReportsViewController(_ vc: TransportReportsViewController, didSelect report: Report?) {
        if let report = report {
            if let index = cart.reports.firstIndex(of: report) {
                cart.reports.remove(at: index)
            } else if report.filterPriority != TriagePriority.transported.rawValue {
                cart.reports.append(report)
            }
            vc.cart = cart
        }
    }

    // MARK: - TransportRespondersViewControllerDelegate

    func transportRespondersViewController(_ vc: TransportRespondersViewController, didSelect responder: Responder?) {
        if let responder = responder {
            if cart.responder == responder {
                cart.responder = nil
            } else {
                cart.responder = responder
            }
            vc.cart = cart
        }
    }

    func transportRespondersViewController(_ vc: TransportRespondersViewController, didRemove report: Report?) {
        if let report = report {
            if let index = cart.reports.firstIndex(of: report) {
                cart.reports.remove(at: index)
            }
            vc.cart = cart
            vc.updateCart()
        }
    }
}
