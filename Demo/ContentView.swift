//
//  ContentView.swift
//  Demo
//
//  Created by Gesen on 2019/7/14.
//

import AVFoundation
import SwiftUI
import VideoPlayer

private let demoURL = URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!

struct ContentView : View {
    @State private var play: Bool = true
    @State private var time: CMTime = .zero
    @State private var autoReplay: Bool = true
    @State private var mute: Bool = false
    @State private var stateText: String = ""
    @State private var totalDuration: Double = 0
    
    var body: some View {
        VStack {
            VideoPlayer(url: demoURL, play: $play, time: $time)
                .autoReplay(autoReplay)
                .mute(mute)
                .onPlayToEndTime { print("onPlayToEndTime") }
                .onReplay { print("onReplay") }
                .onStateChanged { state in
                    switch state {
                    case .loading:
                        self.stateText = "Loading..."
                    case .playing(let totalDuration):
                        self.stateText = "Playing!"
                        self.totalDuration = totalDuration
                    case .paused(let playProgress, let bufferProgress):
                        self.stateText = "Paused: play \(Int(playProgress * 100))% buffer \(Int(bufferProgress * 100))%"
                    case .error(let error):
                        self.stateText = "Error: \(error)"
                    }
                }
                .aspectRatio(1.78, contentMode: .fit)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.7), radius: 30, x: 0, y: 2)
                .padding()
            
            Text(stateText)
                .padding()
            
            HStack {
                Button(self.play ? "Pause" : "Play") {
                    self.play.toggle()
                }
                
                Divider().frame(height: 20)
                
                Button(self.mute ? "Sound Off" : "Sound On") {
                    self.mute.toggle()
                }
                
                Divider().frame(height: 20)
                
                Button(self.autoReplay ? "Auto Replay On" : "Auto Replay Off") {
                    self.autoReplay.toggle()
                }
            }
            
            HStack {
                Button("Backward 5s") {
                    self.time = CMTimeMakeWithSeconds(max(0, self.time.seconds - 5), preferredTimescale: self.time.timescale)
                }
                
                Divider().frame(height: 20)
                
                Text("\(getTimeString()) / \(getTotalDurationString())")
                
                Divider().frame(height: 20)
                
                Button("Forward 5s") {
                    self.time = CMTimeMakeWithSeconds(min(self.totalDuration, self.time.seconds + 5), preferredTimescale: self.time.timescale)
                }
            }
            
            Spacer()
        }
        .onDisappear { self.play = false }
    }
    
    func getTimeString() -> String {
        let m = Int(time.seconds / 60)
        let s = Int(time.seconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", arguments: [m, s])
    }
    
    func getTotalDurationString() -> String {
        let m = Int(totalDuration / 60)
        let s = Int(totalDuration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", arguments: [m, s])
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
