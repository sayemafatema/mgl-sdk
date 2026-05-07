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
export interface MGLFleetSdkPlugin {
    initialize(options: FleetSdkInitializeOptions): Promise<void>;
    presentFleetFlow(options?: FleetSdkPresentOptions): Promise<FleetSdkSuccessPayload>;
}
