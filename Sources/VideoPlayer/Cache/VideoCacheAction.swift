//
//  VideoCacheAction.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

struct VideoCacheAction {
    
    enum ActionType {
        case local
        case remote
    }
    
    let actionType: ActionType
    let range: NSRange
    
}
