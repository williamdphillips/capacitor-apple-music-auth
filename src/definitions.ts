export interface AppleMusicAuthPlugin {
  /**
   * Request Apple Music authorization using native iOS MusicKit.
   * Use this on iOS instead of MusicKit JS authorize() so the user stays in-app
   * and is not stuck in a popup that doesn't redirect back.
   */
  requestAuthorization(): Promise<{ authorized: boolean; status: string }>;

  /**
   * Get current MusicKit authorization status (iOS only).
   */
  getAuthorizationStatus(): Promise<{ status: string }>;

  /**
   * Check if user has an active Apple Music subscription (iOS only).
   */
  hasSubscription(): Promise<{ value: boolean }>;
}
