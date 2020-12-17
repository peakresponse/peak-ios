//
//  PatientViewController.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

class PatientViewController: UIViewController, PatientTableViewControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var navigationBar: NavigationBar!
    @IBOutlet weak var containerView: UIView!

    var patient: Patient!
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isModal = true

        if patient.realm != nil {
            notificationToken = patient.observe { [weak self] (change) in
                self?.didObserveChange(change)
            }
        }

        updateNavigationBarColor(priority: patient.priority.value)
    }

    private func updateNavigationBarColor(priority: Int?) {
        if let priority = priority {
            navigationBar.barTintColor = PRIORITY_COLORS[priority]
            navigationBar.tintColor = PRIORITY_LABEL_COLORS[priority]
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navVC = segue.destination as? UINavigationController,
            let vc = navVC.topViewController as? PatientTableViewController {
            vc.patient = patient
            vc.delegate = self
            navVC.delegate = self
        }
    }

    func didObserveChange(_ change: ObjectChange<Patient>) {
        switch change {
        case .change:
            updateNavigationBarColor(priority: patient.priority.value)
        case .error(let error):
            presentAlert(error: error)
        case .deleted:
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - PatientTableViewControllerDelegate

    func patientTableViewController(_ vc: PatientTableViewController, didUpdatePriority priority: Int) {
        updateNavigationBarColor(priority: priority)
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        navigationBar.navigationItem = viewController.navigationItem
        if let priority = (viewController as? PatientTableViewController)?.patient.priority.value {
            updateNavigationBarColor(priority: priority)
        }
    }
}
