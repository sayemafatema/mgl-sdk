import 'package:flutter/material.dart';

import 'fleet_config.dart';
import 'fleet_flow_screen.dart';
import 'fleet_react_theme.dart';
import 'fleet_repository.dart';
import 'fleet_scope.dart';
import 'fleet_app_engine.dart';

/// Single integration point: login/signup → driver shell (parity with Angular host).
class FleetSdkApp extends StatefulWidget {
  const FleetSdkApp({super.key, required this.config});

  final FleetConfig config;

  @override
  State<FleetSdkApp> createState() => _FleetSdkAppState();
}

class _FleetSdkAppState extends State<FleetSdkApp> {
  late final FleetRepository _repository = FleetRepository(widget.config);
  late final FleetAppEngine _engine = FleetAppEngine(config: widget.config);

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FleetScope(
      repository: _repository,
      child: MaterialApp(
        title: 'MGL Fleet Connect',
        theme: FleetReactTheme.materialTheme(),
        home: FleetFlowScreen(engine: _engine),
      ),
    );
  }
}
