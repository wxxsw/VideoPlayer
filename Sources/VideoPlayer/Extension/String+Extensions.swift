//
//  String+Extensions.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
    
    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }
    
    var int: Int? {
        Int(self)
    }
    
    var sha256: String {
        guard let data = data(using: .utf8) else { return self }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes {
            return CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var url: URL? {
        URL(string: self)
    }
    
    func appendingPathComponent(_ str: String) -> String {
        (self as NSString).appendingPathComponent(str)
    }
    
    func appendingPathExtension(_ str: String) -> String? {
        (self as NSString).appendingPathExtension(str)
    }
    
}
