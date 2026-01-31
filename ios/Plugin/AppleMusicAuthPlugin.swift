@preconcurrency import Capacitor
import Foundation
import MusicKit
import StoreKit

/// Box to capture CAPPluginCall in a @Sendable closure; only use call on MainActor.
private final class PluginCallBox: @unchecked Sendable {
    weak var call: CAPPluginCall?
    init(_ call: CAPPluginCall?) { self.call = call }
}

/// Box to capture bridge reference in a @Sendable closure; only use on MainActor.
private final class BridgeBox: @unchecked Sendable {
    weak var bridge: CAPBridgeProtocol?
    init(_ bridge: CAPBridgeProtocol?) { self.bridge = bridge }
}

@objc(AppleMusicAuthPlugin)
public class AppleMusicAuthPlugin: CAPPlugin {
    
    // Store the currently playing song to access its duration (stored as Any to avoid @available on stored property)
    private var currentSongStorage: Any?
    
    // Timer for progress updates
    private var progressTimer: Timer?
    
    deinit {
        stopProgressTimer()
    }
    
    private func startProgressTimer() {
        stopProgressTimer() // Clear any existing timer
        
        // Ensure timer runs on main thread's run loop
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if #available(iOS 15.0, *) {
                    let player = ApplicationMusicPlayer.shared
                    let currentTime = player.playbackTime
                    
                    // Get duration from stored song
                    var duration: TimeInterval = 0
                    if let song = self.currentSongStorage as? Song {
                        duration = song.duration ?? 0
                    }
                    
                    NSLog("⏱️ Progress timer: \(currentTime)s / \(duration)s")
                    
                    self.notifyListeners("playbackTime", data: [
                        "currentTime": currentTime,
                        "duration": duration
                    ])
                }
            }
            
            // Add to run loop to ensure it fires
            if let timer = self.progressTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }
    
    private func stopProgressTimer() {
        DispatchQueue.main.async { [weak self] in
            NSLog("⏱️ Stopping progress timer")
            self?.progressTimer?.invalidate()
            self?.progressTimer = nil
        }
    }

    @objc func requestAuthorization(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            bridge?.saveCall(call)
            let developerToken = call.getString("developerToken")
            Task { @MainActor in
                let status = await MusicAuthorization.request()
                let authorized = status == .authorized
                let statusString = statusToString(status)
                if !authorized {
                    call.resolve([
                        "authorized": false,
                        "status": statusString
                    ])
                    self.bridge?.releaseCall(call)
                    return
                }
                if let devToken = developerToken, !devToken.isEmpty {
                    let callBox = PluginCallBox(call)
                    let bridgeBox = BridgeBox(bridge)
                    SKCloudServiceController().requestUserToken(forDeveloperToken: devToken) { userToken, error in
                        let status = statusString
                        DispatchQueue.main.async {
                            guard let call = callBox.call else { return }
                            if let error = error {
                                call.reject("Apple Music user token failed: \(error.localizedDescription)", nil, error)
                                bridgeBox.bridge?.releaseCall(call)
                                return
                            }
                            var result: [String: Any] = [
                                "authorized": true,
                                "status": status
                            ]
                            if let token = userToken, !token.isEmpty {
                                result["token"] = token
                            }
                            call.resolve(result)
                            bridgeBox.bridge?.releaseCall(call)
                        }
                    }
                } else {
                    call.resolve([
                        "authorized": true,
                        "status": statusString
                    ])
                    self.bridge?.releaseCall(call)
                }
            }
        } else {
            call.reject("Apple Music requires iOS 15 or later", nil, nil)
        }
    }

    @objc func getAuthorizationStatus(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            let status = MusicAuthorization.currentStatus
            call.resolve([
                "status": statusToString(status)
            ])
        } else {
            call.resolve(["status": "notDetermined"])
        }
    }

    @objc func hasSubscription(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            Task { @MainActor in
                do {
                    let value = try await MusicSubscription.current.canPlayCatalogContent
                    call.resolve(["value": value])
                } catch {
                    call.resolve(["value": false])
                }
            }
        } else {
            call.resolve(["value": false])
        }
    }

    @objc func playSong(_ call: CAPPluginCall) {
        guard let songId = call.getString("songId"), !songId.isEmpty else {
            call.reject("songId is required")
            return
        }
        if #available(iOS 15.0, *) {
            Task { @MainActor in
                let status = MusicAuthorization.currentStatus
                guard status == .authorized else {
                    let statusStr = statusToString(status)
                    NSLog("❌ Apple Music not authorized. Status: \(statusStr)")
                    call.reject("Apple Music not authorized. Status: \(statusStr)")
                    return
                }
                do {
                    let canPlay = try await MusicSubscription.current.canPlayCatalogContent
                    guard canPlay else {
                        NSLog("❌ No active Apple Music subscription")
                        call.reject("No active Apple Music subscription")
                        return
                    }
                    let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(songId))
                    let response = try await request.response()
                    guard let song = response.items.first else {
                        NSLog("❌ Song not found in catalog: \(songId)")
                        call.reject("Song not found in Apple Music catalog (ID: \(songId))")
                        return
                    }
                    let player = ApplicationMusicPlayer.shared
                    player.queue = [song]
                    try await player.play()
                    
                    // Store the current song for duration retrieval
                    self.currentSongStorage = song
                    
                    // Start progress timer when playback starts
                    self.startProgressTimer()
                    
                    // Notify that playback started
                    self.notifyListeners("playbackStateChange", data: [
                        "isPlaying": true,
                        "state": "playing"
                    ])
                    
                    NSLog("✅ Playing song: \(songId)")
                    call.resolve([:])
                } catch {
                    let errorMsg = "Failed to play song: \(error.localizedDescription)"
                    let errorDetails = "\(error)"
                    NSLog("❌ \(errorMsg) - Details: \(errorDetails)")
                    call.reject(errorMsg, "PLAYBACK_ERROR", error, ["details": errorDetails])
                }
            }
        } else {
            call.reject("Apple Music requires iOS 15 or later")
        }
    }

    @objc func getCurrentTime(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            let player = ApplicationMusicPlayer.shared
            let currentTime = player.playbackTime
            call.resolve(["value": currentTime])
        } else {
            call.resolve(["value": 0])
        }
    }
    
    @objc func getDuration(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            // Use the stored current song to get duration
            if let song = self.currentSongStorage as? Song {
                let duration = song.duration ?? 0
                call.resolve(["value": duration])
            } else {
                // No song stored, return 0
                call.resolve(["value": 0])
            }
        } else {
            call.resolve(["value": 0])
        }
    }
    
    @objc func pause(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            Task {
                let player = ApplicationMusicPlayer.shared
                player.pause()
                
                // Stop progress timer
                self.stopProgressTimer()
                
                // Notify that playback paused
                self.notifyListeners("playbackStateChange", data: [
                    "isPlaying": false,
                    "state": "paused"
                ])
                
                await MainActor.run {
                    call.resolve()
                }
            }
        } else {
            call.reject("Apple Music requires iOS 15 or later")
        }
    }
    
    @objc func play(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            Task {
                do {
                    let player = ApplicationMusicPlayer.shared
                    try await player.play()
                    
                    // Start progress timer
                    self.startProgressTimer()
                    
                    // Notify that playback resumed
                    self.notifyListeners("playbackStateChange", data: [
                        "isPlaying": true,
                        "state": "playing"
                    ])
                    
                    await MainActor.run {
                        call.resolve()
                    }
                } catch {
                    await MainActor.run {
                        call.reject("Failed to play: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            call.reject("Apple Music requires iOS 15 or later")
        }
    }
    
    @objc func stop(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            Task {
                let player = ApplicationMusicPlayer.shared
                player.stop()
                
                // Stop progress timer
                self.stopProgressTimer()
                
                // Clear stored song
                self.currentSongStorage = nil
                
                // Notify that playback stopped
                self.notifyListeners("playbackStateChange", data: [
                    "isPlaying": false,
                    "state": "stopped"
                ])
                
                await MainActor.run {
                    call.resolve()
                }
            }
        } else {
            call.reject("Apple Music requires iOS 15 or later")
        }
    }
    
    @objc func seek(_ call: CAPPluginCall) {
        guard let time = call.getDouble("time") else {
            call.reject("time parameter is required")
            return
        }
        if #available(iOS 15.0, *) {
            Task {
                let player = ApplicationMusicPlayer.shared
                player.playbackTime = time
                
                // Immediately notify listeners with the new time
                var duration: TimeInterval = 0
                if let song = self.currentSongStorage as? Song {
                    duration = song.duration ?? 0
                }
                
                self.notifyListeners("playbackTime", data: [
                    "currentTime": time,
                    "duration": duration
                ])
                
                await MainActor.run {
                    call.resolve()
                }
            }
        } else {
            call.reject("Apple Music requires iOS 15 or later")
        }
    }

    @available(iOS 15.0, *)
    private func statusToString(_ status: MusicAuthorization.Status) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }
}
