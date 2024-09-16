//
//  MotionHelper.swift
//  Triage
//
//  Created by Francis Li on 9/16/24.
//  Copyright © 2024 Francis Li. All rights reserved.
//

import CoreMotion
import Foundation

extension CMAcceleration {
    var magnitude: Double {
        return sqrt(x * x + y * y + z * z)
    }
}

class MotionHelper: NSObject {
    static let instance = MotionHelper()

    var motionManager: CMMotionManager!

    var deviceMotion: CMDeviceMotion? {
        return motionManager.deviceMotion
    }

    override init() {
        super.init()
        motionManager = CMMotionManager()
    }

    func startDeviceMotionUpdates() {
        motionManager.startDeviceMotionUpdates()
    }

    func stopDeviceMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
