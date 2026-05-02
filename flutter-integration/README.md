> Prefer the packaged **[`flutter-sdk/`](../flutter-sdk/)** (`FleetSdkApp`) for a **single-entry full flow**. This document is manual HTTP wiring only.

## Flutter reference client (native UI; `http` package)

Generate models with **openapi_generator** against [docs/openapi/fleet-api.yaml](../docs/openapi/fleet-api.yaml), or mirror the JSON by hand as below.

Suggested layout:

```text
lib/
  models/
    driver.dart
  services/
    fleet_api_service.dart
  screens/
    driver_list_screen.dart
    driver_detail_screen.dart
```

### `lib/models/driver.dart`

```dart
enum DriverStatus { active, inactive }

class Driver {
  final String id;
  final String name;
  final String vrn;
  final DriverStatus status;
  final int cardBalancePaise;

  const Driver({
    required this.id,
    required this.name,
    required this.vrn,
    required this.status,
    required this.cardBalancePaise,
  });

  factory Driver.fromJson(Map<String, dynamic> j) {
    return Driver(
      id: j['id'] as String,
      name: j['name'] as String,
      vrn: j['vrn'] as String,
      status: (j['status'] as String) == 'Inactive'
          ? DriverStatus.inactive
          : DriverStatus.active,
      cardBalancePaise: (j['cardBalancePaise'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'vrn': vrn,
        'status': status == DriverStatus.inactive ? 'Inactive' : 'Active',
        'cardBalancePaise': cardBalancePaise,
      };
}
```

### `lib/services/fleet_api_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver.dart';

class FleetApiService {
  FleetApiService({
    required this.baseUrl,
    this.authToken,
  });

  final String baseUrl;
  String? authToken;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<List<Driver>> getDrivers() async {
    final uri = Uri.parse('$baseUrl/fleet/drivers');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('getDrivers failed: ${res.statusCode} ${res.body}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final list = map['drivers'] as List<dynamic>;
    return list.map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Driver> getDriver(String id) async {
    final uri = Uri.parse('$baseUrl/fleet/drivers/${Uri.encodeComponent(id)}');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('getDriver failed: ${res.statusCode}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Driver.fromJson(map['driver'] as Map<String, dynamic>);
  }

  Future<void> updateDriver(String id, Map<String, dynamic> patch) async {
    final uri = Uri.parse('$baseUrl/fleet/drivers/${Uri.encodeComponent(id)}');
    final res = await http.patch(uri, headers: _headers, body: json.encode(patch));
    if (res.statusCode != 200) {
      throw Exception('updateDriver failed: ${res.statusCode}');
    }
  }
}
```

### `lib/screens/driver_list_screen.dart` (sketch)

Use `ListView.builder` bound to `FutureBuilder` or a `ChangeNotifier` / `riverpod` provider that calls `FleetApiService.getDrivers()`.

This folder is documentation-only; copy into your Flutter app.
