# @sounds/capacitor-apple-music-auth

Capacitor plugin for Apple Music authorization and playback across iOS, Android, and Web platforms. Each platform uses the most appropriate Apple Music integration method.

## Platform support

| Platform | Authorization | Playback | Implementation |
|----------|--------------|----------|----------------|
| **iOS**  | ✅ Native MusicKit (in-app) | ✅ Native ApplicationMusicPlayer | Use plugin methods for everything |
| **Android** | ✅ Native MusicKit SDK | ⚠️ Use MusicKit JS in WebView | Plugin for auth, MusicKit JS for playback |
| **Web**  | ✅ MusicKit JS | ✅ MusicKit JS | Load MusicKit globally, use plugin for auth |

## Requirements

- **iOS**: 15.0+ (MusicKit)
- **Android**: MusicKit authentication SDK (included via JitPack). Apple Music app required on device for auth flow.
- **Capacitor**: ^7.0.0

## Installation

```bash
npm install @sounds/capacitor-apple-music-auth
npx cap sync ios
npx cap sync android
```

## Recommended Implementation by Platform

### iOS (Native - Recommended)

Use the plugin for **all** Apple Music operations. No MusicKit JS needed.

```typescript
import AppleMusicAuth from '@sounds/capacitor-apple-music-auth';
import { Capacitor } from '@capacitor/core';

if (Capacitor.getPlatform() === 'ios') {
  // Authorization
  const res = await AppleMusicAuth.requestAuthorization();
  if (res.authorized) {
    // Playback control
    await AppleMusicAuth.playSong({ songId: '1234567890' });
    await AppleMusicAuth.pause();
    await AppleMusicAuth.play();
    await AppleMusicAuth.stop();
    
    // Playback info
    const { value: currentTime } = await AppleMusicAuth.getCurrentTime();
    const { value: duration } = await AppleMusicAuth.getDuration();
    
    // Subscription check
    const { value: hasSub } = await AppleMusicAuth.hasSubscription();
  }
}
```

### Web (MusicKit JS - Recommended)

Load MusicKit JS globally and use it directly for playback. The plugin can handle authorization but MusicKit JS is preferred.

```typescript
// 1. Load MusicKit JS in your HTML
// <script src="https://js-cdn.music.apple.com/musickit/v1/musickit.js"></script>

// 2. Configure MusicKit with your developer token
await MusicKit.configure({
  developerToken: 'YOUR_DEVELOPER_TOKEN',
  app: {
    name: 'Your App Name',
    build: '1.0.0'
  }
});

// 3. Authorize (you can use the plugin or MusicKit JS directly)
const musicKitInstance = MusicKit.getInstance();
const userToken = await musicKitInstance.authorize();

// 4. Use MusicKit JS directly for playback
await musicKitInstance.setQueue({ song: '1234567890' });
await musicKitInstance.play();
await musicKitInstance.pause();

// Get playback info from MusicKit JS
const currentTime = musicKitInstance.player.currentPlaybackTime;
const duration = musicKitInstance.player.currentPlaybackDuration;
```

### Android (Hybrid - Plugin + MusicKit JS)

Use the plugin for authorization, but MusicKit JS for playback (plugin doesn't support playback on Android).

```typescript
import AppleMusicAuth from '@sounds/capacitor-apple-music-auth';
import { Capacitor } from '@capacitor/core';

if (Capacitor.getPlatform() === 'android') {
  // Authorization via plugin (requires Apple Music app installed)
  const res = await AppleMusicAuth.requestAuthorization({ 
    developerToken: 'YOUR_DEVELOPER_TOKEN' 
  });
  
  if (res.authorized && res.token) {
    // Save the token for MusicKit JS
    localStorage.setItem('music-user-token', res.token);
    
    // Configure MusicKit JS in the WebView
    await MusicKit.configure({
      developerToken: 'YOUR_DEVELOPER_TOKEN',
      app: { name: 'Your App', build: '1.0.0' }
    });
    
    // Use MusicKit JS for playback (same as web)
    const instance = MusicKit.getInstance();
    await instance.setQueue({ song: '1234567890' });
    await instance.play();
  }
}
```

## Basic Usage (Cross-Platform)

```typescript
import AppleMusicAuth from '@sounds/capacitor-apple-music-auth';

// Authorization
const res = await AppleMusicAuth.requestAuthorization();
if (res.authorized && res.token) {
  await saveAppleMusicToken(userId, res.token);
}

// Check status
const { status } = await AppleMusicAuth.getAuthorizationStatus();
const { value } = await AppleMusicAuth.hasSubscription();
```

## API Reference

### Authorization Methods

#### `requestAuthorization(options?)`
Request Apple Music authorization from the user.

**Options:**
- `developerToken` (string, optional): Required for Android. Optional for iOS to get user token for web storage.

**Returns:** `{ authorized: boolean, status: string, token?: string }`

#### `getAuthorizationStatus()`
Get current authorization status without prompting.

**Returns:** `{ status: string }` - Values: `'authorized'`, `'denied'`, `'restricted'`, `'notDetermined'`, `'unsupported'`

#### `hasSubscription()`
Check if user has an active Apple Music subscription.

**Returns:** `{ value: boolean }`

### Playback Methods (iOS Only)

#### `playSong(options)`
Play a song by Apple Music catalog ID.

**Options:**
- `songId` (string, required): Apple Music catalog song ID

**iOS:** Uses native `ApplicationMusicPlayer`  
**Web/Android:** Throws error - use MusicKit JS instead

#### `play()`, `pause()`, `stop()`
Control playback.

**iOS:** Uses native `ApplicationMusicPlayer`  
**Web/Android:** Throws error - use MusicKit JS instead

#### `getCurrentTime()`, `getDuration()`
Get playback position and song duration.

**Returns:** `{ value: number }` - Time in seconds

**iOS:** Uses native `ApplicationMusicPlayer`  
**Web/Android:** Throws error - use MusicKit JS instead

## Platform Setup

### iOS Setup

1. Add **Music** capability in Xcode (Signing & Capabilities → + Capability → Music)
2. Add `NSAppleMusicUsageDescription` to Info.plist:
   ```xml
   <key>NSAppleMusicUsageDescription</key>
   <string>This app needs access to Apple Music to play your music.</string>
   ```
3. **(Optional)** To get the music user token for cross-platform use, pass your developer token:
   ```typescript
   const res = await AppleMusicAuth.requestAuthorization({ 
     developerToken: 'YOUR_DEVELOPER_TOKEN' 
   });
   // res.token can be saved to your backend for web/API use
   ```

### Web Setup

1. Load MusicKit JS in your HTML:
   ```html
   <script src="https://js-cdn.music.apple.com/musickit/v1/musickit.js"></script>
   ```

2. Configure MusicKit before using:
   ```typescript
   await MusicKit.configure({
     developerToken: 'YOUR_DEVELOPER_TOKEN',
     app: {
       name: 'Your App Name',
       build: '1.0.0'
     }
   });
   ```

3. Use MusicKit JS directly for playback (plugin methods will throw "Not implemented" errors)

### Android Setup

1. The plugin uses [MusicKit SDK for Android](https://developer.apple.com/musickit/) via JitPack
2. **Apple Music app must be installed** on the device for authorization
3. Pass developer token when authorizing:
   ```typescript
   const res = await AppleMusicAuth.requestAuthorization({ 
     developerToken: 'YOUR_DEVELOPER_TOKEN' 
   });
   ```
4. Use MusicKit JS in WebView for playback (same as web)

## Example: Unified Player Implementation

Here's how to create a unified player that works across all platforms:

```typescript
import AppleMusicAuth from '@sounds/capacitor-apple-music-auth';
import { Capacitor } from '@capacitor/core';

class AppleMusicPlayer {
  private musicKitInstance: any = null;
  
  async play(songId: string) {
    const platform = Capacitor.getPlatform();
    
    if (platform === 'ios') {
      // iOS: Use native plugin
      await AppleMusicAuth.playSong({ songId });
    } else {
      // Web/Android: Use MusicKit JS
      if (!this.musicKitInstance) {
        this.musicKitInstance = MusicKit.getInstance();
      }
      await this.musicKitInstance.setQueue({ song: songId });
      await this.musicKitInstance.play();
    }
  }
  
  async pause() {
    const platform = Capacitor.getPlatform();
    
    if (platform === 'ios') {
      await AppleMusicAuth.pause();
    } else {
      await this.musicKitInstance?.pause();
    }
  }
  
  async getCurrentTime(): Promise<number> {
    const platform = Capacitor.getPlatform();
    
    if (platform === 'ios') {
      const { value } = await AppleMusicAuth.getCurrentTime();
      return value;
    } else {
      return this.musicKitInstance?.player?.currentPlaybackTime || 0;
    }
  }
}
```

## Troubleshooting

### iOS: "No configured instance" errors
- Make sure you're **not** calling `MusicKit.configure()` on iOS
- Use the native plugin methods directly
- MusicKit JS is not needed on iOS

### Web: "MusicKit not available"
- Ensure MusicKit JS script is loaded in your HTML
- Call `MusicKit.configure()` before using the plugin or MusicKit instance

### Android: Authorization fails
- Verify Apple Music app is installed on the device
- Ensure you're passing a valid developer token
- Check that the developer token matches the one used for iOS/Web

## License

MIT
