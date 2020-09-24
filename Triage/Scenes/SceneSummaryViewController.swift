//
//  SceneSummaryViewController.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit

private class SectionHeaderView: UICollectionReusableView {
    weak var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .copyMBold
        label.textColor = .mainGrey
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 22),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -22),
            bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 10)
        ])
        self.label = label

        let hr = HorizontalRuleView()
        hr.translatesAutoresizingMaskIntoConstraints = false
        hr.lineColor = .lowPriorityGrey
        addSubview(hr)
        NSLayoutConstraint.activate([
            hr.topAnchor.constraint(equalTo: topAnchor),
            hr.leftAnchor.constraint(equalTo: leftAnchor),
            hr.rightAnchor.constraint(equalTo: rightAnchor),
            hr.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

private class SceneSummaryHeaderCollectionViewCell: UICollectionViewCell {
    weak var headerView: SceneSummaryHeaderView!
    weak var headerViewWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let headerView = SceneSummaryHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            headerView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        self.headerView = headerView
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let autoLayoutAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        let autoLayoutSize = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.defaultLow)
        let autoLayoutFrame = CGRect(origin: autoLayoutAttributes.frame.origin, size: autoLayoutSize)
        autoLayoutAttributes.frame = autoLayoutFrame
        return autoLayoutAttributes
    }

    func configure(from scene: Scene) {
        headerView.configure(from: scene)
    }
}

class SceneSummaryViewController: BaseNonSceneViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var scene: Scene!
    var notificationToken: NotificationToken?
    var results: Results<Patient>?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = UICollectionViewFlowLayout.automaticSize
            layout.estimatedItemSize = CGSize(width: view.frame.width, height: 70)
        }
        collectionView.register(SceneSummaryHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "Summary")
        collectionView.register(PatientsCollectionViewCell.self, forCellWithReuseIdentifier: "Patient")
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader")
        collectionView.reloadData()

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
            collectionView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: deletions.map{ IndexPath(row: $0, section: 1) })
                collectionView.insertItems(at: insertions.map{ IndexPath(row: $0, section: 1) })
                collectionView.reloadItems(at: modifications.map{ IndexPath(row: $0, section: 1) })
            }, completion: nil)
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

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return results?.count ?? 0
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!
        switch indexPath.section {
        case 0:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Summary", for: indexPath)
            if let cell = cell as? SceneSummaryHeaderCollectionViewCell {
                cell.configure(from: scene)
            }
        default:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Patient", for: indexPath)
            if let cell = cell as? PatientsCollectionViewCell, let patient = results?[indexPath.row] {
                cell.configure(from: patient)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath)
        if let view = view as? SectionHeaderView {
            switch indexPath.section {
            case 1:
                view.label.text = "SceneSummaryViewController.patients".localized
            case 2:
                view.label.text = "SceneSummaryViewController.notes".localized
            case 3:
                view.label.text = "SceneSummaryViewController.photos".localized
            default:
                break
            }
        }
        return view
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Patients", bundle: nil).instantiateViewController(identifier: "Patient") as? PatientViewController,
            let patient = results?[indexPath.row] {
            vc.patient = patient
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.done".localized, style: .plain, target: self, action: #selector(dismissAnimated))
            presentAnimated(vc)
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let collectionViewLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            switch indexPath.section {
            case 1:
                return CGSize(width: collectionView.frame.width - 44, height: 70)
            default:
                return collectionViewLayout.estimatedItemSize
            }
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch section {
        case 1:
            return UIEdgeInsets(top: 0, left: 22, bottom: 22, right: 22)
        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            return .zero
        default:
            return CGSize(width: 0, height: UIFont.copyMBold.lineHeight + 20)
        }
    }
}
