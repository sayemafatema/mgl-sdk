import 'dart:async';

import 'package:flutter/services.dart';

/// Initialize options — mirrors Capacitor `FleetSdkInitializeOptions` / native `FleetSdkOptions`.
class FleetSdkInitializeOptions {
  const FleetSdkInitializeOptions({
    required this.apiBaseUrl,
    this.authToken,
    this.useMock = true,
    this.foCompanyId,
  });

  final String apiBaseUrl;
  final String? authToken;
  final bool useMock;

  /// Required for Profile → Change PIN when only [authToken] is supplied (FO select skipped).
  final int? foCompanyId;

  Map<String, dynamic> toJson() => {
        'apiBaseUrl': apiBaseUrl,
        if (authToken != null) 'authToken': authToken,
        'useMock': useMock,
        if (foCompanyId != null) 'foCompanyId': foCompanyId,
      };
}

class FleetSdkPresentOptions {
  const FleetSdkPresentOptions({this.correlationId});

  final String? correlationId;

  Map<String, dynamic> toJson() => {
        if (correlationId != null) 'correlationId': correlationId,
      };
}

class FleetSdkOpenNativeFlowOptions {
  const FleetSdkOpenNativeFlowOptions({
    required this.initialize,
    this.present,
  });

  final FleetSdkInitializeOptions initialize;
  final FleetSdkPresentOptions? present;
}

/// Success payload from native flow completion.
class FleetSdkSuccessPayload {
  const FleetSdkSuccessPayload({required this.event, required this.payload});

  final String event;
  final Map<String, dynamic> payload;

  factory FleetSdkSuccessPayload.fromMap(Map<String, dynamic> map) {
    final rawPayload = map['payload'];
    return FleetSdkSuccessPayload(
      event: map['event'] as String? ?? '',
      payload: rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : const {},
    );
  }
}

/// Documented error codes aligned with native `FleetSdkErrorCodes`.
abstract final class FleetSdkErrorCodes {
  static const invalidInput = '1001';
  static const notInitialized = '1002';
  static const userCancelled = '1003';
  static const internalSdkError = '1004';
  static const permissionDenied = '1005';
  static const networkError = '1007';
  static const notInitializedMessage =
      'NOT_INITIALIZED';
}

/// Unified Flutter facade — same surface as `@mgl/capacitor-fleet-sdk`.
class MglFleetNativeSdk {
  MglFleetNativeSdk._();

  static const MethodChannel _channel = MethodChannel('mgl_fleet_native_sdk');

  static Future<void> initialize({
    required String apiBaseUrl,
    String? authToken,
    bool useMock = true,
    int? foCompanyId,
  }) =>
      initializeOptions(
        FleetSdkInitializeOptions(
          apiBaseUrl: apiBaseUrl,
          authToken: authToken,
          useMock: useMock,
          foCompanyId: foCompanyId,
        ),
      );

  static Future<void> initializeOptions(FleetSdkInitializeOptions options) async {
    final normalized = _normalizeInitialize(options);
    await _channel.invokeMethod<void>('initialize', normalized.toJson());
  }

  static Future<bool> isInitialized() async {
    final v = await _channel.invokeMethod<bool>('isInitialized');
    return v ?? false;
  }

  static Future<FleetSdkSuccessPayload> presentFleetFlow({
    String? correlationId,
  }) =>
      presentFleetFlowOptions(
        FleetSdkPresentOptions(correlationId: correlationId),
      );

  static Future<FleetSdkSuccessPayload> presentFleetFlowOptions(
    FleetSdkPresentOptions options,
  ) async {
    if (!await isInitialized()) {
      throw PlatformException(
        code: FleetSdkErrorCodes.notInitializedMessage,
        message:
            'Fleet SDK is not initialized. Call initialize() or openMglFleetNativeFlow() first.',
      );
    }
    return _invokePresent(options);
  }

  /// Single bridge call: initialize then present (recommended from UI buttons).
  static Future<FleetSdkSuccessPayload> openFleetNativeFlow(
    FleetSdkOpenNativeFlowOptions options,
  ) async {
    final init = _normalizeInitialize(options.initialize);
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'openFleetNativeFlow',
      {
        'initialize': init.toJson(),
        if (options.present != null) 'present': options.present!.toJson(),
      },
    );
    return FleetSdkSuccessPayload.fromMap(
      Map<String, dynamic>.from(raw ?? const {}),
    );
  }

  /// Alias matching Capacitor `openMglFleetNativeFlow` naming.
  static Future<FleetSdkSuccessPayload> openMglFleetNativeFlow({
    required FleetSdkInitializeOptions initialize,
    FleetSdkPresentOptions? present,
  }) =>
      openFleetNativeFlow(
        FleetSdkOpenNativeFlowOptions(initialize: initialize, present: present),
      );

  static FleetSdkInitializeOptions _normalizeInitialize(
    FleetSdkInitializeOptions opts,
  ) {
    var apiBaseUrl = opts.apiBaseUrl.trim();
    if (apiBaseUrl.isEmpty) {
      if (opts.useMock) {
        apiBaseUrl = 'https://mock.fleet.local';
      } else {
        throw ArgumentError(
          'apiBaseUrl is required when useMock is false.',
        );
      }
    }
    return FleetSdkInitializeOptions(
      apiBaseUrl: apiBaseUrl,
      authToken: opts.authToken,
      useMock: opts.useMock,
      foCompanyId: opts.foCompanyId,
    );
  }

  static Future<FleetSdkSuccessPayload> _invokePresent(
    FleetSdkPresentOptions options,
  ) async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'presentFleetFlow',
        options.toJson(),
      );
      return FleetSdkSuccessPayload.fromMap(
        Map<String, dynamic>.from(raw ?? const {}),
      );
    } on PlatformException catch (e) {
      if (e.code == FleetSdkErrorCodes.notInitializedMessage) {
        throw PlatformException(
          code: FleetSdkErrorCodes.notInitializedMessage,
          message:
              'Fleet SDK is not initialized. Use openMglFleetNativeFlow() or await initialize() before presentFleetFlow().',
          details: e.details,
        );
      }
      rethrow;
    }
  }
}
