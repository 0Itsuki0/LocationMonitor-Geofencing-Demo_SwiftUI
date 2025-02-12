//
//  CLMonitor+utils.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/09.
//

import SwiftUI
import CoreLocation

extension CLMonitor.Event.State {
    var string: String {
        switch self {
        case .unknown:
            return "unknown"
        case .satisfied:
            return "satisfied"
        case .unsatisfied:
            return "unsatisfied"
        case .unmonitored:
            return "unmonitored"
        @unknown default:
            return "unknown"
        }
    }
}
