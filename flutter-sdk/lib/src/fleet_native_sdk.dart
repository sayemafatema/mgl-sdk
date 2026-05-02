import 'package:flutter/material.dart';

import 'fleet_config.dart';
import 'fleet_sdk_app.dart';

/// Native Fleet SDK — **initialization-only** surface for host apps.
///
/// Use [root] as `runApp(FleetNativeSdk.root(config))` or [present] from an existing navigator.
final class FleetNativeSdk {
  FleetNativeSdk._();

  /// Full-window fleet experience (same as [FleetSdkApp]).
  static Widget root(FleetConfig config) => FleetSdkApp(config: config);

  /// Push the full fleet flow from your existing app.
  static Future<T?> present<T extends Object?>(
    BuildContext context,
    FleetConfig config,
  ) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => FleetSdkApp(config: config),
      ),
    );
  }
}
