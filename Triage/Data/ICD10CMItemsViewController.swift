//
//  ICD10CMItemsViewController.swift
//  Triage
//
//  Created by Francis Li on 12/7/21.
//  Copyright © 2021 Francis Li. All rights reserved.
//

import UIKit
import PRKit

class ICD10CMItemsViewController: UIViewController, CommandHeaderDelegate,
                                  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var commandHeader: CommandHeader!
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Checkbox", for: indexPath)
        return cell
    }
}
