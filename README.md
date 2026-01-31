# @sounds/capacitor-apple-music-auth

Capacitor plugin for native Apple Music authorization on iOS. Use this instead of MusicKit JS `authorize()` in a WebView so users stay in the app (no popup/redirect that fails to return on iOS).

## Requirements

- **iOS**: 14.0+ (MusicKit API requires 15.0+; on iOS 14 the plugin rejects with a message)
- **Capacitor**: ^7.0.0

## Installation

```bash
npm install @sounds/capacitor-apple-music-auth
npx cap sync ios
```

## Usage

```typescript
import AppleMusicAuth from '@sounds/capacitor-apple-music-auth';

// Request authorization (shows system Apple Music permission)
const { authorized, status } = await AppleMusicAuth.requestAuthorization();

// Check current status
const { status } = await AppleMusicAuth.getAuthorizationStatus();

// Check if user has an active Apple Music subscription
const { value } = await AppleMusicAuth.hasSubscription();
```

On web and Android the plugin returns `authorized: false` / `status: 'unsupported'` / `value: false`.

## iOS setup

- Add **Music** capability in Xcode (Signing & Capabilities) if needed.
- `NSAppleMusicUsageDescription` is required in Info.plist for authorization (add via Xcode or Info.plist).

## License

MIT
