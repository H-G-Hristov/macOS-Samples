//
//  main.swift
//  LaunchAgent
//
//  Created by Hristo Hristov on 1/7/21.
//

import Cocoa

func main() -> Int32 {
    Logger.logToFile("----------------------------------------------------")
    Logger.logToFile("main() -> Application start")
    
    // Create a strong reference
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    
    return NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
}

_ = main()
