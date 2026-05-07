import { WebPlugin } from '@capacitor/core';
import type { FleetSdkInitializeOptions, FleetSdkPresentOptions, FleetSdkSuccessPayload, MGLFleetSdkPlugin } from './definitions';
export declare class MGLFleetSdkWeb extends WebPlugin implements MGLFleetSdkPlugin {
    initialize(_options: FleetSdkInitializeOptions): Promise<void>;
    presentFleetFlow(_options?: FleetSdkPresentOptions): Promise<FleetSdkSuccessPayload>;
}
