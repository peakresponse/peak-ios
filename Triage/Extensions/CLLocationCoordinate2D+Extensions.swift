//
//  CLLocationCoordinate2D+Extensions.swift
//  Triage
//
//  Created by Francis Li on 9/28/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import CoreLocation
import Foundation
import Keys
import UIKit

fileprivate let googleMapsApiKey = TriageKeys().googleMapsSdkApiKey

extension CLLocationCoordinate2D {
    func mapImageURL(size: CGSize) -> String {
        return "https://maps.googleapis.com/maps/api/staticmap?size=\(Int(size.width))x\(Int(size.height))&scale=2&center=\(latitude),\(longitude)&zoom=14&key=\(googleMapsApiKey)"
    }
}
