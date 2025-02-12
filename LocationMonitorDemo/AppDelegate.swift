//
//  AppDelegate.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/07.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    private let notificationManager = NotificationManager.shared
    private let logger = FileLogger.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        logger.info("Launch with options: \(launchOptions ?? [:])")
        
        UNUserNotificationCenter.current().delegate = self
        
        let _ = LocationMonitor.shared

        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return await notificationManager.willPresentNotification(notification)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await notificationManager.notificationResponseReceived(response)
    }
    
}


