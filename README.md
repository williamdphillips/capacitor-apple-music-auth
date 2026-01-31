# @sounds/capacitor-apple-music-auth

Capacitor plugin for native Apple Music authorization on iOS. Use this instead of MusicKit JS `authorize()` in a WebView so users stay in the app (no popup/redirect that fails to return on iOS).

## Platform support

| Platform | Support |
|----------|---------|
| **iOS**  | Full (native MusicKit). iOS 15+ required. |
| **Android** | Full (native [MusicKit SDK for Android](https://developer.apple.com/musickit/)). Pass `developerToken` in options. Requires Apple Music app on device. |
| **Web**  | Full (MusicKit JS). App must load and configure MusicKit with developer token first. |

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

## Usage

```typescript
import AppleMusicAuth from '@sounds/capacitor-apple-music-auth';

// iOS: no options. Web: configure MusicKit first. Android: pass developer token.
const options = (platform === 'android' && developerToken)
  ? { developerToken }
  : undefined;
const res = await AppleMusicAuth.requestAuthorization(options);
if (res.authorized) {
  // On Android (and optionally web), use res.token for API calls and storage
  const userToken = res.token ?? musicKitInstance?.musicUserToken;
}

const { status } = await AppleMusicAuth.getAuthorizationStatus();
const { value } = await AppleMusicAuth.hasSubscription();
```

## iOS setup

- Add **Music** capability in Xcode (Signing & Capabilities) if needed.
- `NSAppleMusicUsageDescription` is required in Info.plist for authorization (add via Xcode or Info.plist).

## Android setup

- The plugin uses the [MusicKit SDK for Android](https://developer.apple.com/musickit/) (authentication library) via JitPack (`com.github.misiio:musickitauth`).
- **Apple Music app** must be installed on the device for the auth flow; the SDK deep-links to it.
- Your app must pass the same **developer token** (from your backend) as used for iOS/Web when calling `requestAuthorization({ developerToken })`.

## License

MIT
