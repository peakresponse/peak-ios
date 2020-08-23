//
//  ConfirmTransportViewController.swift
//  Triage
//
//  Created by Francis Li on 8/20/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

@objc protocol ConfirmTransportViewControllerDelegate {
    @objc optional func confirmTransportViewControllerDidConfirm(_ vc: ConfirmTransportViewController, facility: Facility, agency: Agency)
}

class ConfirmTransportViewController: UIViewController {
    @IBOutlet weak var facilityView: FacilityView!
    @IBOutlet weak var agencyView: FacilityView!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var confirmButton: FormButton!
    @IBOutlet weak var cancelButton: FormButton!

    weak var delegate: ConfirmTransportViewControllerDelegate?

    var facility: Facility!
    var agency: Agency!

    override func viewDidLoad() {
        super.viewDidLoad()

        facilityView.layer.borderColor = UIColor.greyPeakBlue.cgColor
        facilityView.layer.borderWidth = 2
        facilityView.configure(from: facility)
        
        agencyView.layer.borderColor = UIColor.greyPeakBlue.cgColor
        agencyView.layer.borderWidth = 2
        agencyView.configure(from: agency)
    }

    @IBAction func confirmPressed(_ sender: Any) {
        delegate?.confirmTransportViewControllerDidConfirm?(self, facility: facility, agency: agency)
        dismissAnimated()
    }
}
