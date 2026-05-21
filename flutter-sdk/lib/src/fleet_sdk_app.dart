import 'package:flutter/material.dart';

import 'fleet_app_engine.dart';
import 'fleet_config.dart';
import 'fleet_flow_screen.dart';
import 'fleet_react_theme.dart';
import 'fleet_repository.dart';
import 'fleet_scope.dart';
import 'fleet_sdk_holder.dart';

/// Full-window fleet driver flow (pure Flutter).
class FleetSdkApp extends StatefulWidget {
  const FleetSdkApp({super.key, required this.config});

  final FleetConfig config;

  @override
  State<FleetSdkApp> createState() => _FleetSdkAppState();
}

class _FleetSdkAppState extends State<FleetSdkApp> {
  late final FleetAppEngine _engine = FleetAppEngine(config: widget.config);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cid = widget.config.correlationId;
      FleetSdkHolder.emit(
        'FLOW_STARTED',
        cid != null ? {'correlationId': cid} : null,
      );
    });
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = FleetRepository(widget.config);
    return MaterialApp(
      title: 'MGL Fleet',
      theme: FleetReactTheme.materialTheme(),
      home: FleetScope(
        repository: repository,
        child: FleetFlowScreen(
          engine: _engine,
          onFlowComplete: widget.config.onFlowComplete,
        ),
      ),
    );
  }
}
