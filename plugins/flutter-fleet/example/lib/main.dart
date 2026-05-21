import 'package:flutter/material.dart';
import 'package:mgl_fleet_native_sdk/mgl_fleet_native_sdk.dart';

void main() => runApp(const FleetNativeExampleApp());

class FleetNativeExampleApp extends StatelessWidget {
  const FleetNativeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MGL Fleet Native',
      home: const FleetNativeExampleHome(),
    );
  }
}

class FleetNativeExampleHome extends StatefulWidget {
  const FleetNativeExampleHome({super.key});

  @override
  State<FleetNativeExampleHome> createState() => _FleetNativeExampleHomeState();
}

class _FleetNativeExampleHomeState extends State<FleetNativeExampleHome> {
  String _status = 'Tap Open Fleet to launch native driver UI.';

  Future<void> _openFleet() async {
    setState(() => _status = 'Opening native flow…');
    try {
      final result = await MglFleetNativeSdk.openMglFleetNativeFlow(
        initialize: const FleetSdkInitializeOptions(
          apiBaseUrl: 'https://mock.fleet.local',
          useMock: true,
        ),
        present: const FleetSdkPresentOptions(correlationId: 'flutter-example'),
      );
      setState(
        () => _status = 'Done: ${result.event}\n${result.payload}',
      );
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MGL Fleet Native Example')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fullscreen native SDK (Compose + SwiftUI). '
              'Mock OTP 123456, PIN 234567.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _openFleet,
              child: const Text('Open Fleet (native)'),
            ),
            const SizedBox(height: 24),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
