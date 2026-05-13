@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.mgl.fleet.sdk.demo.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.QrCode2
import androidx.compose.material.icons.filled.Route
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.Alignment
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.mgl.fleet.sdk.FleetSdkErrorCodes
import com.mgl.fleet.sdk.FleetSdkException
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.demo.DemoAuthMode
import com.mgl.fleet.sdk.demo.DemoBinding
import com.mgl.fleet.sdk.demo.DemoBindingState
import com.mgl.fleet.sdk.demo.FleetReactMock
import com.mgl.fleet.sdk.demo.DemoTxn
import com.mgl.fleet.sdk.demo.DemoDriver
import com.mgl.fleet.sdk.demo.ReactParityBanner
import com.mgl.fleet.sdk.FleetSdkHolder
import com.mgl.fleet.sdk.internal.DriverAppApiClient
import com.mgl.fleet.sdk.internal.DriverHomeJson
import com.mgl.fleet.sdk.internal.DriverAssignmentJson
import com.mgl.fleet.sdk.internal.DriverProfileJson
import com.mgl.fleet.sdk.internal.FoListEntry
import com.mgl.fleet.sdk.internal.FleetpayQrPayload
import com.mgl.fleet.sdk.internal.InviteValidateResult
import com.mgl.fleet.sdk.internal.QrPayResultJson
import com.mgl.fleet.sdk.internal.CheckMobileStatus
import com.mgl.fleet.sdk.internal.DriverTxnRowParse
import com.mgl.fleet.sdk.internal.mapAssignmentsToDemoBindings
import com.mgl.fleet.sdk.internal.parseFleetpayPayUri
import com.mgl.fleet.sdk.internal.paiseToInrDisplay
import com.mgl.fleet.sdk.internal.validIndianMobile10
import com.mgl.fleet.sdk.internal.normVrnPublic
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

import java.text.NumberFormat
import java.util.Locale

internal val Green700 = Color(0xFF047857)
internal val Green600 = Color(0xFF059669)
internal val Gray100 = Color(0xFFF3F4F6)
internal val Gray900 = Color(0xFF111827)

internal fun Long.inr(): String = NumberFormat.getNumberInstance(Locale("en", "IN")).format(this)

private fun MutableList<String>.clearDigits() {
    for (i in indices) this[i] = ""
}

private fun initialsOf(name: String): String {
    val parts = name.trim().split(Regex("\\s+")).filter { it.isNotEmpty() }
    return when {
        parts.isEmpty() -> "?"
        parts.size == 1 -> parts[0].take(2).uppercase(Locale.getDefault())
        else -> (parts[0].first().toString() + parts[1].first().toString()).uppercase(Locale.getDefault())
    }
}

private fun vehicleIdForActiveCard(
    bindingsList: List<DemoBinding>,
    activeCardIdx: Int,
): String? {
    val cards = bindingsList.filter { it.paired && it.state == DemoBindingState.ACTIVE }
    val b = cards.getOrNull(activeCardIdx) ?: return null
    return b.vehicleId.trim().takeIf { it.isNotEmpty() }
}

private val ApiBannerBottomNavClearance = 96.dp
/** Space reserved above the fixed bottom nav dock so scroll content is not hidden under it. */
private val FleetBottomDockReserve = 88.dp
private val ApiBannerOnboardingFabClearance = 52.dp

@Composable
private fun ApiErrorBanner(
    message: String?,
    modifier: Modifier = Modifier,
    onDismiss: () -> Unit,
) {
    val msg = message?.trim()?.takeIf { it.isNotEmpty() } ?: return
    val maxScrollH =
        kotlin.math.min(
            (LocalConfiguration.current.screenHeightDp * 0.4f).toInt(),
            220,
        ).dp
    val amber50 = Color(0xFFFFFBEB)
    val amber200 = Color(0xFFFDE68A)
    val amber700 = Color(0xFFB45309)
    val amber900 = Color(0xFF78350F)
    val amber950 = Color(0xFF451A03)
    val bannerScroll = rememberScrollState()
    Row(
        modifier =
            modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .border(BorderStroke(1.dp, amber200), RoundedCornerShape(12.dp))
                .background(amber50)
                .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            Icons.Outlined.ErrorOutline,
            contentDescription = null,
            tint = amber700,
            modifier = Modifier.size(18.dp),
        )
        Box(
            modifier =
                Modifier
                    .weight(1f)
                    .padding(horizontal = 8.dp)
                    .heightIn(max = maxScrollH),
        ) {
            Text(
                msg,
                modifier = Modifier.verticalScroll(bannerScroll),
                color = amber950,
                fontSize = 12.sp,
                lineHeight = 16.sp,
                fontWeight = FontWeight.Normal,
            )
        }
        TextButton(
            onClick = onDismiss,
            modifier = Modifier.wrapContentWidth(Alignment.End),
            contentPadding = PaddingValues(horizontal = 4.dp, vertical = 0.dp),
        ) {
            Text(
                "Dismiss",
                fontWeight = FontWeight.SemiBold,
                fontSize = 12.sp,
                color = amber900,
            )
        }
    }
}

@Composable
internal fun FleetDriverFlow(
    onFinished: (FleetSdkResult) -> Unit,
) {
    MaterialTheme {
        val opts = remember { FleetSdkHolder.requireOptions() }
        val liveApi = remember { DriverAppApiClient(opts) }
        val liveMode = !opts.useMock

        var foScopedToken by remember {
            mutableStateOf(
                if (!opts.useMock) opts.authToken?.trim()?.takeIf { it.isNotEmpty() } else null,
            )
        }
        var onboardingStep by remember {
            mutableStateOf(
                if (!opts.useMock && !opts.authToken.isNullOrBlank()) "complete" else "login",
            )
        }
        var isRegistered by remember { mutableStateOf(true) }
        var mobileNumber by remember { mutableStateOf("") }
        val otpDigits = remember { mutableStateListOf("", "", "", "", "", "") }
        var otpError by remember { mutableStateOf("") }
        var otpCountdown by remember { mutableIntStateOf(0) }
        var scanSessionOtpCountdown by remember { mutableIntStateOf(0) }
        var inviteCode by remember { mutableStateOf("") }
        val inviteOtpDigits = remember { mutableStateListOf("", "", "", "", "", "") }
        var nuPin by remember { mutableStateOf("") }
        var nuPinConfirm by remember { mutableStateOf("") }
        var pinError by remember { mutableStateOf("") }
        var mainTab by remember { mutableStateOf("card") }
        var txnFilter by remember { mutableStateOf("all") }
        var mainOverlay by remember { mutableStateOf("none") }
        var activeCard by remember { mutableIntStateOf(0) }
        var sessionIdle by remember { mutableStateOf(true) }
        var sessionPhase by remember { mutableStateOf("idle") }
        var selectedScan: DemoBinding? by remember { mutableStateOf(null) }
        var sessionPin by remember { mutableStateOf("") }
        val sessionOtpDigits = remember { mutableStateListOf("", "", "", "", "", "") }
        var pairingCodeEntry by remember { mutableStateOf("") }
        var pairingError by remember { mutableStateOf("") }
        var showDeclineConfirm by remember { mutableStateOf(false) }
        var successToast by remember { mutableStateOf<String?>(null) }
        var pairingAttempts by remember { mutableIntStateOf(0) }
        var pairingSuccess by remember { mutableStateOf(false) }
        var showPairingHelp by remember { mutableStateOf(false) }
        var showOnboardingDevMenu by remember { mutableStateOf(false) }

        var apiBanner by remember { mutableStateOf<String?>(null) }
        var onboardingAction by remember { mutableStateOf<String?>(null) }
        var otpPhaseToken by remember { mutableStateOf<String?>(null) }
        var foOrganizationList by remember { mutableStateOf<List<FoListEntry>>(emptyList()) }
        var selectedFoCompanyId by remember { mutableStateOf<Long?>(null) }
        var foPinEntry by remember { mutableStateOf("") }
        var fleetPinFoDisplay by remember { mutableStateOf("") }
        var inviteOtpRefNumber by remember { mutableStateOf<String?>(null) }
        var inviteMobileVerificationToken by remember { mutableStateOf<String?>(null) }
        var inviteSessionToken by remember { mutableStateOf<String?>(null) }
        var validatedInvitePreview by remember { mutableStateOf<InviteValidateResult?>(null) }
        var apiHome by remember { mutableStateOf<DriverHomeJson?>(null) }
        var apiAssignments by remember { mutableStateOf<List<DriverAssignmentJson>>(emptyList()) }
        var apiProfile by remember { mutableStateOf<DriverProfileJson?>(null) }
        var recentLiveTx by remember { mutableStateOf<List<DemoTxn>>(emptyList()) }
        var apiTxnDetailRows by remember { mutableStateOf<List<DriverTxnRowParse>>(emptyList()) }
        var parsedScanQr by remember { mutableStateOf<FleetpayQrPayload?>(null) }
        var qrPayBusy by remember { mutableStateOf(false) }
        var lastQrPay by remember { mutableStateOf<QrPayResultJson?>(null) }
        var loginOtpRefocusKey by remember { mutableIntStateOf(0) }
        var inviteOtpRefocusKey by remember { mutableIntStateOf(0) }

        val pairingScope = rememberCoroutineScope()
        val mainScrollState = rememberScrollState()

        LaunchedEffect(mainTab) {
            mainScrollState.scrollTo(0)
        }

        LaunchedEffect(apiBanner) {
            if (apiBanner == null) return@LaunchedEffect
            delay(5000)
            apiBanner = null
        }

        val bindings =
            remember(liveMode, apiHome, apiAssignments) {
                if (!liveMode) {
                    FleetReactMock.bindings
                } else {
                    mapAssignmentsToDemoBindings(apiHome, apiAssignments)
                }
            }

        val driver =
            remember(liveMode, apiProfile, mobileNumber) {
                if (!liveMode) {
                    FleetReactMock.driver
                } else if (apiProfile != null) {
                    val p = apiProfile!!
                    val mob = mobileNumber.filter(Char::isDigit).takeLast(4).padStart(10, '•')
                    DemoDriver(
                        id = p.driverId.ifEmpty { "DRV" },
                        name = p.name.ifEmpty { "Driver" },
                        initials = initialsOf(p.name.ifEmpty { "D" }),
                        mobile = mobileNumber,
                        maskedMobile = p.maskedMobile ?: "+91 $mob",
                        pin = "",
                    )
                } else {
                    FleetReactMock.driver
                }
            }

        val activeCards =
            remember(bindings) {
                bindings.filter { it.paired && it.state == DemoBindingState.ACTIVE }
            }
        val pendingCount =
            remember(bindings) {
                bindings.count {
                    it.state == DemoBindingState.PENDING_ACCEPTANCE ||
                        (!it.paired && it.state == DemoBindingState.ACTIVE)
                }
            }
        var assignmentPick by remember { mutableStateOf<DemoBinding?>(null) }
        val defaultAssignment =
            remember(bindings, liveMode) {
                if (!liveMode) {
                    FleetReactMock.assignmentForPairing
                } else {
                    bindings.firstOrNull {
                        it.state == DemoBindingState.PENDING_ACCEPTANCE &&
                            (
                                it.scanPayStatus == "locked_unpaired" ||
                                    it.scanPayStatus == "locked_repair"
                            )
                    }
                        ?: bindings.firstOrNull { it.state == DemoBindingState.PENDING_ACCEPTANCE }
                        ?: FleetReactMock.assignmentForPairing
                }
            }
        val assignment = assignmentPick ?: defaultAssignment

        LaunchedEffect(mainOverlay) {
            if (mainOverlay == "none") assignmentPick = null
        }

        LaunchedEffect(mainTab, bindings) {
            if (mainTab != "scan") return@LaunchedEffect
            val scanAvail =
                bindings.filter {
                    it.paired && it.state == DemoBindingState.ACTIVE &&
                        (it.scanPayStatus == "always_available" ||
                            it.scanPayStatus == "in_window" ||
                            it.scanPayStatus == "trip_window")
                }
            if (selectedScan == null && scanAvail.isNotEmpty()) {
                selectedScan = scanAvail.first()
            }
        }

        LaunchedEffect(otpCountdown) {
            if (otpCountdown > 0) {
                delay(1000)
                otpCountdown--
            }
        }

        LaunchedEffect(scanSessionOtpCountdown) {
            if (scanSessionOtpCountdown > 0) {
                delay(1000)
                scanSessionOtpCountdown--
            }
        }

        LaunchedEffect(liveMode, foScopedToken, onboardingStep) {
            if (!liveMode || foScopedToken == null || onboardingStep != "complete") return@LaunchedEffect
            val tok = foScopedToken!!
            coroutineScope {
                val homeR = async { liveApi.driverGetHome(tok) }
                val profR = async { liveApi.driverGetProfile(tok) }
                val asgR = async { liveApi.driverGetAssignments(tok) }
                apiHome =
                    homeR.await().getOrElse { e ->
                        apiBanner = ReactParityBanner.forGenericFailure(e)
                        null
                    }
                apiProfile = profR.await().getOrNull()
                apiAssignments =
                    asgR.await().getOrElse { e ->
                        apiBanner = ReactParityBanner.forGenericFailure(e)
                        emptyList()
                    }
            }
        }

        LaunchedEffect(liveMode, foScopedToken, onboardingStep, activeCard, bindings) {
            if (!liveMode || foScopedToken == null || onboardingStep != "complete") return@LaunchedEffect
            val tok = foScopedToken!!
            val vid =
                vehicleIdForActiveCard(bindings, activeCard) ?: run {
                    recentLiveTx = emptyList()
                    apiTxnDetailRows = emptyList()
                    return@LaunchedEffect
                }
            liveApi.driverGetTransactions(tok, vid, 0).fold(
                onSuccess = { page ->
                    apiTxnDetailRows = page.rows
                    recentLiveTx =
                        page.rows.map { row ->
                            DemoTxn(
                                id = row.serverTxnId,
                                station = row.status.ifEmpty { "Fueling" },
                                vrn = row.vehicleRegNo,
                                amount = kotlin.math.abs(row.amountINR).toLong(),
                                date = row.createdOn,
                                type = if (row.status.uppercase().contains("CREDIT")) "Credit" else "Fueling",
                                quantity = "",
                                status = row.status,
                            )
                        }
                },
                onFailure = { e ->
                    apiTxnDetailRows = emptyList()
                    apiBanner = ReactParityBanner.forGenericFailure(e)
                },
            )
        }

        LaunchedEffect(liveMode, onboardingStep, otpDigits.joinToString("")) {
            if (!liveMode || onboardingStep != "login_otp") return@LaunchedEffect
            val otpStr = otpDigits.joinToString("")
            if (otpStr.length != 6 || onboardingAction != null) return@LaunchedEffect
            otpError = ""
            onboardingAction = "login_verify_otp"
            try {
                val partial = liveApi.driverOauthOtpGrant(mobileNumber, otpStr).getOrThrow()
                otpPhaseToken = partial
                val fos = liveApi.driverFoList(partial).getOrThrow().filter { it.foStatus == "ACTIVE" }
                foOrganizationList = fos
                if (fos.isEmpty()) {
                    apiBanner = ReactParityBanner.NO_ACTIVE_FLEET
                    otpPhaseToken = null
                    otpDigits.clearDigits()
                    loginOtpRefocusKey++
                    return@LaunchedEffect
                }
                if (fos.size == 1) {
                    selectedFoCompanyId = fos[0].foCompanyId
                    fleetPinFoDisplay = fos[0].foName
                    foPinEntry = ""
                    onboardingStep = "fo_pin_login"
                } else {
                    selectedFoCompanyId = null
                    onboardingStep = "select_fo"
                }
                otpDigits.clearDigits()
            } catch (e: Exception) {
                otpError = ""
                apiBanner = ReactParityBanner.forOtpFailure(e)
                otpDigits.clearDigits()
                loginOtpRefocusKey++
            } finally {
                onboardingAction = null
            }
        }

        fun verifyLoginOtp() {
            if (liveMode) return
            val entered = otpDigits.joinToString("")
            if (entered == "123456") {
                otpError = ""
                if (isRegistered) {
                    onboardingStep = "complete"
                } else {
                    nuPin = ""
                    nuPinConfirm = ""
                    pinError = ""
                    onboardingStep = "set_pin"
                }
            } else {
                otpError = "Incorrect OTP. Try again."
                otpDigits.clearDigits()
                loginOtpRefocusKey++
            }
        }

        val assignmentOpen = mainOverlay == "assignment_notification"
        val pairingOpen = mainOverlay == "pairing_code"
        val acceptedOpen = mainOverlay == "assignment_accepted"
        val mainShellDockVisible = !acceptedOpen && !assignmentOpen && !pairingOpen
        val bottomDockContentPad = if (mainShellDockVisible) FleetBottomDockReserve else 0.dp

        BackHandler(enabled = onboardingStep == "complete") {
            when {
                acceptedOpen -> mainOverlay = "none"
                pairingOpen -> {
                    pairingCodeEntry = ""
                    pairingError = ""
                    pairingSuccess = false
                    pairingAttempts = 0
                    mainOverlay = "assignment_notification"
                }
                assignmentOpen -> mainOverlay = "none"
                sessionPhase != "idle" -> {
                    when (sessionPhase) {
                        "confirmation" -> {
                            sessionPhase = "idle"
                            sessionPin = ""
                            parsedScanQr = null
                            lastQrPay = null
                            sessionIdle = true
                        }
                        "pin_confirm" -> {
                            sessionPhase = "confirmation"
                            sessionPin = ""
                        }
                        "otp_entry" -> {
                            sessionPhase = "pin_confirm"
                            sessionOtpDigits.clearDigits()
                            scanSessionOtpCountdown = 0
                        }
                        "authorized" -> {}
                        "complete" -> {
                            sessionPhase = "idle"
                            sessionPin = ""
                            sessionOtpDigits.clearDigits()
                            scanSessionOtpCountdown = 0
                            mainTab = "card"
                            selectedScan = null
                            sessionIdle = true
                            parsedScanQr = null
                            lastQrPay = null
                        }
                        else -> {}
                    }
                }
                mainTab != "card" -> mainTab = "card"
                else -> onFinished(FleetSdkResult.Failure(FleetSdkException(FleetSdkErrorCodes.USER_CANCELLED, "Back closed flow.")))
            }
        }

        BackHandler(enabled = onboardingStep != "complete") {
            when (onboardingStep) {
                "login_otp" -> {
                    onboardingStep = "login"
                    otpDigits.clearDigits()
                    otpError = ""
                }

                "1c" ->
                    onboardingStep =
                        when {
                            liveMode -> {
                                inviteOtpRefNumber = null
                                inviteMobileVerificationToken = null
                                inviteCode = ""
                                "login"
                            }
                            else -> "1b"
                        }

                "select_fo" -> {
                    onboardingStep = "login_otp"
                    otpPhaseToken = null
                }

                "fo_pin_login" -> {
                    foPinEntry = ""
                    val fos = foOrganizationList.filter { it.foStatus == "ACTIVE" }
                    if (fos.size > 1) {
                        onboardingStep = "select_fo"
                    } else {
                        onboardingStep = "login_otp"
                        otpPhaseToken = null
                    }
                }

                "1b" -> onboardingStep = if (liveMode && inviteMobileVerificationToken != null) "1d" else "login"

                "1d" ->
                    onboardingStep =
                        if (liveMode) {
                            inviteOtpRefNumber = null
                            inviteCode = ""
                            "1c"
                        } else {
                            "1c"
                        }

                "1e", "set_pin" -> onboardingStep = if (onboardingStep == "set_pin") "login_otp" else "1d"
                "1f", "confirm_pin" -> onboardingStep = if (onboardingStep.startsWith("1")) "1e" else "set_pin"
                "registered" -> onboardingStep = "confirm_pin"
                "forgot_pin" -> onboardingStep = "login"
                "login" ->
                    onFinished(FleetSdkResult.Failure(FleetSdkException(FleetSdkErrorCodes.USER_CANCELLED, "User cancelled.")))
                else -> Unit
            }
        }

        if (onboardingStep != "complete") {
            PhoneFrame {
                Box(Modifier.fillMaxSize()) {
                Column(
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .windowInsetsPadding(WindowInsets.statusBars)
                        .padding(top = 12.dp)
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    when (onboardingStep) {
                        "login" ->
                            LoginScreen(
                                mobileNumber = mobileNumber,
                                onMobileChange = { mobileNumber = it.filter(Char::isDigit).take(10) },
                                showMobileFormatError =
                                    mobileNumber.isNotEmpty() &&
                                        (mobileNumber.first().digitToIntOrNull() !in 6..9),
                                isSendingOtp = onboardingAction == "login_send_otp",
                                onSendOtp = {
                                    if (!validIndianMobile10(mobileNumber)) return@LoginScreen
                                    apiBanner = null
                                    otpDigits.clearDigits()
                                    loginOtpRefocusKey++
                                    otpError = ""
                                    if (liveMode) {
                                        pairingScope.launch {
                                            onboardingAction = "login_send_otp"
                                            try {
                                                when (liveApi.driverCheckMobile(mobileNumber).getOrThrow()) {
                                                    CheckMobileStatus.NEW_USER -> {
                                                        apiBanner = ReactParityBanner.NEW_USER_CONTINUE_INVITE
                                                        inviteOtpRefNumber = null
                                                        inviteMobileVerificationToken = null
                                                        inviteCode = ""
                                                        onboardingStep = "1c"
                                                    }

                                                    CheckMobileStatus.RETURNING_USER -> {
                                                        liveApi.driverSendLoginOtp(mobileNumber).getOrThrow()
                                                        otpCountdown = 60
                                                        onboardingStep = "login_otp"
                                                    }
                                                }
                                            } catch (e: Exception) {
                                                apiBanner = ReactParityBanner.forGenericFailure(e)
                                            } finally {
                                                onboardingAction = null
                                            }
                                        }
                                    } else {
                                        otpCountdown = 30
                                        onboardingStep = "login_otp"
                                    }
                                },
                                onInvite = {
                                    apiBanner = null
                                    inviteCode = ""
                                    inviteOtpRefNumber = null
                                    inviteMobileVerificationToken = null
                                    if (liveMode) {
                                        mobileNumber = ""
                                        onboardingStep = "1c"
                                    } else {
                                        onboardingStep = "1b"
                                    }
                                },
                            )

                        "select_fo" -> {
                            Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.Start) {
                                OnboardingBackRow(onClick = { onboardingStep = "login_otp"; otpPhaseToken = null })
                                Spacer(Modifier.height(16.dp))
                                Text("Choose fleet operator", fontWeight = FontWeight.Bold, fontSize = 20.sp)
                                Spacer(Modifier.height(16.dp))
                                foOrganizationList
                                    .filter { it.foStatus == "ACTIVE" }
                                    .forEach { fo ->
                                        Card(
                                            Modifier
                                                .fillMaxWidth()
                                                .padding(vertical = 6.dp)
                                                .clickable {
                                                    selectedFoCompanyId = fo.foCompanyId
                                                    fleetPinFoDisplay = fo.foName
                                                    foPinEntry = ""
                                                    onboardingStep = "fo_pin_login"
                                                },
                                            colors = CardDefaults.cardColors(containerColor = Color.White),
                                            border = BorderStroke(1.dp, Color.LightGray),
                                        ) {
                                            Column(Modifier.padding(16.dp)) {
                                                Text(fo.foName, fontWeight = FontWeight.SemiBold)
                                                Text("Fleet ID #${fo.foCompanyId}", fontSize = 11.sp, color = Color.Gray)
                                            }
                                        }
                                    }
                            }
                        }

                        "fo_pin_login" -> {
                            Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.Start) {
                                OnboardingBackRow(
                                    onClick = {
                                        foPinEntry = ""
                                        val fos = foOrganizationList.filter { it.foStatus == "ACTIVE" }
                                        if (fos.size > 1) onboardingStep = "select_fo" else {
                                            onboardingStep = "login_otp"
                                            otpPhaseToken = null
                                        }
                                    },
                                )
                                Spacer(Modifier.height(16.dp))
                                Text("Fleet PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp)
                                Text(
                                    "Enter your PIN for this Fleet Operator",
                                    fontSize = 14.sp,
                                    color = Color(0xFF6B7280),
                                    modifier = Modifier.padding(top = 8.dp),
                                )
                                Text(
                                    fleetPinFoDisplay.ifEmpty { "—" },
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 18.sp,
                                    modifier = Modifier.padding(top = 8.dp, bottom = 24.dp),
                                )
                                PinDots(foPinEntry)
                                Numpad(
                                    enabled = onboardingAction != "fo_unlock",
                                    onDigit = { d -> if ((onboardingAction == null || onboardingAction != "fo_unlock") && foPinEntry.length < 6) foPinEntry += d },
                                    onBackspace = { foPinEntry = foPinEntry.dropLast(1) },
                                )
                                Button(
                                    onClick = {
                                        val selId = selectedFoCompanyId ?: return@Button
                                        val phase = otpPhaseToken ?: return@Button
                                        if (foPinEntry.length != 6) return@Button
                                        pairingScope.launch {
                                            onboardingAction = "fo_unlock"
                                            try {
                                                val tok =
                                                    liveApi.driverFoSelect(phase, selId, foPinEntry).getOrThrow()
                                                foScopedToken = tok
                                                otpPhaseToken = null
                                                foPinEntry = ""
                                                apiBanner = null
                                                onboardingStep = "complete"
                                            } catch (e: Exception) {
                                                apiBanner = ReactParityBanner.forPinFailure(e)
                                                foPinEntry = ""
                                            } finally {
                                                onboardingAction = null
                                            }
                                        }
                                    },
                                    enabled = foPinEntry.length == 6 && selectedFoCompanyId != null && onboardingAction != "fo_unlock",
                                    modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = Green700),
                                ) { Text(if (onboardingAction == "fo_unlock") "Unlocking…" else "Unlock app") }
                            }
                        }

                        "login_otp" ->
                            LoginOtpScreen(
                                mobileNumber = mobileNumber,
                                otpDigits = otpDigits,
                                otpError = otpError,
                                otpCountdown = otpCountdown,
                                otpRefocusAfterKey = loginOtpRefocusKey,
                                isVerifying = onboardingAction == "login_verify_otp",
                                isResending = onboardingAction == "login_resend_otp",
                                onBack = { onboardingStep = "login" },
                                onResend = {
                                    if (liveMode) {
                                        pairingScope.launch {
                                            onboardingAction = "login_resend_otp"
                                            try {
                                                liveApi.driverSendLoginOtp(mobileNumber).onFailure { e ->
                                                    apiBanner = ReactParityBanner.forGenericFailure(e)
                                                }
                                                otpCountdown = 60
                                                apiBanner = null
                                            } finally {
                                                onboardingAction = null
                                            }
                                        }
                                    } else {
                                        otpCountdown = 30
                                    }
                                },
                                onVerifyManual = { verifyLoginOtp() },
                            )

                        "set_pin" ->
                            SetPinScreen(isNewUser = !isRegistered, pin = nuPin, onDigit = { nuPin = (nuPin + it).take(6) }, onBack = { nuPin = nuPin.dropLast(1) }, onNext = { if (nuPin.length == 6) onboardingStep = "confirm_pin" })

                        "confirm_pin" ->
                            ConfirmPinScreen(
                                pinConfirm = nuPinConfirm,
                                pinError = pinError,
                                onDigit = {
                                    nuPinConfirm = (nuPinConfirm + it).take(6)
                                    pinError = ""
                                },
                                onBackNavigation = {
                                    nuPinConfirm = ""
                                    pinError = ""
                                    apiBanner = null
                                    onboardingStep = "set_pin"
                                },
                                onBackspace = {
                                    nuPinConfirm = nuPinConfirm.dropLast(1)
                                    pinError = ""
                                },
                                onSubmit = {
                                    if (nuPinConfirm == nuPin) {
                                        pinError = ""
                                        if (!isRegistered) {
                                            onboardingStep = "registered"
                                        } else {
                                            nuPin = ""
                                            nuPinConfirm = ""
                                            isRegistered = true
                                            successToast = "PIN updated successfully"
                                            onboardingStep = "login"
                                        }
                                    } else {
                                        pinError = ReactParityBanner.PINS_DONT_MATCH_CONFIRM
                                        nuPinConfirm = ""
                                        onboardingStep = "set_pin"
                                    }
                                },
                            )

                        "registered" ->
                            RegisteredScreen(onContinue = {
                                nuPin = ""
                                nuPinConfirm = ""
                                isRegistered = true
                                onboardingStep = "complete"
                            })

                        "1b" ->
                            InviteCodeScreen(
                                code = inviteCode,
                                onCode = { inviteCode = it.uppercase().filter { ch -> ch.isLetterOrDigit() }.take(24) },
                                onBack = {
                                    onboardingStep =
                                        if (liveMode && inviteMobileVerificationToken != null) "1d" else "login"
                                },
                                previewDriverName = null,
                                previewFoName = null,
                                isContinuing = onboardingAction == "invite_validate",
                                onContinue = {
                                    if (liveMode) {
                                        apiBanner = null
                                        val tok = inviteMobileVerificationToken
                                        if (tok.isNullOrBlank() || inviteCode.length < 6) {
                                            apiBanner = ReactParityBanner.INVITE_VERIFY_MOBILE_FIRST
                                            return@InviteCodeScreen
                                        }
                                        pairingScope.launch {
                                            onboardingAction = "invite_validate"
                                            try {
                                                val v =
                                                    liveApi.driverInviteValidate(mobileNumber, inviteCode, tok).getOrThrow()
                                                validatedInvitePreview = v
                                                inviteSessionToken = v.sessionToken
                                                fleetPinFoDisplay = v.foName
                                                nuPin = ""
                                                nuPinConfirm = ""
                                                pinError = ""
                                                onboardingStep = "1e"
                                            } catch (e: Exception) {
                                                apiBanner = ReactParityBanner.forGenericFailure(e)
                                            } finally {
                                                onboardingAction = null
                                            }
                                        }
                                    } else if (FleetReactMock.inviteCodes.containsKey(inviteCode)) {
                                        onboardingStep = "1c"
                                    }
                                },
                                continueEnabled =
                                    inviteCode.length >= 6 &&
                                        (
                                            (!liveMode && FleetReactMock.inviteCodes.containsKey(inviteCode)) ||
                                                (liveMode && !inviteMobileVerificationToken.isNullOrBlank())
                                            ),
                            )

                        "1c" ->
                            MobileVerifyInvite(
                                mobile = mobileNumber,
                                onMobile = { mobileNumber = it.filter(Char::isDigit).take(10) },
                                onBack = { onboardingStep = if (liveMode) "login" else "1b" },
                                showMobileFormatError =
                                    mobileNumber.isNotEmpty() &&
                                        (mobileNumber.first().digitToIntOrNull() !in 6..9),
                                isSending = onboardingAction == "invite_send_otp",
                                onSend = {
                                    if (!validIndianMobile10(mobileNumber)) return@MobileVerifyInvite
                                    apiBanner = null
                                    if (!liveMode) {
                                        inviteOtpDigits.clearDigits()
                                        inviteOtpRefocusKey++
                                        otpCountdown = 30
                                        onboardingStep = "1d"
                                    } else {
                                        pairingScope.launch {
                                            onboardingAction = "invite_send_otp"
                                            try {
                                                when (liveApi.driverCheckMobile(mobileNumber).getOrThrow()) {
                                                    CheckMobileStatus.RETURNING_USER -> {
                                                        apiBanner = ReactParityBanner.USE_SEND_OTP_ON_LOGIN
                                                    }

                                                    CheckMobileStatus.NEW_USER -> {
                                                        val ref = liveApi.driverInviteMobileSendOtp(mobileNumber).getOrThrow()
                                                        inviteOtpRefNumber = ref
                                                        inviteOtpDigits.clearDigits()
                                                        inviteOtpRefocusKey++
                                                        otpCountdown = 60
                                                        onboardingStep = "1d"
                                                    }
                                                }
                                            } catch (e: Exception) {
                                                apiBanner = ReactParityBanner.forGenericFailure(e)
                                            } finally {
                                                onboardingAction = null
                                            }
                                        }
                                    }
                                },
                            )

                        "1d" ->
                            InviteOtpScreen(
                                mobile = mobileNumber,
                                otpDigits = inviteOtpDigits,
                                otpCountdown = otpCountdown,
                                otpRefocusAfterKey = inviteOtpRefocusKey,
                                isVerifying = onboardingAction == "invite_verify_otp",
                                isResending = onboardingAction == "invite_resend_otp",
                                onBack = { onboardingStep = "1c" },
                                onResend = {
                                    if (liveMode) {
                                        pairingScope.launch {
                                            onboardingAction = "invite_resend_otp"
                                            try {
                                                val ref = liveApi.driverInviteMobileSendOtp(mobileNumber).getOrThrow()
                                                inviteOtpRefNumber = ref
                                                inviteOtpDigits.clearDigits()
                                                inviteOtpRefocusKey++
                                                otpCountdown = 60
                                                apiBanner = null
                                            } catch (e: Exception) {
                                                apiBanner = ReactParityBanner.forGenericFailure(e)
                                            } finally {
                                                onboardingAction = null
                                            }
                                        }
                                    } else {
                                        otpCountdown = 30
                                    }
                                },
                                onVerify = {
                                    val otpStr = inviteOtpDigits.joinToString("")
                                    if (otpStr.length != 6) return@InviteOtpScreen
                                    if (liveMode) {
                                        val ref = inviteOtpRefNumber ?: return@InviteOtpScreen
                                        pairingScope.launch {
                                            onboardingAction = "invite_verify_otp"
                                            try {
                                                val t =
                                                    liveApi.driverInviteMobileVerifyOtp(
                                                        mobileNumber,
                                                        ref,
                                                        otpStr,
                                                    ).getOrThrow()
                                                inviteMobileVerificationToken = t
                                                inviteOtpDigits.clearDigits()
                                                inviteCode = ""
                                                apiBanner = null
                                                onboardingStep = "1b"
                                            } catch (e: Exception) {
                                                apiBanner = ReactParityBanner.forOtpFailure(e)
                                                inviteOtpDigits.clearDigits()
                                                inviteOtpRefocusKey++
                                            } finally {
                                                onboardingAction = null
                                            }
                                        }
                                    } else {
                                        onboardingStep = "1b"
                                    }
                                },
                            )

                        "1e" ->
                            InvitePinSetup(
                                pin = nuPin,
                                onDigit = { nuPin = (nuPin + it).take(6) },
                                onBackspace = { nuPin = nuPin.dropLast(1) },
                                onNext = { if (nuPin.length == 6) onboardingStep = "1f" },
                            )

                        "1f" ->
                            InvitePinConfirm(
                                pinConfirm = nuPinConfirm,
                                pinStored = nuPin,
                                pinError = pinError,
                                onDigit = {
                                    nuPinConfirm = (nuPinConfirm + it).take(6)
                                    pinError = ""
                                },
                                onBackspace = { nuPinConfirm = nuPinConfirm.dropLast(1) },
                                onBackNavigation = {
                                    nuPinConfirm = ""
                                    pinError = ""
                                    onboardingStep = "1e"
                                },
                                isSubmitting = onboardingAction == "invite_set_pin",
                                onSubmit = {
                                    if (nuPinConfirm != nuPin) {
                                        pinError = ReactParityBanner.PINS_DONT_MATCH_1F
                                        nuPinConfirm = ""
                                        return@InvitePinConfirm
                                    }
                                    pinError = ""
                                    if (liveMode) {
                                        val sess = inviteSessionToken
                                        if (sess.isNullOrBlank()) {
                                            apiBanner = ReactParityBanner.SESSION_MISSING_INVITE
                                            return@InvitePinConfirm
                                        }
                                        pairingScope.launch {
                                            onboardingAction = "invite_set_pin"
                                            try {
                                                val tok =
                                                    liveApi.driverInviteSetPin(sess, nuPin).getOrThrow()
                                                foScopedToken = tok
                                                val preview = validatedInvitePreview
                                                if (preview != null) {
                                                    fleetPinFoDisplay = preview.foName.trim()
                                                }
                                                inviteSessionToken = null
                                                nuPin = ""
                                                nuPinConfirm = ""
                                                apiBanner = null
                                                onboardingStep = "complete"
                                            } catch (e: Exception) {
                                                apiBanner = ReactParityBanner.forPinFailure(e)
                                                nuPinConfirm = ""
                                            } finally {
                                                onboardingAction = null
                                            }
                                        }
                                    } else {
                                        onboardingStep = "complete"
                                    }
                                },
                            )

                        "forgot_pin" ->
                            ForgotPinReactScreen(onBackToLogin = { onboardingStep = "login" })

                    }
                }
                    if (showOnboardingDevMenu) {
                        Card(
                            Modifier
                                .align(Alignment.TopEnd)
                                .padding(8.dp),
                            colors = CardDefaults.cardColors(containerColor = Gray900),
                        ) {
                            Column(Modifier.padding(8.dp)) {
                                TextButton(
                                    {
                                        showOnboardingDevMenu = false
                                        onboardingStep = "complete"
                                    },
                                ) { Text("Skip to Main App", color = Color.White, fontSize = 12.sp) }
                                TextButton(
                                    {
                                        isRegistered = !isRegistered
                                        showOnboardingDevMenu = false
                                    },
                                ) {
                                    Text(
                                        if (isRegistered) "Mode: returning user" else "Mode: new user",
                                        color = Color.White,
                                        fontSize = 12.sp,
                                    )
                                }
                            }
                        }
                    }
                    Box(
                        Modifier
                            .align(Alignment.BottomEnd)
                            .padding(12.dp)
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(Gray100)
                            .clickable { showOnboardingDevMenu = !showOnboardingDevMenu },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("⋮", fontSize = 16.sp, color = Color.Gray)
                    }
                    ApiErrorBanner(
                        message = apiBanner,
                        onDismiss = { apiBanner = null },
                        modifier =
                            Modifier
                                .align(Alignment.BottomCenter)
                                .fillMaxWidth()
                                .windowInsetsPadding(WindowInsets.navigationBars)
                                .padding(horizontal = 12.dp)
                                .padding(bottom = 12.dp + ApiBannerOnboardingFabClearance),
                    )
                }
            }
            return@MaterialTheme
        }

        // Main shell
        PhoneFrame {
            Box(Modifier.fillMaxSize()) {
            Column(
                Modifier
                    .fillMaxSize()
                    .windowInsetsPadding(WindowInsets.statusBars)
                    .padding(top = 16.dp),
            ) {
                when {
                    acceptedOpen ->
                        AssignmentAcceptedOverlay(
                            assignment = assignment,
                            onGoAssignments = {
                                mainOverlay = "none"
                                mainTab = "assignments"
                            },
                        )

                    assignmentOpen -> {
                        Column(Modifier.fillMaxSize()) {
                            AssignmentOverlay(
                                assignment = assignment,
                                onAcceptPair = {
                                    pairingCodeEntry = ""
                                    pairingError = ""
                                    pairingAttempts = 0
                                    pairingSuccess = false
                                    mainOverlay = "pairing_code"
                                },
                                onDeclineRequest = { showDeclineConfirm = true },
                                onBack = { mainOverlay = "none" },
                            )
                            if (showDeclineConfirm) {
                                AlertDialog(
                                    onDismissRequest = { showDeclineConfirm = false },
                                    title = { Text("Decline this assignment?") },
                                    text = { Text("Your Fleet Operator will be notified.") },
                                    confirmButton = {
                                        TextButton({
                                            showDeclineConfirm = false
                                            mainOverlay = "none"
                                        }) { Text("Yes, decline", color = Color.Red) }
                                    },
                                    dismissButton = { TextButton({ showDeclineConfirm = false }) { Text("Cancel") } },
                                )
                            }
                        }
                    }

                    pairingOpen -> {
                        PairingOverlayExtended(
                            assignment = assignment,
                            code = pairingCodeEntry,
                            pairingSuccess = pairingSuccess,
                            attempts = pairingAttempts,
                            error = pairingError,
                            showHelp = showPairingHelp,
                            onDismissHelp = { showPairingHelp = false },
                            onCode = {
                                pairingCodeEntry = it.filter(Char::isDigit).take(6)
                                pairingError = ""
                            },
                            onHelp = { showPairingHelp = true },
                            onBack = {
                                mainOverlay = "assignment_notification"
                                pairingCodeEntry = ""
                                pairingError = ""
                                pairingAttempts = 0
                                pairingSuccess = false
                            },
                            onSubmit = {
                                if (liveMode) {
                                    val tok = foScopedToken
                                    if (tok == null) {
                                        pairingError = "Session expired. Sign in again."
                                    } else {
                                        pairingScope.launch {
                                            liveApi.driverAcceptPairing(tok, pairingCodeEntry).fold(
                                                onSuccess = {
                                                    pairingSuccess = true
                                                    pairingError = ""
                                                    delay(900)
                                                    mainOverlay = "assignment_accepted"
                                                    pairingSuccess = false
                                                    pairingCodeEntry = ""
                                                    pairingAttempts = 0
                                                    val h = liveApi.driverGetHome(tok).getOrNull()
                                                    if (h != null) apiHome = h
                                                    apiAssignments =
                                                        liveApi.driverGetAssignments(tok).getOrElse { emptyList() }
                                                },
                                                onFailure = {
                                                    pairingAttempts++
                                                    pairingError = it.message ?: "Incorrect code."
                                                    pairingCodeEntry = ""
                                                },
                                            )
                                        }
                                    }
                                } else if (pairingCodeEntry == assignment.validPairingCode) {
                                    pairingSuccess = true
                                    pairingError = ""
                                    pairingScope.launch {
                                        delay(900)
                                        mainOverlay = "assignment_accepted"
                                        pairingSuccess = false
                                        pairingCodeEntry = ""
                                        pairingAttempts = 0
                                    }
                                } else {
                                    pairingAttempts++
                                    pairingError = "Incorrect code."
                                    pairingCodeEntry = ""
                                }
                            },
                            onCloseMaxAttempts = { mainOverlay = "none"; pairingAttempts = 0 },
                        )
                    }

                    else -> {
                    Column(
                        Modifier
                            .weight(1f)
                            .padding(bottom = bottomDockContentPad),
                    ) {
                        MainHeader(driverName = driver.name, initials = driver.initials)
                        successToast?.let { t ->
                            Box(Modifier.fillMaxWidth().background(Green600).padding(12.dp)) { Text(t, color = Color.White, fontSize = 13.sp) }
                        }
                        val scrollBg =
                            if (mainTab == "card" || mainTab == "assignments") Color(0xFFECEFF1) else Color.White
                        if (mainTab == "transactions") {
                            TransactionsTab(
                                modifier = Modifier.weight(1f).fillMaxWidth(),
                                filter = txnFilter,
                                onFilter = { txnFilter = it },
                                rows =
                                    if (liveMode) {
                                        apiTxnDetailRows
                                    } else {
                                        FleetReactMock.transactions.map { demoTxnToDetailRow(it) }
                                    },
                            )
                        } else {
                            Column(
                                Modifier
                                    .weight(1f)
                                    .verticalScroll(mainScrollState)
                                    .background(scrollBg),
                            ) {
                                when (mainTab) {
                                    "card" ->
                                        CardTab(
                                            fleetPinFoDisplay = fleetPinFoDisplay,
                                            apiHome = apiHome,
                                            activeCards = activeCards,
                                            activeCard = activeCard,
                                            onCardChange = { activeCard = it },
                                            pendingCount = pendingCount,
                                            onOpenAssignments = { mainTab = "assignments" },
                                            onOpenTransactions = { mainTab = "transactions" },
                                            onScanTab = { mainTab = "scan" },
                                            recentTransactions = if (liveMode) recentLiveTx else FleetReactMock.transactions,
                                        )

                                    "scan" ->
                                        ScanTab(
                                            bindings = bindings,
                                            selected = selectedScan,
                                            onSelect = { selectedScan = it },
                                            phase = sessionPhase,
                                            sessionPin = sessionPin,
                                            onSessionDigit = { sessionPin = (sessionPin + it).take(6) },
                                            onSessionBs = { sessionPin = sessionPin.dropLast(1) },
                                            sessionOtpDigits = sessionOtpDigits,
                                            onFleetpayQrScanned = { raw ->
                                                val sel = selectedScan
                                                if (sel == null) {
                                                    apiBanner = ReactParityBanner.SELECT_VEHICLE_FIRST
                                                } else {
                                                    apiBanner = null
                                                    val p = parseFleetpayPayUri(raw.trim())
                                                    if (p == null) {
                                                        apiBanner = ReactParityBanner.INVALID_FLEETPAY_QR
                                                    } else {
                                                        parsedScanQr = p
                                                        sessionIdle = false
                                                        sessionPhase = "confirmation"
                                                    }
                                                }
                                            },
                                            onCloseConfirm = {
                                                sessionPhase = "idle"
                                                sessionIdle = true
                                                sessionPin = ""
                                                scanSessionOtpCountdown = 0
                                                parsedScanQr = null
                                                lastQrPay = null
                                            },
                                            onContinueToPin = {
                                                sessionPhase = "pin_confirm"
                                                sessionPin = ""
                                            },
                                            onBackFromPinConfirm = {
                                                sessionPhase = "confirmation"
                                                sessionPin = ""
                                            },
                                            onVerifyPinForSession = {
                                                if (liveMode) {
                                                    val tok = foScopedToken
                                                    val veh = selectedScan
                                                    val qr = parsedScanQr
                                                    if (tok != null && veh != null && qr != null && sessionPin.length == 6) {
                                                        pairingScope.launch {
                                                        qrPayBusy = true
                                                        try {
                                                            val vrnNorm = normVrnPublic(veh.vrn).replace(" ", "")
                                                            val pay =
                                                                liveApi.driverQrPay(
                                                                    tok,
                                                                    qr.txnId,
                                                                    vrnNorm,
                                                                    sessionPin,
                                                                    qr.mid,
                                                                    qr.terminalId,
                                                                    qr.amountPaise,
                                                                    qr.expiryEpoch,
                                                                    qr.sign,
                                                                ).getOrThrow()
                                                            lastQrPay = pay
                                                            sessionPin = ""
                                                            sessionPhase = "complete"
                                                            val h = liveApi.driverGetHome(tok).getOrNull()
                                                            if (h != null) apiHome = h
                                                            val vid =
                                                                vehicleIdForActiveCard(bindings, activeCard)
                                                                    ?: veh.vehicleId.takeIf { it.isNotBlank() }
                                                            if (!vid.isNullOrBlank()) {
                                                                liveApi.driverGetTransactions(tok, vid, 0).onSuccess { pg ->
                                                                    apiTxnDetailRows = pg.rows
                                                                    recentLiveTx =
                                                                        pg.rows.map { row ->
                                                                            DemoTxn(
                                                                                id = row.serverTxnId,
                                                                                station = row.status.ifEmpty { "Fueling" },
                                                                                vrn = row.vehicleRegNo,
                                                                                amount =
                                                                                    kotlin.math.abs(row.amountINR)
                                                                                        .toLong(),
                                                                                date = row.createdOn,
                                                                                type =
                                                                                    if (row.status.uppercase()
                                                                                            .contains(
                                                                                                "CREDIT",
                                                                                            )
                                                                                    ) {
                                                                                        "Credit"
                                                                                    } else {
                                                                                        "Fueling"
                                                                                    },
                                                                                quantity = "",
                                                                                status = row.status,
                                                                            )
                                                                        }
                                                                }
                                                            }
                                                        } catch (e: Exception) {
                                                            apiBanner = ReactParityBanner.forPinFailure(e)
                                                            sessionPin = ""
                                                        } finally {
                                                            qrPayBusy = false
                                                        }
                                                        }
                                                    }
                                                } else {
                                                    if (sessionPin == (if (nuPin.length == 6) nuPin else driver.pin)) {
                                                        sessionPhase = "otp_entry"
                                                        sessionPin = ""
                                                        scanSessionOtpCountdown = 60
                                                    } else sessionPin = ""
                                                }
                                            },
                                            onVerifySessionOtp = {
                                                if (sessionOtpDigits.joinToString("").length == 6) {
                                                    sessionPhase = "authorized"
                                                    scanSessionOtpCountdown = 0
                                                }
                                            },
                                            onFuelingComplete = { sessionPhase = "complete" },
                                            onSessionDone = {
                                                sessionPhase = "idle"
                                                sessionIdle = true
                                                sessionOtpDigits.clearDigits()
                                                scanSessionOtpCountdown = 0
                                                mainTab = "card"
                                                selectedScan = null
                                                parsedScanQr = null
                                                lastQrPay = null
                                            },
                                            scannedLoginMobileDigits =
                                                mobileNumber.filter { it.isDigit() }.take(10),
                                            maskedMobileFromProfile =
                                                apiProfile?.maskedMobile?.trim()?.takeIf { it.isNotEmpty() },
                                            onBackFromOtpEntry = { sessionPhase = "pin_confirm" },
                                            parsedQr = parsedScanQr,
                                            liveMode = liveMode,
                                            qrPayBusy = qrPayBusy,
                                            lastPay = lastQrPay,
                                            scanSessionOtpCountdown = scanSessionOtpCountdown,
                                            onResendScanSessionOtp = {
                                                if (scanSessionOtpCountdown == 0) scanSessionOtpCountdown = 60
                                            },
                                            onGoToMyVehicles = { mainTab = "assignments" },
                                            receiptDriverName = if (liveMode) driver.name else null,
                                        )

                                    "assignments" ->
                                        AssignmentsTab(
                                            bindings = bindings,
                                            onOpenScan = { b ->
                                                selectedScan = b
                                                sessionPhase = "idle"
                                                sessionIdle = true
                                                sessionPin = ""
                                                sessionOtpDigits.clearDigits()
                                                scanSessionOtpCountdown = 0
                                                parsedScanQr = null
                                                lastQrPay = null
                                                mainTab = "scan"
                                            },
                                            onOpenTransactions = { b ->
                                                val idx = activeCards.indexOfFirst { it.id == b.id }
                                                if (idx >= 0) activeCard = idx
                                                mainTab = "transactions"
                                            },
                                            onAcceptPending = { b ->
                                                assignmentPick = b
                                                mainOverlay = "assignment_notification"
                                            },
                                            onEnterRepairPairing = { b ->
                                                assignmentPick = b
                                                pairingCodeEntry = ""
                                                pairingError = ""
                                                pairingAttempts = 0
                                                pairingSuccess = false
                                                mainOverlay = "pairing_code"
                                            },
                                        )

                                    "profile" -> {
                                        val prof = apiProfile
                                        val profileSubtitle =
                                            when {
                                                liveMode && prof != null ->
                                                    "Driver · FO ${prof.foStatus?.trim().orEmpty()}"
                                                fleetPinFoDisplay.isNotBlank() -> "Driver · $fleetPinFoDisplay"
                                                else -> "Driver"
                                            }
                                        ProfileTab(
                                            driverDisplayName = driver.name,
                                            initials = driver.initials,
                                            subtitle = profileSubtitle,
                                            maskedMobile = driver.maskedMobile,
                                            registeredDisplay = profileRegisteredFromAssignments(apiAssignments),
                                            fleetOperatorDisplay =
                                                fleetPinFoDisplay.ifBlank { apiHome?.foName.orEmpty() }.ifBlank { "—" },
                                            driverId = prof?.driverId?.takeIf { it.isNotBlank() } ?: "—",
                                            licenceLine = prof?.dlNumber?.trim()?.takeIf { it.isNotEmpty() } ?: "—",
                                            apiAssignments = apiAssignments,
                                            onLogout = {
                                                onFinished(
                                                    FleetSdkResult.Success(
                                                        event = "FLEET_FLOW_COMPLETED",
                                                        payload = mapOf("reason" to "logout"),
                                                    ),
                                                )
                                            },
                                        )
                                    }

                                    else -> Unit
                                }
                            }
                        }
                    }
                }
            }
            }

            ApiErrorBanner(
                message = apiBanner,
                onDismiss = { apiBanner = null },
                modifier =
                    Modifier
                        .align(Alignment.BottomCenter)
                        .zIndex(50f)
                        .fillMaxWidth()
                        .windowInsetsPadding(WindowInsets.navigationBars)
                        .padding(horizontal = 12.dp)
                        .padding(
                            bottom =
                                12.dp + ApiBannerBottomNavClearance +
                                    if (mainShellDockVisible) FleetBottomDockReserve else 0.dp,
                        ),
            )
            if (mainShellDockVisible) {
                val dockSel =
                    if (mainTab == "card" || mainTab == "scan" ||
                        mainTab == "assignments" || mainTab == "profile"
                    ) {
                        mainTab
                    } else {
                        null
                    }
                BottomNav(
                    current = dockSel,
                    onTab = { id ->
                        mainOverlay = "none"
                        assignmentPick = null
                        showDeclineConfirm = false
                        showPairingHelp = false
                        mainTab = id
                    },
                    modifier =
                        Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .zIndex(100f),
                )
            }
            }
        }
    }
}
