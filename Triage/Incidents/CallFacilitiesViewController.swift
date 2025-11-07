//
//  CallFacilitiesViewController.swift
//  Triage
//
//  Created by Francis Li on 11/2/25.
//  Copyright © 2025 Francis Li. All rights reserved.
//

import PRKit
internal import RealmSwift
import UIKit

class CallFacilitiesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    weak var contentView: UIView!
    weak var tableView: TableView!
    weak var tableViewHeightConstraint: NSLayoutConstraint!

    var region: Region!
    var filter: HospitalTeamActivation?
    var baseFacility: Facility?
    var results: Results<RegionFacility>?

    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }

    func commonInit() {
        modalPresentationStyle = .overCurrentContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .background
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.contentView = contentView

        if let regionId = AppSettings.regionId {
            let realm = AppRealm.open()
            region = realm.object(ofType: Region.self, forPrimaryKey: regionId)
            results = AppRealm.open().objects(RegionFacility.self).filter("regionId = %@", regionId)
            if let baseHospitalFacilityId = region.baseHospitalFacilityId {
                baseFacility = AppRealm.open().object(ofType: Facility.self, forPrimaryKey: baseHospitalFacilityId)
                results = results?.filter("facility <> %@", baseFacility ?? NSNull())
            }
            results = results?.sorted(by: \.position)
        }

        let tableView = TableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(GroupedTableViewSectionHeader.self, forHeaderFooterViewReuseIdentifier: "groupedSectionHeader")
        tableView.register(ListItemTableViewCell.self, forCellReuseIdentifier: "item")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.addObserver(self, forKeyPath: "contentSize", options: [.new, .old], context: nil)
        contentView.addSubview(tableView)
        let tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint.priority = .defaultLow
        NSLayoutConstraint.activate([
            tableViewHeightConstraint,
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20) // stackView.bottomAnchor),
        ])
        self.tableView = tableView
        self.tableViewHeightConstraint = tableViewHeightConstraint

        let cancelButton = PRKit.Button()
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.style = .secondary
        cancelButton.setTitle("Button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        contentView.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 10),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newSize = change?[.newKey] as? CGSize {
            let height = ceil(newSize.height)
            if height != tableViewHeightConstraint.constant {
                UIView.animate(withDuration: 0.1, animations: { [weak self] in
                    self?.tableViewHeightConstraint.constant = height
                }) { [weak self] _ in
                    self?.tableView?.isScrollEnabled = self?.tableView.frame.height != height
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        contentView.transform = .init(translationX: 0, y: view.frame.height)
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.view.backgroundColor = .modalBackdrop.withAlphaComponent(0.6)
            self?.contentView.transform = .identity
        }
    }

    override func dismissAnimated() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.view.backgroundColor = .modalBackdrop.withAlphaComponent(0)
            self?.contentView.transform = .init(translationX: 0, y: self?.view.frame.height ?? 0)
        }) { [weak self] _ in
            self?.dismiss(animated: false, completion: { [weak self] in
                self?.didDismissPresentation()
            })
        }
    }

    @objc func cancelPressed() {
        dismissAnimated()
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return baseFacility != nil ? 2 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && baseFacility != nil {
            return 1
        }
        return results?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        if let cell = cell as? ListItemTableViewCell {
            cell.disclosureImageView.image = UIImage(named: "Phone40px", in: PRKitBundle.instance, compatibleWith: nil)
            if indexPath.section == 0, let baseFacility = baseFacility {
                cell.label.text = baseFacility.displayName
            } else {
                cell.label.text = results?[indexPath.row].description ?? ""
            }
        }
        return cell
    }

    // UITableViewDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0, baseFacility != nil {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "groupedSectionHeader")
            if let header = header as? GroupedTableViewSectionHeader {
                header.titleLabel.text = "CallFacilitiesViewController.baseHospital".localized
            }
            return header
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }

}
