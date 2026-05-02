import 'package:flutter/material.dart';
import 'package:mgl_fleet_sdk/mgl_fleet_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FleetSdkApp(
      config: FleetConfig(
        apiBaseUrl: 'http://localhost',
        useMock: true,
      ),
    ),
  );
}
