package com.mgl.fleet.sdk.internal

import com.mgl.fleet.sdk.demo.DemoAuthMode
import com.mgl.fleet.sdk.demo.DemoBinding
import com.mgl.fleet.sdk.demo.DemoBindingState
import kotlin.math.roundToLong
import java.util.Locale as JLocale

internal fun normVrnPublic(v: String): String =
    v.trim().replace("\\s+".toRegex(), " ").uppercase(JLocale.ENGLISH)

private fun parseShiftDays(csv: String?): List<String>? {
    if (csv.isNullOrBlank()) return null
    return csv.split(',').map { d ->
        val t = d.trim()
        if (t.length < 2) t else t.take(1) + t.substring(1, 3.coerceAtMost(t.length)).lowercase(JLocale.ENGLISH)
    }
}

private fun assignmentTypeToAuthMode(t: String): DemoAuthMode =
    when (t.uppercase(JLocale.ENGLISH)) {
        "WHOLE_TIME" -> DemoAuthMode.VEHICLE_LINKED
        "SHIFT" -> DemoAuthMode.SHIFT_BASED
        else -> DemoAuthMode.TRIP_LINKED
    }

/** Mirrors `mapAssignmentsToUiBindings` from `driver-api.ts` into [DemoBinding]. */
internal fun mapAssignmentsToDemoBindings(
    home: DriverHomeJson?,
    rows: List<DriverAssignmentJson>,
): List<DemoBinding> {
    val homeVrn = home?.vehicleRegNo?.let { normVrnPublic(it) }.orEmpty()
    val hasHomeVrn = homeVrn.isNotEmpty()
    return rows.map { a ->
        val authMode = assignmentTypeToAuthMode(a.assignmentType)
        val vrnKey = normVrnPublic(a.vehicleRegNo)
        val matchesHome = home?.hasActiveVehicle == true && hasHomeVrn && vrnKey == homeVrn
        val activeEligible = a.status == "ACTIVE" && !a.requiresPairing
        val homeEligible =
            home?.isCurrentlyEligible == true ||
                home?.currentlyEligible == true ||
                (
                    home?.isCurrentlyEligible == null &&
                        home?.currentlyEligible == null &&
                        activeEligible
                    )
        val eligible = if (matchesHome) homeEligible else activeEligible

        val scanPay =
            when {
                a.status == "PENDING_ACCEPTANCE" && a.requiresPairing -> "locked_unpaired"
                !eligible -> "out_window"
                a.assignmentType.uppercase(JLocale.ENGLISH) == "WHOLE_TIME" -> "always_available"
                a.assignmentType.uppercase(JLocale.ENGLISH) == "SHIFT" -> "in_window"
                else -> "trip_window"
            }

        val balance: Long =
            if (matchesHome && home?.totalBalanceINR != null) {
                home.totalBalanceINR!!.roundToLong()
            } else {
                0L
            }
        val foFromHome =
            if (matchesHome && !home?.foName.isNullOrBlank()) {
                home!!.foName!!.trim()
            } else {
                ""
            }

        val state =
            if (a.status == "PENDING_ACCEPTANCE") {
                DemoBindingState.PENDING_ACCEPTANCE
            } else {
                DemoBindingState.ACTIVE
            }
        val paired = !(a.status == "PENDING_ACCEPTANCE" && a.requiresPairing)

        DemoBinding(
            id = a.vehicleDriverId.toString(),
            vrn = a.vehicleRegNo,
            fo = foFromHome,
            vehicleId = a.vehicleId,
            authMode = authMode,
            state = state,
            paired = paired,
            scanPayStatus = scanPay,
            shiftDays = parseShiftDays(a.shiftDaysOfWeek) ?: emptyList(),
            shiftStart = a.shiftStartTime ?: "",
            shiftEnd = a.shiftEndTime ?: "",
            tripDate = a.tripDate ?: "",
            tripStart = a.tripStartTime ?: "",
            tripEnd = a.tripEndTime ?: "",
            origin = a.tripStartLocation ?: "",
            destination = "",
            balance = balance,
            cardBalance = balance,
            incentiveBalance = 0,
        )
    }
}
