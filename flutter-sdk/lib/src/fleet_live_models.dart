/// JSON DTOs for driver-app live APIs (aligned with Android [DriverFleetTypes] / [DriverAppApiClient]).
class DriverHomeJson {
  const DriverHomeJson({
    required this.hasActiveVehicle,
    this.foName,
    this.vehicleRegNo,
    this.vehicleId,
    this.assignmentType,
    this.isCurrentlyEligible,
    this.currentlyEligible,
    this.totalBalanceINR,
    this.shiftDaysOfWeek,
    this.shiftStartTime,
    this.shiftEndTime,
    this.tripDate,
    this.tripStartTime,
    this.tripEndTime,
    this.tripStartLocation,
  });

  final bool hasActiveVehicle;
  final String? foName;
  final String? vehicleRegNo;
  final String? vehicleId;
  final String? assignmentType;
  final bool? isCurrentlyEligible;
  final bool? currentlyEligible;
  final double? totalBalanceINR;
  final String? shiftDaysOfWeek;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final String? tripDate;
  final String? tripStartTime;
  final String? tripEndTime;
  final String? tripStartLocation;

  static DriverHomeJson? fromJson(Map<String, dynamic>? o) {
    if (o == null) return null;
    double? d(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    return DriverHomeJson(
      hasActiveVehicle: o['hasActiveVehicle'] == true,
      foName: o['foName']?.toString(),
      vehicleRegNo: o['vehicleRegNo']?.toString(),
      vehicleId: o['vehicleId']?.toString(),
      assignmentType: o['assignmentType']?.toString(),
      isCurrentlyEligible: o['isCurrentlyEligible'] as bool?,
      currentlyEligible: o['currentlyEligible'] as bool?,
      totalBalanceINR: d(o['totalBalanceINR']),
      shiftDaysOfWeek: o['shiftDaysOfWeek']?.toString(),
      shiftStartTime: o['shiftStartTime']?.toString(),
      shiftEndTime: o['shiftEndTime']?.toString(),
      tripDate: o['tripDate']?.toString(),
      tripStartTime: o['tripStartTime']?.toString(),
      tripEndTime: o['tripEndTime']?.toString(),
      tripStartLocation: o['tripStartLocation']?.toString(),
    );
  }
}

class DriverAssignmentJson {
  const DriverAssignmentJson({
    required this.vehicleDriverId,
    required this.vehicleId,
    required this.vehicleRegNo,
    required this.assignmentType,
    required this.status,
    required this.requiresPairing,
    this.shiftDaysOfWeek,
    this.shiftStartTime,
    this.shiftEndTime,
    this.tripDate,
    this.tripStartTime,
    this.tripEndTime,
    this.tripStartLocation,
    this.assignedAt,
  });

  final int vehicleDriverId;
  final String vehicleId;
  final String vehicleRegNo;
  final String assignmentType;
  final String status;
  final bool requiresPairing;
  final String? shiftDaysOfWeek;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final String? tripDate;
  final String? tripStartTime;
  final String? tripEndTime;
  final String? tripStartLocation;
  final String? assignedAt;

  static DriverAssignmentJson fromJson(Map<String, dynamic> m) {
    return DriverAssignmentJson(
      vehicleDriverId: (m['vehicleDriverId'] as num?)?.toInt() ?? 0,
      vehicleId: m['vehicleId']?.toString() ?? '',
      vehicleRegNo: m['vehicleRegNo']?.toString() ?? '',
      assignmentType: m['assignmentType']?.toString() ?? '',
      status: m['status']?.toString() ?? '',
      requiresPairing: m['requiresPairing'] == true,
      shiftDaysOfWeek: m['shiftDaysOfWeek']?.toString(),
      shiftStartTime: m['shiftStartTime']?.toString(),
      shiftEndTime: m['shiftEndTime']?.toString(),
      tripDate: m['tripDate']?.toString(),
      tripStartTime: m['tripStartTime']?.toString(),
      tripEndTime: m['tripEndTime']?.toString(),
      tripStartLocation: m['tripStartLocation']?.toString(),
      assignedAt: m['assignedAt']?.toString(),
    );
  }
}

class DriverProfileJson {
  const DriverProfileJson({
    required this.driverId,
    required this.name,
    this.maskedMobile,
    this.dlNumber,
    this.foStatus,
  });

  final String driverId;
  final String name;
  final String? maskedMobile;
  final String? dlNumber;
  final String? foStatus;

  static DriverProfileJson fromJson(Map<String, dynamic> o) {
    final dl = o['dlNumber'] ??
        o['licenceNumber'] ??
        o['licenseNumber'] ??
        o['dlNo'];
    return DriverProfileJson(
      driverId: o['driverId']?.toString() ?? '',
      name: o['name']?.toString() ?? '',
      maskedMobile: o['maskedMobile']?.toString(),
      dlNumber: dl?.toString(),
      foStatus: o['foStatus']?.toString(),
    );
  }
}

class DriverTxnRowParse {
  const DriverTxnRowParse({
    required this.serverTxnId,
    required this.vehicleRegNo,
    required this.amountINR,
    required this.status,
    required this.driverName,
    required this.createdOn,
  });

  final String serverTxnId;
  final String vehicleRegNo;
  final double amountINR;
  final String status;
  final String driverName;
  final String createdOn;
}

class TxnsPageParsed {
  const TxnsPageParsed({required this.rows});

  final List<DriverTxnRowParse> rows;
}

class ParsedFleetpayQr {
  const ParsedFleetpayQr({
    required this.txnId,
    required this.mid,
    required this.terminalId,
    required this.amountPaise,
    required this.expiryEpoch,
    required this.sign,
    this.merchantName,
    this.currency,
  });

  final String txnId;
  final String mid;
  final String terminalId;
  final int amountPaise;
  final int expiryEpoch;
  final String sign;
  final String? merchantName;
  final String? currency;
}

class QrPayResultLive {
  const QrPayResultLive({
    this.serverTxnId,
    this.vehicleRegNo,
    this.amountINR,
    this.newBalanceINR,
    this.authCode,
    this.txnTime,
    required this.status,
    this.quantityKg,
  });

  final String? serverTxnId;
  final String? vehicleRegNo;
  final double? amountINR;
  final double? newBalanceINR;
  final String? authCode;
  final String? txnTime;
  final String status;
  final double? quantityKg;

  bool get payFailed => status == 'FAILED';
}
