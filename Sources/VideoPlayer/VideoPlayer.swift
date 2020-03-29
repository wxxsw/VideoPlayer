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
    
    private var configuration = Configuration()
    
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
    
    /// Set the video urls to be preload queue. Preloading will automatically cache a short segment of the beginning of the video and decide whether to start or pause the preload based on the buffering of the currently playing video.
    /// - Parameter urls: URL array
    static func preload(urls: [URL]) {
        VideoPreloadManager.shared.set(waiting: urls)
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
    
    struct Configuration {
        var autoReplay: Bool = false
        var mute: Bool = false
        var onPlayToEndTime: (() -> Void)?
        var onReplay: (() -> Void)?
        var onStateChanged: ((State) -> Void)?
    }
    
    /// Whether the video will be automatically replayed until the end of the video playback.
    func autoReplay(_ value: Bool) -> Self {
        var view = self
        view.configuration.autoReplay = value
        return view
    }
    
    /// Whether the video is muted, only for this instance.
    func mute(_ value: Bool) -> Self {
        var view = self
        view.configuration.mute = value
        return view
    }
    
    func onPlayToEndTime(_ handler: @escaping () -> Void) -> Self {
        var view = self
        view.configuration.onPlayToEndTime = handler
        return view
    }
    
    /// Replay after playing to the end.
    func onReplay(_ handler: @escaping () -> Void) -> Self {
        var view = self
        view.configuration.onReplay = handler
        return view
    }
    
    /// Playback status changes, such as from play to pause.
    func onStateChanged(_ handler: @escaping (State) -> Void) -> Self {
        var view = self
        view.configuration.onStateChanged = handler
        return view
    }
    
}

@available(iOS 13, *)
extension VideoPlayer: UIViewRepresentable {
    
    public func makeUIView(context: Context) -> VideoPlayerView {
        let uiView = VideoPlayerView()
        
        uiView.playToEndTime = {
            if self.configuration.autoReplay == false {
                self.play = false
            }
            DispatchQueue.main.async { self.configuration.onPlayToEndTime?() }
        }
        
        uiView.replay = {
            DispatchQueue.main.async { self.configuration.onReplay?() }
        }
        
        uiView.stateDidChanged = { [unowned uiView] originalState in
            let state: State
            
            switch originalState {
                
            case .playing:
                state = .playing(totalDuration: uiView.totalDuration)
                
                if context.coordinator.observer != nil { break }
                context.coordinator.observer = uiView.addPeriodicTimeObserver(forInterval: .init(seconds: 0.5, preferredTimescale: 60)) { time in
                    self.time = time
                    context.coordinator.observerTime = time
                }
                
            case .paused(let p, let b):
                state = .paused(playProgress: p, bufferProgress: b)
                
                if context.coordinator.observer == nil { break }
                uiView.removeTimeObserver(context.coordinator.observer!)
                context.coordinator.observer = nil
                
            case .error(let error):
                state = .error(error)
                
            default:
                state = .loading
            }
            
            DispatchQueue.main.async { self.configuration.onStateChanged?(state) }
        }
        
        return uiView
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func updateUIView(_ uiView: VideoPlayerView, context: Context) {
        play ? uiView.play(for: url) : uiView.pause(reason: .userInteraction)
        uiView.isMuted = configuration.mute
        uiView.isAutoReplay = configuration.autoReplay
        
        if let observerTime = context.coordinator.observerTime, time != observerTime {
            uiView.seek(to: time, toleranceBefore: time, toleranceAfter: time, completion: { _ in })
        }
    }
    
    public static func dismantleUIView(_ uiView: VideoPlayerView, coordinator: VideoPlayer.Coordinator) {
        uiView.pause(reason: .hidden)
    }
    
    public class Coordinator: NSObject {
        var videoPlayer: VideoPlayer
        var observer: Any?
        var observerTime: CMTime?

        init(_ videoPlayer: VideoPlayer) {
            self.videoPlayer = videoPlayer
        }
    }
    
}
