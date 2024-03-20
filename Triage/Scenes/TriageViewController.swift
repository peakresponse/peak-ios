//
//  TriageViewController.swift
//  Triage
//
//  Created by Francis Li on 9/2/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import RealmSwift
import UIKit
import PRKit

class TriageViewController: SceneViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                            TriageCounterCellDelegate {
    @IBOutlet weak var collectionView: UICollectionView!

    private var scene: Scene?
    private var notificationToken: NotificationToken?
    private var isExpectantHidden = true

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tabBarItem.title = "TabBarItem.triage".localized
        tabBarItem.image = UIImage(named: "Triage", in: PRKitBundle.instance, compatibleWith: nil)
    }

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initSceneCommandHeader()
        commandHeader.searchField.alpha = 0

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 120)
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }

        guard let sceneId = AppSettings.sceneId else { return }
        let realm = AppRealm.open()
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
        notificationToken = scene?.observe { [weak self] (change) in
            self?.didObserveChange(change)
        }
    }

    func didObserveChange(_ change: ObjectChange<Scene>) {
        switch change {
        case .change:
            refresh()
        case .error(let error):
            presentAlert(error: error)
        case .deleted:
            leaveScene()
        }
    }

    private func leaveScene() {
        _ = AppDelegate.leaveScene()
    }

    private func refresh() {
        guard let scene = scene else { return }
        for cell in collectionView.visibleCells {
            if let cell = cell as? TriageCounterCell {
                cell.configure(from: scene)
            }
        }
    }

    // MARK: - TriageCounterCellDelegate

    func counterCell(_ cell: TriageCounterCell, didChange value: Int, for priority: TriagePriority?) {
        guard let sceneId = scene?.id else { return }
        AppRealm.updateApproxPatientsCounts(sceneId: sceneId, priority: priority, value: value)
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: // approx triage counts header
            return 1
        case 1: // triage counters
            return isExpectantHidden ? 5 : 6
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        switch indexPath.section {
        case 0:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TriageHeader", for: indexPath)
        case 1:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TriageCounter", for: indexPath)
            if let cell = cell as? TriageCounterCell {
                cell.delegate = self
                if indexPath.row > 0 {
                    var value = indexPath.row - 1
                    if isExpectantHidden && value >= TriagePriority.expectant.rawValue {
                        value += 1
                    }
                    cell.priority = TriagePriority(rawValue: value)
                } else {
                    cell.priority = nil
                }
                if let scene = scene {
                    cell.configure(from: scene)
                }
            }
        default:
            cell = UICollectionViewCell()
        }
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }
}
