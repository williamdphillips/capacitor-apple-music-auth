import { WebPlugin } from '@capacitor/core';

import type { AppleMusicAuthPlugin } from './definitions';

export class AppleMusicAuthWeb extends WebPlugin implements AppleMusicAuthPlugin {
  async requestAuthorization(): Promise<{ authorized: boolean; status: string }> {
    return { authorized: false, status: 'unsupported' };
  }

  async getAuthorizationStatus(): Promise<{ status: string }> {
    return { status: 'unsupported' };
  }

  async hasSubscription(): Promise<{ value: boolean }> {
    return { value: false };
  }
}
