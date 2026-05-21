import 'fleet_sdk_payload.dart';

/// Mirrors TS `FleetSDKConfig` and native `FleetSdkOptions`.
class FleetConfig {
  const FleetConfig({
    this.apiBaseUrl = 'https://api.example.com',
    this.authToken,
    this.useMock = true,
    this.foCompanyId,
    this.correlationId,
    this.onFlowComplete,
  });

  final String apiBaseUrl;
  final String? authToken;
  final String? correlationId;

  /// When true, in-memory demo (OTP/PIN `123456`).
  final bool useMock;

  /// When [authToken] is set without FO select, required for Profile → Change PIN.
  final int? foCompanyId;

  /// Called on logout or when user backs out of the flow (Android `onFinished` parity).
  final void Function(FleetSdkSuccessPayload payload)? onFlowComplete;

  FleetConfig copyWith({
    String? apiBaseUrl,
    String? authToken,
    bool? useMock,
    int? foCompanyId,
    String? correlationId,
    void Function(FleetSdkSuccessPayload payload)? onFlowComplete,
  }) {
    return FleetConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      authToken: authToken ?? this.authToken,
      useMock: useMock ?? this.useMock,
      foCompanyId: foCompanyId ?? this.foCompanyId,
      correlationId: correlationId ?? this.correlationId,
      onFlowComplete: onFlowComplete ?? this.onFlowComplete,
    );
  }
}
