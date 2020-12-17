//
//  WebSocket+Extensions.swift
//  Triage
//
//  Created by Francis Li on 12/15/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import Foundation
import Starscream

extension WebSocket: Equatable {
    public static func == (lhs: WebSocket, rhs: WebSocket) -> Bool {
        return lhs === rhs
    }
}
