//
//  AVAssetResourceLoadingRequest+Extensions.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import AVFoundation

extension AVAssetResourceLoadingRequest {
    
    var url: URL? {
        let prefix = AVPlayerItem.loaderPrefix
        
        guard
            let urlString = request.url?.absoluteString,
            urlString.hasPrefix(prefix)
            else { return nil }
        
        return urlString.replacingOccurrences(of: prefix, with: "").url
    }
    
}
