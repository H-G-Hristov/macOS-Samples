//
//  main.swift
//  LaunchAgent
//
//  Created by Hristo Hristov on 1/7/21.
//

import Cocoa

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

func main() -> Int32 {
    Logger.logToFile("----------------------------------------------------")
    Logger.logToFile("main() -> Application start")
    
    signal(SIGTERM, SIG_IGN)

    let termSource = DispatchSource.makeSignalSource(signal: SIGTERM)
    termSource.setEventHandler {
        NSLog("SIGTERM")
        Logger.logToFile("Signal received:   SIGTERM")
        let reason = getTerminationReason()
        Logger.logToFile("Reason for signal: \(reason)")
        
        exit(EXIT_SUCCESS)
    }
    termSource.resume()
    
    dispatchMain()
}

_ = main()

exit(EXIT_FAILURE)
