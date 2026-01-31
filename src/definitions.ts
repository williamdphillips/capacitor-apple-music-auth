export interface RequestAuthorizationOptions {
  /** Required on Android: developer token from your backend (same as used for MusicKit JS). */
  developerToken?: string;
}

export interface RequestAuthorizationResult {
  authorized: boolean;
  status: string;
  /** Set on Android (and optionally web) when authorization succeeds; use for API calls and storage. */
  token?: string;
}

export interface AppleMusicAuthPlugin {
  /**
   * Request Apple Music authorization.
   * iOS: native MusicKit (in-app, no popup). Web: MusicKit JS (app must configure first).
   * Android: native MusicKit SDK (pass developerToken in options).
   */
  requestAuthorization(options?: RequestAuthorizationOptions): Promise<RequestAuthorizationResult>;

  /**
   * Get current MusicKit authorization status.
   * iOS: native. Web: from MusicKit JS musicUserToken. Android: unsupported.
   */
  getAuthorizationStatus(): Promise<{ status: string }>;

  /**
   * Check if user has an active Apple Music subscription.
   * iOS: native MusicSubscription. Web: MusicKit JS musicUserSubscription. Android: unsupported.
   */
  hasSubscription(): Promise<{ value: boolean }>;
}
