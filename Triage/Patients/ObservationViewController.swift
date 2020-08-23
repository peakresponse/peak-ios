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
    @objc optional func observationViewController(_ vc: ObservationViewController, didSave observation: Observation)
}

class ObservationViewController: PatientViewController {
    weak var delegate: ObservationViewControllerDelegate?
    
    func patientTableViewControllerDidCancel(_ vc: PatientTableViewController) {
        dismissAnimated()
    }
    
    func patientTableViewController(_ vc: PatientTableViewController, didSave observation: Observation) {
        delegate?.observationViewController?(self, didSave: observation)
    }
}
