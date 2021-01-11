//
//  AppDelegate.swift
//  LaunchAgent
//
//  Created by Hristo Hristov on 1/7/21.
//

import Cocoa

import Network
import SystemConfiguration

class AppDelegate: NSObject {
    
    static let appName = "LaunchAgent-AppDelegate-DispatchSource";
    
    private var statusItem: NSStatusItem!
    
    private let sighupSource = DispatchSource.makeSignalSource(
        signal: SIGHUP,
        queue: DispatchQueue.global()
    )
    
    private let sigintSource = DispatchSource.makeSignalSource(
        signal: SIGINT,
        queue: DispatchQueue.global()
    )
    
    private let sigtermSource = DispatchSource.makeSignalSource(
        signal: SIGTERM,
        queue: DispatchQueue.global()
    )
    
    // MARK: Tray icon
    
    private func setupStatusBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(imageLiteralResourceName: "TrayIcon")
    }
    
    // MARK: App
    
    private func getTerminationReason() -> String {
        // https://stackoverflow.com/questions/56839403/detect-a-user-logout-on-macos
        let reason = NSAppleEventManager.shared()
            .currentAppleEvent?
            .attributeDescriptor(forKeyword: kAEQuitReason)
        var reasonCode = "invalid"
        if let code = reason?.enumCodeValue {
            reasonCode = "\(code)"
        }
        
        switch reason?.enumCodeValue {
        case kAELogOut, kAEReallyLogOut:
            return "logout"
            
        case kAERestart, kAEShowRestartDialog:
            return "restart"
            
        case kAEShutDown, kAEShowShutdownDialog:
            return "shutdown"
            
        case 0:
            // `enumCodeValue` docs:
            //
            //    The contents of the descriptor, as an enumeration type,
            //    or 0 if an error occurs.
            return "unknown error"
            
        default:
            return "Cmd + Q, Quit menu item, ... [kAEQuitReason code: \(reasonCode)]"
        }
    }
    
    // MARK: Network
    
    private func checkNetworkReachability(with hostName: String? = nil) -> String {
        // Used method:
        //   https://marcosantadev.com/network-reachability-swift/
        // Other methods:
        //   https://www.hackingwithswift.com/example-code/networking/how-to-check-for-internet-connectivity-using-nwpathmonitor
        //   https://stackoverflow.com/questions/1083701/how-to-check-for-an-active-internet-connection-on-ios-or-macos
        
        let reachability: SCNetworkReachability?
        
        // Obtain reachability by host name
        if let hostName = hostName {
            reachability = SCNetworkReachabilityCreateWithName(nil, hostName)
        }
        // Obtain reachability by a network address reference
        else {
            // Initializes the socket IPv4 address struct
            var address = sockaddr_in()
            address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            address.sin_family = sa_family_t(AF_INET)
            
            // Passes the reference of the struct
            reachability = withUnsafePointer(to: &address, { pointer in
                // Converts to a generic socket address
                return pointer.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size) {
                    // $0 is the pointer to `sockaddr`
                    return SCNetworkReachabilityCreateWithAddress(nil, $0)
                }
            })
        }
        
        var reachabilityFlags = SCNetworkReachabilityFlags()
        var areFlagsOk = false
        
        if let reachability = reachability {
            areFlagsOk = SCNetworkReachabilityGetFlags(reachability, &reachabilityFlags)
        }
        
        return
            """
                Network reachability flags state: \(areFlagsOk ? "OK" : "unavailable")
                Network is reachable:             \(isNetworkReachable(with: reachabilityFlags) )
            """
    }
    
    private func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable
            && (!needsConnection || canConnectWithoutUserInteraction)
    }
    
    // MARK: Log
    
    static var documentsDirectory: URL? {
        return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    }
    
    private func handleQuitEvent(_ message: String? = nil) {
        guard let directory = Directory.getDownloadDirectory() else {
            return
        }
        
        let saveDirectoryOk = Directory.makeSaveToDirectory(for: directory)
        if !saveDirectoryOk {
            NSLog("[LaunchAgent] Failed to create a save directory")
            
            return
        }
        
        let dateFormatter = DateFormatter()
        //  dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateTime = Date()
        let dateTimeStr = dateFormatter.string(from: currentDateTime)
        let dateTimeFileStr = dateTimeStr
            .replacingOccurrences(of: " ", with: "_T")
            .replacingOccurrences(of: ":", with: "-")
        
        let logDirectory = directory.appendingPathComponent(AppDelegate.appName)
        let filename = logDirectory.appendingPathComponent("\(AppDelegate.appName)-\(dateTimeFileStr)-Session.txt")
        
        dateFormatter.dateFormat = "HH.mm:ss.SSS'Z'"
        let currentTime = dateFormatter.string(from: currentDateTime)
        
        var logStr =
            """
                \n
                ----------------------------------------------------------------
                Launch Agent log
                ----------------------------------------------------------------

                Logout/Shutdown/Restart event at: \(dateTimeStr)
                                                  \(currentTime)
                Event type:                       \(getTerminationReason())\n
            """
        if let message = message {
            logStr.append(message)
        }
        logStr.append(checkNetworkReachability())

        guard let logData = logStr.data(using: String.Encoding.utf8) else {
            return
        }
        
        Logger.writeToFile(logData, to: filename)
        
//        do {
//            try logStr.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
//        }
//        catch {
//            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
//
//            NSLog("\(AppDelegate.appName) -> Failed to write to file")
//            handleQuitEvent("handleQuitEvent() -> Failed to write to file")
//        }
    }
    
    private func makeSignalMessage(for signalName: String) -> String {
        return
            """
                Signal handled:                   \(signalName)\n
            """
    }
    
    // MARK: Event handling
    
    private func setupEventHandlers() {
        signal(SIGHUP, SIG_IGN)
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
        
        sighupSource.setEventHandler {
            [weak self] in
            
            let signalName = "SIGHUP"
            let signalMessage = self?.makeSignalMessage(for: signalName)
            self?.handleQuitEvent(signalMessage)
            Logger.logToFile("Signal received: \(signalName)")
        }
        sighupSource.resume()
        
        sigintSource.setEventHandler {
            [weak self] in
            
            let signalName = "SIGINT"
            let signalMessage = self?.makeSignalMessage(for: signalName)
            self?.handleQuitEvent(signalMessage)
            Logger.logToFile("Signal received: \(signalName)")
        }
        sigintSource.resume()
        
        sigtermSource.setEventHandler {
            [weak self] in
            
            let signalName = "SIGTERM"
            let signalMessage = self?.makeSignalMessage(for: signalName)
            self?.handleQuitEvent(signalMessage)
            Logger.logToFile("Signal received: \(signalName)")
        }
        sigtermSource.resume()
    }
    
}

extension AppDelegate: NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        Logger.logToFile("applicationDidFinishLaunching()")
        
        setupEventHandlers()
        setupStatusBarIcon()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        let quitEventMessage =
            """
                Quit reason:                      applicationWillTerminate()\n
            """
        handleQuitEvent(quitEventMessage)
        Logger.logToFile("applicationWillTerminate()")
    }
    
}

