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
    
    static let appName = "LaunchAgent-AppDelegate-NotificationCenter";
    
    private var statusItem: NSStatusItem!
    
    // MARK: Tray icon
    
    private func setupStatusBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(imageLiteralResourceName: "TrayIcon")
    }
    
    // MARK: Directory
    
    private func getDownloadDirectory() -> URL {
        let paths = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func makeSaveToDirectory(for url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil)
        }
        catch {
            print(error)
            
            return false
        }
        
        return true
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
    
    private func handleQuitEvent() {
        let directory = getDownloadDirectory().appendingPathComponent(AppDelegate.appName)
        
        let saveDirectoryOk = makeSaveToDirectory(for: directory)
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
        
        let filename = directory.appendingPathComponent("LaunchAgent-\(dateTimeFileStr).txt")
        
        var logStr =
            """
                ----------------------------------------------------------------
                Launch Agent log
                ----------------------------------------------------------------

                Logout/Shutdown/Restart event at: \(dateTimeStr)
                Event type:                       \(getTerminationReason())\n
            """
        logStr.append(checkNetworkReachability())
        
        do {
            try logStr.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        }
        catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
    
    private func handleQuitEventAsync() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            [weak self] in
            
            self?.handleQuitEvent()
            
            // Continue Poweroff/Restart/Logout
            NSApplication.shared.reply(toApplicationShouldTerminate: true)
        }
    }
    
    // MARK: Notifications
    
    private func setupWorkspaceNotifications() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(AppDelegate.handleWillPowerOff(_:)), name: NSWorkspace.willPowerOffNotification, object: nil)
    }
    
    @objc
    private func handleWillPowerOff(_ notification: Notification) {
        handleQuitEvent()
    }
    
}

extension AppDelegate: NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        setupStatusBarIcon()
        setupWorkspaceNotifications()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
}

