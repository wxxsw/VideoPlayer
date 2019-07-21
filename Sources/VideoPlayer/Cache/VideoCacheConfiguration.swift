//
//  VideoCacheConfiguration.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

public struct VideoCacheConfiguration: Codable {
    
    static func configuration(for videoFilePath: String) throws -> VideoCacheConfiguration {
        let filePath = configurationFilePath(for: videoFilePath)
        
        guard
            FileManager.default.fileExists(atPath: filePath),
            let data = FileManager.default.contents(atPath: filePath)
            else { return VideoCacheConfiguration(filePath: filePath) }
        
        var configuration = try JSONDecoder().decode(VideoCacheConfiguration.self, from: data)
        configuration.filePath = filePath
        
        return configuration
    }
    
    static func configurationFilePath(for filePath: String) -> String {
        filePath.appendingPathExtension("cfg")!
    }
    
    var info: VideoInfo?

    private(set) var fragments: [NSRange] = []
    
    var downloadedByteCount: Int {
        fragments.reduce(0) { $0 + $1.length }
    }
    
    var progress: Double {
        Double(downloadedByteCount) / Double(info?.contentLength ?? -1)
    }
    
    private var filePath: String
    
    private init(filePath: String) {
        self.filePath = filePath
    }
    
    mutating func add(fragment: NSRange) {
        guard
            fragment.location != NSNotFound,
            fragment.length > 0
            else { return }
        
        if fragments.count == 0 {
            fragments.append(fragment)
            return
        }
        
        var indexSet = IndexSet()
        
        for (i, range) in fragments.enumerated() {
            if fragment.upperBound <= range.location {
                if indexSet.count == 0 { indexSet.insert(i) }
                break
            } else if fragment.location <= range.upperBound && fragment.upperBound > range.location {
                indexSet.insert(i)
            } else if fragment.location >= range.upperBound {
                if i == fragments.count - 1 { indexSet.insert(i) }
            }
        }
        
        guard
            let firstIndex = indexSet.first,
            let lastIndex = indexSet.last
            else { return }
        
        if indexSet.count == 1 {
            
            var range1 = fragments[firstIndex]
            range1.length += 1
            
            var range2 = fragment
            range2.length += 1
            
            let intersection = NSIntersectionRange(range1, range2)
            
            if intersection.length == 0 {
                if fragment.location < fragments[firstIndex].location {
                    fragments.insert(fragment, at: firstIndex)
                } else {
                    fragments.insert(fragment, at: lastIndex + 1)
                }
                return
            }
        }
        
        let location = min(fragments[firstIndex].location, fragment.location)
        let upperBound = max(fragments[lastIndex].upperBound, fragment.upperBound)
        let combine = NSRange(location: location, length: upperBound - location)
        
        fragments = fragments
            .enumerated()
            .compactMap { indexSet.contains($0.0) ? nil : $0.1 }
        
        fragments.insert(combine, at: firstIndex)
    }
    
    func save() {
        do {
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
            }
            
            if !FileManager.default.createFile(
                atPath: filePath,
                contents: try JSONEncoder().encode(self),
                attributes: nil
            ) {
                throw NSError(
                    domain: "me.gesen.player.cache",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create file"]
                )
            }
        } catch {
            VideoLoadManager.shared.reportError?(error)
        }
    }
    
}
