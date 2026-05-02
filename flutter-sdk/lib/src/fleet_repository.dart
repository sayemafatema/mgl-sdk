import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fleet_config.dart';
import 'models/driver.dart';

/// Data access aligned with OpenAPI / TS `DriversApi`.
class FleetRepository {
  FleetRepository(this.config);

  final FleetConfig config;

  static final List<Driver> _mockDrivers = [
    Driver(
      id: 'fo-drv-1',
      name: 'Ramesh Kumar',
      vrn: 'MH 02 AB 1234',
      status: DriverStatus.active,
      cardBalancePaise: 1250000,
    ),
    Driver(
      id: 'fo-drv-2',
      name: 'Priya Patel',
      vrn: 'MH 02 CD 5678',
      status: DriverStatus.active,
      cardBalancePaise: 820000,
    ),
    Driver(
      id: 'fo-drv-3',
      name: 'Suresh Singh',
      vrn: 'MH 02 EF 9012',
      status: DriverStatus.inactive,
      cardBalancePaise: 510000,
    ),
  ];

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (config.authToken != null && config.authToken!.isNotEmpty)
          'Authorization': 'Bearer ${config.authToken}',
      };

  String get _base => config.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');

  Future<List<Driver>> getDrivers() async {
    if (config.useMock) {
      return List<Driver>.from(_mockDrivers);
    }
    final uri = Uri.parse('$_base/fleet/drivers');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('getDrivers ${res.statusCode}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    final list = map['drivers'] as List<dynamic>;
    return list
        .map((e) => Driver.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Driver> getDriver(String id) async {
    if (config.useMock) {
      for (final d in _mockDrivers) {
        if (d.id == id) return d;
      }
      throw Exception('Driver not found');
    }
    final uri =
        Uri.parse('$_base/fleet/drivers/${Uri.encodeComponent(id)}');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw Exception('getDriver ${res.statusCode}');
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Driver.fromJson(map['driver'] as Map<String, dynamic>);
  }

  Future<Driver> updateDriver(Driver patched) async {
    if (config.useMock) {
      final i = _mockDrivers.indexWhere((e) => e.id == patched.id);
      if (i < 0) throw Exception('Driver not found');
      _mockDrivers[i] = patched;
      return patched;
    }
    final uri =
        Uri.parse('$_base/fleet/drivers/${Uri.encodeComponent(patched.id)}');
    final body = <String, dynamic>{
      if (patched.name.isNotEmpty) 'name': patched.name,
      'status': patched.status == DriverStatus.inactive ? 'Inactive' : 'Active',
      'cardBalancePaise': patched.cardBalancePaise,
    };
    final res =
        await http.patch(uri, headers: _headers, body: json.encode(body));
    if (res.statusCode != 200) {
      throw Exception('updateDriver ${res.statusCode}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return Driver.fromJson(map['driver'] as Map<String, dynamic>);
  }
}
