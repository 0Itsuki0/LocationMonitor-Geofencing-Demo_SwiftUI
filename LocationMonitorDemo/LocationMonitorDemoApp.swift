//
//  LocationMonitorDemoApp.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/07.
//

import SwiftUI

@main
struct LocationMonitorDemoApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
//            LocationTriggerView()
//            CLMonitorView()
            NavigationStack {
                ContentView()
            }
        }
    }
}
