//
//  LocationMonitor.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/07.
//

import SwiftUI
import CoreLocation


@MainActor
@Observable
class LocationMonitor {

    static let shared = LocationMonitor()  // Create a single, shared instance of the object.
    static private let monitorStartedKey = "monitorStarted"

    enum MonitorError: Error {
        case invalidMonitor
        case coreLocationNotAuthorized
        case fullAccuracyNotAuthorized
        case existingCondition
        case notificationNotAuthorized
        case sessionError(String)
        
        var message: String {
            switch self {
            case .invalidMonitor:
                return "Invalid monitor."
            case .coreLocationNotAuthorized:
                return "CoreLocation is not authorized."
            case .fullAccuracyNotAuthorized:
                return "Full accuracy is not authorized."
            case .existingCondition:
                return "A condition with the same identifier already exists."
            case .notificationNotAuthorized:
                return "Notification is not authorized."
            case .sessionError(let message):
                return message
            }
        }
    }

    var error: MonitorError? = nil
    var conditionEvents: [String : [CLMonitor.Event]] = [:]
    
    var monitorStarted: Bool = UserDefaults.standard.bool(forKey: LocationMonitor.monitorStartedKey) {
        didSet {
            monitorStarted ? self.startMonitor() : self.stopMonitor()
            UserDefaults.standard.set(monitorStarted, forKey: LocationMonitor.monitorStartedKey)
        }
    }
    
    @ObservationIgnored
    var conditionIdentifier: String {
        "itsuki_condition"
    }
    
    @ObservationIgnored
    var condition: CLMonitor.CircularGeographicCondition {
        return .init(center: CENTER, radius: RADIUS)
    }

    private var monitorIdentifier: String {
        if let bundleId = Bundle.main.bundleIdentifier {
            return bundleId.replacingOccurrences(of: ".", with: "_")
        }
        return "itsuki_monitor"
    }
    
    private let fullAccuracyPurposeKey = "monitor"
    
    
    private var monitor: CLMonitor?
    private let notificationCenter = UNUserNotificationCenter.current()
    private let locationManager: CLLocationManager = CLLocationManager()
    private var session: CLServiceSession?
    private let logger = FileLogger.shared
    
    private init() {
        Task {
            await requestPermission()
            await initializeMonitor()
        }
    }
    
    private func requestPermission() async {
        if locationManager.authorizationStatus != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        
        if locationManager.accuracyAuthorization != .fullAccuracy {
            locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: fullAccuracyPurposeKey, completion: { error in
                if let error {
                    self.logger.error("Fail to request full accuracy authorization: \(error.localizedDescription)")
                    self.error = .fullAccuracyNotAuthorized
                }
            })
        }
        
        do {
            try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch (let error) {
            logger.error("Fail to request notification authorization: \(error.localizedDescription)")
            self.error = .notificationNotAuthorized
        }
    }


    private func initializeMonitor() async {

        if self.monitor == nil {
            // create monitor
            let monitor = await CLMonitor(monitorIdentifier)
            self.monitor = monitor
            // if there is any previous events
            for identifier in await monitor.identifiers {
                guard let lastEvent = await monitor.record(for: identifier)?.lastEvent else { continue }
                self.conditionEvents[identifier] = [lastEvent]
            }
        }
                
        if monitorStarted {
            startMonitor()
        }
    }
    
    private func startMonitor() {
        Task {
            await requestPermission()
            startSessionMonitor()
            startEventMonitor()
        }
    }
    
    private func startSessionMonitor() {
        Task {
            session = CLServiceSession(authorization: .always, fullAccuracyPurposeKey: fullAccuracyPurposeKey)
            for try await diagnostics in session!.diagnostics {
       
                if diagnostics.authorizationDenied {
                    self.error = .sessionError("Authorization Denied. Please authorize the app to access Location Services")
                    self.logger.info("Authorization Denied")
                    continue
                }
                
                if diagnostics.alwaysAuthorizationDenied {
                    self.error = .sessionError("Always Authorization Denied. Monitor will only work in the foreground.")
                    self.logger.info("Always Authorization Denied")
                    continue
                }
                if diagnostics.authorizationDeniedGlobally {
                    self.error = .sessionError("Authorization Denied Globally. Please enable Location Services by going to Settings -> Privacy & Security.")
                    self.logger.info("authorizationDeniedGlobally")
                    continue
                }
                if diagnostics.authorizationRestricted {
                    self.error = .sessionError("Authorization Restricted. Do you have Parental Controls enabled?")
                    self.logger.info("Authorization Restricted")
                    continue
                }
                if diagnostics.fullAccuracyDenied {
                    self.error = .sessionError("Full Accuracy Denied. Monitoring might fail without access to the precise location.")
                    self.logger.info("always authorization denied")
                    continue
                }
                if diagnostics.insufficientlyInUse {
                    self.error = .sessionError("Insufficiently In Use. Location monitoring can't receive condition events while not in the foreground")
                    self.logger.info("Insufficiently In Use")
                    continue
                }
                
                self.error = nil
            }
        }
    }
    
    private func startEventMonitor() {
        guard let monitor else {
            self.logger.info("monitor not available")
            self.error = .invalidMonitor
            return
        }
        self.logger.info("Starting event monitoring")

        Task {
            // same identifier every time so that we don't end up adding multiple same condition
            await monitor.add(condition, identifier: conditionIdentifier)

            do {
                
                // about 2~5 seconds delay between the user's action and the event fired
                for try await event in await monitor.events {
                    if !self.monitorStarted { break }  // End monitoring updates by breaking out of the loop.

                    logger.info("event received: \(event)")

                    // If the event state is the same as the previous state, the only new information is in diagnostics.
                    if let lastEvent = await monitor.record(for: event.identifier)?.lastEvent, event.state == lastEvent.state {
                        continue
                    }

                    if self.conditionEvents.contains(where: {$0.key == event.identifier}) {
                        self.conditionEvents[event.identifier]?.insert(event, at: 0)
                    } else {
                        self.conditionEvents[event.identifier] = [event]
                    }

                    if event.state == .satisfied {
                        let notificationContent = UNMutableNotificationContent()
                        notificationContent.title = "Entered from CLMonitor!"
                        notificationContent.body = "Welcome to my world!"
                        notificationContent.sound = .default
                        let notification = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: nil)
                        try await notificationCenter.add(notification)
                    }
                    
                    if event.state == .unsatisfied {
                        let notificationContent = UNMutableNotificationContent()
                        notificationContent.title = "Exited from CLMonitor!"
                        notificationContent.body = "See you next time!"
                        notificationContent.sound = .default
                        let notification = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: nil)
                        try await notificationCenter.add(notification)
                    }
                }
            } catch(let error) {
                logger.error("Could not monitor events: \(error.localizedDescription)")
            }
        }
        
        // live updates approach
//        self.logger.info("Starting location updates")
//        Task {
//            do {
//                let updates = CLLocationUpdate.liveUpdates()
//                for try await update in updates {
//                    if !self.monitorStarted { break }  // End location updates by breaking out of the loop.
//                    if let loc = update.location {
//                        logger.info("Location \(loc)")
//                    }
//                }
//            } catch {
//                self.logger.error("Could not start location updates")
//            }
//            return
//        }
    }
   
    
    private func stopMonitor() {
        self.logger.info("Stopping location updates")
        self.session?.invalidate()
        guard let monitor else { return }
        Task {
            for identifier in await monitor.identifiers {
                await monitor.remove(identifier)
            }
        }
    }
}

