import 'package:flutter/material.dart';

import 'fleet_config.dart';
import 'fleet_sdk_app.dart';
import 'fleet_sdk_holder.dart';
import 'fleet_sdk_payload.dart';

export 'fleet_sdk_holder.dart' show FleetSdkEventListener, FleetSdkHolder;
export 'fleet_sdk_payload.dart';

/// Fleet SDK entry — mounts pure Flutter driver flow via [FleetSdkApp].
final class FleetNativeSdk {
  FleetNativeSdk._();

  /// Mirrors Android [FleetSdk.initialize].
  static void initialize(FleetConfig config) {
    FleetSdkHolder.attach(config);
  }

  /// Mirrors Android [FleetSdk.isInitialized].
  static bool isInitialized() => FleetSdkHolder.isAttached();

  /// Mirrors Android [FleetSdk.addListener].
  static void addListener(String tag, FleetSdkEventListener listener) {
    FleetSdkHolder.addListener(tag, listener);
  }

  /// Mirrors Android [FleetSdk.removeListener].
  static void removeListener(String tag) {
    FleetSdkHolder.removeListener(tag);
  }

  static Widget root(FleetConfig config) {
    if (!FleetSdkHolder.isAttached()) {
      FleetSdkHolder.attach(config);
    }
    return FleetSdkApp(config: FleetSdkHolder.requireOptions());
  }

  static Future<T?> present<T extends Object?>(
    BuildContext context,
    FleetConfig config, {
    String? correlationId,
  }) {
    if (!FleetSdkHolder.isAttached()) {
      FleetSdkHolder.attach(config);
    }
    final merged = correlationId != null
        ? config.copyWith(correlationId: correlationId)
        : config;
    FleetSdkHolder.attach(merged);
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => FleetSdkApp(config: merged),
      ),
    );
  }
}
