//
//  VideoDownloaderSessionDelegateHandler.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

private let bufferSize = 1024 * 256

protocol VideoDownloaderSessionDelegateHandlerDelegate: class {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)

}

class VideoDownloaderSessionDelegateHandler: NSObject {
    
    weak var delegate: VideoDownloaderSessionDelegateHandlerDelegate?
    
    var buffer = Data()
    
    init(delegate: VideoDownloaderSessionDelegateHandlerDelegate) {
        self.delegate = delegate
    }
    
}

extension VideoDownloaderSessionDelegateHandler: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        delegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        
        guard buffer.count > bufferSize else { return }
        
        callbackBuffer(session: session, dataTask: dataTask)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if buffer.count > 0 && error == nil {
            callbackBuffer(session: session, dataTask: task as! URLSessionDataTask)
        }
        
        delegate?.urlSession(session, task: task, didCompleteWithError: error)
    }
    
}

private extension VideoDownloaderSessionDelegateHandler {
    
    private func callbackBuffer(session: URLSession, dataTask: URLSessionDataTask) {
        let range: Range<Int> = 0 ..< buffer.count
        let chunk = buffer.subdata(in: range)
        
        buffer.replaceSubrange(range, with: [], count: 0)
        
        delegate?.urlSession(session, dataTask: dataTask, didReceive: chunk)
    }
    
}
