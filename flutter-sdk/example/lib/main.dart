import 'package:flutter/material.dart';
import 'package:mgl_fleet_sdk/mgl_fleet_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const config = FleetConfig(
    apiBaseUrl: 'http://localhost',
    useMock: true,
  );
  FleetNativeSdk.initialize(config);
  runApp(FleetNativeSdk.root(config));
}
