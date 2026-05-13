import 'fleet_live_models.dart';

/// Same demo URI as iOS [DriverFleetQr.simulatedUri].
const String kSimulatedFleetpayUri =
    'fleetpay://pay?txn=SIMTXN01&mid=DEMOMID&tid=DEMOTID&am=67200&exp=9999999999&sign=demosign&mn=Demo%20CNG%20Station';

String normVrnPublic(String v) =>
    v.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

/// Parses `fleetpay://pay?...` URIs; mirrors Android [parseFleetpayPayUri].
ParsedFleetpayQr? parseFleetpayPayUri(String raw) {
  final s = raw.trim();
  if (!RegExp(r'^fleetpay://', caseSensitive: false).hasMatch(s)) {
    return null;
  }
  Uri uri;
  try {
    uri = Uri.parse(s);
  } catch (_) {
    return null;
  }
  final pathNorm = uri.path.toLowerCase().replaceAll(RegExp(r'^/+|/+$'), '');
  final payPathOk = pathNorm.isEmpty || pathNorm.endsWith('/pay');
  final host = (uri.host).toLowerCase();
  final payHostOk = host == 'pay';
  if (!payHostOk && !payPathOk) return null;

  String? qp(String name) => uri.queryParameters[name];

  final txnId = qp('txn');
  final mid = qp('mid');
  final terminalId = qp('tid');
  final am = qp('am');
  final exp = qp('exp');
  final sign = qp('sign');
  if (txnId == null ||
      mid == null ||
      terminalId == null ||
      am == null ||
      exp == null ||
      sign == null) {
    return null;
  }
  final amountPaise = double.tryParse(am)?.toInt();
  final expiryEpoch = double.tryParse(exp)?.toInt();
  if (amountPaise == null || expiryEpoch == null) return null;

  return ParsedFleetpayQr(
    txnId: txnId,
    mid: mid,
    terminalId: terminalId,
    amountPaise: amountPaise,
    expiryEpoch: expiryEpoch,
    sign: sign,
    merchantName: qp('mn'),
    currency: qp('cu'),
  );
}

String paiseToInrDisplay(int amountPaise) {
  final inr = amountPaise / 100.0;
  return inr.toStringAsFixed(2);
}

bool validIndianMobile10(String digitsOnly) {
  final d = digitsOnly.replaceAll(RegExp(r'\D'), '');
  if (d.length < 10) return false;
  final last10 = d.length == 10 ? d : d.substring(d.length - 10);
  final first = int.tryParse(last10[0]);
  return first != null && first >= 6 && first <= 9;
}
