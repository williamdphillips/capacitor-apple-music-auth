# @sounds/capacitor-apple-music-auth

Capacitor plugin for native Apple Music authorization on iOS. Use this instead of MusicKit JS `authorize()` in a WebView so users stay in the app (no popup/redirect that fails to return on iOS).

## Platform support

| Platform | Support |
|----------|---------|
| **iOS**  | Full (native MusicKit). iOS 15+ required. Pass `developerToken` to get `token` in response for web/cross-platform storage. |
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

// iOS: pass developerToken to get res.token for web storage. Web: configure MusicKit first. Android: pass developerToken.
const options = developerToken ? { developerToken } : undefined;
const res = await AppleMusicAuth.requestAuthorization(options);
if (res.authorized && res.token) {
  // Store res.token for API calls and for web/cross-platform use (iOS, Android, web)
  await saveAppleMusicToken(userId, res.token);
}

const { status } = await AppleMusicAuth.getAuthorizationStatus();
const { value } = await AppleMusicAuth.hasSubscription();
```

## iOS setup

- Add **Music** capability in Xcode (Signing & Capabilities) if needed.
- `NSAppleMusicUsageDescription` is required in Info.plist for authorization (add via Xcode or Info.plist).
- To store the music user token for web usage (so the same user is connected on web without re-auth), pass your **developer token** when calling `requestAuthorization({ developerToken })`. The plugin uses `SKCloudServiceController.requestUserToken(forDeveloperToken:)` and returns the token in the response; your app can then save it to your backend.

## Android setup

- The plugin uses the [MusicKit SDK for Android](https://developer.apple.com/musickit/) (authentication library) via JitPack (`com.github.misiio:musickitauth`).
- **Apple Music app** must be installed on the device for the auth flow; the SDK deep-links to it.
- Your app must pass the same **developer token** (from your backend) as used for iOS/Web when calling `requestAuthorization({ developerToken })`.

## License

MIT
