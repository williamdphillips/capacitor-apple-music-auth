import { WebPlugin } from '@capacitor/core';

import type { AppleMusicAuthPlugin, RequestAuthorizationResult } from './definitions';

declare global {
  interface Window {
    MusicKit?: {
      getInstance: () => {
        authorize: () => Promise<string>;
        musicUserToken?: string;
        musicUserSubscription?: { canPlayCatalogContent?: boolean };
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
}
