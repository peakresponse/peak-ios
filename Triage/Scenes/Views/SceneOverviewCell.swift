//
//  SceneOverviewCell.swift
//  Triage
//
//  Created by Francis Li on 5/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation

protocol SceneOverviewCell: AnyObject {
    func configure(from scene: Scene)
}
