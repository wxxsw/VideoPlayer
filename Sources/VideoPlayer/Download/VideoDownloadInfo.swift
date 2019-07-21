//
//  VideoDownloadInfo.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

struct VideoDownloadInfo: Codable {
    
    let byteCount: Int
    let spendTime: TimeInterval
    let startTime: Date
    
    var speed: Double {
        Double(byteCount) / 1024 / spendTime
    }
    
    init(byteCount: Int, spendTime: TimeInterval, startTime: Date) {
        self.byteCount = byteCount
        self.spendTime = spendTime
        self.startTime = startTime
    }
    
}
