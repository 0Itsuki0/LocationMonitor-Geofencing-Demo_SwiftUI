//
//  FileLogger.swift
//  LocationMonitorDemo
//
//  Created by Itsuki on 2025/02/07.
//

import SwiftUI

class FileLogger {
    
    static let shared = FileLogger()
    
    init() {
        print("File Logger initialized.")
        print("Destination File URL: \(String(describing: fileURL))")
    }
    
    func debug(_ string: String) {
        #if DEBUG
        write(level: .debug, string: string)
        #endif
    }
    
    func info(_ string: String) {
        #if DEBUG
        write(level: .info, string: string)
        #endif
    }
    
    func warning(_ string: String) {
        write(level: .warning, string: string)
    }
    
    func error(_ string: String) {
        write(level: .error, string: string)
    }
    
    private enum LogLevel: String {
        case debug
        case info
        case warning
        case error
    }
    
    private let fileManager = FileManager.default
    
    private var filename: String {
        let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        if let appName {
            return "\(appName).txt"
        }
        return "log.txt"
    }
    
    private var fileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {return nil}
        return documentsDirectory.appendingPathComponent(filename)
    }
    
    private func write(level: LogLevel, string: String) {
        let log = "\(Date()) [\(level.rawValue)] \(string)\n"
        print(log)
        guard let fileURL else {
            print("error writing to file")
            return
        }
        
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(log.data(using: .utf8)!)
            handle.closeFile()
        } else {
            do {
                try log.data(using: .utf8)?.write(to: fileURL)
            } catch (let error) {
                print("Error writing to file: \(error.localizedDescription)")
            }
        }
    }
}
