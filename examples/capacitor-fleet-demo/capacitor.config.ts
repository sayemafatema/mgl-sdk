import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.mgl.fleet.capdemo',
  appName: 'Fleet Cap Demo',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
  },
};

export default config;
