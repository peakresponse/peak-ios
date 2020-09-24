//
//  ObservationViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import Speech
import UIKit

@objc protocol ObservationViewControllerDelegate {
    @objc optional func observationViewControllerDidSave(_ vc: ObservationViewController)
}

class ObservationViewController: PatientViewController {
    weak var delegate: ObservationViewControllerDelegate?
    
    func patientTableViewControllerDidCancel(_ vc: PatientTableViewController) {
        dismissAnimated()
    }
    
    func patientTableViewControllerDidSave(_ vc: PatientTableViewController) {
        delegate?.observationViewControllerDidSave?(self)
    }
}
