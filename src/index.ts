import { registerPlugin } from '@capacitor/core';

import type { AppleMusicAuthPlugin } from './definitions';

const AppleMusicAuth = registerPlugin<AppleMusicAuthPlugin>('AppleMusicAuth', {
  web: () => import('./web').then(m => new m.AppleMusicAuthWeb()),
});

export * from './definitions';
export default AppleMusicAuth;
