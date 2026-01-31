import { WebPlugin } from '@capacitor/core';

import type { AppleMusicAuthPlugin, RequestAuthorizationResult } from './definitions';

declare global {
  interface Window {
    MusicKit?: {
      getInstance: () => {
        authorize: () => Promise<string>;
        musicUserToken?: string;
        musicUserSubscription?: { canPlayCatalogContent?: boolean };
        setQueue: (opts: { song: string } | { song: string[] }) => Promise<void>;
        play: () => Promise<void>;
      };
    };
  }
}

function getMusicKitInstance(): ReturnType<NonNullable<typeof window.MusicKit>['getInstance']> | null {
  if (typeof window === 'undefined' || !window.MusicKit) return null;
  try {
    return window.MusicKit.getInstance();
  } catch {
    return null;
  }
}

export class AppleMusicAuthWeb extends WebPlugin implements AppleMusicAuthPlugin {
  async requestAuthorization(): Promise<RequestAuthorizationResult> {
    const instance = getMusicKitInstance();
    if (!instance) {
      return { authorized: false, status: 'unsupported' };
    }
    try {
      const userToken = await instance.authorize();
      if (userToken) {
        return { authorized: true, status: 'authorized', token: userToken };
      }
      return { authorized: false, status: 'denied' };
    } catch {
      return { authorized: false, status: 'denied' };
    }
  }

  async getAuthorizationStatus(): Promise<{ status: string }> {
    const instance = getMusicKitInstance();
    if (!instance) {
      return { status: 'unsupported' };
    }
    const token = instance.musicUserToken;
    return { status: token ? 'authorized' : 'notDetermined' };
  }

  async hasSubscription(): Promise<{ value: boolean }> {
    const instance = getMusicKitInstance();
    if (!instance) {
      return { value: false };
    }
    const canPlay = instance.musicUserSubscription?.canPlayCatalogContent ?? false;
    return { value: canPlay };
  }

  async playSong(options: { songId: string }): Promise<void> {
    const instance = getMusicKitInstance();
    if (!instance) {
      throw new Error('MusicKit not available; configure with developer token first.');
    }
    if (!instance.musicUserToken) {
      throw new Error('Apple Music not authorized in this session; play will fall back to file.');
    }
    await instance.setQueue({ song: options.songId });
    await instance.play();
  }

  async getCurrentTime(): Promise<{ value: number }> {
    throw new Error('Not implemented on web - use MusicKit JS directly');
  }

  async getDuration(): Promise<{ value: number }> {
    throw new Error('Not implemented on web - use MusicKit JS directly');
  }

  async pause(): Promise<void> {
    throw new Error('Not implemented on web - use MusicKit JS directly');
  }

  async play(): Promise<void> {
    throw new Error('Not implemented on web - use MusicKit JS directly');
  }

  async stop(): Promise<void> {
    throw new Error('Not implemented on web - use MusicKit JS directly');
  }

  async seek(options: { time: number }): Promise<void> {
    throw new Error('Not implemented on web - use MusicKit JS directly');
  }
}
