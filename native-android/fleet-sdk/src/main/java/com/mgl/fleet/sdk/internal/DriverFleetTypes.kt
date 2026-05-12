package com.mgl.fleet.sdk.internal

internal enum class CheckMobileStatus {
    NEW_USER,
    RETURNING_USER,
}

internal data class FoListEntry(
    val foCompanyId: Long,
    val foName: String,
    val foStatus: String,
)

internal data class InviteValidateResult(
    val sessionToken: String,
    val driverName: String,
    val foName: String,
    val foCompanyId: Long,
)

internal data class DriverHomeJson(
    val hasActiveVehicle: Boolean,
    val foName: String?,
    val vehicleRegNo: String?,
    val vehicleId: String?,
    val assignmentType: String?,
    val isCurrentlyEligible: Boolean?,
    val currentlyEligible: Boolean?,
    val totalBalanceINR: Double?,
    val shiftDaysOfWeek: String?,
    val shiftStartTime: String?,
    val shiftEndTime: String?,
    val tripDate: String?,
    val tripStartTime: String?,
    val tripEndTime: String?,
    val tripStartLocation: String?,
)

internal data class DriverAssignmentJson(
    val vehicleDriverId: Long,
    val vehicleId: String,
    val vehicleRegNo: String,
    val assignmentType: String,
    val status: String,
    val requiresPairing: Boolean,
    val shiftDaysOfWeek: String?,
    val shiftStartTime: String?,
    val shiftEndTime: String?,
    val tripDate: String?,
    val tripStartTime: String?,
    val tripEndTime: String?,
    val tripStartLocation: String?,
    val assignedAt: String?,
)

internal data class DriverProfileJson(
    val driverId: String,
    val name: String,
    val maskedMobile: String?,
    val dlNumber: String? = null,
    val foStatus: String? = null,
)

internal data class QrPayResultJson(
    val serverTxnId: String?,
    val vehicleRegNo: String?,
    val amountINR: Double?,
    val newBalanceINR: Double?,
    val authCode: String?,
    val txnTime: String?,
    val status: String?,
    val quantityKg: Double?,
)

internal data class FleetpayQrPayload(
    val txnId: String,
    val mid: String,
    val terminalId: String,
    val amountPaise: Long,
    val expiryEpoch: Long,
    val sign: String,
    val merchantName: String?,
    val currency: String?,
)
