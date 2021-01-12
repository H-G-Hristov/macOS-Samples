//
//  Directory.swift
//  LaunchAgent-Signals
//
//  Created by Hristo Hristov on 1/11/21.
//

import Foundation

struct Directory {
    
    static func getDownloadDirectory() -> URL? {
        let paths = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        return paths.first
    }
    
    static func makeSaveToDirectory(for url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil)
        }
        catch {
            NSLog("Failed to create directory: \(error)")
            
            return false
        }
        
        return true
    }
    
}
