//
//  SceneOverviewViewController.swift
//  Triage
//
//  Created by Francis Li on 5/29/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import AlignedCollectionViewFlowLayout
import PRKit
internal import RealmSwift
import UIKit

class SceneOverviewViewController: BaseViewController, CommandHeaderDelegate, PRKit.FormFieldDelegate, KeyboardAwareScrollViewController,
                                   UICollectionViewDataSource, UICollectionViewDelegate {
    weak var commandHeader: CommandHeader!
    weak var collectionView: UICollectionView!
    weak var collectionViewBottomConstraint: NSLayoutConstraint!
    var scrollView: UIScrollView! { return collectionView }
    var scrollViewBottomConstraint: NSLayoutConstraint! { return collectionViewBottomConstraint }
    var formInputAccessoryView: UIView!

    var scene: Scene?
    var responders: [Responder]?

    override init() {
        super.init()
        tabBarItem.title = "TabBarItem.rolesResources".localized
        tabBarItem.image = UIImage(named: "Stage", in: PRKitBundle.instance, compatibleWith: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterFromKeyboardNotifications()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let commandHeader = CommandHeader()
        commandHeader.translatesAutoresizingMaskIntoConstraints = false
        commandHeader.preservesSuperviewLayoutMargins = true
        commandHeader.delegate = self
        commandHeader.searchFieldDelegate = self
        headerView.addSubview(commandHeader)
        NSLayoutConstraint.activate([
            commandHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
            commandHeader.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            commandHeader.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            commandHeader.contentView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            commandHeader.contentView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            headerView.bottomAnchor.constraint(equalTo: commandHeader.bottomAnchor)
        ])
        self.commandHeader = commandHeader

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        let layout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        layout.estimatedItemSize = CGSize(width: 372, height: 136)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl
        collectionView.register(SceneOverviewHeaderCell.self, forCellWithReuseIdentifier: "SceneOverviewHeader")
        collectionView.register(ResponderRoleCollectionViewCell.self, forCellWithReuseIdentifier: "Responder")
        mainView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: mainView.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: mainView.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: mainView.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor)
        ])
        self.collectionView = collectionView

        commandHeader.leftBarButtonItem = navigationItem.leftBarButtonItem
        commandHeader.searchFieldDelegate = self

        formInputAccessoryView = FormInputAccessoryView(rootView: view)

        performQuery()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if traitCollection.horizontalSizeClass == .regular {
            if let layout = collectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout {
                var sectionInset = layout.sectionInset
                let inset = max(0, (collectionView.frame.width - 744) / 2)
                sectionInset.left = inset
                sectionInset.right = inset
                layout.sectionInset = sectionInset
            }
        }
    }

    func performQuery() {
        let realm = AppRealm.open()
        guard let sceneId = AppSettings.sceneId else { return }
        scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)

        guard let scene = scene else { return }
        var results = scene.responders.filter("user<>%@ AND departedAt=%@", NSNull(), NSNull())
        if let text = commandHeader.searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            results = results.filter("(vehicle.number CONTAINS[cd] %@) OR (user.firstName CONTAINS[cd] %@) OR (user.lastName CONTAINS[cd] %@)",
                                      text, text, text)
        }
        results = results.sorted(by: [
            SortDescriptor(keyPath: "vehicle.number"),
            SortDescriptor(keyPath: "user.firstName"),
            SortDescriptor(keyPath: "user.lastName")
        ])

        responders = Array(results)
        refresh()
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<Responder>>) {
        switch changes {
        case .initial:
            collectionView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: deletions.map { IndexPath(row: $0, section: 1) })
                self.collectionView.insertItems(at: insertions.map { IndexPath(row: $0, section: 1) })
                self.collectionView.reloadItems(at: modifications.map { IndexPath(row: $0, section: 1) })
            }, completion: nil)
        case .error(let error):
            presentAlert(error: error)
        }
    }

    @objc func refresh() {
        collectionView.refreshControl?.endRefreshing()
        collectionView.reloadData()
    }

    private func leaveScene() {
        _ = AppDelegate.leaveScene()
    }

    @objc func closePressed(_ sender: Any) {
        guard let scene = scene else { return }
        let sceneId = scene.id
        if scene.isMgs(userId: AppSettings.userId) {
            let vc = ModalViewController()
            vc.isDismissedOnAction = false
            vc.messageText = "CloseSceneConfirmation.message".localized
            vc.addAction(UIAlertAction(title: "Button.close".localized, style: .destructive, handler: { [weak self] (_) in
                guard let self = self else { return }
                AppRealm.endScene(sceneId: sceneId) { [weak self] (error) in
                    DispatchQueue.main.async { [weak self] in
                        vc.dismissAnimated()
                        if let error = error {
                            self?.presentAlert(error: error)
                        } else {
                            self?.leaveScene()
                        }
                    }
                }
            }))
            vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
            presentAnimated(vc)
        } else {
            if scene.isResponder(userId: AppSettings.userId) {
                let vc = ModalViewController()
                vc.isDismissedOnAction = false
                vc.messageText = "LeaveSceneConfirmation.message".localized
                vc.addAction(UIAlertAction(title: "Button.leave".localized, style: .destructive, handler: { [weak self] (_) in
                    guard let self = self else { return }
                    AppRealm.leaveScene(sceneId: sceneId) { [weak self] (error) in
                        DispatchQueue.main.async { [weak self] in
                            vc.dismissAnimated()
                            if let error = error {
                                self?.presentAlert(error: error)
                            } else {
                                self?.leaveScene()
                            }
                        }
                    }
                }))
                vc.addAction(UIAlertAction(title: "Button.cancel".localized, style: .cancel))
                presentAnimated(vc)
            } else {
                leaveScene()
            }
        }
    }

    @objc func editPressed(_ sender: Any) {
        guard let scene = scene else { return }
        let vc = LocationViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "NavigationBar.cancel".localized, style: .plain, target: self, action: #selector(dismissAnimated))
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "NavigationBar.save".localized, style: .done, target: self, action: #selector(saveScenePressed))
        vc.scene = scene
        vc.newScene = Scene(clone: scene)
        _ = vc.view
        vc.isEditing = true
        presentAnimated(vc)
    }

    @objc func saveScenePressed() {
        if let vc = presentedViewController as? LocationViewController {
            if let scene = vc.newScene {
                AppRealm.updateScene(scene: scene)
            }
            dismissAnimated()
        }
    }

    // MARK: - FormFieldDelegate

    func formComponentDidChange(_ component: PRKit.FormComponent) {
        if let field = component as? PRKit.FormField {
            if field == commandHeader.searchField {
                performQuery()
            } else {
                let roleValue = field.attributeValue as? String
                let role = ResponderRole(rawValue: roleValue ?? "")
                if let responder = field.source as? Responder {
                    AppRealm.assignResponder(responderId: responder.id, role: role)
                    for cell in collectionView.visibleCells {
                        if let cell = cell as? ResponderRoleCollectionViewCell,
                           let responderId = cell.responderId,
                           let responder = responders?.first(where: { $0.id == responderId }),
                           let index = responders?.firstIndex(of: responder) {
                            cell.configure(from: responder, index: index)
                        }
                    }
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
        case 0: // overview header
            return 1
        case 1: // responders
            return responders?.count ?? 0
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        switch indexPath.section {
        case 0:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SceneOverviewHeader", for: indexPath)
            if let cell = cell as? SceneOverviewHeaderCell, let scene = scene {
                cell.configure(from: scene)
                cell.closeButton.removeTarget(self, action: #selector(closePressed(_:)), for: .touchUpInside)
                cell.closeButton.addTarget(self, action: #selector(closePressed(_:)), for: .touchUpInside)
                cell.editButton.removeTarget(self, action: #selector(editPressed(_:)), for: .touchUpInside)
                cell.editButton.addTarget(self, action: #selector(editPressed(_:)), for: .touchUpInside)
            }
        case 1:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Responder", for: indexPath)
            if let cell = cell as? ResponderRoleCollectionViewCell {
                let responder = responders?[indexPath.row]
                cell.configure(from: responder, index: indexPath.row)
                cell.roleSelector.delegate = self
                cell.roleSelector.inputAccessoryView = formInputAccessoryView
                cell.roleSelector.isEnabled = scene?.isResponder(userId: AppSettings.userId) ?? false
            }
        default:
            cell = UICollectionViewCell()
        }
        return cell
    }
}
