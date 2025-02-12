//
//  NotificationManager.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/08.
//

import SwiftUI
import CoreLocation


@Observable
class NotificationManager {
    static private let triggerRegisteredKey = "localNotificationTriggerRegistered"
    static let shared = NotificationManager()
    
    var triggerRegistered: Bool = UserDefaults.standard.bool(forKey: NotificationManager.triggerRegisteredKey) {
        didSet {
            if triggerRegistered {
                Task {
                    await registerLocationNotification()
                }
            } else {
                removeRegisteredNotifications()
            }
            UserDefaults.standard.setValue(triggerRegistered, forKey: NotificationManager.triggerRegisteredKey)
        }
    }
    
    enum NotificationError: Error {
        case coreLocationNotAuthorized
        case notificationNotAuthorized
        
        var message: String {
            switch self {
            case .coreLocationNotAuthorized:
                return "CoreLocation not authorized."
            case .notificationNotAuthorized:
                return "Notification not authorized."
            }
        }
    }
    
    var error: NotificationError? = nil
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let locationManager = CLLocationManager()
    private let logger = FileLogger.shared
    
    init() {
        locationManager.requestWhenInUseAuthorization()
        Task {
            await requestNotificationPermission()
        }
    }
    
    private func requestNotificationPermission() async -> Bool {
        do {
            let success = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Request notification authorization with success: \(success)")
            if !success {
                logger.error("Fail to request notification authorization.")
                self.error = .notificationNotAuthorized
            }
            return success
        } catch (let error) {
            logger.error("Fail to request notification authorization: \(error.localizedDescription)")
            self.error = .notificationNotAuthorized
            return false
        }
    }
    
    func notificationResponseReceived(_ response: UNNotificationResponse) async {
        let content = response.notification.request.content
        logger.info("notification response received: \(content)")
    }
    
    func willPresentNotification(_ notification: UNNotification) async -> UNNotificationPresentationOptions {
        // a place for addition processing when triggers are fired
        // To have different processing for different trigger,
        // check `notification.request.identifier` and process accordingly
        let content = notification.request.content
        logger.info("will present notification: \(content)")
        return [[.badge, .sound, .banner, .list]]
    }
    
    
    func removeRegisteredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    private func registerLocationNotification() async {
        let result = await requestNotificationPermission()
        if !result {
            return
        }
        
        locationManager.requestWhenInUseAuthorization()

        if locationManager.authorizationStatus != .authorizedWhenInUse && locationManager.authorizationStatus != .authorizedAlways {
            logger.error("Fail to request location authorization.")
            self.error = .coreLocationNotAuthorized
            return
        }

        
        // for entry
        let entryRegion = CLCircularRegion(center: CENTER, radius: RADIUS, identifier: "itsuki_world_entry")
        let entryContent = UNMutableNotificationContent()
        entryContent.title = "Entered from UNTrigger!"
        entryContent.body = "Welcome to my world!"
        entryContent.sound = .default
        
        entryRegion.notifyOnEntry = true
        entryRegion.notifyOnExit = false
        let entryTrigger = UNLocationNotificationTrigger(region: entryRegion, repeats: true)
        await registerNotificationRequest(content: entryContent, trigger: entryTrigger)
        
        // for exit
        let exitRegion = CLCircularRegion(center: CENTER, radius: RADIUS, identifier: "itsuki_world_exit")
        let exitContent = UNMutableNotificationContent()
        exitContent.title = "Exited from UNTrigger!"
        exitContent.body = "See you next time!"
        exitContent.sound = .default
        
        exitRegion.notifyOnEntry = false
        exitRegion.notifyOnExit = true
        let exitTrigger = UNLocationNotificationTrigger(region: exitRegion, repeats: true)
        await registerNotificationRequest(content: exitContent, trigger: exitTrigger)

    }
    
    private func registerNotificationRequest(content: UNMutableNotificationContent, trigger: UNNotificationTrigger) async {
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule the request with the system.
        do {
            try await notificationCenter.add(request)
            logger.info("registration succeed for request with identifier \(identifier)")
        } catch(let error) {
            // Handle errors that may occur during add.
            logger.error("error adding request: \(error.localizedDescription)")
        }

    }
}
