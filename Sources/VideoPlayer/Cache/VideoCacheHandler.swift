//
//  VideoCacheHandler.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

private let packageLength = 1024 * 512

public class VideoCacheHandler {
    
    private(set) var configuration: VideoCacheConfiguration
    
    private let readFileHandle: FileHandle
    private let writeFileHandle: FileHandle
    
    public init(url: URL) throws {
        let fileManager = FileManager.default
        let filePath = VideoCacheManager.shared.cachedFilePath(for: url)
        let fileURL = URL(fileURLWithPath: filePath)
        let fileDirectory = filePath.deletingLastPathComponent
        
        if !fileManager.fileExists(atPath: fileDirectory) {
            try fileManager.createDirectory(
                atPath: fileDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        if !fileManager.fileExists(atPath: filePath) {
            fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
        }
        
        configuration = try VideoCacheConfiguration.configuration(for: filePath)
        readFileHandle = try FileHandle(forReadingFrom: fileURL)
        writeFileHandle = try FileHandle(forWritingTo: fileURL)
    }
    
    deinit {
        readFileHandle.closeFile()
        writeFileHandle.closeFile()
    }
    
    func actions(for range: NSRange) -> [VideoCacheAction] {
        guard range.location != NSNotFound else { return [] }
        
        var localActions = [VideoCacheAction]()
        
        for fragment in configuration.fragments {
            let intersection = NSIntersectionRange(range, fragment)

            guard intersection.length > 0 else {
                if fragment.location >= range.upperBound {
                    break
                } else {
                    continue
                }
            }

            let package = intersection.length.double / packageLength.double
            let max = intersection.location + intersection.length

            for i in 0 ..< package.rounded(.up).int {
                let offset = intersection.location + i * packageLength
                let length = (offset + packageLength) > max ? max - offset : packageLength

                localActions.append(VideoCacheAction(
                    actionType: .local,
                    range: NSRange(location: offset, length: length)
                ))
            }
        }
        
        guard localActions.count > 0 else {
            return [VideoCacheAction(actionType: .remote, range: range)]
        }
        
        var localRemoteActions = [VideoCacheAction]()
        
        for (i, action) in localActions.enumerated() {
            if i == 0 {
                if range.location < action.range.location {
                    localRemoteActions.append(VideoCacheAction(
                        actionType: .remote,
                        range: NSRange(
                            location: range.location,
                            length: action.range.location - range.location
                        )
                    ))
                }
                localRemoteActions.append(action)
            } else if let lastOffset = localRemoteActions.last?.range.upperBound {
                if lastOffset < action.range.location {
                    localRemoteActions.append(VideoCacheAction(
                        actionType: .remote,
                        range: NSRange(
                            location: lastOffset,
                            length: action.range.location - lastOffset
                        )
                    ))
                }
                localRemoteActions.append(action)
            }
            
            if i == localActions.count - 1, action.range.upperBound < range.upperBound {
                localRemoteActions.append(VideoCacheAction(
                    actionType: .remote,
                    range: NSRange(
                        location: action.range.upperBound,
                        length: range.upperBound - action.range.upperBound
                    )
                ))
            }
        }
        
        return localRemoteActions
    }
    
    func cache(data: Data, for range: NSRange) {
        objc_sync_enter(writeFileHandle)
        writeFileHandle.seek(toFileOffset: UInt64(range.location))
        writeFileHandle.write(data)
        configuration.add(fragment: range)
        objc_sync_exit(writeFileHandle)
    }
    
    func cachedData(for range: NSRange) -> Data {
        objc_sync_enter(readFileHandle)
        readFileHandle.seek(toFileOffset: UInt64(range.location))
        let data = self.readFileHandle.readData(ofLength: range.length)
        objc_sync_exit(readFileHandle)
        return data
    }
    
    func set(info: VideoInfo) {
        objc_sync_enter(writeFileHandle)
        configuration.info = info
        writeFileHandle.truncateFile(atOffset: UInt64(info.contentLength))
        writeFileHandle.synchronizeFile()
        objc_sync_exit(writeFileHandle)
    }
    
    func save() {
        objc_sync_enter(writeFileHandle)
        writeFileHandle.synchronizeFile()
        configuration.save()
        objc_sync_exit(writeFileHandle)
    }
    
}
