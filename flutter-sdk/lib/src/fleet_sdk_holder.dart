import 'fleet_config.dart';

typedef FleetSdkEventListener = void Function(
  String name,
  Map<String, dynamic>? payload,
);

/// Process-wide SDK state — Android `FleetSdkHolder` / `FleetPresentationBridge`.
abstract final class FleetSdkHolder {
  static FleetConfig? _config;
  static bool _attached = false;
  static final List<(String tag, FleetSdkEventListener listener)> _listeners = [];

  static void attach(FleetConfig config) {
    _config = config;
    _attached = true;
  }

  static bool isAttached() => _attached;

  static FleetConfig requireOptions() {
    final c = _config;
    if (!_attached || c == null) {
      throw StateError(
        'FleetNativeSdk.initialize() must be called before presenting the flow.',
      );
    }
    return c;
  }

  static void addListener(String tag, FleetSdkEventListener listener) {
    _listeners.removeWhere((e) => e.$1 == tag);
    _listeners.add((tag, listener));
  }

  static void removeListener(String tag) {
    _listeners.removeWhere((e) => e.$1 == tag);
  }

  static void emit(String name, [Map<String, dynamic>? payload]) {
    for (final e in List<(String, FleetSdkEventListener)>.from(_listeners)) {
      e.$2(name, payload);
    }
  }
}
