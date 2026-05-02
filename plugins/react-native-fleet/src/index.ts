import { NativeModules, Platform } from 'react-native';

export interface FleetSdkInitializeOptions {
  apiBaseUrl: string;
  authToken?: string;
  useMock?: boolean;
}

export interface FleetSdkPresentOptions {
  correlationId?: string;
}

export interface FleetSdkSuccessPayload {
  event: string;
  payload: Record<string, unknown>;
}

type NativeFleetType = {
  initialize(opts: FleetSdkInitializeOptions): Promise<void>;
  presentFleetFlow(opts?: FleetSdkPresentOptions): Promise<FleetSdkSuccessPayload>;
};

const NativeFleet: NativeFleetType =
  NativeModules.MglFleetSdk ?? ({} as NativeFleetType);

export async function fleetSdkInitialize(opts: FleetSdkInitializeOptions): Promise<void> {
  if (!NativeFleet.initialize) {
    throw new Error(`MglFleetSdk native module missing on ${Platform.OS}`);
  }
  await NativeFleet.initialize(opts);
}

export async function fleetSdkPresentFleetFlow(
  opts?: FleetSdkPresentOptions,
): Promise<FleetSdkSuccessPayload> {
  if (!NativeFleet.presentFleetFlow) {
    throw new Error(`MglFleetSdk native module missing on ${Platform.OS}`);
  }
  return NativeFleet.presentFleetFlow(opts ?? {});
}
