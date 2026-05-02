import 'package:flutter/material.dart';

import 'fleet_repository.dart';

class FleetScope extends InheritedWidget {
  const FleetScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final FleetRepository repository;

  static FleetRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FleetScope>();
    assert(scope != null, 'FleetScope not found — wrap with FleetSdkApp');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(FleetScope oldWidget) =>
      repository != oldWidget.repository;
}
