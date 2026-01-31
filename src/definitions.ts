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

  /**
   * Play an Apple Music song by catalog ID.
   * iOS: native MusicKit. Web: MusicKit JS (app must configure first). Android: not supported in plugin; app uses MusicKit JS.
   */
  playSong(options: { songId: string }): Promise<void>;

  /**
   * Get current playback time in seconds.
   * iOS: native ApplicationMusicPlayer. Web: not implemented (use MusicKit JS). Android: not supported.
   */
  getCurrentTime(): Promise<{ value: number }>;

  /**
   * Get duration of current song in seconds.
   * iOS: native ApplicationMusicPlayer. Web: not implemented (use MusicKit JS). Android: not supported.
   */
  getDuration(): Promise<{ value: number }>;

  /**
   * Pause playback.
   * iOS: native ApplicationMusicPlayer. Web: not implemented (use MusicKit JS). Android: not supported.
   */
  pause(): Promise<void>;

  /**
   * Resume/start playback.
   * iOS: native ApplicationMusicPlayer. Web: not implemented (use MusicKit JS). Android: not supported.
   */
  play(): Promise<void>;

  /**
   * Stop playback.
   * iOS: native ApplicationMusicPlayer. Web: not implemented (use MusicKit JS). Android: not supported.
   */
  stop(): Promise<void>;

  /**
   * Seek to a specific time in the current song.
   * iOS: native ApplicationMusicPlayer. Web: not implemented (use MusicKit JS). Android: not supported.
   */
  seek(options: { time: number }): Promise<void>;
}
