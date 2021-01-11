//
//  Logger.swift
//  LaunchAgent-Signals
//
//  Created by Hristo Hristov on 1/11/21.
//

import Foundation

struct Logger {
    
    static var appName = AppDelegate.appName
    
    static var logFile: URL? {
        let downloadDirectories = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        guard let directory = downloadDirectories.first else {
            return nil
        }
        
        // Return a unique log file name for each unique date
        let dateFormatter = DateFormatter()
        // Set date format: "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDateTime = Date()
        let dateTimeFileStr = dateFormatter.string(from: currentDateTime)
        // Add directory
        let logDirectory = directory.appendingPathComponent(appName)
        
        let directoryOk = Directory.makeSaveToDirectory(for: logDirectory)
        if !directoryOk {
            return nil
        }
        
        // Add filename
        return logDirectory.appendingPathComponent("\(appName)-\(dateTimeFileStr)-Log.txt")
    }
    
    static func logToFile(_ message: String) {
        guard let logFile = logFile else {
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let logItem = (timestamp + ": " + message + "\n")
        
        guard let logData = logItem.data(using: String.Encoding.utf8) else {
            return
        }
        
        writeToFile(logData, to: logFile)
    }
    
    static func writeToFile(_ logData: Data, to logFile: URL) {
        if FileManager.default.fileExists(atPath: logFile.path) {
            // Append info to existing log file
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logData)
                fileHandle.closeFile()
            }
            else {
                NSLog("Failed to write to file: \(logFile)")
            }
        } else {
            do {
                // Create new log file
                try logData.write(to: logFile, options: .atomicWrite)
            } catch (let error) {
                NSLog("Failed to create file: \(logFile) with error: \(error)")
            }
        }
    }
    
}
