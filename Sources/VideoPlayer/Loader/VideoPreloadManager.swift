//
//  VideoPreloadManager.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

public class VideoPreloadManager: NSObject {
    
    public static let shared = VideoPreloadManager()
    
    public var didStart: (() -> Void)?
    public var didPause: (() -> Void)?
    public var didFinish: ((Error?) -> Void)?
    
    private var downloader: VideoDownloader?
    private var waitingQueue: [URL] = []
    
    public func set(waiting: [URL]) {
        downloader = nil
        waitingQueue = waiting
    }
    
    func start() {
        guard downloader == nil, waitingQueue.count > 0 else {
            downloader?.resume()
            return
        }
        
        let url = waitingQueue.removeFirst()
        
        guard
            !VideoLoadManager.shared.loaderMap.keys.contains(url),
            let cacheHandler = try? VideoCacheHandler(url: url) else {
            return
        }
        
        downloader = VideoDownloader(url: url, cacheHandler: cacheHandler)
        downloader?.delegate = self
        downloader?.download(from: 0, length: 1024 * 1024)
        
        if cacheHandler.configuration.downloadedByteCount < 1024 * 1024 {
            didStart?()
        }
    }
    
    func pause() {
        downloader?.suspend()
        didPause?()
    }
    
    func remove(url: URL) {
        if let index = waitingQueue.firstIndex(of: url) {
            waitingQueue.remove(at: index)
        }
        
        if downloader?.url == url {
            downloader = nil
        }
    }
    
}

extension VideoPreloadManager: VideoDownloaderDelegate {
    
    public func downloader(_ downloader: VideoDownloader, didReceive response: URLResponse) {
        
    }
    
    public func downloader(_ downloader: VideoDownloader, didReceive data: Data) {
        
    }
    
    public func downloader(_ downloader: VideoDownloader, didFinished error: Error?) {
        self.downloader = nil
        start()
        didFinish?(error)
    }
    
}
