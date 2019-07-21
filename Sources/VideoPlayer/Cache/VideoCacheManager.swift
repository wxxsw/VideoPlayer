//
//  VideoCacheManager.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

public class VideoCacheManager {
    
    public static let shared = VideoCacheManager()
    
    public var directory = NSTemporaryDirectory().appendingPathComponent("VideoPlayer")
    
    public func cachedFilePath(for url: URL) -> String {
        directory
            .appendingPathComponent(url.absoluteString.sha256)
            .appendingPathExtension(url.pathExtension)!
    }
    
    public func cachedConfiguration(for url: URL) throws -> VideoCacheConfiguration {
        try VideoCacheConfiguration
            .configuration(for: cachedFilePath(for: url))
    }
    
    public func calculateCachedSize() -> UInt {
        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        
        let fileContents = (try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)) ?? []
        
        return fileContents.reduce(0) { size, fileContent in
            guard
                let resourceValues = try? fileContent.resourceValues(forKeys: resourceKeys),
                resourceValues.isDirectory != true,
                let fileSize = resourceValues.totalFileAllocatedSize
                else { return size }
            
            return size + UInt(fileSize)
        }
    }
    
    public func cleanAllCache() throws {
        let fileManager = FileManager.default
        let fileContents = try fileManager.contentsOfDirectory(atPath: directory)
        
        for fileContent in fileContents {
            let filePath = directory.appendingPathComponent(fileContent)
            try fileManager.removeItem(atPath: filePath)
        }
    }
    
}
