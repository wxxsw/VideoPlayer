![VideoPlayer](https://github.com/wxxsw/VideoPlayer/blob/master/Images/logo.png)

<p align="center">
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/language-Swift%205-f48041.svg?style=flat"></a>
<a href="https://developer.apple.com/swiftui"><img src="https://img.shields.io/badge/framework-SwiftUI-blue.svg?style=flat"></a>
<a href="https://developer.apple.com/ios"><img src="https://img.shields.io/badge/platform-iOS%2013%2b-blue.svg?style=flat"></a>
<a href="https://github.com/apple/swift-package-manager"><img src="https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat"></a>
<a href="https://codebeat.co/projects/github-com-wxxsw-videoplayer-master"><img alt="codebeat badge" src="https://codebeat.co/badges/030d7cd9-f1ed-46b0-b6cc-90928ef7c941" /></a>
<a href="https://github.com/wxxsw/VideoPlayer/blob/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat"></a>
</p>
<br/>

- [Features](#features)
- [QuickStart](#quick-start)
- [Advances](#advances)
- [Installation](#installation)
- [Requirements](#requirements)
- [License](#license)


## Demo

![Screenshot](https://github.com/wxxsw/VideoPlayer/blob/master/Images/screenshot.png)

1. Clone or download the project.
2. In the terminal, run `swift package resolve`
3. Open `VideoPlayer.xcodeproj` and run `Demo` target.

## Features

- [x] Fully customizable UI.
- [x] Plays local media or streams remote media over HTTP.
- [x] Built-in caching mechanism to support playback while downloading.
- [x] Can preload multiple videos at any time.
- [x] Support seek to duration.
- [x] Simple API.

## Quick Start

```swift
struct ContentView : View {
    @State private var play: Bool = true
    
    var body: some View {
        VideoPlayer(url: someVideoURL, play: $play)
    }
}
```

## Advances

```swift
struct ContentView : View {  
    @State private var autoReplay: Bool = true 
    @State private var mute: Bool = false      
    @State private var play: Bool = true       
    @State private var time: CMTime = .zero  
    
    var body: some View {
        VideoPlayer(url: someVideoURL, play: $play, time: $time)
            .autoReplay(autoReplay)
            .mute(mute)
            .onBufferChanged { progress in
                // Network loading buffer progress changed
            }
            .onPlayToEndTime { 
                // Play to the end time.
            }
            .onReplay { 
                // Replay after playing to the end. 
            }
            .onStateChanged { state in 
                switch state {
                case .loading:
                    // Loading...
                case .playing(let totalDuration):
                    // Playing...
                case .paused(let playProgress, let bufferProgress):
                    // Paused...
                case .error(let error):
                    // Error...
                }
            }
    }
}
```

### Preload

Set the video urls to be preload queue. Preloading will automatically cache a short segment of the beginning of the video and decide whether to start or pause the preload based on the buffering of the currently playing video.
```swift
VideoPlayer.preload(urls: [URL])
```

Set the preload size, the default value is 1024 * 1024, unit is byte.
```swift
VideoPlayer.preloadByteCount = 1024 * 1024 // = 1M
```

### Cache

Get the total size of the video cache.
```swift
let size = VideoPlayer.calculateCachedSize()
```

Clean up all caches.
```swift
VideoPlayer.cleanAllCache()
```

## Installation

### Swift Package Manager

1. Select `Xcode -> File -> Swift Packages -> Add Package Dependency...` 
2. Enter `https://github.com/wxxsw/VideoPlayer`.
3. Click `Next`, then select the version, complete.

## Requirements

- iOS 13+
- Xcode 11+
- Swift 5+

## Thanks

Banner Design by [@aduqin](https://dribbble.com/aduqin)

## License

VideoPlayer is released under the MIT license. [See LICENSE](https://github.com/wxxsw/VideoPlayer/blob/master/LICENSE) for details.
