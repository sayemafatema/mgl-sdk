import 'dart:async';
import 'package:flutter/services.dart';

/// Unified Flutter facade matching `@mgl/capacitor-fleet-sdk` JS surface.
class MglFleetNativeSdk {
  MglFleetNativeSdk._();

  static const MethodChannel _channel = MethodChannel('mgl_fleet_native_sdk');

  static Future<void> initialize({
    required String apiBaseUrl,
    String? authToken,
    bool useMock = true,
  }) async {
    await _channel.invokeMethod<void>('initialize', {
      'apiBaseUrl': apiBaseUrl,
      'authToken': authToken,
      'useMock': useMock,
    });
  }

  static Future<Map<String, dynamic>> presentFleetFlow({
    String? correlationId,
  }) async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'presentFleetFlow',
      {
        if (correlationId != null) 'correlationId': correlationId,
      },
    );
    return Map<String, dynamic>.from(raw ?? const {});
  }
}
