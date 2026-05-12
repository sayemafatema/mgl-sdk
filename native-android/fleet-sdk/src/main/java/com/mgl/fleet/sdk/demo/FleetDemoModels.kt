package com.mgl.fleet.sdk.demo

internal enum class DemoAuthMode {
    VEHICLE_LINKED,
    SHIFT_BASED,
    TRIP_LINKED,
}

internal enum class DemoBindingState {
    ACTIVE,
    PENDING_ACCEPTANCE,
}

internal data class DemoBinding(
    val id: String,
    val vrn: String,
    val fo: String,
    /** Fleet vehicle id for `/vehicles/{id}/transactions` (live API). */
    val vehicleId: String = "",
    val authMode: DemoAuthMode,
    val state: DemoBindingState,
    val paired: Boolean,
    val scanPayStatus: String,
    val balance: Long = 0,
    val cardBalance: Long = 0,
    val incentiveBalance: Long = 0,
    val spendLimit: Long = 0,
    val shiftDays: List<String> = emptyList(),
    val shiftStart: String = "",
    val shiftEnd: String = "",
    val shiftEndsIn: String = "",
    val tripDate: String = "",
    val tripStart: String = "",
    val tripEnd: String = "",
    val tripEndsIn: String = "",
    val origin: String = "",
    val destination: String = "",
    val assignedBy: String? = null,
    val validPairingCode: String? = null,
    val repairReason: String? = null,
    val assignedAt: String? = null,
)

internal data class DemoDriver(
    val id: String,
    val name: String,
    val initials: String,
    val mobile: String,
    val maskedMobile: String,
    val pin: String,
)

internal data class DemoTxn(
    val id: String,
    val station: String,
    val vrn: String,
    val amount: Long,
    val date: String,
    val type: String,
    val quantity: String = "",
    val status: String,
)

internal data class DemoPairedVehicle(
    val vrn: String,
    val company: String,
    val authMode: String,
    val balance: Long,
    val limit: Long,
)

internal object FleetReactMock {
    val driver =
        DemoDriver(
            id = "DRV001",
            name = "Ravi Sharma",
            initials = "RS",
            mobile = "9876501234",
            maskedMobile = "+91 ••••••1234",
            pin = "123456",
        )

    val bindings: List<DemoBinding> =
        listOf(
            DemoBinding(
                id = "BND001",
                vrn = "MH 02 AB 1234",
                fo = "ABC Logistics Pvt. Ltd.",
                authMode = DemoAuthMode.VEHICLE_LINKED,
                state = DemoBindingState.ACTIVE,
                paired = true,
                scanPayStatus = "always_available",
                balance = 14600,
                cardBalance = 12500,
                incentiveBalance = 2100,
                spendLimit = 2000,
            ),
            DemoBinding(
                id = "BND002",
                vrn = "MH 02 CD 5678",
                fo = "ABC Logistics Pvt. Ltd.",
                authMode = DemoAuthMode.SHIFT_BASED,
                state = DemoBindingState.ACTIVE,
                paired = true,
                scanPayStatus = "in_window",
                shiftDays = listOf("Mon", "Tue", "Wed", "Thu", "Fri"),
                shiftStart = "06:00",
                shiftEnd = "14:00",
                shiftEndsIn = "3h 20m",
                balance = 8200,
                cardBalance = 8200,
                incentiveBalance = 0,
                spendLimit = 1500,
            ),
            DemoBinding(
                id = "BND003",
                vrn = "MH 04 GH 9012",
                fo = "ABC Logistics Pvt. Ltd.",
                authMode = DemoAuthMode.TRIP_LINKED,
                state = DemoBindingState.ACTIVE,
                paired = true,
                scanPayStatus = "in_window",
                tripDate = "Today",
                tripStart = "08:00",
                tripEnd = "18:00",
                tripEndsIn = "7h 20m",
                origin = "Andheri East",
                destination = "Pune",
                balance = 5400,
                cardBalance = 5400,
                incentiveBalance = 0,
                spendLimit = 3000,
            ),
            DemoBinding(
                id = "BND004",
                vrn = "MH 06 EF 3456",
                fo = "ABC Logistics Pvt. Ltd.",
                authMode = DemoAuthMode.VEHICLE_LINKED,
                state = DemoBindingState.PENDING_ACCEPTANCE,
                paired = false,
                scanPayStatus = "locked_unpaired",
                balance = 0,
                spendLimit = 2000,
                assignedBy = "Ramesh Shah",
                validPairingCode = "234567",
            ),
            DemoBinding(
                id = "BND005",
                vrn = "MH 08 KL 7890",
                fo = "XYZ Transport",
                authMode = DemoAuthMode.SHIFT_BASED,
                state = DemoBindingState.ACTIVE,
                paired = false,
                scanPayStatus = "locked_repair",
                shiftDays = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat"),
                shiftStart = "22:00",
                shiftEnd = "06:00",
                repairReason = "Monthly re-verification",
                balance = 3200,
                spendLimit = 1000,
                validPairingCode = "345678",
            ),
        )

    val transactions: List<DemoTxn> =
        listOf(
            DemoTxn("TXN001", "MGL Hind CNG Filling", "MH 02 AB 1234", 672, "Mar 23, 10:30 AM", "Fueling", "4.2 kg", "Success"),
            DemoTxn("TXN002", "NEFT Credit", "MH 02 AB 1234", 10000, "Mar 22, 02:15 PM", "Credit", status = "Success"),
            DemoTxn("TXN003", "MGL Kurla Station", "MH 02 CD 5678", 1200, "Mar 21, 08:45 AM", "Fueling", "7.5 kg", "Success"),
            DemoTxn("TXN004", "MGL Andheri East", "MH 02 AB 1234", 950, "Mar 20, 06:20 PM", "Fueling", "6.0 kg", "Success"),
        )

    val pairedVehicles: List<DemoPairedVehicle> =
        listOf(
            DemoPairedVehicle("MH 02 AB 1234", "ABC Logistics Pvt. Ltd.", "Vehicle-linked", 14600, 2000),
            DemoPairedVehicle("MH 02 CD 5678", "XYZ Transport", "Day shift 06:00-14:00", 8500, 1500),
        )

    val inviteCodes: Map<String, String> =
        mapOf(
            "ABC123" to "ABC Logistics Pvt. Ltd.",
            "XYZ789" to "XYZ Transport",
        )

    val pairingCodes: Map<String, Pair<String, String>> =
        mapOf(
            "123456" to ("ABC Logistics Pvt. Ltd." to "Ramesh Shah"),
            "789012" to ("XYZ Transport" to "Priya Patel"),
        )

    val assignmentForPairing: DemoBinding get() = bindings[3]
}
