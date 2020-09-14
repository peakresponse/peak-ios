//
//  GMSMarker+Extensions.swift
//  Triage
//
//  Created by Francis Li on 9/13/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import GoogleMaps

extension GMSMarker {
    static let customMarkerImage: UIImage = {
        return UIImage(named: "MapMarker")!
    }()

    static let priorityMarkerImages: [UIImage] = {
        return [
            UIImage(named: "MapMarkerImmediate")!,
            UIImage(named: "MapMarkerDelayed")!,
            UIImage(named: "MapMarkerMinimal")!,
            UIImage(named: "MapMarkerExpectant")!,
            UIImage(named: "MapMarkerDead")!
        ]
    }()
}
