export interface FleetSDKConfig {
  apiBaseUrl: string;
  authToken?: string;
  /** When true or when requests fail, fall back to bundled mock fleet data */
  useMock?: boolean;
}
