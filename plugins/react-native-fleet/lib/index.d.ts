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
export declare function fleetSdkInitialize(opts: FleetSdkInitializeOptions): Promise<void>;
export declare function fleetSdkPresentFleetFlow(opts?: FleetSdkPresentOptions): Promise<FleetSdkSuccessPayload>;
