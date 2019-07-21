![VideoPlayer](https://github.com/wxxsw/VideoPlayer/blob/master/Images/logo.png)

<p align="center">
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/language-Swift%205-f48041.svg?style=flat"></a>
<a href="https://developer.apple.com/swiftui"><img src="https://img.shields.io/badge/framework-SwiftUI-blue.svg?style=flat"></a>
<a href="https://developer.apple.com/ios"><img src="https://img.shields.io/badge/platform-iOS%2013%2b-blue.svg?style=flat"></a>
<a href="https://github.com/apple/swift-package-manager"><img src="https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat"></a>
<a href="https://github.com/wxxsw/VideoPlayer/blob/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat"></a>
</p>

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Features

- [x] Plays local media or streams remote media over HTTP.
- [x] Cache video data at playing.
- [x] Customizable UI and user interaction.
- [x] No size restrictions.
- [x] Simple API.

## TODO

- [ ] Orientation change support.
- [ ] Seek time support.
- [ ] More complex demo.

## Requirements

- iOS 13+
- Xcode 11+
- Swift 5+

## Installation

### Swift Package Manager

1. Select `Xcode -> File -> Swift Packages -> Add Package Dependency...` 
2. Enter `https://github.com/wxxsw/VideoPlayer`.
3. Click `Next`, then select the version, complete.

## Usage

```swift
struct ContentView : View {
    @State var isAutoReplay: Bool = true
    @State var isPlay: Bool = true
    @State var isMute: Bool = false
    
    let videoURL: URL
    
    var body: some View {
        VideoPlayerView(url: .constant(videoURL), isPlay: $isPlay)
            .autoReplay($isAutoReplay)
            .mute($isMute)
            .onPlayToEndTime { print("Play to the end time.") }
            .onReplay { print("Replay after playing to the end.") }
            .onStateChanged { _ in print("Playback status changes, such as from play to pause.") }
    }
}
```

## Thanks

Banner Design by [@aduqin](https://dribbble.com/aduqin)

## License

VideoPlayer is released under the MIT license. [See LICENSE](https://github.com/wxxsw/VideoPlayer/blob/master/LICENSE) for details.
