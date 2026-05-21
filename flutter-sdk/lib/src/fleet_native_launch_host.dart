import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fleet_config.dart';
import 'fleet_native_bridge.dart';
import 'fleet_react_theme.dart';

/// Host widget that presents fullscreen native fleet UI (Android Compose / iOS SwiftUI).
class FleetNativeLaunchHost extends StatefulWidget {
  const FleetNativeLaunchHost({
    super.key,
    required this.config,
    this.correlationId,
  });

  final FleetConfig config;
  final String? correlationId;

  @override
  State<FleetNativeLaunchHost> createState() => _FleetNativeLaunchHostState();
}

class _FleetNativeLaunchHostState extends State<FleetNativeLaunchHost> {
  bool _busy = true;
  String? _error;
  FleetSdkSuccessPayload? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openNativeFlow());
  }

  Future<void> _openNativeFlow() async {
    if (kIsWeb) {
      setState(() {
        _busy = false;
        _error =
            'MGL Fleet native SDK runs on Android and iOS only. Use a device or emulator, not web.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });

    try {
      final payload = await FleetNativeBridge.openFlow(
        widget.config,
        correlationId: widget.correlationId,
      );
      if (!mounted) return;
      _finish(payload);
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == '1003' || e.code == 'USER_CANCELLED') {
        _finish(null);
        return;
      }
      setState(() {
        _busy = false;
        _error = e.message ?? e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  void _finish(FleetSdkSuccessPayload? payload) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(payload);
      return;
    }
    setState(() {
      _busy = false;
      _result = payload;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Opening MGL Fleet…'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _openNativeFlow,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final event = _result?.event ?? 'Session ended';
    final payload = _result?.payload ?? const <String, dynamic>{};
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event, style: Theme.of(context).textTheme.titleMedium),
              if (payload.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(payload.toString(), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _openNativeFlow,
                child: const Text('Open Fleet again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standalone [MaterialApp] wrapper for `runApp(FleetNativeSdk.root(...))`.
class FleetNativeShell extends StatelessWidget {
  const FleetNativeShell({super.key, required this.config});

  final FleetConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MGL Fleet Connect',
      theme: FleetReactTheme.materialTheme(),
      home: FleetNativeLaunchHost(config: config),
    );
  }
}
