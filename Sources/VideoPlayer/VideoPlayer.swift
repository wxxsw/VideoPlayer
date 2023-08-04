//
//  VideoPlayer.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import AVFoundation
import GSPlayer
import SwiftUI

@available(iOS 13, *)
public struct VideoPlayer {
    
    public enum State {
        
        /// From the first load to get the first frame of the video
        case loading
        
        /// Playing now
        case playing(totalDuration: Double)
        
        /// Pause, will be called repeatedly when the buffer progress changes
        case paused(playProgress: Double, bufferProgress: Double)
        
        /// An error occurred and cannot continue playing
        case error(NSError)
    }
    
    private(set) var url: URL
    
    @Binding private var play: Bool
    @Binding private var time: CMTime
    
    private var config = Config()
    
    /// Init video player instance.
    /// - Parameters:
    ///   - url: http/https URL
    ///   - play: play/pause
    ///   - time: current time
    public init(url: URL, play: Binding<Bool>, time: Binding<CMTime> = .constant(.zero)) {
        self.url = url
        _play = play
        _time = time
    }
}

@available(iOS 13, *)
public extension VideoPlayer {
    
    /// Set the preload size, the default value is 1024 * 1024, unit is byte.
    static var preloadByteCount: Int {
        get { VideoPreloadManager.shared.preloadByteCount }
        set { VideoPreloadManager.shared.preloadByteCount = newValue }
    }
    
    /// Set the video urls to be preload queue.
    /// Preloading will automatically cache a short segment of the beginning of the video
    /// and decide whether to start or pause the preload based on the buffering of the currently playing video.
    /// - Parameter urls: URL array
    static func preload(urls: [URL]) {
        VideoPreloadManager.shared.set(waiting: urls)
    }
    
    /// Set custom http header, such as token.
    static func customHTTPHeaderFields(transform: @escaping (URL) -> [String: String]?) {
        VideoLoadManager.shared.customHTTPHeaderFields = transform
    }
    
    /// Get the total size of the video cache.
    static func calculateCachedSize() -> UInt {
        return VideoCacheManager.calculateCachedSize()
    }
    
    /// Clean up all caches.
    static func cleanAllCache() {
        try? VideoCacheManager.cleanAllCache()
    }
}

@available(iOS 13, *)
public extension VideoPlayer {
    
    struct Config {
        struct Handler {
            var onBufferChanged: ((Double) -> Void)?
            var onPlayToEndTime: (() -> Void)?
            var onReplay: (() -> Void)?
            var onStateChanged: ((State) -> Void)?
        }
        
        var autoReplay: Bool = false
        var mute: Bool = false
        var speedRate: Float = 1.0
        var contentMode: UIView.ContentMode = .scaleToFill
        
        var handler: Handler = Handler()
    }
    
    /// Whether the video will be automatically replayed until the end of the video playback.
    func autoReplay(_ value: Bool) -> Self {
        var view = self
        view.config.autoReplay = value
        return view
    }
    
    /// Whether the video is muted, only for this instance.
    func mute(_ value: Bool) -> Self {
        var view = self
        view.config.mute = value
        return view
    }

    /// Set the playing speed of video
    func speedRate(_ value: Float) -> Self {
        var view = self
        view.config.speedRate = value
        return view
    }
    
    /// A string defining how the video is displayed within an AVPlayerLayer bounds rect.
    /// scaleAspectFill -> resizeAspectFill, scaleAspectFit -> resizeAspect, other -> resize
    func contentMode(_ value: UIView.ContentMode) -> Self {
        var view = self
        view.config.contentMode = value
        return view
    }
    
    /// Trigger a callback when the buffer progress changes,
    /// the value is between 0 and 1.
    func onBufferChanged(_ handler: @escaping (Double) -> Void) -> Self {
        var view = self
        view.config.handler.onBufferChanged = handler
        return view
    }
    
    /// Playing to the end.
    func onPlayToEndTime(_ handler: @escaping () -> Void) -> Self {
        var view = self
        view.config.handler.onPlayToEndTime = handler
        return view
    }
    
    /// Replay after playing to the end.
    func onReplay(_ handler: @escaping () -> Void) -> Self {
        var view = self
        view.config.handler.onReplay = handler
        return view
    }
    
    /// Playback status changes, such as from play to pause.
    func onStateChanged(_ handler: @escaping (State) -> Void) -> Self {
        var view = self
        view.config.handler.onStateChanged = handler
        return view
    }
    
}

@available(iOS 13, *)
extension VideoPlayer: UIViewRepresentable {
    
    public func makeUIView(context: Context) -> VideoPlayerView {
        let uiView = VideoPlayerView()
        
        uiView.playToEndTime = {
            if self.config.autoReplay == false {
                self.play = false
            }
            DispatchQueue.main.async { self.config.handler.onPlayToEndTime?() }
        }
        
        uiView.contentMode = config.contentMode
        
        uiView.replay = {
            DispatchQueue.main.async { self.config.handler.onReplay?() }
        }
        
        uiView.stateDidChanged = { [unowned uiView] _ in
            let state: State = uiView.convertState()
            
            if case .playing = state {
                context.coordinator.startObserver(uiView: uiView)
            } else {
                context.coordinator.stopObserver(uiView: uiView)
            }
            
            DispatchQueue.main.async { self.config.handler.onStateChanged?(state) }
        }
        
        return uiView
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func updateUIView(_ uiView: VideoPlayerView, context: Context) {
        if context.coordinator.observingURL != url {
            context.coordinator.stopObserver(uiView: uiView)
            context.coordinator.observerTime = nil
            context.coordinator.observerBuffer = nil
            context.coordinator.observingURL = url
        }
        
        play ? uiView.play(for: url) : uiView.pause(reason: .userInteraction)
        uiView.isMuted = config.mute
        uiView.isAutoReplay = config.autoReplay
        uiView.speedRate = config.speedRate
        
        if let observerTime = context.coordinator.observerTime, time != observerTime {
            uiView.seek(to: time, toleranceBefore: time, toleranceAfter: time, completion: { _ in })
        }
    }
    
    public static func dismantleUIView(_ uiView: VideoPlayerView, coordinator: VideoPlayer.Coordinator) {
        uiView.pause(reason: .hidden)
    }
    
    public class Coordinator: NSObject {
        var videoPlayer: VideoPlayer
        var observingURL: URL?
        var observer: Any?
        var observerTime: CMTime?
        var observerBuffer: Double?

        init(_ videoPlayer: VideoPlayer) {
            self.videoPlayer = videoPlayer
        }
        
        func startObserver(uiView: VideoPlayerView) {
            guard observer == nil else { return }
            
            observer = uiView.addPeriodicTimeObserver(forInterval: .init(seconds: 0.25, preferredTimescale: 60)) { [weak self, unowned uiView] time in
                guard let `self` = self else { return }
                
                self.videoPlayer.time = time
                self.observerTime = time
                
                self.updateBuffer(uiView: uiView)
            }
        }
        
        func stopObserver(uiView: VideoPlayerView) {
            guard let observer = observer else { return }
            
            uiView.removeTimeObserver(observer)
            
            self.observer = nil
        }
        
        func updateBuffer(uiView: VideoPlayerView) {
            guard let handler = videoPlayer.config.handler.onBufferChanged else { return }
            
            let bufferProgress = uiView.bufferProgress
                
            guard bufferProgress != observerBuffer else { return }
            
            DispatchQueue.main.async { handler(bufferProgress) }
            
            observerBuffer = bufferProgress
        }
    }
}

private extension VideoPlayerView {
    
    func convertState() -> VideoPlayer.State {
        switch state {
        case .none, .loading:
            return .loading
        case .playing:
            return .playing(totalDuration: totalDuration)
        case .paused(let p, let b):
            return .paused(playProgress: p, bufferProgress: b)
        case .error(let error):
            return .error(error)
        }
    }
}
