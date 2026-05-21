/// Success payload when a fleet flow completes (aligned with native/Capacitor).
class FleetSdkSuccessPayload {
  const FleetSdkSuccessPayload({required this.event, required this.payload});

  final String event;
  final Map<String, dynamic> payload;
}

abstract final class FleetSdkErrorCodes {
  static const userCancelled = '1003';
}
