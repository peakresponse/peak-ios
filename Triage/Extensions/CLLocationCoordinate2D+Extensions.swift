//
//  CLLocationCoordinate2D+Extensions.swift
//  Triage
//
//  Created by Francis Li on 9/28/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import ArkanaKeys
import CoreLocation
import Foundation
import UIKit

private let googleMapsApiKey = ArkanaKeys.Global().googleMapsSdkApiKey

extension CLLocationCoordinate2D {
    func mapImageURL(size: CGSize) -> String {
        // swiftlint:disable line_length
        return "https://maps.googleapis.com/maps/api/staticmap?size=\(Int(size.width))x\(Int(size.height))&scale=2&center=\(latitude),\(longitude)&zoom=14&key=\(googleMapsApiKey)"
    }
}
