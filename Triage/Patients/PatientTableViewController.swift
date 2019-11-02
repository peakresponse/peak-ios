//
//  PatientTableViewController.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import UIKit

let INFO = ["location", "firstName", "lastName", "age"]
let VITALS = ["respiratoryRate", "pulse", "capillaryRefill", "bloodPressure"]

class PatientTableViewCell: UITableViewCell {
    func configure(from patient: Patient) {
    }
}

class PatientAttributeTableViewCell: PatientTableViewCell {
    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    var attribute: String!
    
    override func configure(from patient: Patient) {
        attributeLabel.text = NSLocalizedString("Patient.\(attribute ?? "")", comment: "")
        if let value = patient.value(forKey: attribute) {
            valueLabel.text = String(describing: value)
        } else {
            valueLabel.text = nil
        }
    }
}

class PatientPortraitTableViewCell: PatientTableViewCell {
    @IBOutlet weak var patientView: PatientView!
    
    override func configure(from patient: Patient) {
        patientView.configure(from: patient)
    }
}

class PatientPriorityTableViewCell: PatientTableViewCell {
    override func configure(from patient: Patient) {
        contentView.backgroundColor = PRIORITY_COLORS[patient.priority.value ?? 5]
        textLabel?.text = NSLocalizedString("Patient.priority.\(patient.priority.value ?? 5)", comment: "")
        textLabel?.textColor = PRIORITY_LABEL_COLORS[patient.priority.value ?? 5]
    }
}

class PatientTableViewController: UITableViewController {
    var patient: Patient!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        title = "\(patient.firstName ?? "") \(patient.lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 200
        default:
            break
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 2:
            return NSLocalizedString("Info", comment: "")
        case 3:
            return NSLocalizedString("Vitals", comment: "")
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: //// portrait
            return 1
        case 1: //// priority
            return 1
        case 2: //// info
            return INFO.count
        case 3: //// vitals
            return VITALS.count
        default: //// observations
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "Portrait", for: indexPath)
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "Priority", for: indexPath)
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "Attribute", for: indexPath)
            if let cell = cell as? PatientAttributeTableViewCell {
                switch indexPath.section {
                case 2:
                    cell.attribute = INFO[indexPath.row]
                case 3:
                    cell.attribute = VITALS[indexPath.row]
                default:
                    break
                }
            }
        }
        if let cell = cell as? PatientTableViewCell {
            cell.configure(from: patient)
        }
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
