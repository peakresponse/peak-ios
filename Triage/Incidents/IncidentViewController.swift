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

    override func viewDidLoad() {
        super.viewDidLoad()

        commandHeader.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized,
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(cancelPressed))
        commandHeader.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.saveAndExit".localized,
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(savePressed))

        segmentedControl.addSegment(title: "IncidentViewController.tab.incident".localized)
        segmentedControl.addSegment(title: "IncidentViewController.tab.ringdown".localized)
        segmentedControl.addSegment(title: "IncidentViewController.tab.refusal".localized)
    }

    @objc func cancelPressed() {
        dismissAnimated()
    }

    @objc func savePressed() {

    }
}
