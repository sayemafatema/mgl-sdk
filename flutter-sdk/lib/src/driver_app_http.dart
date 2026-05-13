import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fleet_live_models.dart';

/// Driver-app HTTP aligned with [components/mgl/driver-api.ts] / Kotlin [DriverAppApiClient].
class DriverAppHttp {
  DriverAppHttp({required this.apiBaseUrl});

  final String apiBaseUrl;
  static const _userAgent = 'mgl-fleet-flutter-sdk/1.0';

  String get _base => apiBaseUrl.replaceAll(RegExp(r'/+$'), '');

  /// `NEW_USER` | `RETURNING_USER`
  Future<String> driverCheckMobile(String mobile) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/auth/check-mobile');
    final res = await http.post(
      uri,
      headers: _jsonHeaders(),
      body: json.encode({'mobile': mobile}),
    );
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final data = unwrapDriverBody(peeled) as Map<String, dynamic>?;
    final st = data?['status'] as String?;
    if (st != 'NEW_USER' && st != 'RETURNING_USER') {
      throw Exception('Unexpected check-mobile response');
    }
    return st!;
  }

  Future<void> driverSendLoginOtp(String mobile) async {
    final q = Uri.encodeComponent(mobile.trim());
    final uri = Uri.parse('$_base/api/v0/otp/login?username=$q');
    final res = await http.get(uri, headers: _jsonHeaders(nullAuth: true));
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
  }

  Future<String> driverOauthOtpGrant(String mobile, String otp) async {
    final uri = Uri.parse('$_base/oauth/token');
    final body = {
      'grant_type': 'otp',
      'username': mobile.trim(),
      'otp': otp.trim(),
      'client_id': 'mgl-driver-app-client',
      'client_secret': 'driver-app-secret',
    };
    final enc = body.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': _userAgent,
      },
      body: enc,
    );
    final raw = _parseBody(res);
    if (!res.ok) {
      throw Exception(_oauthErr(raw) ?? 'HTTP ${res.statusCode}');
    }
    final map = raw is Map<String, dynamic> ? raw : json.decode(json.encode(raw)) as Map<String, dynamic>;
    final tok = (map['access_token'] ?? map['accessToken'])?.toString().trim();
    if (tok == null || tok.isEmpty) throw Exception('OAuth: no token');
    return tok;
  }

  Future<List<FoOrganization>> driverFoList(String bearerPartial) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/auth/fo-list');
    final res = await http.get(uri, headers: _jsonHeaders(bearer: bearerPartial));
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final inner = unwrapDriverBody(peeled);
    return _parseFoList(inner);
  }

  Future<String> driverFoSelect({
    required String bearerPartial,
    required int foCompanyId,
    required String pin,
  }) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/auth/fo-select');
    final res = await http.post(
      uri,
      headers: _jsonHeaders(bearer: bearerPartial),
      body: json.encode({'foCompanyId': foCompanyId, 'pin': pin}),
    );
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final tok = oauthAccessFromAny(unwrapDriverBody(peeled));
    if (tok == null || tok.isEmpty) throw Exception('Missing fleet token');
    return tok;
  }

  Future<String> driverInviteMobileSendOtp(String mobile) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/auth/mobile/send-otp');
    final res = await http.post(
      uri,
      headers: _jsonHeaders(),
      body: json.encode({'mobile': mobile}),
    );
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    return _unwrapInviteSendOtpRef(peeled);
  }

  Future<String> driverInviteMobileVerifyOtp({
    required String mobile,
    required String otpRefNumber,
    required String otp,
  }) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/auth/mobile/verify-otp');
    final res = await http.post(
      uri,
      headers: _jsonHeaders(),
      body: json.encode({
        'mobile': mobile,
        'otpRefNumber': otpRefNumber,
        'otp': otp,
      }),
    );
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final o = unwrapDriverBody(peeled) as Map<String, dynamic>?;
    final tok = o?['mobileVerificationToken']?.toString().trim() ?? '';
    if (tok.isEmpty) throw Exception('Unexpected verify-otp response');
    return tok;
  }

  Future<InviteValidateResult> driverInviteValidate({
    required String mobile,
    required String inviteCode,
    required String mobileVerificationToken,
  }) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/auth/invite/validate');
    final res = await http.post(
      uri,
      headers: _jsonHeaders(),
      body: json.encode({
        'mobile': mobile,
        'inviteCode': inviteCode,
        'mobileVerificationToken': mobileVerificationToken,
      }),
    );
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final o = unwrapDriverBody(peeled) as Map<String, dynamic>?;
    return InviteValidateResult(
      sessionToken: o!['sessionToken'] as String,
      driverName: o['driverName']?.toString() ?? '',
      foName: o['foName']?.toString() ?? '',
      foCompanyId: (o['foCompanyId'] as num?)?.toInt() ?? 0,
    );
  }

  Future<String> driverInviteSetPin(String sessionToken, String pin) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/auth/invite/set-pin');
    final res = await http.post(
      uri,
      headers: _jsonHeaders(),
      body: json.encode({'sessionToken': sessionToken, 'pin': pin}),
    );
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final tok = oauthAccessFromAny(unwrapDriverBody(peeled));
    if (tok == null || tok.isEmpty) throw Exception('Missing access token');
    return tok;
  }

  Future<DriverHomeJson?> driverGetHome(String token) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/home');
    final res = await http.get(uri, headers: _jsonHeaders(bearer: token));
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final inner = unwrapDriverBody(peeled);
    final map = inner is Map<String, dynamic> ? inner : null;
    return DriverHomeJson.fromJson(map);
  }

  Future<DriverProfileJson> driverGetProfile(String token) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/profile');
    final res = await http.get(uri, headers: _jsonHeaders(bearer: token));
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final o = unwrapDriverBody(peeled) as Map<String, dynamic>?;
    return DriverProfileJson.fromJson(o ?? {});
  }

  Future<List<DriverAssignmentJson>> driverGetAssignments(String token) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/assignments');
    final res = await http.get(uri, headers: _jsonHeaders(bearer: token));
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final inner = unwrapDriverBody(peeled);
    if (inner is! List) return [];
    return inner
        .map((e) => DriverAssignmentJson.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<({String vehicleRegNo, String status})> driverAcceptPairing(
    String token,
    String pairingCode,
  ) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/vehicle/accept-pairing');
    final res = await http.post(
      uri,
      headers: _jsonHeaders(bearer: token),
      body: json.encode({'pairingCode': pairingCode}),
    );
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final o = unwrapDriverBody(peeled) as Map<String, dynamic>?;
    final vrn = o?['vehicleRegNo']?.toString() ?? '';
    final st = o?['status']?.toString() ?? '';
    return (vehicleRegNo: vrn, status: st);
  }

  Future<QrPayResultLive> driverQrPay({
    required String token,
    required String txnId,
    required String vehicleRegNoNorm,
    required String pin,
    required String mid,
    required String terminalId,
    required int amountPaise,
    required int expiryEpoch,
    required String sign,
  }) async {
    final uri = Uri.parse('$_base/api/v0/driver-app/qr/pay');
    final res = await http.post(
      uri,
      headers: _jsonHeaders(bearer: token),
      body: json.encode({
        'txnId': txnId,
        'vehicleRegNo': vehicleRegNoNorm,
        'pin': pin,
        'mid': mid,
        'terminalId': terminalId,
        'amountPaise': amountPaise,
        'expiryEpoch': expiryEpoch,
        'sign': sign,
      }),
    );
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final o = unwrapDriverBody(peeled) as Map<String, dynamic>?;
    if (o == null) throw Exception('Empty qr/pay response');
    final stRaw = o['status']?.toString() ?? '';
    final st = stRaw.isEmpty ? '' : stRaw.toUpperCase();
    double? d(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    return QrPayResultLive(
      serverTxnId: o['serverTxnId']?.toString(),
      vehicleRegNo: o['vehicleRegNo']?.toString(),
      amountINR: d(o['amountINR']),
      newBalanceINR: d(o['newBalanceINR']),
      authCode: o['authCode']?.toString(),
      txnTime: o['txnTime']?.toString(),
      status: st == 'FAILED' ? 'FAILED' : 'SUCCESS',
      quantityKg: d(o['quantityKg']),
    );
  }

  Future<TxnsPageParsed> driverGetTransactions(
    String token,
    String vehicleId,
    int page,
  ) async {
    final vid = Uri.encodeComponent(vehicleId);
    final q = page > 0 ? '?page=$page' : '';
    final uri = Uri.parse(
        '$_base/api/v0/driver-app/vehicles/$vid/transactions$q');
    final res = await http.get(uri, headers: _jsonHeaders(bearer: token));
    final body = _parseBody(res);
    if (!res.ok) throw Exception(_errMsg(body) ?? 'HTTP ${res.statusCode}');
    final peeled = peelFleetEnvelope(body);
    final inner = unwrapDriverBody(peeled);
    return _normalizeDriverTransactionsPayload(inner);
  }

  TxnsPageParsed _normalizeDriverTransactionsPayload(dynamic data) {
    if (data is List) {
      final rows = _txnRowsFromList(data);
      return TxnsPageParsed(rows: rows);
    }
    if (data is Map) {
      final m = Map<String, dynamic>.from(data as Map);
      final content = m['content'];
      final list = content is List ? content : <dynamic>[];
      final rows = _txnRowsFromList(list);
      return TxnsPageParsed(rows: rows);
    }
    return const TxnsPageParsed(rows: []);
  }

  List<DriverTxnRowParse> _txnRowsFromList(List<dynamic> arr) {
    return arr.map((e) {
      final o = Map<String, dynamic>.from(e as Map);
      return DriverTxnRowParse(
        serverTxnId: o['serverTxnId']?.toString() ?? '',
        vehicleRegNo: o['vehicleRegNo']?.toString() ?? '',
        amountINR: (o['amountINR'] as num?)?.toDouble() ?? 0,
        status: o['status']?.toString() ?? '',
        driverName: o['driverName']?.toString() ?? '',
        createdOn: o['createdOn']?.toString() ?? '',
      );
    }).toList();
  }

  Map<String, String> _jsonHeaders({String? bearer, bool nullAuth = false}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
      if (bearer != null && bearer.isNotEmpty) 'Authorization': 'Bearer $bearer',
    };
  }

  dynamic _parseBody(http.Response res) {
    final t = res.body;
    if (t.isEmpty) return null;
    try {
      return json.decode(t);
    } catch (_) {
      return t;
    }
  }
}

class FoOrganization {
  const FoOrganization({
    required this.foCompanyId,
    required this.foName,
    required this.foStatus,
  });

  final int foCompanyId;
  final String foName;
  final String foStatus;
}

class InviteValidateResult {
  const InviteValidateResult({
    required this.sessionToken,
    required this.driverName,
    required this.foName,
    required this.foCompanyId,
  });

  final String sessionToken;
  final String driverName;
  final String foName;
  final int foCompanyId;
}

extension _Ok on http.Response {
  bool get ok => statusCode >= 200 && statusCode < 300;
}

dynamic peelFleetEnvelope(dynamic raw) {
  if (raw == null || raw is! Map) return raw;
  final o = Map<String, dynamic>.from(raw);
  if (!o.containsKey('payload') || !o.containsKey('response_message')) return raw;
  final msg = o['response_message']?.toString() ?? '';
  final code = o['response_code'];
  final errDetail = extractFleetApiErrorMessage(o);
  final isError = o['errorResponse'] != null ||
      msg == 'FAILURE' ||
      (code is num && code >= 400);
  if (isError) {
    throw Exception(
      errDetail ??
          (msg != 'FAILURE' && msg.trim().isNotEmpty ? msg.trim() : null) ??
          (code is num ? 'Error $code' : null) ??
          'Request failed',
    );
  }
  return o['payload'];
}

dynamic unwrapDriverBody(dynamic raw) {
  final step = unwrapIfWrapped(raw);
  if (step != null &&
      step is Map &&
      !((step as Map).containsKey('length')) &&
      (step as Map).length == 1 &&
      (step as Map).containsKey('data')) {
    return (step as Map)['data'];
  }
  return step;
}

dynamic unwrapIfWrapped(dynamic raw) {
  final peeled = peelFleetEnvelope(raw);
  if (peeled is Map && peeled.containsKey('status') && peeled.containsKey('data')) {
    if (peeled['status'] == 'FAILURE') {
      throw Exception(
        (peeled['errorMessage'] ?? peeled['message'])?.toString() ?? 'Request failed',
      );
    }
    return peeled['data'];
  }
  return peeled;
}

String? extractFleetApiErrorMessage(dynamic body) {
  if (body == null || body is! Map) return null;
  final o = Map<String, dynamic>.from(body as Map);
  final er = o['errorResponse'];
  if (er is Map) {
    for (final k in ['errorMessage', 'message', 'error', 'detail']) {
      final v = er[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
  }
  for (final k in ['errorMessage', 'message', 'error', 'detail']) {
    final v = o[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  final p = o['payload'];
  if (p is String && p.trim().isNotEmpty && o['response_message'] == 'FAILURE') {
    return p.trim();
  }
  return null;
}

String? oauthAccessFromAny(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is Map) {
    final t = raw['access_token'] ?? raw['accessToken'];
    if (t is String && t.isNotEmpty) return t;
  }
  return null;
}

List<FoOrganization> _parseFoList(dynamic inner) {
  if (inner is! List) return [];
  return inner.map((e) {
    final m = e as Map<String, dynamic>;
    return FoOrganization(
      foCompanyId: (m['foCompanyId'] as num?)?.toInt() ?? 0,
      foName: m['foName']?.toString() ?? '',
      foStatus: m['foStatus']?.toString() ?? '',
    );
  }).toList();
}

String _unwrapInviteSendOtpRef(dynamic peeled) {
  final inner = unwrapDriverBody(peeled);
  if (inner is Map) {
    for (final k in ['otpRefNumber', 'refNumber', 'reference']) {
      final v = inner[k];
      if (v is String && v.isNotEmpty) return v;
    }
  }
  if (inner is String && inner.isNotEmpty) return inner;
  throw Exception('Unexpected send-otp response');
}

String? _oauthErr(dynamic body) {
  if (body is Map) {
    final m = Map<String, dynamic>.from(body as Map);
    return m['error_description']?.toString() ??
        m['error']?.toString() ??
        extractFleetApiErrorMessage(m);
  }
  return null;
}

String? _errMsg(dynamic body) => extractFleetApiErrorMessage(body is Map ? body : null) ??
    (body is String ? body : null);
