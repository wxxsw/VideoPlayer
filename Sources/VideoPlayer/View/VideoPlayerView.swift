//
//  VideoPlayerView.swift
//  VideoPlayer
//
//  Created by Gesen on 2019/7/7.
//  Copyright © 2019 Gesen. All rights reserved.
//

import AVFoundation
import UIKit

public class VideoPlayerView: UIView {
    
    /// An object that manages a player's visual output.
    public let playerLayer = AVPlayerLayer()
    
    /// Get current video status.
    public private(set) var state: VideoPlayer.State = .none {
        didSet { stateDidChanged(state: state, previous: oldValue) }
    }
    
    /// The reason the video was paused.
    public private(set) var pausedReason: VideoPlayer.PausedReason = .waitingKeepUp
    
    /// Number of replays.
    public private(set) var replayCount: Int = 0
    
    /// Whether the video will be automatically replayed until the end of the video playback.
    public var isAutoReplay: Bool = true
    
    /// Play to the end time.
    public var playToEndTime: (() -> Void)?
    
    /// Replay after playing to the end.
    public var replay: (() -> Void)?
    
    /// Playback status changes, such as from play to pause.
    public var stateDidChanged: ((VideoPlayer.State) -> Void)?
    
    /// Whether the video is muted, only for this instance.
    public var isMuted: Bool {
        get { player?.isMuted ?? false }
        set { player?.isMuted = newValue }
    }
    
    /// Video volume, only for this instance.
    public var volume: Double {
        get { player?.volume.double ?? 0 }
        set { player?.volume = newValue.float }
    }
    
    /// Played progress, value range 0-1.
    public var playProgress: Double {
        isLoaded ? player?.playProgress ?? 0 : 0
    }
    
    /// Played length in seconds.
    public var currentDuration: Double {
        isLoaded ? player?.currentDuration ?? 0 : 0
    }
    
    /// Buffered progress, value range 0-1.
    public var bufferProgress: Double {
        isLoaded ? player?.bufferProgress ?? 0 : 0
    }
    
    /// Buffered length in seconds.
    public var currentBufferDuration: Double {
        isLoaded ? player?.currentBufferDuration ?? 0 : 0
    }
    
    /// Total video duration in seconds.
    public var totalDuration: Double {
        isLoaded ? player?.totalDuration ?? 0 : 0
    }
    
    /// The total watch time of this video, in seconds.
    public var watchDuration: Double {
        isLoaded ? currentDuration + totalDuration * Double(replayCount) : 0
    }
    
    private var isLoaded = false
    private var isReplay = false
    
    private var playerURL: URL?
    private var playerBufferingObservation: NSKeyValueObservation?
    private var playerItemKeepUpObservation: NSKeyValueObservation?
    private var playerItemStatusObservation: NSKeyValueObservation?
    private var playerLayerReadyForDisplayObservation: NSKeyValueObservation?
    private var playerTimeControlStatusObservation: NSKeyValueObservation?
    
    // MARK: - Lifecycle
    
    public override var contentMode: UIView.ContentMode {
        didSet {
            switch contentMode {
            case .scaleAspectFill:  playerLayer.videoGravity = .resizeAspectFill
            case .scaleAspectFit:   playerLayer.videoGravity = .resizeAspect
            default:                playerLayer.videoGravity = .resize
            }
        }
    }
    
    public init() {
        super.init(frame: .zero)
        configureInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureInit()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard playerLayer.superlayer == layer else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
    
}

extension VideoPlayerView {
    
    /// Play a video of the specified url.
    ///
    /// - Parameter url: Can be a local or remote URL
    func play(for url: URL) {
        guard playerURL != url else {
            pausedReason = .waitingKeepUp
            player?.play()
            return
        }
        
        observe(player: nil)
        observe(playerItem: nil)
        
        self.player?.currentItem?.cancelPendingSeeks()
        self.player?.currentItem?.asset.cancelLoading()
        
        let player = AVPlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        
        let playerItem = AVPlayerItem(loader: url)
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        self.player = player
        self.playerURL = url
        self.pausedReason = .waitingKeepUp
        self.replayCount = 0
        self.isLoaded = false
        
        if playerItem.isEnoughToPlay || url.isFileURL {
            state = .none
            isLoaded = true
            player.play()
        } else {
            state = .loading
        }
        
        player.replaceCurrentItem(with: playerItem)
        
        observe(player: player)
        observe(playerItem: playerItem)
    }
    
    /// Pause video.
    ///
    /// - Parameter reason: Reason for pause
    func pause(reason: VideoPlayer.PausedReason) {
        pausedReason = reason
        player?.pause()
    }
    
}

private extension VideoPlayerView {
    
    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
}

private extension VideoPlayerView {
    
    func configureInit() {
        
        isHidden = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        
        layer.addSublayer(playerLayer)
    }
    
    func stateDidChanged(state: VideoPlayer.State, previous: VideoPlayer.State) {
        
        guard state != previous else {
            return
        }
        
        switch state {
        case .playing, .paused: isHidden = false
        default:                isHidden = true
        }
        
        self.stateDidChanged?(state)
    }
    
    func observe(player: AVPlayer?) {
        
        guard let player = player else {
            playerLayerReadyForDisplayObservation = nil
            playerTimeControlStatusObservation = nil
            return
        }
        
        playerLayerReadyForDisplayObservation = playerLayer.observe(\.isReadyForDisplay) { [unowned self, unowned player] playerLayer, _ in
            if playerLayer.isReadyForDisplay, player.rate > 0 {
                self.isLoaded = true
                self.state = .playing
            }
        }
        
        playerTimeControlStatusObservation = player.observe(\.timeControlStatus) { [unowned self] player, _ in
            switch player.timeControlStatus {
            case .paused:
                if self.isReplay { break }
                self.state = .paused(reason: self.pausedReason, playProgress: self.playProgress, bufferProgress: self.bufferProgress)
                if self.pausedReason == .waitingKeepUp { player.play() }
            case .waitingToPlayAtSpecifiedRate:
                break
            case .playing:
                if self.playerLayer.isReadyForDisplay, player.rate > 0 {
                    self.isLoaded = true
                    if self.playProgress == 0, self.isReplay { self.isReplay = false; break }
                    self.state = .playing
                }
            @unknown default:
                break
            }
        }
    }
    
    func observe(playerItem: AVPlayerItem?) {
        
        guard let playerItem = playerItem else {
            playerBufferingObservation = nil
            playerItemStatusObservation = nil
            playerItemKeepUpObservation = nil
            return
        }
        
        playerBufferingObservation = playerItem.observe(\.loadedTimeRanges) { [unowned self] item, _ in
            if case .paused = self.state, self.pausedReason != .disappear {
                self.state = .paused(reason: self.pausedReason, playProgress: self.playProgress, bufferProgress: self.bufferProgress)
            }
            
            if self.bufferProgress >= 0.99 || (self.currentBufferDuration - self.currentDuration) > 3 {
                VideoPreloadManager.shared.start()
            } else {
                VideoPreloadManager.shared.pause()
            }
        }
        
        playerItemStatusObservation = playerItem.observe(\.status) { [unowned self] item, _ in
            if item.status == .failed, let error = item.error as NSError? {
                self.state = .error(error)
            }
        }
        
        playerItemKeepUpObservation = playerItem.observe(\.isPlaybackLikelyToKeepUp) { [unowned self] item, _ in
            if item.isPlaybackLikelyToKeepUp {
                if self.player?.rate == 0, self.pausedReason == .waitingKeepUp {
                    self.player?.play()
                }
            }
        }
    }
    
    @objc func playerItemDidPlayToEndTime(notification: Notification) {
        playToEndTime?()
        
        guard
            isAutoReplay,
            pausedReason == .waitingKeepUp,
            (notification.object as? AVPlayerItem) == player?.currentItem
            else { return }
        
        isReplay = true
        
        replay?()
        replayCount += 1
        
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    
}

extension VideoPlayer.State: Equatable {
    
    public static func == (lhs: VideoPlayer.State, rhs: VideoPlayer.State) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.loading, .loading):
            return true
        case (.playing, .playing):
            return true
        case let (.paused(r1, p1, b1), .paused(r2, p2, b2)):
            return (r1 == r2) && (p1 == p2) && (b1 == b2)
        case let (.error(e1), .error(e2)):
            return e1 == e2
        default:
            return false
        }
    }
    
}
