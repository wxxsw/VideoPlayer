//
//  VideoLoader.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import AVFoundation

protocol VideoLoaderDelegate: class {
    
    func loader(_ loader: VideoLoader, didFail error: Error)
    
}

class VideoLoader {
    
    weak var delegate: VideoLoaderDelegate?
    
    let url: URL
    
    private let cacheHandler: VideoCacheHandler
    private let downloader: VideoDownloader
    
    private var requestLoaders: [VideoRequestLoader] = []
    
    init(url: URL) throws {
        self.url = url
        self.cacheHandler = try VideoCacheHandler(url: url)
        self.downloader = VideoDownloader(url: url, cacheHandler: cacheHandler)
    }
    
    func append(request: AVAssetResourceLoadingRequest) {
        let requestLoader: VideoRequestLoader
        
        if requestLoaders.count > 0 {
            let downloader = VideoDownloader(url: url, cacheHandler: cacheHandler)
            requestLoader = VideoRequestLoader(request: request, downloader: downloader)
        } else {
            requestLoader = VideoRequestLoader(request: request, downloader: downloader)
        }
        
        requestLoaders.append(requestLoader)
        requestLoader.delegate = self
        requestLoader.start()
    }
    
    func remove(request: AVAssetResourceLoadingRequest) {
        if let index = requestLoaders.firstIndex(where: { $0.request == request }) {
            requestLoaders[index].finish()
            requestLoaders.remove(at: index)
        }
    }
    
    func cancel() {
        downloader.cancel()
        requestLoaders.removeAll()
    }
    
}

extension VideoLoader: VideoRequestLoaderDelegate {

    func loader(_ loader: VideoRequestLoader, didFinish error: Error?) {
        remove(request: loader.request)
        
        if let error = error {
            delegate?.loader(self, didFail: error)
        }
    }
    
}
