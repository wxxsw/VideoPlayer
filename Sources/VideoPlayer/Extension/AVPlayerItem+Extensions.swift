//
//  AVPlayerItem+Extensions.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import AVFoundation

public extension AVPlayerItem {
    
    var bufferProgress: Double {
        currentBufferDuration / totalDuration
    }
    
    var currentBufferDuration: Double {
        guard let range = loadedTimeRanges.first else { return 0 }
        return Double(CMTimeGetSeconds(CMTimeRangeGetEnd(range.timeRangeValue)))
    }
    
    var currentDuration: Double {
        Double(CMTimeGetSeconds(currentTime()))
    }
    
    var playProgress: Double {
        currentDuration / totalDuration
    }
    
    var totalDuration: Double {
        Double(CMTimeGetSeconds(asset.duration))
    }
    
}

extension AVPlayerItem {
    
    static var loaderPrefix: String = "__loader__"
    
    var url: URL? {
        guard
            let urlString = (asset as? AVURLAsset)?.url.absoluteString,
            urlString.hasPrefix(AVPlayerItem.loaderPrefix)
            else { return nil }
        
        return urlString.replacingOccurrences(of: AVPlayerItem.loaderPrefix, with: "").url
    }
    
    var isEnoughToPlay: Bool {
        guard
            let url = url,
            let configuration = try? VideoCacheManager.shared.cachedConfiguration(for: url)
            else { return false }
        
        return configuration.downloadedByteCount >= 1024 * 768
    }
    
    convenience init(loader url: URL) {
        if url.isFileURL {
            self.init(url: url)
            return
        }
        
        guard let loaderURL = (AVPlayerItem.loaderPrefix + url.absoluteString).url else {
            VideoLoadManager.shared.reportError?(NSError(
                domain: "me.gesen.player.loader",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Wrong url \(url.absoluteString)，unable to initialize Loader"]
            ))
            self.init(url: url)
            return
        }
        
        let urlAsset = AVURLAsset(url: loaderURL)
        urlAsset.resourceLoader.setDelegate(VideoLoadManager.shared, queue: .main)
        
        self.init(asset: urlAsset)
    }
    
}
