//
//  Predictions.swift
//  Triage
//
//  Created by Francis Li on 2/10/22.
//  Copyright © 2022 Francis Li. All rights reserved.
//

import Foundation
import PRKit

protocol Predictions {
    var predictions: [String: Any]? { get set }
}

extension Predictions {
    func predictionStatus(for keyPath: String) -> PredictionStatus {
        if let prediction = predictions?[keyPath] as? [String: Any] {
            return PredictionStatus(rawValue: prediction["status"] as? String ?? "") ?? .none
        }
        return .none
    }

    mutating func setPredictionStatus(_ status: PredictionStatus, for keyPath: String) {
        if var predictions = self.predictions {
            if status == .none {
                predictions.removeValue(forKey: keyPath)
            } else if var prediction = predictions[keyPath] as? [String: Any] {
                prediction["status"] = status.rawValue
                predictions[keyPath] = prediction
            }
            self.predictions = predictions
        }
    }
}
