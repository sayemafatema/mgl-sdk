import 'package:mgl_fleet_native_sdk/mgl_fleet_native_sdk.dart';

import 'fleet_config.dart';

/// Maps [FleetConfig] to native `MGLFleetSDK` (Kotlin + SwiftUI parity).
abstract final class FleetNativeBridge {
  static Future<FleetSdkSuccessPayload> openFlow(
    FleetConfig config, {
    String? correlationId,
  }) {
    return MglFleetNativeSdk.openMglFleetNativeFlow(
      initialize: FleetSdkInitializeOptions(
        apiBaseUrl: config.apiBaseUrl,
        authToken: config.authToken,
        useMock: config.useMock,
        foCompanyId: config.foCompanyId,
      ),
      present: correlationId != null
          ? FleetSdkPresentOptions(correlationId: correlationId)
          : null,
    );
  }
}
