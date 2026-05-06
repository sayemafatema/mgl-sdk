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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
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
import androidx.compose.material3.OutlinedButton
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
import com.mgl.fleet.sdk.FleetSdkErrorCodes
import com.mgl.fleet.sdk.FleetSdkException
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.demo.DemoAuthMode
import com.mgl.fleet.sdk.demo.DemoBinding
import com.mgl.fleet.sdk.demo.DemoBindingState
import com.mgl.fleet.sdk.demo.FleetReactMock
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

import java.text.NumberFormat
import java.util.Locale

internal val Green700 = Color(0xFF047857)
internal val Green600 = Color(0xFF059669)
internal val Gray100 = Color(0xFFF3F4F6)
internal val Gray900 = Color(0xFF111827)

private fun Long.inr(): String = NumberFormat.getNumberInstance(Locale("en", "IN")).format(this)

private fun MutableList<String>.clearDigits() {
    for (i in indices) this[i] = ""
}

@Composable
internal fun FleetDriverFlow(
    onFinished: (FleetSdkResult) -> Unit,
) {
    MaterialTheme {
        var onboardingStep by remember { mutableStateOf("login") }
        var isRegistered by remember { mutableStateOf(true) }
        var mobileNumber by remember { mutableStateOf("") }
        val otpDigits = remember { mutableStateListOf("", "", "", "", "", "") }
        var otpError by remember { mutableStateOf("") }
        var otpCountdown by remember { mutableIntStateOf(0) }
        var inviteCode by remember { mutableStateOf("") }
        var inviteOtpDigits by remember { mutableStateOf("") }
        var nuPin by remember { mutableStateOf("") }
        var nuPinConfirm by remember { mutableStateOf("") }
        var pinError by remember { mutableStateOf("") }
        var loginPin by remember { mutableStateOf("") }
        var loginPinError by remember { mutableStateOf("") }
        var wrongAttempts by remember { mutableIntStateOf(0) }
        var disableNumpad by remember { mutableStateOf(false) }
        var shake by remember { mutableStateOf(false) }
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
        val forgotResetOtpDigits = remember { mutableStateListOf("", "", "", "", "", "") }
        var rstPin by remember { mutableStateOf("") }
        var rstPinConfirm by remember { mutableStateOf("") }
        var rstPinError by remember { mutableStateOf("") }
        var pairingAttempts by remember { mutableIntStateOf(0) }
        var pairingSuccess by remember { mutableStateOf(false) }
        var showPairingHelp by remember { mutableStateOf(false) }
        var showOnboardingDevMenu by remember { mutableStateOf(false) }
        val pairingScope = rememberCoroutineScope()

        val bindings = FleetReactMock.bindings
        val driver = FleetReactMock.driver
        val activeCards = remember(bindings) {
            bindings.filter { it.paired && it.state == DemoBindingState.ACTIVE }
        }
        val pendingCount =
            remember(bindings) {
                bindings.count {
                    it.state == DemoBindingState.PENDING_ACCEPTANCE ||
                        (!it.paired && it.state == DemoBindingState.ACTIVE)
                }
            }
        val assignment = remember { FleetReactMock.assignmentForPairing }

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

        fun verifyLoginOtp() {
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
            }
        }

        val assignmentOpen = mainOverlay == "assignment_notification"
        val pairingOpen = mainOverlay == "pairing_code"
        val acceptedOpen = mainOverlay == "assignment_accepted"

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
                        "confirmation" -> sessionPhase = "idle"
                        "otp_entry" -> sessionPhase = "confirmation"
                        "authorized" -> {}
                        "complete" -> {
                            sessionPhase = "idle"
                            sessionPin = ""
                            sessionOtpDigits.clearDigits()
                            mainTab = "card"
                            selectedScan = null
                            sessionIdle = true
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
                "login_otp", "1c" -> {
                    onboardingStep = if (onboardingStep == "1c") "1b" else "login"
                    otpDigits.clearDigits()
                    otpError = ""
                }
                "1b" -> onboardingStep = "login"
                "1d" -> onboardingStep = "1c"
                "1e", "set_pin" -> onboardingStep = if (onboardingStep == "set_pin") "login_otp" else "1d"
                "1f", "confirm_pin" -> onboardingStep = if (onboardingStep.startsWith("1")) "1e" else "set_pin"
                "registered" -> onboardingStep = "confirm_pin"
                "pin_login" -> onboardingStep = "login"
                "forgot_pin" -> onboardingStep = "pin_login"
                "forgot_otp" -> onboardingStep = "forgot_pin"
                "set_pin_reset" -> {
                    onboardingStep = "forgot_otp"
                    rstPin = ""
                    rstPinError = ""
                    forgotResetOtpDigits.clearDigits()
                }
                "confirm_pin_reset" -> onboardingStep = "set_pin_reset"
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
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    when (onboardingStep) {
                        "login" ->
                            LoginScreen(
                                mobileNumber = mobileNumber,
                                onMobileChange = { mobileNumber = it.filter(Char::isDigit).take(10) },
                                onSendOtp = {
                                    otpDigits.clearDigits()
                                    otpError = ""
                                    otpCountdown = 30
                                    onboardingStep = "login_otp"
                                },
                                onInvite = {
                                    inviteCode = ""
                                    onboardingStep = "1b"
                                },
                            )

                        "login_otp" ->
                            LoginOtpScreen(
                                mobileNumber = mobileNumber,
                                otpDigits = otpDigits,
                                otpError = otpError,
                                otpCountdown = otpCountdown,
                                onBack = { onboardingStep = "login" },
                                onResend = { otpCountdown = 30 },
                                onVerifyManual = { verifyLoginOtp() },
                            )

                        "pin_login" ->
                            PinLoginScreen(
                                driverName = driver.name,
                                loginPin = loginPin,
                                loginPinError = loginPinError,
                                disableNumpad = disableNumpad,
                                shake = shake,
                                onDigit = { d ->
                                    if (!disableNumpad && loginPin.length < 6) {
                                        val np = loginPin + d
                                        loginPin = np
                                        loginPinError = ""
                                        if (np.length == 6) {
                                            if (np == driver.pin) {
                                                shake = false
                                                onboardingStep = "complete"
                                            } else {
                                                shake = true
                                                wrongAttempts++
                                                loginPinError = "Incorrect PIN"
                                                loginPin = ""
                                                if (wrongAttempts >= 3) disableNumpad = true
                                            }
                                        }
                                    }
                                },
                                onBackspace = { loginPin = loginPin.dropLast(1) },
                                onForgot = {
                                    onboardingStep = "forgot_pin"
                                    loginPin = ""
                                    loginPinError = ""
                                },
                            )

                        "set_pin" ->
                            SetPinScreen(isNewUser = !isRegistered, pin = nuPin, onDigit = { nuPin = (nuPin + it).take(6) }, onBack = { nuPin = nuPin.dropLast(1) }, onNext = { if (nuPin.length == 6) onboardingStep = "confirm_pin" })

                        "confirm_pin" ->
                            ConfirmPinScreen(pinConfirm = nuPinConfirm, pinError = pinError, onDigit = { nuPinConfirm = (nuPinConfirm + it).take(6) }, onBack = { nuPinConfirm = nuPinConfirm.dropLast(1) }, onSubmit = {
                                if (nuPinConfirm == nuPin) {
                                    pinError = ""
                                    if (!isRegistered) {
                                        onboardingStep = "registered"
                                    } else {
                                        nuPin = ""
                                        nuPinConfirm = ""
                                        isRegistered = true
                                        onboardingStep = "pin_login"
                                    }
                                } else {
                                    pinError = "PINs didn't match. Try again."
                                    nuPinConfirm = ""
                                    onboardingStep = "set_pin"
                                }
                            })

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
                                onCode = { inviteCode = it.uppercase().filter { ch -> ch.isLetterOrDigit() }.take(6) },
                                onBack = { onboardingStep = "login" },
                                onContinue = { if (FleetReactMock.inviteCodes.containsKey(inviteCode)) onboardingStep = "1c" },
                                validCompany = FleetReactMock.inviteCodes[inviteCode],
                            )

                        "1c" ->
                            MobileVerifyInvite(
                                mobile = mobileNumber,
                                onMobile = { mobileNumber = it.filter(Char::isDigit).take(10) },
                                onBack = { onboardingStep = "1b" },
                                onSend = {
                                    otpCountdown = 30
                                    onboardingStep = "1d"
                                },
                            )

                        "1d" ->
                            InviteOtpScreen(
                                mobile = mobileNumber,
                                otp = inviteOtpDigits,
                                onOtpChange = { inviteOtpDigits = it.filter(Char::isDigit).take(6) },
                                onBack = { onboardingStep = "1c" },
                                onVerify = { if (inviteOtpDigits.length == 6) onboardingStep = "1e" },
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
                                onDigit = { nuPinConfirm = (nuPinConfirm + it).take(6) },
                                onBackspace = { nuPinConfirm = nuPinConfirm.dropLast(1) },
                                onSubmit = {
                                    if (nuPinConfirm == nuPin) {
                                        pinError = ""
                                        onboardingStep = "complete"
                                    } else {
                                        pinError = "PINs don't match, try again"
                                        nuPinConfirm = ""
                                    }
                                },
                            )

                        "forgot_pin" ->
                            ForgotPinIntroScreen(
                                maskedMobile = driver.maskedMobile,
                                onBack = { onboardingStep = "pin_login" },
                                onSendOtp = {
                                    forgotResetOtpDigits.clearDigits()
                                    otpCountdown = 30
                                    onboardingStep = "forgot_otp"
                                },
                            )

                        "forgot_otp" ->
                            ForgotResetOtpScreen(
                                otpDigits = forgotResetOtpDigits,
                                otpCountdown = otpCountdown,
                                onBack = { onboardingStep = "forgot_pin" },
                                onResend = { otpCountdown = 30 },
                                onVerify = {
                                    if (forgotResetOtpDigits.joinToString("") == "123456") {
                                        rstPin = ""
                                        rstPinConfirm = ""
                                        rstPinError = ""
                                        nuPin = ""
                                        onboardingStep = "set_pin_reset"
                                    }
                                },
                            )

                        "set_pin_reset" ->
                            SetPinResetScreen(
                                pin = rstPin,
                                onDigit = { rstPin = (rstPin + it).take(6) },
                                onBackspace = { rstPin = rstPin.dropLast(1) },
                                onNext = { if (rstPin.length == 6) onboardingStep = "confirm_pin_reset" },
                            )

                        "confirm_pin_reset" ->
                            ConfirmPinResetScreen(
                                pinConfirm = rstPinConfirm,
                                pinStored = rstPin,
                                pinError = rstPinError,
                                onDigit = { rstPinConfirm = (rstPinConfirm + it).take(6) },
                                onBackspace = { rstPinConfirm = rstPinConfirm.dropLast(1) },
                                onSubmit = {
                                    if (rstPinConfirm == rstPin) {
                                        rstPinError = ""
                                        rstPin = ""
                                        rstPinConfirm = ""
                                        forgotResetOtpDigits.clearDigits()
                                        loginPin = ""
                                        loginPinError = ""
                                        wrongAttempts = 0
                                        disableNumpad = false
                                        onboardingStep = "pin_login"
                                    } else {
                                        rstPinError = "PINs don't match, try again"
                                        rstPinConfirm = ""
                                    }
                                },
                            )

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
                }
            }
            return@MaterialTheme
        }

        // Main shell
        PhoneFrame {
            Column(Modifier.fillMaxSize()) {
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
                                if (pairingCodeEntry == assignment.validPairingCode) {
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
                    if (!sessionIdle && sessionPhase != "idle") {
                        FuelingBanner()
                    }
                    Column(Modifier.weight(1f)) {
                        MainHeader(driverName = driver.name, initials = driver.initials)
                        successToast?.let { t ->
                            Box(Modifier.fillMaxWidth().background(Green600).padding(12.dp)) { Text(t, color = Color.White, fontSize = 13.sp) }
                        }
                        Column(
                            Modifier
                                .weight(1f)
                                .verticalScroll(rememberScrollState()),
                        ) {
                            when (mainTab) {
                                "card" ->
                                    CardTab(
                                        activeCards = activeCards,
                                        activeCard = activeCard,
                                        onCardChange = { activeCard = it },
                                        pendingCount = pendingCount,
                                        onOpenAssignments = { mainTab = "assignments" },
                                        onOpenPendingOverlay = { mainOverlay = "assignment_notification" },
                                        onOpenTransactions = { mainTab = "transactions" },
                                        onScanTab = { mainTab = "scan" },
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
                                        sessionOtpOnChange = { i, ch ->
                                            if (ch.isEmpty()) sessionOtpDigits[i] = ""
                                            else sessionOtpDigits[i] = ch.last().toString().filter(Char::isDigit).takeLast(1)
                                        },
                                        onSimulateScan = {
                                            selectedScan?.let {
                                                sessionIdle = false
                                                sessionPhase = "confirmation"
                                            }
                                        },
                                        onCloseConfirm = {
                                            sessionPhase = "idle"
                                            sessionIdle = true
                                            sessionPin = ""
                                        },
                                        onVerifyPinForSession = {
                                            if (sessionPin == (if (nuPin.length == 6) nuPin else driver.pin)) {
                                                sessionPhase = "otp_entry"
                                                sessionPin = ""
                                            } else sessionPin = ""
                                        },
                                        onVerifySessionOtp = {
                                            if (sessionOtpDigits.joinToString("").length == 6) sessionPhase = "authorized"
                                        },
                                        onFuelingComplete = { sessionPhase = "complete" },
                                        onSessionDone = {
                                            sessionPhase = "idle"
                                            sessionIdle = true
                                            sessionOtpDigits.clearDigits()
                                            mainTab = "card"
                                            selectedScan = null
                                        },
                                    )

                                "assignments" -> AssignmentsTab(bindings = bindings)

                                "transactions" ->
                                    TransactionsTab(
                                        filter = txnFilter,
                                        onFilter = { txnFilter = it },
                                    )

                                "profile" ->
                                    ProfileTab(
                                        mobile = mobileNumber.ifEmpty { driver.mobile },
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
                        }
                    }
                    BottomNav(mainTab, onTab = { mainTab = it })
                    }
                }
            }
        }
    }
}

@Composable
private fun PhoneFrame(content: @Composable () -> Unit) {
    Box(
        Modifier
            .fillMaxSize()
            .background(Gray100)
            .padding(8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            Modifier
                .width(360.dp)
                .fillMaxHeight(0.92f)
                .clip(RoundedCornerShape(28.dp))
                .border(6.dp, Gray900, RoundedCornerShape(28.dp))
                .background(Color.White),
        ) {
            Row(
                Modifier
                    .fillMaxWidth()
                    .background(Gray900)
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text("9:41", color = Color.White, fontSize = 11.sp)
            }
            Box(Modifier.weight(1f)) { content() }
        }
    }
}

@Composable
private fun LoginScreen(
    mobileNumber: String,
    onMobileChange: (String) -> Unit,
    onSendOtp: () -> Unit,
    onInvite: () -> Unit,
) {
    Column(Modifier.fillMaxWidth()) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("MGL Fleet Connect", fontWeight = FontWeight.Bold, fontSize = 20.sp)
            Text("Driver App", fontSize = 11.sp, color = Color.Gray)
        }
        Spacer(Modifier.height(24.dp))
        Text("Mobile number", fontSize = 11.sp, color = Color.Gray)
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box(
                Modifier
                    .border(1.dp, Color.LightGray, RoundedCornerShape(12.dp))
                    .background(Color(0xFFF9FAFB))
                    .padding(horizontal = 12.dp, vertical = 12.dp),
            ) { Text("+91") }
            OutlinedTextField(
                value = mobileNumber,
                onValueChange = onMobileChange,
                modifier = Modifier.weight(1f),
                placeholder = { Text("Enter your mobile number") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                singleLine = true,
            )
        }
        Spacer(Modifier.height(12.dp))
        Button(
            onClick = onSendOtp,
            enabled = mobileNumber.length == 10,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color.LightGray),
        ) { Text("Send OTP") }
        Spacer(Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            HorizontalDivider(Modifier.weight(1f))
            Text(" or ", fontSize = 11.sp, color = Color.Gray, modifier = Modifier.padding(8.dp))
            HorizontalDivider(Modifier.weight(1f))
        }
        OutlinedButton(onClick = onInvite, modifier = Modifier.fillMaxWidth()) { Text("New user? I have an invite code") }
        Spacer(Modifier.height(16.dp))
        Text("By continuing you agree to MGL Fleet Terms of Service", fontSize = 10.sp, color = Color.Gray, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
    }
}

@Composable
private fun LoginOtpScreen(
    mobileNumber: String,
    otpDigits: MutableList<String>,
    otpError: String,
    otpCountdown: Int,
    onBack: () -> Unit,
    onResend: () -> Unit,
    onVerifyManual: () -> Unit,
) {
    Column {
        TextButton(onClick = onBack) { Text("< Back") }
        Text("Verify mobile", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        Spacer(Modifier.height(8.dp))
        Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFEFF6FF)), border = BorderStroke(1.dp, Color(0xFFBFDBFE))) {
            Text("OTP sent to +91 ${mobileNumber.takeLast(4).padStart(10, '•')}", Modifier.padding(12.dp), fontSize = 13.sp)
        }
        Spacer(Modifier.height(16.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            repeat(6) { i ->
                OutlinedTextField(
                    value = otpDigits.getOrElse(i) { "" },
                    onValueChange = { v ->
                        val d = v.filter(Char::isDigit).takeLast(1)
                        if (d.isNotEmpty()) otpDigits[i] = d else otpDigits[i] = ""
                    },
                    modifier = Modifier.width(44.dp).padding(2.dp),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                )
            }
        }
        if (otpError.isNotEmpty()) Text(otpError, color = Color.Red, fontSize = 13.sp, modifier = Modifier.padding(top = 8.dp))
        Spacer(Modifier.height(12.dp))
        Button(
            onClick = onVerifyManual,
            enabled = otpDigits.joinToString("").length == 6,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = Green700),
        ) { Text("Verify") }
        if (otpCountdown > 0) Text("Resend OTP in ${otpCountdown}s", fontSize = 11.sp, color = Color.Gray, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        else TextButton(onClick = onResend, modifier = Modifier.fillMaxWidth()) { Text("Resend OTP", color = Green700) }
    }
}

@Composable
private fun PinLoginScreen(
    driverName: String,
    loginPin: String,
    loginPinError: String,
    disableNumpad: Boolean,
    shake: Boolean,
    onDigit: (String) -> Unit,
    onBackspace: () -> Unit,
    onForgot: () -> Unit,
) {
    val offset by animateFloatAsState(if (shake) 8f else 0f, tween(60), label = "shake")
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
        Text("Welcome back", fontSize = 11.sp, color = Color.Gray)
        Text(driverName, fontWeight = FontWeight.Bold, fontSize = 18.sp)
        Spacer(Modifier.height(16.dp))
        Text("Enter your PIN", fontSize = 11.sp, color = Color.Gray, modifier = Modifier.fillMaxWidth())
        Row(
            Modifier
                .padding(vertical = 12.dp)
                .fillMaxWidth()
                .graphicsLayer { translationX = offset },
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            repeat(6) { i ->
                val filled = i < loginPin.length
                val err = loginPinError.isNotEmpty()
                if (i > 0) Spacer(Modifier.width(10.dp))
                Box(
                    Modifier
                        .size(12.dp)
                        .clip(CircleShape)
                        .background(
                            when {
                                filled && err -> Color.Red
                                filled -> Green700
                                else -> Color.Transparent
                            },
                        )
                        .border(2.dp, if (filled) Color.Transparent else Color.LightGray, CircleShape),
                )
            }
        }
        if (loginPinError.isNotEmpty()) Text(loginPinError, color = Color.Red, fontSize = 12.sp)
        Numpad(enabled = !disableNumpad, onDigit = onDigit, onBackspace = onBackspace)
        if (disableNumpad) {
            Text("Too many attempts.", fontSize = 11.sp, color = Color.Gray, textAlign = TextAlign.Center)
        }
        TextButton(onClick = onForgot) { Text("Forgot PIN?", color = Green700) }
    }
}

@Composable
private fun SetPinScreen(isNewUser: Boolean, pin: String, onDigit: (String) -> Unit, onBack: () -> Unit, onNext: () -> Unit) {
    Column {
        Text(if (isNewUser) "Create your PIN" else "Set new PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        PinDots(pin)
        Numpad(enabled = true, onDigit = onDigit, onBackspace = onBack)
        Button(onClick = onNext, enabled = pin.length == 6, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Next") }
    }
}

@Composable
private fun ConfirmPinScreen(pinConfirm: String, pinError: String, onDigit: (String) -> Unit, onBack: () -> Unit, onSubmit: () -> Unit) {
    Column {
        Text("Confirm your PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        if (pinError.isNotEmpty()) Text(pinError, color = Color.Red, fontSize = 12.sp)
        PinDots(pinConfirm)
        Numpad(enabled = true, onDigit = onDigit, onBackspace = onBack)
        Button(onClick = onSubmit, enabled = pinConfirm.length == 6, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Confirm PIN") }
    }
}

@Composable
private fun RegisteredScreen(onContinue: () -> Unit) {
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(Icons.Filled.Check, null, tint = Green600, modifier = Modifier.size(64.dp))
        Text("PIN created successfully", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = Green700, textAlign = TextAlign.Center)
        Text("You can now use Scan & Pay at any MGL CNG station", fontSize = 13.sp, color = Color.Gray, textAlign = TextAlign.Center)
        Button(onClick = onContinue, modifier = Modifier.fillMaxWidth().padding(top = 24.dp), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Continue to Home") }
    }
}

@Composable
private fun InviteCodeScreen(code: String, onCode: (String) -> Unit, onBack: () -> Unit, onContinue: () -> Unit, validCompany: String?) {
    Column {
        TextButton(onClick = onBack) { Text("< Back") }
        Text("Invite Code", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        OutlinedTextField(value = code, onValueChange = onCode, modifier = Modifier.fillMaxWidth(), singleLine = true)
        validCompany?.let { c ->
            Card(Modifier.fillMaxWidth().padding(vertical = 8.dp), colors = CardDefaults.cardColors(containerColor = Color(0xFFF0FDF4))) {
                Text(c, Modifier.padding(12.dp), fontWeight = FontWeight.Medium)
            }
        }
        Button(onClick = onContinue, enabled = code.length == 6 && validCompany != null, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Continue") }
    }
}

@Composable
private fun MobileVerifyInvite(mobile: String, onMobile: (String) -> Unit, onBack: () -> Unit, onSend: () -> Unit) {
    Column {
        TextButton(onClick = onBack) { Text("< Back") }
        Text("Mobile Verification", fontWeight = FontWeight.Bold)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("+91", Modifier.padding(top = 12.dp))
            OutlinedTextField(mobile, onMobile, Modifier.weight(1f), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone))
        }
        Button(onClick = onSend, enabled = mobile.length == 10, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Send OTP") }
    }
}

@Composable
private fun InviteOtpScreen(mobile: String, otp: String, onOtpChange: (String) -> Unit, onBack: () -> Unit, onVerify: () -> Unit) {
    Column {
        TextButton(onClick = onBack) { Text("< Back") }
        Text("Verify OTP", fontWeight = FontWeight.Bold)
        Text("OTP sent to +91 ${mobile.takeLast(4).padStart(10, '•')}", fontSize = 13.sp)
        OutlinedTextField(otp, onOtpChange, Modifier.fillMaxWidth(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number))
        Button(onClick = onVerify, enabled = otp.length == 6, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Verify OTP") }
    }
}

@Composable
private fun InvitePinSetup(pin: String, onDigit: (String) -> Unit, onBackspace: () -> Unit, onNext: () -> Unit) {
    Column {
        Text("Create your app PIN", fontWeight = FontWeight.Bold)
        PinDots(pin)
        Numpad(true, onDigit, onBackspace)
        Button(onClick = onNext, enabled = pin.length == 6, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Next") }
    }
}

@Composable
private fun InvitePinConfirm(
    pinConfirm: String,
    pinStored: String,
    pinError: String,
    onDigit: (String) -> Unit,
    onBackspace: () -> Unit,
    onSubmit: () -> Unit,
) {
    Column {
        Text("Confirm your PIN", fontWeight = FontWeight.Bold)
        if (pinError.isNotEmpty()) Text(pinError, color = Color.Red)
        PinDots(pinConfirm)
        Numpad(true, onDigit, onBackspace)
        Button(onClick = onSubmit, enabled = pinConfirm.length == 6, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Confirm PIN") }
    }
}

@Composable
private fun PinDots(value: String) {
    Row(Modifier.padding(vertical = 16.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        repeat(6) { i ->
            Box(
                Modifier
                    .size(14.dp)
                    .clip(CircleShape)
                    .background(if (i < value.length) Green700 else Color.Transparent)
                    .border(2.dp, if (i < value.length) Green700 else Color.LightGray, CircleShape),
            )
        }
    }
}

@Composable
private fun Numpad(enabled: Boolean, onDigit: (String) -> Unit, onBackspace: () -> Unit) {
    Column(Modifier.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for (row in listOf(listOf("1", "2", "3"), listOf("4", "5", "6"), listOf("7", "8", "9"))) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { d ->
                    OutlinedButton(
                        onClick = { if (enabled) onDigit(d) },
                        modifier = Modifier.weight(1f),
                        enabled = enabled,
                    ) { Text(d, fontWeight = FontWeight.Bold) }
                }
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = onBackspace, modifier = Modifier.weight(2f), colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFEE2E2), contentColor = Color.Red)) {
                Text("← Backspace")
            }
            OutlinedButton(onClick = { if (enabled) onDigit("0") }, modifier = Modifier.weight(1f), enabled = enabled) { Text("0") }
        }
    }
}

@Composable
private fun FuelingBanner() {
    Row(
        Modifier
            .fillMaxWidth()
            .background(Color(0xFFDBEAFE))
            .border(BorderStroke(1.dp, Color(0xFF93C5FD)))
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text("Fueling in progress · MH 02 AB 1234", fontSize = 12.sp)
    }
}

@Composable
private fun MainHeader(driverName: String, initials: String) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(Green600)
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column {
            Text("Good morning", color = Color(0xFFD1FAE5), fontSize = 13.sp)
            Text(driverName, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 20.sp)
        }
        Box(
            Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.2f)),
            contentAlignment = Alignment.Center,
        ) { Text(initials, color = Color.White, fontWeight = FontWeight.Bold) }
    }
}

@Composable
private fun CardTab(
    activeCards: List<DemoBinding>,
    activeCard: Int,
    onCardChange: (Int) -> Unit,
    pendingCount: Int,
    onOpenAssignments: () -> Unit,
    onOpenPendingOverlay: () -> Unit,
    onOpenTransactions: () -> Unit,
    onScanTab: () -> Unit,
) {
    val card = activeCards.getOrNull(activeCard) ?: return
    Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        if (pendingCount > 0) {
            Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFFFBEB)), border = BorderStroke(1.dp, Color(0xFFFDE68A))) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("$pendingCount assignment(s) need your attention", fontSize = 13.sp, modifier = Modifier.weight(1f))
                    TextButton(onClick = onOpenAssignments) { Text("View", color = Green700) }
                }
            }
            TextButton(onClick = onOpenPendingOverlay) { Text("Open assignment details (demo)", color = Green700, fontSize = 12.sp) }
        }
        Box(Modifier.fillMaxWidth()) {
            if (activeCard > 0) {
                IconButton(onClick = { onCardChange(activeCard - 1) }, modifier = Modifier.align(Alignment.CenterStart)) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, null)
                }
            }
            if (activeCard < activeCards.size - 1) {
                    IconButton(onClick = { onCardChange(activeCard + 1) }, modifier = Modifier.align(Alignment.CenterEnd)) {
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, null)
                    }
            }
            Card(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 28.dp),
                shape = RoundedCornerShape(16.dp),
            ) {
                Box(
                    Modifier
                        .background(
                            Brush.linearGradient(
                                listOf(Green600, Color(0xFF2563EB)),
                                start = Offset.Zero,
                                end = Offset(800f, 800f),
                            ),
                        )
                        .padding(20.dp),
                ) {
                    Column {
                        Text(card.fo.uppercase(Locale.US), color = Color.White.copy(alpha = 0.7f), fontSize = 10.sp)
                        Text(card.vrn, color = Color.White, fontSize = 20.sp, fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold)
                        Spacer(Modifier.height(8.dp))
                        Text(
                            when (card.authMode) {
                                DemoAuthMode.VEHICLE_LINKED -> "Vehicle-linked"
                                DemoAuthMode.SHIFT_BASED -> "Shift · ends ${card.shiftEnd}"
                                DemoAuthMode.TRIP_LINKED -> "Trip · ends ${card.tripEnd}"
                            },
                            color = Color.White.copy(alpha = 0.85f),
                            fontSize = 11.sp,
                        )
                    }
                }
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            activeCards.forEachIndexed { i, _ ->
                Box(
                    Modifier
                        .padding(4.dp)
                        .height(8.dp)
                        .width(if (i == activeCard) 24.dp else 8.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(if (i == activeCard) Green700 else Color.LightGray)
                        .clickable { onCardChange(i) },
                )
            }
        }
        Text("Vehicle Balance", fontSize = 10.sp, color = Color.Gray, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        Text("₹${activeCards[activeCard].balance.inr()}", fontSize = 32.sp, fontWeight = FontWeight.Bold, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        Text("Spend limit ₹${activeCards[activeCard].spendLimit.inr()} per fueling", fontSize = 11.sp, color = Color.Gray, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        Button(onClick = onScanTab, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green600)) {
            Icon(Icons.Filled.QrCode2, null)
            Spacer(Modifier.width(8.dp))
            Text("Scan & Pay")
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Recent", fontWeight = FontWeight.Bold)
            TextButton(onClick = onOpenTransactions) { Text("View all") }
        }
        FleetReactMock.transactions.take(3).forEach { t ->
            Card(Modifier.fillMaxWidth()) {
                Row(Modifier.padding(12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                    Column {
                        Text(t.station, fontWeight = FontWeight.Medium, fontSize = 14.sp)
                        if (t.type == "Fueling") Text(t.vrn, fontSize = 11.sp, color = Color.Gray)
                        Text(t.date, fontSize = 11.sp, color = Color.Gray)
                    }
                    Text("-₹${t.amount.inr()}", color = Color.Red, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun ScanTab(
    bindings: List<DemoBinding>,
    selected: DemoBinding?,
    onSelect: (DemoBinding) -> Unit,
    phase: String,
    sessionPin: String,
    onSessionDigit: (String) -> Unit,
    onSessionBs: () -> Unit,
    sessionOtpDigits: MutableList<String>,
    sessionOtpOnChange: (Int, String) -> Unit,
    onSimulateScan: () -> Unit,
    onCloseConfirm: () -> Unit,
    onVerifyPinForSession: () -> Unit,
    onVerifySessionOtp: () -> Unit,
    onFuelingComplete: () -> Unit,
    onSessionDone: () -> Unit,
) {
    val available =
        bindings.filter {
            it.paired && it.state == DemoBindingState.ACTIVE &&
                (it.scanPayStatus == "always_available" || it.scanPayStatus == "in_window" || it.scanPayStatus == "trip_window")
        }
    Column(Modifier.padding(16.dp)) {
        when (phase) {
            "idle" -> {
                if (available.isEmpty()) {
                    Column {
                        Text("Scan & Pay unavailable", fontWeight = FontWeight.Bold)
                        Text("No vehicles available right now.", fontSize = 13.sp, color = Color.Gray)
                    }
                } else {
                    val sel = selected
                    if (sel == null) {
                        Text("Preparing Scan & Pay…", color = Color.Gray)
                    } else {
                    if (available.size > 1) {
                        Row(Modifier.horizontalScroll(rememberScrollState())) {
                            available.forEach { b ->
                                TextButton(
                                    onClick = { onSelect(b) },
                                    colors =
                                        ButtonDefaults.textButtonColors(
                                            contentColor = if (b.id == sel.id) Color.White else Green700,
                                        ),
                                    modifier =
                                        Modifier
                                            .padding(end = 4.dp)
                                            .background(if (b.id == sel.id) Green600 else Color(0xFFF3F4F6), RoundedCornerShape(16.dp)),
                                ) {
                                    Text(b.vrn)
                                }
                            }
                        }
                    }
                    Text("Fueling: ${sel.vrn}", fontWeight = FontWeight.Medium)
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .aspectRatio(1f)
                            .clip(RoundedCornerShape(16.dp))
                            .background(Color.Black),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.QrCode2, null, tint = Color.White.copy(alpha = 0.5f), modifier = Modifier.size(48.dp))
                    }
                    Button(onClick = onSimulateScan, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) {
                        Text("Simulate Scan")
                    }
                    }
                }
            }
            "confirmation" -> {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Confirm fueling", fontWeight = FontWeight.Bold)
                    IconButton(onClick = onCloseConfirm) { Icon(Icons.Filled.Close, null) }
                }
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(12.dp)) {
                        Text("MGL Hind CNG Filling Station", fontWeight = FontWeight.SemiBold)
                        Text("Andheri, Mumbai", fontSize = 12.sp, color = Color.Gray)
                    }
                }
                selected?.let { b ->
                    Text("Vehicle ${b.vrn}")
                    Text("Balance ₹${b.balance.inr()}")
                }
                Text(
                    text = "Enter your PIN to confirm",
                    modifier = Modifier.padding(top = 8.dp),
                )
                PinDots(sessionPin)
                Numpad(true, onSessionDigit, onSessionBs)
                Button(onClick = onVerifyPinForSession, enabled = sessionPin.length == 6, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) {
                    Text("Verify PIN")
                }
            }
            "otp_entry" -> {
                Text("One-time password", fontWeight = FontWeight.Bold)
                Row(horizontalArrangement = Arrangement.Center, modifier = Modifier.fillMaxWidth()) {
                    repeat(6) { i ->
                        OutlinedTextField(
                            value = sessionOtpDigits[i],
                            onValueChange = { sessionOtpOnChange(i, it) },
                            modifier = Modifier.width(44.dp).padding(4.dp),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        )
                    }
                }
                Button(onClick = onVerifySessionOtp, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Verify & Authorize") }
            }
            "authorized" -> {
                Icon(Icons.Filled.Check, null, tint = Green700, modifier = Modifier.size(48.dp))
                Text("Fueling authorized", fontWeight = FontWeight.Bold)
                Text("Pre-authorized ₹1,200")
                Button(onClick = onFuelingComplete, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) {
                    Text("Fueling Complete")
                }
            }
            "complete" -> {
                Text("Fueling Complete", fontWeight = FontWeight.Bold, fontSize = 20.sp)
                Text("Amount ₹672", fontWeight = FontWeight.Bold, color = Green700)
                Button(onClick = onSessionDone, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Done") }
            }
        }
    }
}

@Composable
private fun AssignmentsTab(bindings: List<DemoBinding>) {
    val active = bindings.filter { it.paired && it.state == DemoBindingState.ACTIVE }
    val pending = bindings.filter { it.state == DemoBindingState.PENDING_ACCEPTANCE }
    val needsAttention = bindings.filter { !it.paired && it.state == DemoBindingState.ACTIVE }

    Column(
        Modifier
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("My Assignments", fontWeight = FontWeight.Bold, fontSize = 22.sp)
        Text(
            "${active.size} active · ${pending.size + needsAttention.size} need attention",
            fontSize = 11.sp,
            color = Color.Gray,
        )

        if (active.isNotEmpty()) {
            Text("ACTIVE", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.Gray)
            active.forEach { b -> AssignmentSummaryCard(binding = b) }
        }

        if (pending.isNotEmpty()) {
            Spacer(Modifier.height(8.dp))
            Text("PENDING ACCEPTANCE", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.Gray)
            pending.forEach { b -> AssignmentSummaryCard(binding = b, highlightPending = true) }
        }

        if (needsAttention.isNotEmpty()) {
            Spacer(Modifier.height(8.dp))
            Text("ATTENTION REQUIRED", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFFB45309))
            needsAttention.forEach { b -> AssignmentSummaryCard(binding = b, needsPairing = true) }
        }

        if (active.isEmpty() && pending.isEmpty() && needsAttention.isEmpty()) {
            Text("No assignments to show.", color = Color.Gray)
        }
    }
}

@Composable
private fun AssignmentSummaryCard(
    binding: DemoBinding,
    highlightPending: Boolean = false,
    needsPairing: Boolean = false,
) {
    val border =
        when {
            needsPairing -> BorderStroke(1.dp, Color(0xFFFDE68A))
            highlightPending -> BorderStroke(1.dp, Color(0xFFFBBF24))
            binding.authMode == DemoAuthMode.VEHICLE_LINKED -> BorderStroke(4.dp, Green700)
            else -> BorderStroke(1.dp, Color.LightGray)
        }
    Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = Color.White), border = border) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(binding.fo.uppercase(Locale.US), fontSize = 10.sp, color = Color.Gray, fontWeight = FontWeight.Medium)
            Text(binding.vrn, fontWeight = FontWeight.Bold, fontSize = 18.sp, fontFamily = FontFamily.Monospace)
            Text(
                when (binding.authMode) {
                    DemoAuthMode.VEHICLE_LINKED -> "Permanent · Vehicle-linked"
                    DemoAuthMode.SHIFT_BASED -> "Mon–Fri · ${binding.shiftStart}–${binding.shiftEnd}"
                    DemoAuthMode.TRIP_LINKED -> "${binding.tripDate} · ${binding.origin} → ${binding.destination}"
                },
                fontSize = 11.sp,
                color = Color.Gray,
            )
            Text(binding.state.name.replace('_', ' ') + " · " + binding.scanPayStatus.replace('_', ' '), fontSize = 10.sp)
            if (needsPairing) {
                Text("Pair to unlock Scan & Pay", fontSize = 11.sp, color = Color(0xFFB45309))
            }
        }
    }
}

@Composable
private fun TransactionsTab(filter: String, onFilter: (String) -> Unit) {
    Column {
        Row(
            Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            listOf("all", "successful", "failed").forEach { f ->
                val selected = filter == f
                TextButton(
                    onClick = { onFilter(f) },
                    modifier = Modifier,
                ) {
                    Text(
                        text = f.replaceFirstChar { it.uppercase() },
                        modifier =
                            Modifier
                                .clip(RoundedCornerShape(16.dp))
                                .background(if (selected) Green600 else Gray100)
                                .padding(horizontal = 14.dp, vertical = 8.dp),
                        color = if (selected) Color.White else Color.DarkGray,
                    )
                }
            }
        }
        val list =
            FleetReactMock.transactions.filter { t ->
                when (filter) {
                    "successful" -> t.status == "Success"
                    "failed" -> t.status == "Failed"
                    else -> true
                }
            }
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            list.forEach { t ->
                Card(Modifier.fillMaxWidth()) {
                    Row(Modifier.padding(12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                        Column {
                            Text(t.station, fontWeight = FontWeight.Medium)
                            Text(t.vrn, fontSize = 11.sp, color = Color.Gray)
                        }
                        Text(
                            "${if (t.type == "Fueling") '-' else '+' }₹${t.amount.inr()}",
                            fontWeight = FontWeight.Bold,
                            color = if (t.type == "Fueling") Color.Red else Green700,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ProfileTab(mobile: String, onLogout: () -> Unit) {
    Column(Modifier.padding(16.dp)) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                Modifier
                    .size(64.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFD1FAE5)),
                contentAlignment = Alignment.Center,
            ) {
                Text(FleetReactMock.driver.initials, color = Green700, fontSize = 18.sp, fontWeight = FontWeight.Bold)
            }
            Text(FleetReactMock.driver.name, fontWeight = FontWeight.Bold, fontSize = 18.sp)
            Text("Driver · ABC Logistics", fontSize = 11.sp, color = Color.Gray)
        }
        Card(Modifier.fillMaxWidth().padding(top = 16.dp)) {
            Column {
                ProfileRow("Mobile", "+91 $mobile")
                ProfileRow("Driver ID", "DRV-00123")
            }
        }
        Card(Modifier.fillMaxWidth().padding(top = 12.dp)) {
            Text("My Vehicles", Modifier.padding(12.dp), fontWeight = FontWeight.Bold)
            FleetReactMock.pairedVehicles.forEach { v ->
                Column(Modifier.padding(12.dp)) {
                    Text(v.vrn, fontWeight = FontWeight.Medium)
                    Text(v.company, fontSize = 11.sp, color = Color.Gray)
                }
                HorizontalDivider()
            }
        }
        OutlinedButton(onClick = onLogout, Modifier.fillMaxWidth().padding(top = 16.dp), border = BorderStroke(2.dp, Color.Red), colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red)) {
            Text("Logout")
        }
    }
}

@Composable
private fun ProfileRow(k: String, v: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(k, fontSize = 13.sp, color = Color.Gray)
        Text(v, fontWeight = FontWeight.Medium, fontSize = 13.sp)
    }
}

@Composable
private fun AssignmentOverlay(
    assignment: DemoBinding,
    onAcceptPair: () -> Unit,
    onDeclineRequest: () -> Unit,
    onBack: () -> Unit,
) {
    Column(
        Modifier
            .fillMaxSize(),
    ) {
        TopAppBar(title = {}, navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, null) } })
        Column(Modifier.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            when (assignment.authMode) {
                DemoAuthMode.VEHICLE_LINKED ->
                    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFF0FDF4)), border = BorderStroke(1.dp, Color(0xFFBBF7D0))) {
                        Column(Modifier.padding(12.dp)) {
                            Text("New vehicle assigned", fontWeight = FontWeight.Bold, color = Color(0xFF14532D))
                            Text("Vehicle-linked · Permanent assignment", fontSize = 12.sp, color = Color(0xFF166534))
                        }
                    }
                DemoAuthMode.SHIFT_BASED ->
                    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFFFBEB)), border = BorderStroke(1.dp, Color(0xFFFDE68A))) {
                        Column(Modifier.padding(12.dp)) {
                            Text("New shift assigned", fontWeight = FontWeight.Bold, color = Color(0xFF78350F))
                            Text("Shift-based · Time-restricted fueling", fontSize = 12.sp)
                        }
                    }
                DemoAuthMode.TRIP_LINKED ->
                    Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFEFF6FF)), border = BorderStroke(1.dp, Color(0xFFBFDBFE))) {
                        Column(Modifier.padding(12.dp)) {
                            Text("New trip assigned", fontWeight = FontWeight.Bold, color = Color(0xFF1E3A8A))
                            Text("Trip-linked · Single trip fueling", fontSize = 12.sp)
                        }
                    }
            }
            Text(assignment.vrn, fontSize = 28.sp, fontFamily = FontFamily.Monospace)
            Text(assignment.fo)
            assignment.assignedBy?.let { Text("Assigned by $it", fontSize = 12.sp, color = Color.Gray) }
            Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFFFBEB)), border = BorderStroke(1.dp, Color(0xFFFBBF24))) {
                Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Pairing required", fontWeight = FontWeight.Bold, color = Color(0xFF78350F))
                    Text(
                        "Enter the 6-digit code from your Fleet Operator to activate fueling.",
                        fontSize = 13.sp,
                    )
                }
            }
        }
        Column(
            Modifier
                .fillMaxWidth()
                .padding(16.dp),
        ) {
            Button(onClick = onAcceptPair, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) { Text("Accept & Pair") }
            OutlinedButton(onClick = onDeclineRequest, modifier = Modifier.fillMaxWidth()) { Text("Decline", color = Color.Red) }
        }
    }
}

@Composable
private fun ForgotPinIntroScreen(
    maskedMobile: String,
    onBack: () -> Unit,
    onSendOtp: () -> Unit,
) {
    Column(Modifier.fillMaxWidth()) {
        TextButton(onClick = onBack) { Text("< Back") }
        Text("Reset your PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        Text("Verify your mobile to reset", fontSize = 13.sp, color = Color.Gray)
        Card(Modifier.fillMaxWidth().padding(vertical = 12.dp), colors = CardDefaults.cardColors(containerColor = Gray100)) {
            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Column {
                    Text(maskedMobile, fontWeight = FontWeight.SemiBold)
                    Text("Your registered mobile number", fontSize = 11.sp, color = Color.Gray)
                }
            }
        }
        Button(onClick = onSendOtp, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) {
            Text("Send OTP")
        }
    }
}

@Composable
private fun ForgotResetOtpScreen(
    otpDigits: MutableList<String>,
    otpCountdown: Int,
    onBack: () -> Unit,
    onResend: () -> Unit,
    onVerify: () -> Unit,
) {
    Column(Modifier.fillMaxWidth()) {
        TextButton(onClick = onBack) { Text("< Back") }
        Text("Verify mobile", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFEFF6FF)), border = BorderStroke(1.dp, Color(0xFFBFDBFE))) {
            Text("OTP sent to +91 ••••••1234", Modifier.padding(12.dp), fontSize = 13.sp)
        }
        Spacer(Modifier.height(12.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            repeat(6) { i ->
                OutlinedTextField(
                    value = otpDigits.getOrElse(i) { "" },
                    onValueChange = { v ->
                        val d = v.filter(Char::isDigit).takeLast(1)
                        otpDigits[i] = d.ifEmpty { "" }.take(1)
                    },
                    modifier = Modifier.width(44.dp).padding(2.dp),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        Button(
            onClick = onVerify,
            enabled = otpDigits.joinToString("").length == 6,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = Green700),
        ) { Text("Verify") }
        if (otpCountdown > 0) {
            Text("Resend OTP in ${otpCountdown}s", fontSize = 11.sp, color = Color.Gray, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        } else {
            TextButton(onClick = onResend, modifier = Modifier.fillMaxWidth()) { Text("Resend OTP", color = Green700) }
        }
    }
}

@Composable
private fun SetPinResetScreen(
    pin: String,
    onDigit: (String) -> Unit,
    onBackspace: () -> Unit,
    onNext: () -> Unit,
) {
    Column(Modifier.fillMaxWidth()) {
        Text("Create new PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        Text("6 digits for fueling authorization", fontSize = 13.sp, color = Color.Gray)
        PinDots(pin)
        Numpad(true, onDigit, onBackspace)
        Button(onClick = onNext, enabled = pin.length == 6, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) {
            Text("Next")
        }
    }
}

@Composable
private fun ConfirmPinResetScreen(
    pinConfirm: String,
    @Suppress("UNUSED_PARAMETER") pinStored: String,
    pinError: String,
    onDigit: (String) -> Unit,
    onBackspace: () -> Unit,
    onSubmit: () -> Unit,
) {
    Column(Modifier.fillMaxWidth()) {
        Text("Confirm new PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp)
        Text("Enter the same PIN again", fontSize = 13.sp, color = Color.Gray)
        if (pinError.isNotEmpty()) {
            Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFEF2F2)), border = BorderStroke(1.dp, Color(0xFFFECACA))) {
                Text(pinError, Modifier.padding(12.dp), color = Color(0xFF991B1B), fontSize = 13.sp)
            }
        }
        PinDots(pinConfirm)
        Numpad(true, onDigit, onBackspace)
        Button(onClick = onSubmit, enabled = pinConfirm.length == 6, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) {
            Text("Confirm PIN")
        }
    }
}

@Composable
private fun AssignmentAcceptedOverlay(
    assignment: DemoBinding,
    onGoAssignments: () -> Unit,
) {
    Column(
        Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(Color(0xFFF0FDF4), Color.White)))
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Icon(Icons.Filled.Check, null, tint = Green600, modifier = Modifier.size(72.dp))
        Text("Assignment activated!", fontWeight = FontWeight.Bold, fontSize = 26.sp, color = Green700, textAlign = TextAlign.Center)
        Text(
            assignment.vrn,
            fontFamily = FontFamily.Monospace,
            fontWeight = FontWeight.Bold,
            modifier =
                Modifier
                    .clip(RoundedCornerShape(24.dp))
                    .background(Color(0xFFDCFCE7))
                    .padding(horizontal = 16.dp, vertical = 8.dp),
            color = Green700,
        )
        Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = Color.White)) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("What's now unlocked", fontWeight = FontWeight.Bold, fontSize = 13.sp)
                when (assignment.authMode) {
                    DemoAuthMode.VEHICLE_LINKED -> {
                        Text("Scan & Pay always available", fontWeight = FontWeight.Medium)
                        Text("You can fuel ${assignment.vrn} at any MGL CNG station at any time", fontSize = 13.sp, color = Color.Gray)
                    }
                    DemoAuthMode.SHIFT_BASED -> {
                        Text("Scan & Pay within shift hours", fontWeight = FontWeight.Medium)
                        Text("Mon–Fri · ${assignment.shiftStart}–${assignment.shiftEnd}", fontSize = 13.sp, color = Color.Gray)
                    }
                    DemoAuthMode.TRIP_LINKED -> {
                        Text("Scan & Pay until ${assignment.tripEnd} today", fontWeight = FontWeight.Medium)
                        Text("${assignment.origin} → ${assignment.destination}", fontSize = 13.sp, color = Color.Gray)
                    }
                }
            }
        }
        Button(onClick = onGoAssignments, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Green700)) {
            Text("Go to My Assignments")
        }
    }
}

@Composable
private fun PairingOverlayExtended(
    assignment: DemoBinding,
    code: String,
    pairingSuccess: Boolean,
    attempts: Int,
    error: String,
    showHelp: Boolean,
    onDismissHelp: () -> Unit,
    onCode: (String) -> Unit,
    onHelp: () -> Unit,
    onBack: () -> Unit,
    onSubmit: () -> Unit,
    onCloseMaxAttempts: () -> Unit,
) {
    Column(Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text("Enter pairing code") },
            navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, null) } },
        )
        Column(Modifier.padding(16.dp).verticalScroll(rememberScrollState())) {
            Card(colors = CardDefaults.cardColors(containerColor = Gray100)) {
                Column(Modifier.padding(12.dp)) {
                    Text(assignment.vrn, fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold, fontSize = 20.sp)
                    Text(
                        when (assignment.authMode) {
                            DemoAuthMode.VEHICLE_LINKED -> "Vehicle-linked"
                            DemoAuthMode.SHIFT_BASED -> "Shift-based"
                            DemoAuthMode.TRIP_LINKED -> "Trip-linked"
                        },
                        fontSize = 11.sp,
                        color = Green700,
                    )
                    Text(assignment.fo, fontSize = 12.sp, color = Color.Gray)
                }
            }
            Text("Enter the 6-digit code your Fleet Operator shared with you", fontSize = 13.sp, color = Color.Gray, modifier = Modifier.padding(vertical = 12.dp))
            OutlinedTextField(
                value = code,
                onValueChange = onCode,
                label = { Text("Pairing code") },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            )
            if (pairingSuccess) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                    Icon(Icons.Filled.Check, null, tint = Green600, modifier = Modifier.size(40.dp))
                    Text("Pairing successful!", fontWeight = FontWeight.Bold, color = Green700)
                    Text("Activating your assignment…", fontSize = 13.sp, color = Color.Gray)
                }
            }
            if (error.isNotEmpty() && !pairingSuccess) {
                Text(error, color = Color.Red, fontSize = 13.sp, modifier = Modifier.padding(top = 8.dp))
            }
            if (attempts >= 3) {
                Card(colors = CardDefaults.cardColors(containerColor = Color(0xFFFEF2F2)), border = BorderStroke(1.dp, Color(0xFFFECACA))) {
                    Column(Modifier.padding(12.dp)) {
                        Text("Too many attempts", fontWeight = FontWeight.Bold, color = Color(0xFF991B1B))
                        Text("Contact your Fleet Operator for a new code.", fontSize = 12.sp)
                    }
                }
                Button(onClick = onCloseMaxAttempts, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) { Text("Close") }
            } else if (!pairingSuccess) {
                Button(
                    onClick = onSubmit,
                    enabled = code.length == 6,
                    modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Green700),
                ) { Text("Verify & Activate") }
            }
            TextButton(onClick = onHelp, modifier = Modifier.fillMaxWidth()) { Text("Haven't received your code?", color = Green700) }
        }
    }
    if (showHelp) {
        AlertDialog(
            onDismissRequest = onDismissHelp,
            title = { Text("Pairing code help") },
            text = {
                Column {
                    Text("Ask your Fleet Operator to share the 6-digit pairing code for this assignment.")
                    Spacer(Modifier.height(8.dp))
                    Text("They can find it in the MGL Fleet portal under Driver Management.", fontSize = 13.sp, color = Color.Gray)
                }
            },
            confirmButton = { TextButton(onDismissHelp) { Text("OK") } },
        )
    }
}

@Composable
private fun BottomNav(current: String, onTab: (String) -> Unit) {
    val items =
        listOf(
            Triple("card", Icons.Filled.Home, "Home"),
            Triple("scan", Icons.Filled.QrCode2, "Scan & Pay"),
            Triple("assignments", Icons.Filled.Route, "Assignments"),
            Triple("profile", Icons.Filled.Person, "Profile"),
        )
    Row(
        Modifier
            .fillMaxWidth()
            .background(Color.White)
            .border(BorderStroke(1.dp, Color(0xFFE5E7EB)))
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceAround,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        items.forEach { (id, icon, label) ->
            Column(
                Modifier
                    .clickable { onTab(id) }
                    .padding(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(icon, null, tint = if (current == id) Green700 else Color.Gray, modifier = Modifier.size(24.dp))
                Text(label, fontSize = 10.sp, color = if (current == id) Green700 else Color.Gray)
            }
        }
    }
}

