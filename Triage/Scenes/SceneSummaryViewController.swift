//
//  SceneSummaryViewController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

private class SectionHeaderView: UITableViewHeaderFooterView {
    weak var label: UILabel!
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .bgBackground
        self.backgroundView = backgroundView
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copyMBold
        label.textColor = .mainGrey
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 22),
            label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -22),
            contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
        ])
        self.label = label

        let hr = HorizontalRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.lineColor = .lowPriorityGrey
        contentView.addSubview(hr)
        NSLayoutConstraint.activate([
            hr.topAnchor.constraint(equalTo: contentView.topAnchor),
            hr.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            hr.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            hr.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

class SceneSummaryViewController: BaseNonSceneViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var scene: Scene!
    var notificationToken: NotificationToken?
    var results: Results<Patient>?

    override func viewDidLoad() {
        super.viewDidLoad()

        let headerView = SceneSummaryHeaderView()
        headerView.configure(from: scene)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = headerView

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 84
        tableView.register(PatientTableViewCell.self, forCellReuseIdentifier: "Patient")
        
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 40
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "Header")
        
        let realm = AppRealm.open()
        results = realm.objects(Patient.self)
        results = results?.filter("sceneId=%@", scene.id)
        results = results?.sorted(by: [
            SortDescriptor(keyPath: "firstName", ascending: true),
            SortDescriptor(keyPath: "lastName", ascending: true)
        ])
        notificationToken = results?.observe { [weak self] (changes) in
            self?.didObserveRealmChanges(changes)
        }
        refresh()
    }

    private func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Patient>>) {
        switch changes {
        case .initial(_):
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            tableView.beginUpdates()
            tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) },
               with: .automatic)
            tableView.endUpdates()
        case .error(let error):
            presentAlert(error: error)
        }
    }

    func refresh() {
        AppRealm.getPatients(sceneId: scene.id) { [weak self] (error) in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.presentAlert(error: error)
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Patient", for: indexPath)
        if let cell = cell as? PatientTableViewCell, let patient = results?[indexPath.row] {
            cell.configure(from: patient)
        }
        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header")
        if let headerView = headerView as? SectionHeaderView {
            switch section {
            case 0:
                headerView.label.text = "SceneSummaryViewController.patients".localized
            default:
                return nil
            }
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Patient") as? PatientViewController,
            let patient = results?[indexPath.row] {
            vc.patient = patient
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized, style: .plain, target: self, action: #selector(dismissAnimated))
            presentAnimated(vc)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
