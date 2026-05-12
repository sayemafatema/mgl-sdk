@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package com.mgl.fleet.sdk.demo.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.text.BasicTextField
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
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.QrCode2
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mgl.fleet.sdk.R
import com.mgl.fleet.sdk.FleetSdkErrorCodes
import com.mgl.fleet.sdk.FleetSdkException
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.demo.DemoAuthMode
import com.mgl.fleet.sdk.demo.DemoBinding
import com.mgl.fleet.sdk.demo.DemoBindingState
import com.mgl.fleet.sdk.demo.FleetReactMock
import com.mgl.fleet.sdk.demo.DemoTxn
import com.mgl.fleet.sdk.FleetSdkHolder
import com.mgl.fleet.sdk.internal.DriverAppApiClient
import com.mgl.fleet.sdk.internal.DriverHomeJson
import com.mgl.fleet.sdk.internal.DriverAssignmentJson
import com.mgl.fleet.sdk.internal.FoListEntry
import com.mgl.fleet.sdk.internal.FleetpayQrPayload
import com.mgl.fleet.sdk.internal.InviteValidateResult
import com.mgl.fleet.sdk.internal.QrPayResultJson
import com.mgl.fleet.sdk.internal.CheckMobileStatus
import com.mgl.fleet.sdk.internal.DriverProfileJson
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
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

internal fun formatPayApiTxnDate(iso: String?): String {
    val t = iso?.trim().orEmpty()
    if (t.isEmpty()) return "—"
    val fmtLocal =
        DateTimeFormatter.ofLocalizedDateTime(
            FormatStyle.MEDIUM,
            FormatStyle.SHORT,
        ).withLocale(Locale.forLanguageTag("en-IN"))
    return try {
        Instant.parse(t).atZone(ZoneId.systemDefault()).format(fmtLocal)
    } catch (_: Exception) {
        try {
            ZonedDateTime.parse(t).format(fmtLocal)
        } catch (_: Exception) {
            t
        }
    }
}

internal fun demoTxnToDetailRow(t: DemoTxn): DriverTxnRowParse {
    val st =
        when {
            t.status.contains("success", ignoreCase = true) -> "SUCCESS"
            t.status.contains("fail", ignoreCase = true) -> "FAILED"
            else -> t.status.uppercase(Locale.US)
        }
    return DriverTxnRowParse(
        serverTxnId = t.id,
        vehicleRegNo = t.vrn,
        amountINR = t.amount.toDouble(),
        status = st,
        driverName = "",
        createdOn = t.date,
    )
}

internal fun otpBannerLineMobileReactStyle(loginDigits10: String): String {
    val d = loginDigits10.filter(Char::isDigit)
    val last4 =
        when {
            d.length >= 4 -> d.takeLast(4)
            d.isEmpty() -> "••••"
            else -> d.padStart(4, '•')
        }
    val maskedCore = last4.padStart(10, '•')
    return "OTP sent to +91 $maskedCore"
}

internal fun otpScanBannerLine(loginDigits10: String, maskedFromProfile: String?): String {
    val m = maskedFromProfile?.trim()?.takeIf { it.isNotEmpty() } ?: return otpBannerLineMobileReactStyle(loginDigits10)
    return "OTP sent to $m"
}

internal fun formatPrettyVrn(vrn: String?): String {
    val raw = vrn?.trim()?.replace("\\s+".toRegex(), "").orEmpty()
    if (raw.isEmpty()) return "—"
    val upper = raw.uppercase(Locale.ROOT)
    return Regex("^([A-Z]{2})(\\d{2})([A-Z]{1,3})(\\d{1,4})$").matchEntire(upper)?.let { m ->
        "${m.groupValues[1]} ${m.groupValues[2]} ${m.groupValues[3]} ${m.groupValues[4]}"
    } ?: (vrn?.trim()?.ifEmpty { "—" } ?: "—")
}

internal fun indiaGreeting(): String {
    val h = ZonedDateTime.now(ZoneId.of("Asia/Kolkata")).hour
    return when {
        h in 5..11 -> "Good Morning"
        h in 12..16 -> "Good Afternoon"
        else -> "Good Evening"
    }
}

internal fun profileRegisteredFromAssignments(assignments: List<DriverAssignmentJson>): String {
    val instants =
        assignments.mapNotNull { a ->
            val s = a.assignedAt?.trim().orEmpty()
            if (s.isEmpty()) return@mapNotNull null
            runCatching { Instant.parse(s) }.getOrNull()
        }
    if (instants.isEmpty()) return "—"
    val min = instants.minOrNull() ?: return "—"
    return min
        .atZone(ZoneId.of("Asia/Kolkata"))
        .toLocalDateTime()
        .format(DateTimeFormatter.ofPattern("d MMM yyyy, h:mm a", Locale.ENGLISH))
}

internal fun txnSubtitleParts(txn: DemoTxn): Pair<String, String> {
    val raw = txn.date
    if ('T' in raw) {
        val d = raw.substringBefore('T')
        val t = raw.substringAfter('T', "").take(5)
        return d to t
    }
    val m = Regex("\\d{1,2}:\\d{2}").find(raw)
    val time = m?.value ?: ""
    val day = raw.replace(Regex("\\d{1,2}:\\d{2}"), "").trim().trimEnd(',').trim()
    return ((if (day.isEmpty()) raw else day) to time)
}

internal fun txnStatusIsSuccess(status: String): Boolean =
    status.equals("SUCCESS", ignoreCase = true) || status.equals("Success", ignoreCase = true)

internal fun txnRowIsCredit(t: DemoTxn): Boolean {
    if (t.type.equals("credit", ignoreCase = true)) return true
    return Regex("credit|top-up|top up|wallet|neft", RegexOption.IGNORE_CASE).containsMatchIn(t.status)
}

private val ReactTextPrimary = Color(0xFF1A202C)
private val ReactTextMuted = Color(0xFF718096)
private val ReactPlaceholder = Color(0xFF94A3B8)
private val ReactGreenBtn = Color(0xFF43A047)
private val ReactDisabledBg = Color(0xFFE2E8F0)
private val ReactDisabledText = Color(0xFF94A3B8)
private val ReactRedBg = Color(0xFFFEF2F2)
private val ReactRedBorder = Color(0xFFFECACA)
private val ReactRedText = Color(0xFF7F1D1D)
private val ReactCardBorder = Color(0xFFE5E7EB)
private val ReactLogoBg = Color(0xFF3F3F46)
private val ReactLogoBorder = Color(0xFF52525B)
private val ReactGray500 = Color(0xFF6B7280)
private val ReactHeaderBg = Color(0xFF1A3020)
private val ReactHeaderMuted = Color(0xFFC8E6C9)
private val ReactHeaderAvatar = Color(0xFF2D4A36)
private val ReactMutedGreenLink = Color(0xFF2E7D32)
private val TabShellBg = Color(0xFFECEFF1)

internal const val VALID_MOBILE_ERROR_TEXT = "Please enter a valid mobile number"

@Composable
internal fun PhoneFrame(content: @Composable () -> Unit) {
    Box(Modifier.fillMaxSize()) { content() }
}

@Composable
private fun OnboardingBackRow(onClick: () -> Unit) {
    TextButton(
        onClick = onClick,
        contentPadding = PaddingValues(0.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Start,
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, tint = ReactGray500, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
            Text("Back", color = ReactGray500, fontSize = 14.sp)
        }
    }
}

@Composable
private fun SixDigitOtpFields(
    digits: MutableList<String>,
    modifier: Modifier = Modifier,
) {
    val focusRequesters = remember { List(6) { FocusRequester() } }
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(6) { idx ->
            OutlinedTextField(
                value = digits[idx],
                onValueChange = { v: String ->
                    if (v.isEmpty()) {
                        digits[idx] = ""
                        if (idx > 0) focusRequesters[idx - 1].requestFocus()
                    } else {
                        val d = v.filter { it.isDigit() }.takeLast(1)
                        digits[idx] = d
                        if (d.isNotEmpty() && idx < 5) focusRequesters[idx + 1].requestFocus()
                    }
                },
                modifier =
                    Modifier
                        .width(56.dp)
                        .height(68.dp)
                        .focusRequester(focusRequesters[idx]),
                textStyle =
                    TextStyle(
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                    ),
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            )
        }
    }
}

@Composable
internal fun LoginScreen(
    mobileNumber: String,
    onMobileChange: (String) -> Unit,
    onSendOtp: () -> Unit,
    onInvite: () -> Unit,
    showMobileFormatError: Boolean,
    isSendingOtp: Boolean,
) {
    val canSubmit = validIndianMobile10(mobileNumber)
    Column(
        Modifier
            .fillMaxWidth()
            .widthIn(max = 448.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .border(1.dp, ReactLogoBorder.copy(alpha = 0.8f), RoundedCornerShape(8.dp))
                    .background(ReactLogoBg)
                    .padding(horizontal = 10.dp, vertical = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Image(
                    painter = painterResource(id = R.drawable.mgl_logo),
                    contentDescription = "MGL Fleet",
                    modifier =
                        Modifier
                            .height(36.dp)
                            .widthIn(max = 120.dp),
                    contentScale = ContentScale.Fit,
                )
            }
            Spacer(Modifier.height(12.dp))
            Text("Driver App", fontSize = 20.sp, fontWeight = FontWeight.Medium, color = ReactGray500)
        }
        Spacer(Modifier.height(24.dp))
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            border = BorderStroke(1.dp, ReactCardBorder),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        ) {
            Column(Modifier.padding(24.dp)) {
                Text(
                    "Sign in to continue",
                    fontSize = 18.sp,
                    lineHeight = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = ReactTextPrimary,
                )
                Spacer(Modifier.height(24.dp))
                Text("Mobile number", fontSize = 14.sp, fontWeight = FontWeight.Normal, color = ReactTextMuted)
                Spacer(Modifier.height(8.dp))
                if (showMobileFormatError) {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = ReactRedBg),
                        border = BorderStroke(1.dp, ReactRedBorder),
                        shape = RoundedCornerShape(12.dp),
                    ) {
                        Text(
                            VALID_MOBILE_ERROR_TEXT,
                            Modifier.padding(12.dp),
                            fontSize = 14.sp,
                            color = ReactRedText,
                        )
                    }
                    Spacer(Modifier.height(8.dp))
                }
                Row(
                    Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .border(1.dp, ReactCardBorder, RoundedCornerShape(12.dp))
                        .background(Color.White),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        "+91",
                        Modifier.padding(horizontal = 12.dp),
                        fontSize = 14.sp,
                        color = ReactTextMuted,
                    )
                    Box(Modifier.fillMaxHeight().width(1.dp).background(ReactCardBorder))
                    BasicTextField(
                        value = mobileNumber,
                        onValueChange = { onMobileChange(it.filter(Char::isDigit).take(10)) },
                        modifier =
                            Modifier
                                .weight(1f)
                                .padding(horizontal = 12.dp, vertical = 12.dp),
                        textStyle = TextStyle(fontSize = 14.sp, color = ReactTextPrimary),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                        decorationBox = { innerTextField ->
                            Box {
                                if (mobileNumber.isEmpty()) {
                                    Text("98765 01234", fontSize = 14.sp, color = ReactPlaceholder)
                                }
                                innerTextField()
                            }
                        },
                    )
                }
                Button(
                    onClick = onSendOtp,
                    enabled = canSubmit && !isSendingOtp,
                    modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = ReactGreenBtn,
                        disabledContainerColor = ReactDisabledBg,
                        contentColor = Color.White,
                        disabledContentColor = ReactDisabledText,
                    ),
                    contentPadding = PaddingValues(vertical = 14.dp),
                ) {
                    if (isSendingOtp) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            CircularProgressIndicator(
                                Modifier.size(20.dp),
                                color = Color.White,
                                strokeWidth = 2.dp,
                            )
                            Text("Sending…", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                        }
                    } else {
                        Text("Send OTP", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
                Spacer(Modifier.height(24.dp))
                HorizontalDivider(color = ReactCardBorder)
                Spacer(Modifier.height(24.dp))
                OutlinedButton(
                    onClick = onInvite,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    border = BorderStroke(1.dp, ReactCardBorder),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = ReactTextPrimary),
                ) {
                    Text("New user? I have an invite code", fontSize = 14.sp, fontWeight = FontWeight.Medium)
                }
            }
        }
        Spacer(Modifier.height(16.dp))
        Text(
            "By continuing, I agree to MGL Fleet Terms of Service",
            fontSize = 12.sp,
            color = ReactPlaceholder,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
internal fun LoginOtpScreen(
    mobileNumber: String,
    otpDigits: MutableList<String>,
    otpError: String,
    otpCountdown: Int,
    onBack: () -> Unit,
    onResend: () -> Unit,
    onVerifyManual: () -> Unit,
    isVerifying: Boolean,
    isResending: Boolean,
) {
    Column(Modifier.fillMaxWidth()) {
        OnboardingBackRow(onBack)
        Text("Verify mobile", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = ReactTextPrimary)
        Spacer(Modifier.height(8.dp))
        Card(
            colors = CardDefaults.cardColors(containerColor = Color(0xFFEFF6FF)),
            border = BorderStroke(1.dp, Color(0xFFBFDBFE)),
            shape = RoundedCornerShape(12.dp),
        ) {
            Text(
                "OTP sent to +91 ${mobileNumber.takeLast(4).padStart(10, '•')}",
                Modifier.padding(12.dp),
                fontSize = 14.sp,
                color = Color(0xFF1E3A8A),
            )
        }
        Spacer(Modifier.height(24.dp))
        SixDigitOtpFields(otpDigits)
        if (otpError.isNotEmpty()) {
            Text(otpError, color = Color.Red, fontSize = 13.sp, modifier = Modifier.padding(top = 8.dp))
        }
        Spacer(Modifier.height(12.dp))
        Button(
            onClick = onVerifyManual,
            enabled = otpDigits.joinToString("").length == 6 && !isVerifying && !isResending,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color(0xFFD1D5DB)),
        ) {
            if (isVerifying) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                    Text("Verifying…")
                }
            } else {
                Text("Verify", fontWeight = FontWeight.Medium)
            }
        }
        Spacer(Modifier.height(12.dp))
        if (otpCountdown > 0) {
            Text(
                "Resend OTP in ${otpCountdown}s",
                fontSize = 12.sp,
                color = ReactGray500,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center,
            )
        } else {
            TextButton(
                onClick = onResend,
                enabled = !isResending && !isVerifying,
                modifier = Modifier.fillMaxWidth(),
            ) {
                if (isResending) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(Modifier.size(16.dp), color = Green700, strokeWidth = 2.dp)
                        Text("Sending…", color = Green700, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                    }
                } else {
                    Text("Resend OTP", color = Green700, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                }
            }
        }
    }
}

@Composable
internal fun SetPinScreen(isNewUser: Boolean, pin: String, onDigit: (String) -> Unit, onBack: () -> Unit, onNext: () -> Unit) {
    Column(Modifier.fillMaxWidth()) {
        Text(
            if (isNewUser) "Create your PIN" else "Set new PIN",
            fontWeight = FontWeight.Bold,
            fontSize = 20.sp,
            color = ReactTextPrimary,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            if (isNewUser) "You'll use this every time you sign in" else "Choose a new 6-digit PIN",
            fontSize = 14.sp,
            color = ReactGray500,
        )
        Spacer(Modifier.height(24.dp))
        PinDots(pin)
        Numpad(enabled = true, onDigit = onDigit, onBackspace = onBack)
        Button(
            onClick = onNext,
            enabled = pin.length == 6,
            modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color(0xFFD1D5DB)),
        ) { Text("Next", fontWeight = FontWeight.Medium) }
    }
}

@Composable
internal fun ConfirmPinScreen(
    pinConfirm: String,
    pinError: String,
    onDigit: (String) -> Unit,
    onBackNavigation: () -> Unit,
    onBackspace: () -> Unit,
    onSubmit: () -> Unit,
) {
    Column(Modifier.fillMaxWidth()) {
        OnboardingBackRow(onBackNavigation)
        Text("Confirm your PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = ReactTextPrimary)
        Spacer(Modifier.height(8.dp))
        Text("Enter the same PIN again", fontSize = 14.sp, color = ReactGray500)
        Spacer(Modifier.height(24.dp))
        if (pinError.isNotEmpty()) Text(pinError, color = Color.Red, fontSize = 12.sp, modifier = Modifier.padding(bottom = 8.dp))
        PinDots(pinConfirm)
        Numpad(enabled = true, onDigit = onDigit, onBackspace = onBackspace)
        Button(
            onClick = onSubmit,
            enabled = pinConfirm.length == 6,
            modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color(0xFFD1D5DB)),
        ) { Text("Confirm PIN", fontWeight = FontWeight.Medium) }
    }
}

@Composable
internal fun RegisteredScreen(onContinue: () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .background(Brush.verticalGradient(listOf(Color(0xFFF0FDF4), Color.White)))
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(Icons.Filled.Check, null, tint = Green600, modifier = Modifier.size(80.dp))
        Spacer(Modifier.height(24.dp))
        Text("PIN created successfully", fontWeight = FontWeight.Bold, fontSize = 30.sp, color = Green700, textAlign = TextAlign.Center)
        Spacer(Modifier.height(12.dp))
        Text("You can now use Scan & Pay at any MGL CNG station", fontSize = 14.sp, color = ReactGray500, textAlign = TextAlign.Center)
        Button(
            onClick = onContinue,
            modifier = Modifier.fillMaxWidth().padding(top = 32.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700),
        ) { Text("Continue to Home", fontWeight = FontWeight.Medium) }
    }
}

@Composable
internal fun InviteCodeScreen(
    code: String,
    onCode: (String) -> Unit,
    onBack: () -> Unit,
    onContinue: () -> Unit,
    previewDriverName: String?,
    previewFoName: String?,
    continueEnabled: Boolean,
    isContinuing: Boolean,
) {
    Column(Modifier.fillMaxWidth()) {
        OnboardingBackRow(onBack)
        Text("Invite Code", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = ReactTextPrimary)
        Spacer(Modifier.height(8.dp))
        Text("Enter the code shared by your Fleet Operator", fontSize = 14.sp, color = ReactGray500)
        Spacer(Modifier.height(24.dp))
        OutlinedTextField(
            value = code,
            onValueChange = onCode,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            textStyle = TextStyle(textAlign = TextAlign.Center, letterSpacing = 4.sp, fontWeight = FontWeight.Bold, fontSize = 18.sp),
            shape = RoundedCornerShape(16.dp),
            placeholder = { Text("A3K9M2…", textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth()) },
        )
        if (previewDriverName != null && previewFoName != null) {
            Spacer(Modifier.height(16.dp))
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color(0xFFF0FDF4)),
                border = BorderStroke(1.dp, Color(0xFF86EFAC)),
                shape = RoundedCornerShape(16.dp),
            ) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.Top) {
                    Icon(Icons.Filled.Check, null, tint = Green700, modifier = Modifier.padding(top = 2.dp))
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(previewDriverName, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = Color(0xFF14532D))
                        Text(previewFoName, fontSize = 12.sp, color = Color(0xFF166534))
                    }
                }
            }
        }
        Spacer(Modifier.height(16.dp))
        Button(
            onClick = onContinue,
            enabled = continueEnabled && !isContinuing,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color(0xFFD1D5DB)),
        ) {
            if (isContinuing) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                    Text("Checking…")
                }
            } else {
                Text("Continue", fontWeight = FontWeight.Medium)
            }
        }
    }
}

@Composable
internal fun MobileVerifyInvite(
    mobile: String,
    onMobile: (String) -> Unit,
    onBack: () -> Unit,
    onSend: () -> Unit,
    showMobileFormatError: Boolean,
    isSending: Boolean,
) {
    Column(Modifier.fillMaxWidth()) {
        OnboardingBackRow(onBack)
        Text("Mobile Verification", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = ReactTextPrimary)
        Spacer(Modifier.height(8.dp))
        Text("Must match number your Fleet Operator provided", fontSize = 14.sp, color = ReactGray500)
        Spacer(Modifier.height(24.dp))
        if (showMobileFormatError) {
            Card(
                colors = CardDefaults.cardColors(containerColor = ReactRedBg),
                border = BorderStroke(1.dp, Color(0xFFFECACA)),
                shape = RoundedCornerShape(16.dp),
            ) {
                Text(VALID_MOBILE_ERROR_TEXT, Modifier.padding(12.dp), fontSize = 14.sp, color = ReactRedText)
            }
            Spacer(Modifier.height(16.dp))
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("+91", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = ReactGray500, modifier = Modifier.padding(top = 10.dp))
            OutlinedTextField(
                mobile,
                onMobile,
                Modifier.weight(1f),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                placeholder = { Text("98765 43210") },
                shape = RoundedCornerShape(16.dp),
            )
        }
        Spacer(Modifier.height(16.dp))
        Button(
            onClick = onSend,
            enabled = validIndianMobile10(mobile) && !isSending,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color(0xFFD1D5DB)),
        ) {
            if (isSending) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                    Text("Sending…")
                }
            } else {
                Text("Send OTP", fontWeight = FontWeight.Medium)
            }
        }
    }
}

@Composable
internal fun InviteOtpScreen(
    mobile: String,
    otpDigits: MutableList<String>,
    otpCountdown: Int,
    onBack: () -> Unit,
    onVerify: () -> Unit,
    onResend: () -> Unit,
    isVerifying: Boolean,
    isResending: Boolean,
) {
    Column(Modifier.fillMaxWidth()) {
        OnboardingBackRow(onBack)
        Text("Verify OTP", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = ReactTextPrimary)
        Spacer(Modifier.height(12.dp))
        Card(
            colors = CardDefaults.cardColors(containerColor = Color(0xFFEFF6FF)),
            border = BorderStroke(1.dp, Color(0xFFBFDBFE)),
            shape = RoundedCornerShape(16.dp),
        ) {
            Text(
                "OTP sent to +91 ${mobile.takeLast(4).padStart(10, '•')}",
                Modifier.padding(12.dp),
                fontSize = 14.sp,
                color = Color(0xFF1E3A8A),
            )
        }
        Spacer(Modifier.height(16.dp))
        SixDigitOtpFields(otpDigits)
        Spacer(Modifier.height(12.dp))
        Button(
            onClick = onVerify,
            enabled = otpDigits.joinToString("").length == 6 && !isVerifying && !isResending,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color(0xFFD1D5DB)),
        ) {
            if (isVerifying) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                    Text("Verifying…")
                }
            } else {
                Text("Verify OTP", fontWeight = FontWeight.Medium)
            }
        }
        Spacer(Modifier.height(8.dp))
        if (otpCountdown > 0) {
            Text(
                "Resend OTP in ${otpCountdown}s",
                fontSize = 12.sp,
                color = ReactGray500,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center,
            )
        } else {
            TextButton(onClick = onResend, enabled = !isResending && !isVerifying, modifier = Modifier.fillMaxWidth()) {
                if (isResending) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(Modifier.size(16.dp), color = Green700, strokeWidth = 2.dp)
                        Text("Sending…", color = Green700)
                    }
                } else {
                    Text("Resend OTP", color = Green700, fontWeight = FontWeight.Medium)
                }
            }
        }
    }
}

@Composable
internal fun InvitePinSetup(pin: String, onDigit: (String) -> Unit, onBackspace: () -> Unit, onNext: () -> Unit) {
    Column(Modifier.fillMaxWidth()) {
        Text("Create your app PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = ReactTextPrimary)
        Spacer(Modifier.height(8.dp))
        Text("6 digits for fleet login and fuel authorization", fontSize = 14.sp, color = ReactGray500)
        Spacer(Modifier.height(24.dp))
        PinDots(pin)
        Numpad(true, onDigit, onBackspace)
        Button(
            onClick = onNext,
            enabled = pin.length == 6,
            modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color(0xFFD1D5DB)),
        ) { Text("Next", fontWeight = FontWeight.Medium) }
    }
}

@Composable
internal fun InvitePinConfirm(
    pinConfirm: String,
    pinStored: String,
    pinError: String,
    onDigit: (String) -> Unit,
    onBackspace: () -> Unit,
    onBackNavigation: () -> Unit,
    onSubmit: () -> Unit,
    isSubmitting: Boolean,
) {
    Column(Modifier.fillMaxWidth()) {
        OnboardingBackRow(onBackNavigation)
        Text("Confirm your PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = ReactTextPrimary)
        Spacer(Modifier.height(8.dp))
        Text("Enter the same PIN again", fontSize = 14.sp, color = ReactGray500)
        Spacer(Modifier.height(24.dp))
        if (pinError.isNotEmpty()) Text(pinError, color = Color.Red, fontSize = 13.sp)
        PinDots(pinConfirm)
        Numpad(true, onDigit, onBackspace)
        Button(
            onClick = onSubmit,
            enabled = pinConfirm.length == 6 && !isSubmitting,
            modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = Color(0xFFD1D5DB)),
        ) {
            if (isSubmitting) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                    Text("Saving…")
                }
            } else {
                Text("Confirm PIN", fontWeight = FontWeight.Medium)
            }
        }
    }
}

@Composable
internal fun PinDots(value: String) {
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
internal fun Numpad(enabled: Boolean, onDigit: (String) -> Unit, onBackspace: () -> Unit) {
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
internal fun FuelingBanner() {
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
internal fun MainHeader(driverName: String, initials: String) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(ReactHeaderBg)
            .padding(horizontal = 20.dp, vertical = 20.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column {
            Text(indiaGreeting(), color = ReactHeaderMuted, fontSize = 14.sp)
            Spacer(Modifier.height(2.dp))
            Text(driverName, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 20.sp)
        }
        Box(
            Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(ReactHeaderAvatar)
                .border(2.dp, Color.White.copy(alpha = 0.1f), CircleShape),
            contentAlignment = Alignment.Center,
        ) { Text(initials, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 14.sp) }
    }
}

@Composable
internal fun CardTab(
    fleetPinFoDisplay: String,
    apiHome: DriverHomeJson?,
    activeCards: List<DemoBinding>,
    activeCard: Int,
    onCardChange: (Int) -> Unit,
    pendingCount: Int,
    onOpenAssignments: () -> Unit,
    onOpenTransactions: () -> Unit,
    onScanTab: () -> Unit,
    recentTransactions: List<DemoTxn>,
) {
    val homeEmptyNoVehicle = activeCards.isEmpty()
    val homeEmptyNoTransactions = recentTransactions.isEmpty()
    fun foLine(card: DemoBinding): String =
        when {
            fleetPinFoDisplay.isNotBlank() -> fleetPinFoDisplay
            apiHome?.foName?.isNotBlank() == true -> apiHome.foName!!
            else -> card.fo
        }
    @Composable
    fun PendingBanner() {
        if (pendingCount <= 0) return
        Card(
            colors = CardDefaults.cardColors(containerColor = Color(0xFFFFFBEB)),
            border = BorderStroke(1.dp, Color(0xFFFDE68A)),
            shape = RoundedCornerShape(12.dp),
        ) {
            Row(
                Modifier
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(
                    "$pendingCount assignment${if (pendingCount > 1) "s" else ""} need your attention",
                    fontSize = 14.sp,
                    color = Color(0xFF78350F),
                    modifier = Modifier.weight(1f),
                )
                TextButton(onClick = onOpenAssignments) {
                    Text("View", color = ReactMutedGreenLink, fontWeight = FontWeight.Medium, fontSize = 14.sp)
                }
            }
        }
    }
    @Composable
    fun RecentRows(list: List<DemoTxn>, showViewAll: Boolean) {
        Row(Modifier.fillMaxWidth().padding(top = 16.dp, bottom = 8.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            Text("Recent", fontWeight = FontWeight.SemiBold, fontSize = 16.sp, color = ReactTextPrimary)
            if (showViewAll && list.isNotEmpty()) {
                TextButton(
                    onClick = onOpenTransactions,
                    contentPadding = PaddingValues(0.dp),
                ) {
                    Text("View all", color = ReactMutedGreenLink, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                }
            }
        }
        if (list.isEmpty()) {
            Card(
                Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, Color(0xFFF3F4F6)),
            ) {
                Column(
                    Modifier.padding(horizontal = 14.dp, vertical = 40.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Box(
                        Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF9FAFB)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.History, null, tint = Color(0xFF9CA3AF), modifier = Modifier.size(28.dp))
                    }
                    Spacer(Modifier.height(16.dp))
                    Text("No transactions yet", fontWeight = FontWeight.Medium, color = ReactTextPrimary)
                    Spacer(Modifier.height(4.dp))
                    Text(
                        "Fuel payments and wallet activity will show here once you use Scan & Pay.",
                        fontSize = 12.sp,
                        color = ReactTextMuted,
                        textAlign = TextAlign.Center,
                    )
                }
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                list.take(3).forEach { t ->
                    val credit = txnRowIsCredit(t)
                    val (day, clock) = txnSubtitleParts(t)
                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        border = BorderStroke(1.dp, Color(0xFFF3F4F6)),
                    ) {
                        Row(
                            Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Box(
                                Modifier
                                    .size(40.dp)
                                    .clip(CircleShape)
                                    .background(if (credit) Color(0xFFF0FDF4) else Color(0xFFFEF2F2)),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(
                                    if (credit) "↑" else "↓",
                                    color = if (credit) Color(0xFF15803D) else Color(0xFFDC2626),
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Bold,
                                )
                            }
                            Column(Modifier.weight(1f)) {
                                Text(
                                    t.station,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 14.sp,
                                    color = ReactTextPrimary,
                                    maxLines = 1,
                                )
                                Text(
                                    "${t.vrn} · $day",
                                    fontSize = 12.sp,
                                    color = ReactTextMuted,
                                    maxLines = 1,
                                )
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text(
                                    "${if (credit) "+" else "-"}₹${t.amount.inr()}",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = if (credit) Color(0xFF16A34A) else ReactTextPrimary,
                                )
                                if (clock.isNotEmpty()) {
                                    Text(clock, fontSize = 12.sp, color = Color(0xFF9CA3AF))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        PendingBanner()
        if (!homeEmptyNoVehicle) {
            val card = activeCards.getOrNull(activeCard) ?: activeCards.first()
            val badgeBg: Color
            val badgeFg: Color
            val badgeText: String
            when (card.authMode) {
                DemoAuthMode.VEHICLE_LINKED -> {
                    badgeBg = Color(0xFFE8F5E9)
                    badgeFg = Color(0xFF1B5E20)
                    badgeText = "Vehicle-linked"
                }
                DemoAuthMode.SHIFT_BASED -> {
                    badgeBg = Color(0xFFFEF3C7)
                    badgeFg = Color(0xFF92400E)
                    badgeText = "Shift · ends ${card.shiftEnd}"
                }
                DemoAuthMode.TRIP_LINKED -> {
                    badgeBg = Color(0xFFDBEAFE)
                    badgeFg = Color(0xFF1E40AF)
                    badgeText = "Trip · ends ${card.tripEnd}"
                }
            }
            Box(Modifier.fillMaxWidth()) {
                if (activeCard > 0) {
                    IconButton(onClick = { onCardChange(activeCard - 1) }, modifier = Modifier.align(Alignment.CenterStart)) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, null, tint = ReactTextMuted)
                    }
                }
                if (activeCard < activeCards.size - 1) {
                    IconButton(onClick = { onCardChange(activeCard + 1) }, modifier = Modifier.align(Alignment.CenterEnd)) {
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, null, tint = ReactTextMuted)
                    }
                }
                Card(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 8.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    border = BorderStroke(1.dp, ReactCardBorder),
                ) {
                    Column(Modifier.padding(20.dp)) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(
                                foLine(card),
                                fontSize = 14.sp,
                                color = Color(0xFF4B5563),
                                modifier = Modifier.weight(1f).padding(end = 8.dp),
                            )
                            Text(
                                badgeText,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = badgeFg,
                                modifier =
                                    Modifier
                                        .clip(RoundedCornerShape(6.dp))
                                        .background(badgeBg)
                                        .padding(horizontal = 10.dp, vertical = 4.dp),
                            )
                        }
                        Text(
                            card.vrn,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold,
                            color = ReactTextPrimary,
                            fontFamily = FontFamily.Monospace,
                            modifier = Modifier.padding(top = 16.dp),
                        )
                        HorizontalDivider(Modifier.padding(top = 16.dp), color = Color(0xFFF3F4F6))
                        Spacer(Modifier.height(16.dp))
                        Text(
                            "VEHICLE BALANCE",
                            fontSize = 10.sp,
                            letterSpacing = 2.2.sp,
                            color = Color(0xFF9CA3AF),
                            fontWeight = FontWeight.Medium,
                        )
                        Text(
                            "₹${card.balance.inr()}",
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold,
                            color = ReactTextPrimary,
                            modifier = Modifier.padding(top = 8.dp),
                        )
                        if (card.incentiveBalance > 0) {
                            Text(
                                "Card ₹${card.cardBalance.inr()} · Incentive ₹${card.incentiveBalance.inr()}",
                                fontSize = 12.sp,
                                color = Color(0xFF6B7280),
                                modifier = Modifier.padding(top = 8.dp),
                            )
                        }
                    }
                }
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                activeCards.forEachIndexed { i, _ ->
                    Box(
                        Modifier
                            .padding(horizontal = 4.dp)
                            .height(8.dp)
                            .width(if (i == activeCard) 28.dp else 8.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(if (i == activeCard) ReactGreenBtn else Color(0xFFD1D5DB))
                            .clickable { onCardChange(i) },
                    )
                }
            }
            val scanDisabled = card.scanPayStatus == "out_window"
            Button(
                onClick = onScanTab,
                enabled = !scanDisabled,
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(16.dp),
                colors =
                    ButtonDefaults.buttonColors(
                        containerColor = ReactGreenBtn,
                        disabledContainerColor = ReactDisabledBg,
                        disabledContentColor = ReactDisabledText,
                    ),
            ) {
                Icon(Icons.Filled.QrCode2, null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(10.dp))
                Text("Scan & Pay", fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
            }
            RecentRows(recentTransactions, showViewAll = !homeEmptyNoTransactions)
        } else if (homeEmptyNoVehicle && homeEmptyNoTransactions) {
            Card(
                Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, ReactCardBorder),
            ) {
                Column(
                    Modifier.padding(horizontal = 24.dp, vertical = 56.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Box(
                        Modifier
                            .size(72.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF1F4F2)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.LocalShipping, null, tint = Color(0xFF7D9188), modifier = Modifier.size(36.dp))
                    }
                    Spacer(Modifier.height(20.dp))
                    Text("No vehicles or transactions", fontSize = 18.sp, fontWeight = FontWeight.SemiBold, color = ReactTextPrimary)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "There's nothing to show yet. When your fleet operator assigns you a vehicle and you use Scan & Pay, your balance and activity will appear here.",
                        fontSize = 14.sp,
                        color = ReactTextMuted,
                        textAlign = TextAlign.Center,
                    )
                    if (pendingCount > 0) {
                        Button(
                            onClick = onOpenAssignments,
                            modifier = Modifier.fillMaxWidth().padding(top = 32.dp).height(48.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = ReactGreenBtn),
                        ) { Text("Go to vehicles", fontWeight = FontWeight.SemiBold) }
                    } else {
                        TextButton(onClick = onOpenAssignments) {
                            Text("Browse vehicles", color = ReactMutedGreenLink, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                        }
                    }
                }
            }
        } else {
            Card(
                Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, ReactCardBorder),
            ) {
                Column(
                    Modifier.padding(horizontal = 24.dp, vertical = 48.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Box(
                        Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFF1F4F2)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.LocalShipping, null, tint = Color(0xFF7D9188), modifier = Modifier.size(28.dp))
                    }
                    Spacer(Modifier.height(16.dp))
                    Text("No active vehicle", fontWeight = FontWeight.SemiBold, color = ReactTextPrimary)
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "You don't have a paired vehicle right now. Accept an assignment to unlock Scan & Pay.",
                        fontSize = 14.sp,
                        color = ReactTextMuted,
                        textAlign = TextAlign.Center,
                    )
                    if (pendingCount > 0) {
                        Button(
                            onClick = onOpenAssignments,
                            modifier = Modifier.fillMaxWidth().padding(top = 24.dp).height(48.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = ReactGreenBtn),
                        ) { Text("View vehicles", fontWeight = FontWeight.SemiBold) }
                    }
                }
            }
            RecentRows(recentTransactions, showViewAll = recentTransactions.isNotEmpty())
        }
    }
}

@Composable
private fun ReceiptKvRow(
    label: String,
    value: String,
    valueColor: Color = ReactTextPrimary,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            label,
            fontSize = 14.sp,
            color = Color(0xFF6B7280),
            modifier = Modifier.weight(1f, fill = false),
        )
        Spacer(Modifier.width(12.dp))
        Text(
            value,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = valueColor,
            textAlign = TextAlign.End,
            modifier = Modifier.weight(1f),
        )
    }
    HorizontalDivider(color = Color(0xFFF3F4F6))
}

@Composable
internal fun ScanTab(
    bindings: List<DemoBinding>,
    selected: DemoBinding?,
    onSelect: (DemoBinding) -> Unit,
    phase: String,
    sessionPin: String,
    onSessionDigit: (String) -> Unit,
    onSessionBs: () -> Unit,
    sessionOtpDigits: MutableList<String>,
    onCameraScan: () -> Unit,
    onCloseConfirm: () -> Unit,
    onContinueToPin: () -> Unit,
    onBackFromPinConfirm: () -> Unit,
    onVerifyPinForSession: () -> Unit,
    onVerifySessionOtp: () -> Unit,
    onFuelingComplete: () -> Unit,
    onSessionDone: () -> Unit,
    scannedLoginMobileDigits: String,
    maskedMobileFromProfile: String?,
    onBackFromOtpEntry: () -> Unit = {},
    parsedQr: FleetpayQrPayload?,
    liveMode: Boolean,
    qrPayBusy: Boolean,
    lastPay: QrPayResultJson?,
    scanSessionOtpCountdown: Int = 0,
    onResendScanSessionOtp: () -> Unit = {},
    onGoToMyVehicles: () -> Unit = {},
    receiptDriverName: String? = null,
) {
    val context = LocalContext.current
    val available =
        bindings.filter {
            it.paired && it.state == DemoBindingState.ACTIVE &&
                (it.scanPayStatus == "always_available" || it.scanPayStatus == "in_window" || it.scanPayStatus == "trip_window")
        }
    Column(Modifier.fillMaxWidth().background(Color.White).padding(16.dp)) {
        when (phase) {
            "idle" -> {
                if (available.isEmpty()) {
                    Column(
                        Modifier
                            .fillMaxWidth()
                            .padding(vertical = 24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Icon(Icons.Filled.QrCode2, null, tint = Color(0xFFD1D5DB), modifier = Modifier.size(48.dp))
                        Spacer(Modifier.height(24.dp))
                        Text("Scan & Pay unavailable", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = ReactTextPrimary)
                        Text(
                            "No vehicles available for scanning right now",
                            fontSize = 14.sp,
                            color = ReactGray500,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 12.dp),
                        )
                        val locked =
                            bindings.filter {
                                it.scanPayStatus == "locked_unpaired" ||
                                    it.scanPayStatus == "locked_repair" ||
                                    it.scanPayStatus == "out_window"
                            }
                        if (locked.isNotEmpty()) {
                            Spacer(Modifier.height(24.dp))
                            Card(
                                Modifier.fillMaxWidth(),
                                colors = CardDefaults.cardColors(containerColor = Color(0xFFF9FAFB)),
                                shape = RoundedCornerShape(16.dp),
                            ) {
                                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                    locked.forEach { b ->
                                        Column {
                                            Text(b.vrn, fontWeight = FontWeight.Medium, fontSize = 14.sp, color = ReactTextPrimary)
                                            Text(
                                                when (b.scanPayStatus) {
                                                    "locked_unpaired" -> "Pair to unlock"
                                                    "locked_repair" -> "Re-pair required"
                                                    "out_window" -> "Outside shift/trip window"
                                                    else -> b.scanPayStatus.replace('_', ' ')
                                                },
                                                fontSize = 14.sp,
                                                color = ReactGray500,
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        Spacer(Modifier.height(24.dp))
                        Button(
                            onClick = onGoToMyVehicles,
                            modifier = Modifier.fillMaxWidth().height(48.dp),
                            shape = RoundedCornerShape(16.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Green700),
                        ) {
                            Text("Go to My Vehicles", fontWeight = FontWeight.Medium)
                        }
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
                                                .background(
                                                    if (b.id == sel.id) Green600 else Color(0xFFF3F4F6),
                                                    RoundedCornerShape(16.dp),
                                                ),
                                    ) {
                                        Text(b.vrn)
                                    }
                                }
                            }
                            Spacer(Modifier.height(8.dp))
                        }
                        Card(
                            Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFFF9FAFB)),
                            shape = RoundedCornerShape(16.dp),
                        ) {
                            Column(Modifier.padding(12.dp)) {
                                Text(
                                    "Fueling: ${sel.vrn}",
                                    fontWeight = FontWeight.Medium,
                                    fontSize = 14.sp,
                                    color = ReactTextPrimary,
                                )
                                Row(
                                    Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                ) {
                                    Text("Available balance", fontSize = 14.sp, color = ReactGray500)
                                    Text(
                                        "₹${sel.balance.inr()}",
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = Color(0xFF15803D),
                                    )
                                }
                            }
                        }
                        Spacer(Modifier.height(12.dp))
                        Box(
                            Modifier
                                .fillMaxWidth()
                                .aspectRatio(1f)
                                .border(4.dp, Color.White, RoundedCornerShape(16.dp))
                                .clip(RoundedCornerShape(16.dp))
                                .background(Color.Black),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.QrCode2, null, tint = Color.White.copy(alpha = 0.5f), modifier = Modifier.size(48.dp))
                        }
                        Spacer(Modifier.height(8.dp))
                        Text(
                            "Point camera at the QR on the POS screen",
                            fontSize = 12.sp,
                            color = ReactGray500,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
                        )
                        Spacer(Modifier.height(12.dp))
                        OutlinedButton(
                            onClick = onCameraScan,
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Text("Scan QR with camera")
                        }
                    }
                }
            }
            "confirmation" -> {
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Confirm fueling", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = ReactTextPrimary)
                    IconButton(onClick = onCloseConfirm) {
                        Icon(Icons.Filled.Close, null, tint = ReactGray500)
                    }
                }
                Spacer(Modifier.height(16.dp))
                Card(
                    Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    border = BorderStroke(1.dp, ReactCardBorder),
                ) {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.Top) {
                        Icon(
                            Icons.Filled.LocationOn,
                            contentDescription = null,
                            tint = Color(0xFF15803D),
                            modifier = Modifier.padding(top = 2.dp),
                        )
                        Spacer(Modifier.width(12.dp))
                        Column {
                            val stationLine =
                                parsedQr?.merchantName?.takeIf { it.isNotBlank() }
                                    ?: if (liveMode) "—" else "MGL Hind CNG Filling Station"
                            val midLine =
                                parsedQr?.mid?.takeIf { it.isNotBlank() }?.let { mid -> "MID $mid" }
                                    ?: if (liveMode) "—" else "Andheri, Mumbai"
                            Text(
                                stationLine,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 16.sp,
                                color = ReactTextPrimary,
                            )
                            Text(
                                midLine,
                                fontSize = 14.sp,
                                color = ReactGray500,
                            )
                        }
                    }
                }
                Spacer(Modifier.height(16.dp))
                selected?.let { b ->
                    Column(
                        Modifier
                            .fillMaxWidth()
                            .background(Color(0xFFF9FAFB), RoundedCornerShape(16.dp))
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Amount", fontSize = 14.sp, color = ReactGray500)
                            Text(
                                parsedQr?.let { "₹${paiseToInrDisplay(it.amountPaise)}" } ?: "—",
                                fontWeight = FontWeight.Medium,
                                fontSize = 14.sp,
                                color = ReactTextPrimary,
                            )
                        }
                        HorizontalDivider(color = Color(0xFFE5E7EB))
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Vehicle", fontSize = 14.sp, color = ReactGray500)
                            Text(b.vrn, fontWeight = FontWeight.Medium, fontSize = 14.sp, color = ReactTextPrimary)
                        }
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Fleet Operator", fontSize = 14.sp, color = ReactGray500)
                            Text(
                                b.fo,
                                fontWeight = FontWeight.Medium,
                                fontSize = 14.sp,
                                color = ReactTextPrimary,
                                textAlign = TextAlign.End,
                                modifier = Modifier.widthIn(max = 220.dp),
                            )
                        }
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Available balance", fontSize = 14.sp, color = ReactGray500)
                            Text(
                                "₹${b.balance.inr()}",
                                fontWeight = FontWeight.Medium,
                                fontSize = 14.sp,
                                color = Color(0xFF15803D),
                            )
                        }
                    }
                }
                Spacer(Modifier.height(16.dp))
                Button(
                    onClick = onContinueToPin,
                    enabled = !liveMode || parsedQr != null,
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Green700),
                ) {
                    Text("Continue", fontWeight = FontWeight.Medium)
                }
            }
            "pin_confirm" -> {
                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    IconButton(onClick = onBackFromPinConfirm) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, null, tint = ReactTextPrimary)
                    }
                    Text(
                        "Enter PIN",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Start,
                    )
                }
                Text(
                    text = "Enter your PIN to confirm",
                    fontSize = 14.sp,
                    color = ReactTextMuted,
                    modifier = Modifier.padding(top = 8.dp, bottom = 8.dp),
                )
                PinDots(sessionPin)
                Numpad(enabled = true, onDigit = onSessionDigit, onBackspace = onSessionBs)
                Button(
                    onClick = onVerifyPinForSession,
                    enabled = sessionPin.length == 6 && !qrPayBusy,
                    modifier = Modifier.fillMaxWidth().padding(top = 12.dp).height(48.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Green700, disabledContainerColor = ReactDisabledBg),
                ) {
                    Text(if (qrPayBusy) "Processing…" else "Verify PIN", fontWeight = FontWeight.SemiBold)
                }
            }
            "otp_entry" -> {
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    IconButton(onClick = onBackFromOtpEntry) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, null, tint = ReactTextPrimary)
                    }
                    Text(
                        "One-time password",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Start,
                    )
                }
                Spacer(Modifier.height(12.dp))
                Box(
                    Modifier
                        .fillMaxWidth()
                        .background(Color(0xFFEFF6FF), RoundedCornerShape(16.dp))
                        .border(1.dp, Color(0xFFBFDBFE), RoundedCornerShape(16.dp))
                        .padding(12.dp),
                ) {
                    Text(
                        text = otpScanBannerLine(scannedLoginMobileDigits, maskedMobileFromProfile),
                        fontSize = 14.sp,
                        color = Color(0xFF1E3A8A),
                    )
                }
                Spacer(Modifier.height(12.dp))
                Box(
                    Modifier
                        .fillMaxWidth()
                        .background(Color(0xFFF3F4F6), RoundedCornerShape(16.dp))
                        .padding(12.dp),
                ) {
                    Text(
                        text =
                            buildString {
                                append(selected?.vrn ?: "—")
                                append(" · ")
                                val merchant =
                                    parsedQr?.merchantName?.trim()?.takeIf { it.isNotEmpty() }
                                        ?: if (liveMode) "—" else "Station"
                                append(merchant)
                                append(" · ₹")
                                val amt =
                                    parsedQr?.let { p -> paiseToInrDisplay(p.amountPaise) }
                                        ?: if (liveMode) "—" else "1,200.00"
                                append(amt)
                            },
                        fontSize = 12.sp,
                        color = Color(0xFF4B5563),
                    )
                }
                Spacer(Modifier.height(12.dp))
                SixDigitOtpFields(sessionOtpDigits)
                Spacer(Modifier.height(8.dp))
                if (!liveMode) {
                    Text(
                        "Session expires in 1:24",
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = TextAlign.Center,
                        fontSize = 12.sp,
                        color = Color(0xFFDC2626),
                    )
                }
                Spacer(Modifier.height(16.dp))
                Button(
                    onClick = onVerifySessionOtp,
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Green700),
                    enabled = sessionOtpDigits.joinToString("").length == 6,
                ) {
                    Text("Verify & Authorize", fontWeight = FontWeight.SemiBold)
                }
                Spacer(Modifier.height(8.dp))
                if (scanSessionOtpCountdown > 0) {
                    Text(
                        text = "Resend OTP in ${scanSessionOtpCountdown}s",
                        fontSize = 12.sp,
                        color = ReactTextMuted,
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = TextAlign.Center,
                    )
                } else {
                    TextButton(onClick = onResendScanSessionOtp, modifier = Modifier.fillMaxWidth()) {
                        Text("Resend OTP", color = Green700, fontWeight = FontWeight.Medium)
                    }
                }
            }
            "authorized" -> {
                Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                    Box(
                        Modifier
                            .size(64.dp)
                            .clip(CircleShape)
                            .background(Color(0xFFD1FAE5)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Check, null, tint = Green700, modifier = Modifier.size(32.dp))
                    }
                    Spacer(Modifier.height(16.dp))
                    Text("Fueling authorized", fontWeight = FontWeight.Bold, fontSize = 24.sp)
                    Text(
                        "Dispenser is now unlocked",
                        fontSize = 14.sp,
                        color = ReactTextMuted,
                        modifier = Modifier.padding(horizontal = 8.dp),
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(24.dp))
                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        border = BorderStroke(1.dp, Color(0xFFE5E7EB)),
                    ) {
                        Column(Modifier.padding(16.dp)) {
                            val authStation =
                                parsedQr?.merchantName?.takeIf { it.isNotBlank() }
                                    ?: if (liveMode) "—" else "Station"
                            val authPreAuthAmt =
                                parsedQr?.let { paiseToInrDisplay(it.amountPaise) }
                                    ?: if (liveMode) "—" else "1,200.00"
                            Text(
                                authStation,
                                fontSize = 12.sp,
                                color = ReactTextMuted,
                            )
                            Text(
                                "Pre-authorized: ₹$authPreAuthAmt",
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 16.sp,
                            )
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .background(Color(0xFFFFF7ED), RoundedCornerShape(16.dp))
                            .border(1.dp, Color(0xFFFBBF24), RoundedCornerShape(16.dp))
                            .padding(12.dp),
                    ) {
                        Text(
                            "⚠ Do not leave the pump until fueling is complete",
                            fontSize = 12.sp,
                            color = Color(0xFF78350f),
                        )
                    }
                    Spacer(Modifier.height(16.dp))
                    Column(
                        Modifier
                            .fillMaxWidth()
                            .background(Color(0xFFF9FAFB), RoundedCornerShape(16.dp))
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Text("Dispensing", fontSize = 12.sp, color = ReactTextMuted)
                        if (!liveMode) {
                            Text(
                                "2.4 kg",
                                fontWeight = FontWeight.Bold,
                                fontSize = 24.sp,
                            )
                            Text(
                                "₹384",
                                fontSize = 14.sp,
                                color = ReactTextMuted,
                                modifier = Modifier.padding(top = 4.dp),
                            )
                        } else {
                            val qkg = lastPay?.quantityKg
                            Text(
                                if (qkg != null && qkg.isFinite()) String.format(Locale.US, "%.1f kg", qkg) else "—",
                                fontWeight = FontWeight.Bold,
                                fontSize = 24.sp,
                            )
                            val authInr = parsedQr?.amountPaise?.div(100.0)
                            Text(
                                if (authInr != null && authInr.isFinite()) {
                                    NumberFormat.getCurrencyInstance(Locale("en", "IN")).format(authInr)
                                } else {
                                    "—"
                                },
                                fontSize = 14.sp,
                                color = ReactTextMuted,
                                modifier = Modifier.padding(top = 4.dp),
                            )
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                    Button(
                        onClick = onFuelingComplete,
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        shape = RoundedCornerShape(16.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Green700),
                    ) {
                        Text("Fueling Complete")
                    }
                }
            }
            "complete" -> {
                selected?.let { activeBinding ->
                    val payFailed = liveMode && lastPay?.status == "FAILED"
                    val amtFromPay = lastPay?.amountINR?.takeIf { it.isFinite() }
                    val amtPaiseFb = parsedQr?.amountPaise
                    val amountInrNum =
                        when {
                            amtFromPay != null -> amtFromPay
                            amtPaiseFb != null -> amtPaiseFb / 100.0
                            else -> Double.NaN
                        }
                    val nf =
                        NumberFormat.getNumberInstance(Locale("en", "IN")).apply {
                            minimumFractionDigits = 0
                            maximumFractionDigits = 2
                        }
                    val amountDisplay =
                        if (amountInrNum.isFinite()) "₹${nf.format(amountInrNum)}" else "—"
                    val stationName = parsedQr?.merchantName?.takeIf { it.isNotBlank() } ?: "—"
                    val vrnPretty =
                        formatPrettyVrn(lastPay?.vehicleRegNo ?: activeBinding.vrn)
                    val txnIdDisp =
                        lastPay?.serverTxnId?.trim()?.takeIf { it.isNotEmpty() } ?: "—"
                    val txnDateDisp = formatPayApiTxnDate(lastPay?.txnTime)
                    val newBalRaw = lastPay?.newBalanceINR
                    val newBalDisp =
                        if (!payFailed && newBalRaw != null && newBalRaw.isFinite()) {
                            "₹${NumberFormat.getNumberInstance(Locale("en", "IN")).format(newBalRaw)}"
                        } else {
                            null
                        }
                    val authLine = lastPay?.authCode?.trim().orEmpty()
                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                    ) {
                        Column(
                            Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 24.dp, vertical = 24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            if (payFailed) {
                                Box(
                                    Modifier
                                        .size(64.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFFDC2626)),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Icon(Icons.Filled.Close, null, tint = Color.White, modifier = Modifier.size(36.dp))
                                }
                                Spacer(Modifier.height(12.dp))
                                Text(
                                    "Transaction Failed",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 20.sp,
                                    color = Color(0xFFB91C1C),
                                )
                            } else {
                                Box(
                                    Modifier
                                        .size(64.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFF2E7D32)),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(36.dp))
                                }
                                Spacer(Modifier.height(12.dp))
                                Text(
                                    "Fueling Complete",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 20.sp,
                                    color = Color(0xFF2E7D32),
                                )
                            }
                        }
                        Column(
                            Modifier
                                .fillMaxWidth()
                                .background(Color(0xFF064E3B))
                                .padding(horizontal = 16.dp, vertical = 20.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            Box(
                                Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .border(1.dp, ReactLogoBorder.copy(alpha = 0.8f), RoundedCornerShape(8.dp))
                                    .background(ReactLogoBg)
                                    .padding(horizontal = 10.dp, vertical = 8.dp),
                            ) {
                                Image(
                                    painter = painterResource(id = R.drawable.mgl_logo),
                                    contentDescription = "MGL",
                                    modifier =
                                        Modifier
                                            .height(36.dp)
                                            .widthIn(max = 120.dp),
                                    contentScale = ContentScale.Fit,
                                )
                            }
                            Spacer(Modifier.height(8.dp))
                            Text(
                                "Official Receipt",
                                fontSize = 12.sp,
                                color = Color.White.copy(alpha = 0.9f),
                            )
                        }
                        Column(
                            Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                        ) {
                            ReceiptKvRow("Station", stationName)
                            ReceiptKvRow("Vehicle", vrnPretty)
                            if (!receiptDriverName.isNullOrBlank()) {
                                ReceiptKvRow("Driver", receiptDriverName.trim())
                            }
                            if (payFailed) {
                                ReceiptKvRow(
                                    "Status",
                                    "FAILED",
                                    valueColor = Color(0xFFDC2626),
                                )
                            }
                            ReceiptKvRow(
                                "Amount",
                                amountDisplay,
                                valueColor =
                                    if (payFailed) {
                                        Color(0xFFDC2626)
                                    } else {
                                        Color(0xFF2E7D32)
                                    },
                            )
                            if (!payFailed && newBalDisp != null) {
                                ReceiptKvRow(
                                    "New balance",
                                    newBalDisp,
                                    valueColor = Color(0xFF2E7D32),
                                )
                            }
                            if (authLine.isNotEmpty()) {
                                ReceiptKvRow(
                                    "Auth code",
                                    authLine,
                                    valueColor = ReactTextPrimary,
                                )
                            }
                            Spacer(Modifier.height(8.dp))
                            HorizontalDivider(
                                color = Color(0xFFD1D5DB),
                                modifier = Modifier.padding(vertical = 8.dp),
                            )
                            Text(
                                if (txnIdDisp == "—") {
                                    "TXN ID: —"
                                } else {
                                    "TXN ID: $txnIdDisp"
                                },
                                fontSize = 11.sp,
                                fontFamily = FontFamily.Monospace,
                                color = Color(0xFF6B7280),
                                modifier =
                                    Modifier
                                        .fillMaxWidth()
                                        .padding(bottom = 16.dp),
                                textAlign = TextAlign.Center,
                            )
                            Text(
                                txnDateDisp,
                                fontSize = 11.sp,
                                fontFamily = FontFamily.Monospace,
                                color = Color(0xFF6B7280),
                                modifier =
                                    Modifier
                                        .fillMaxWidth()
                                        .padding(bottom = 16.dp),
                                textAlign = TextAlign.Center,
                            )
                        }
                    }
                    Spacer(Modifier.height(12.dp))
                    Button(
                        onClick = onSessionDone,
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors =
                            ButtonDefaults.buttonColors(
                                containerColor =
                                    if (payFailed) {
                                        Color(0xFF374151)
                                    } else {
                                        Color(0xFF2E7D32)
                                    },
                            ),
                    ) {
                        Text("Done", fontWeight = FontWeight.SemiBold)
                    }
                    Spacer(Modifier.height(8.dp))
                    OutlinedButton(
                        onClick = {
                            FuelingReceiptShare.shareReceiptImage(
                                context = context,
                                payFailed = payFailed,
                                station = stationName,
                                vehicle = vrnPretty,
                                driverName = receiptDriverName?.trim()?.takeIf { it.isNotEmpty() },
                                amountDisplay = amountDisplay,
                                newBalance = newBalDisp,
                                authCode = authLine.takeIf { it.isNotEmpty() },
                                txnId = txnIdDisp,
                                txnDate = txnDateDisp,
                            )
                        },
                        modifier = Modifier.fillMaxWidth().height(52.dp),
                        shape = RoundedCornerShape(12.dp),
                        border = BorderStroke(1.dp, Color(0xFFE5E7EB)),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF111827)),
                    ) {
                        Text("Share receipt", fontWeight = FontWeight.Medium)
                    }
                } ?: Column {
                    Text("—", color = ReactTextMuted)
                    Button(
                        onClick = onSessionDone,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF374151)),
                    ) {
                        Text("Done")
                    }
                }
            }
        }
    }
}

@Composable
internal fun AssignmentsTab(
    bindings: List<DemoBinding>,
    onOpenScan: (DemoBinding) -> Unit,
    onOpenTransactions: (DemoBinding) -> Unit,
    onAcceptPending: (DemoBinding) -> Unit,
    onEnterRepairPairing: (DemoBinding) -> Unit,
) {
    val active = bindings.filter { it.paired && it.state == DemoBindingState.ACTIVE }
    val pending = bindings.filter { it.state == DemoBindingState.PENDING_ACCEPTANCE }
    val repair = bindings.filter { it.scanPayStatus == "locked_repair" }
    val needsCount = pending.size + repair.size

    var vehicleDetail by remember { mutableStateOf<DemoBinding?>(null) }
    var shiftDetail by remember { mutableStateOf<DemoBinding?>(null) }
    var tripDetail by remember { mutableStateOf<DemoBinding?>(null) }
    var declineTarget by remember { mutableStateOf<DemoBinding?>(null) }

    fun openDetails(b: DemoBinding) {
        when (b.authMode) {
            DemoAuthMode.TRIP_LINKED -> tripDetail = b
            DemoAuthMode.SHIFT_BASED -> shiftDetail = b
            else -> vehicleDetail = b
        }
    }

    Box(Modifier.fillMaxWidth()) {
        Column(
            Modifier
                .fillMaxWidth()
                .background(Color(0xFFECEFF1))
                .padding(horizontal = 16.dp, vertical = 16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text("My Vehicles", fontWeight = FontWeight.Bold, fontSize = 24.sp, color = ReactTextPrimary)
            Text(
                "${active.size} active · $needsCount need attention",
                fontSize = 12.sp,
                color = Color(0xFF6B7280),
            )

            active.forEach { b ->
                val scanDisabled =
                    b.scanPayStatus == "out_window" ||
                        b.scanPayStatus == "locked_unpaired" ||
                        b.scanPayStatus == "locked_repair"
                Card(
                    Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                ) {
                    Column(Modifier.fillMaxWidth()) {
                        Box(
                            Modifier
                                .fillMaxWidth()
                                .height(8.dp)
                                .background(Color(0xFF43A047)),
                        )
                        Column(
                            Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 20.dp, vertical = 16.dp),
                        ) {
                            Row(
                                Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.Top,
                            ) {
                                Text(
                                    b.vrn,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 20.sp,
                                    fontFamily = FontFamily.Monospace,
                                    color = ReactTextPrimary,
                                    modifier = Modifier.weight(1f),
                                )
                                Text(
                                    "Active",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFF15803D),
                                    modifier =
                                        Modifier
                                            .border(1.dp, Color(0xFF43A047), RoundedCornerShape(999.dp))
                                            .background(Color(0xFFF0FDF4))
                                            .padding(horizontal = 12.dp, vertical = 4.dp),
                                )
                            }
                            Text(
                                b.fo.trim().ifBlank { "—" },
                                fontSize = 14.sp,
                                color = Color(0xFF6B7280),
                                modifier = Modifier.padding(top = 8.dp),
                            )
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .padding(top = 20.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text("Balance", fontSize = 14.sp, color = Color(0xFF6B7280))
                                Text(
                                    "₹${b.balance.inr()}",
                                    fontSize = 20.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = ReactTextPrimary,
                                )
                            }
                        }
                        HorizontalDivider(color = Color(0xFFE5E7EB), modifier = Modifier.padding(horizontal = 20.dp))
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 12.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            OutlinedButton(
                                onClick = { onOpenScan(b) },
                                enabled = !scanDisabled,
                                modifier =
                                    Modifier
                                        .weight(1f)
                                        .height(72.dp),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, Color(0xFFBBF7D0)),
                                colors =
                                    ButtonDefaults.outlinedButtonColors(
                                        contentColor = Color(0xFF2E7D32),
                                        disabledContentColor = ReactDisabledText,
                                    ),
                                contentPadding = PaddingValues(4.dp),
                            ) {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    verticalArrangement = Arrangement.spacedBy(6.dp),
                                ) {
                                    Icon(Icons.Filled.QrCode2, null, tint = Color(0xFF43A047), modifier = Modifier.size(24.dp))
                                    Text("Scan & Pay", fontSize = 12.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center)
                                }
                            }
                            OutlinedButton(
                                onClick = { onOpenTransactions(b) },
                                modifier =
                                    Modifier
                                        .weight(1f)
                                        .height(72.dp),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, Color(0xFFE5E7EB)),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF4B5563)),
                                contentPadding = PaddingValues(4.dp),
                            ) {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    verticalArrangement = Arrangement.spacedBy(6.dp),
                                ) {
                                    Icon(Icons.AutoMirrored.Filled.List, null, tint = Color(0xFF6B7280), modifier = Modifier.size(24.dp))
                                    Text("Transactions", fontSize = 12.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center)
                                }
                            }
                            OutlinedButton(
                                onClick = { openDetails(b) },
                                modifier =
                                    Modifier
                                        .weight(1f)
                                        .height(72.dp),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, Color(0xFFE5E7EB)),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF4B5563)),
                                contentPadding = PaddingValues(4.dp),
                            ) {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    verticalArrangement = Arrangement.spacedBy(6.dp),
                                ) {
                                    Icon(Icons.Filled.Info, null, tint = Color(0xFF6B7280), modifier = Modifier.size(24.dp))
                                    Text("Details", fontSize = 12.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center)
                                }
                            }
                        }
                    }
                }
            }

            if (pending.isNotEmpty() || repair.isNotEmpty()) {
                Text(
                    "NEEDS ATTENTION",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFFD97706),
                    letterSpacing = 0.5.sp,
                )
                pending.forEach { b ->
                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        border = BorderStroke(2.dp, Color(0xFFFCD34D)),
                    ) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text(
                                    b.vrn,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 20.sp,
                                    fontFamily = FontFamily.Monospace,
                                )
                                Text(
                                    "Action needed",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFFB45309),
                                    modifier =
                                        Modifier
                                            .clip(RoundedCornerShape(999.dp))
                                            .background(Color(0xFFFEF3C7))
                                            .padding(horizontal = 12.dp, vertical = 4.dp),
                                )
                            }
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text("Vehicle-linked", fontSize = 14.sp, color = Color(0xFF6B7280))
                                Text(b.fo.trim().ifBlank { "—" }, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                            }
                            Text(
                                buildString {
                                    append("Assigned by ")
                                    append(b.assignedBy?.trim().orEmpty().ifBlank { "your Fleet Operator" })
                                },
                                fontSize = 12.sp,
                                color = Color(0xFF6B7280),
                            )
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Icon(Icons.Filled.Lock, null, tint = Color(0xFFB45309), modifier = Modifier.size(16.dp))
                                Text("Pair to unlock Scan & Pay", fontSize = 14.sp, color = Color(0xFFB45309))
                            }
                            HorizontalDivider(color = Color(0xFFF3F4F6))
                            Button(
                                onClick = { onAcceptPending(b) },
                                modifier = Modifier.fillMaxWidth().height(40.dp),
                                shape = RoundedCornerShape(8.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF047857)),
                            ) {
                                Text("Accept & Pair", fontSize = 12.sp, fontWeight = FontWeight.Medium, color = Color.White)
                            }
                            OutlinedButton(
                                onClick = { declineTarget = b },
                                modifier = Modifier.fillMaxWidth().height(40.dp),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, Color(0xFFFECACA)),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFDC2626)),
                            ) {
                                Text("Decline", fontSize = 12.sp, fontWeight = FontWeight.Medium)
                            }
                        }
                    }
                }
                repair.forEach { b ->
                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        border = BorderStroke(2.dp, Color(0xFFFCA5A5)),
                    ) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text(b.vrn, fontWeight = FontWeight.Bold, fontSize = 20.sp, fontFamily = FontFamily.Monospace)
                                Text(
                                    "Re-pair required",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFFB91C1C),
                                    modifier =
                                        Modifier
                                            .clip(RoundedCornerShape(999.dp))
                                            .background(Color(0xFFFEE2E2))
                                            .padding(horizontal = 12.dp, vertical = 4.dp),
                                )
                            }
                            Text(
                                "${if (b.authMode == DemoAuthMode.SHIFT_BASED) "Shift-based" else "Vehicle-linked"} · ${b.fo.trim().ifBlank { "—" }}",
                                fontSize = 14.sp,
                                color = Color(0xFF6B7280),
                            )
                            Text(
                                "Reason: ${b.repairReason?.trim().orEmpty().ifBlank { "Re-pair required" }}",
                                fontSize = 12.sp,
                                color = Color(0xFF6B7280),
                            )
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Icon(Icons.Filled.Lock, null, tint = Color(0xFFDC2626), modifier = Modifier.size(16.dp))
                                Text("Scan & Pay locked until re-paired", fontSize = 14.sp, color = Color(0xFFDC2626))
                            }
                            HorizontalDivider(color = Color(0xFFF3F4F6))
                            OutlinedButton(
                                onClick = { onEnterRepairPairing(b) },
                                modifier = Modifier.fillMaxWidth().height(40.dp),
                                shape = RoundedCornerShape(8.dp),
                                border = BorderStroke(1.dp, Color(0xFFFCD34D)),
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFB45309)),
                            ) {
                                Text("Enter new pairing code", fontSize = 12.sp, fontWeight = FontWeight.Medium)
                            }
                        }
                    }
                }
            }

            if (active.isEmpty() && pending.isEmpty() && repair.isEmpty()) {
                Card(
                    Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                ) {
                    Column(
                        Modifier
                            .fillMaxWidth()
                            .padding(vertical = 56.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Icon(Icons.Filled.LocalShipping, null, tint = Color(0xFFD1D5DB), modifier = Modifier.size(48.dp))
                        Spacer(Modifier.height(16.dp))
                        Text("No vehicles yet", fontWeight = FontWeight.Medium, color = Color(0xFF6B7280))
                        Spacer(Modifier.height(8.dp))
                        Text(
                            "Your Fleet Operator will assign vehicles here",
                            fontSize = 14.sp,
                            color = Color(0xFF9CA3AF),
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 24.dp),
                        )
                    }
                }
            }
        }

        vehicleDetail?.let { b ->
            Dialog(onDismissRequest = { vehicleDetail = null }) {
                Card(
                    Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                ) {
                    Column(Modifier.padding(20.dp)) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                b.vrn,
                                fontWeight = FontWeight.Bold,
                                fontFamily = FontFamily.Monospace,
                                modifier = Modifier.weight(1f),
                            )
                            IconButton(onClick = { vehicleDetail = null }) {
                                Icon(Icons.Filled.Close, null, tint = Color(0xFF6B7280))
                            }
                        }
                        HorizontalDivider(Modifier.padding(vertical = 12.dp), color = Color(0xFFF3F4F6))
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Balance", color = Color(0xFF6B7280), fontSize = 14.sp)
                            Text("₹${b.balance.inr()}", fontWeight = FontWeight.Bold)
                        }
                        Row(Modifier.fillMaxWidth().padding(top = 12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Assigned At", color = Color(0xFF6B7280), fontSize = 14.sp)
                            Text(
                                formatPayApiTxnDate(b.assignedAt),
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                textAlign = TextAlign.End,
                                modifier = Modifier.padding(start = 8.dp),
                            )
                        }
                        Row(Modifier.fillMaxWidth().padding(top = 12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("Fleet Operator", color = Color(0xFF6B7280), fontSize = 14.sp)
                            Text(
                                b.fo.trim().ifBlank { "—" },
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                textAlign = TextAlign.End,
                                modifier = Modifier.weight(1f).padding(start = 8.dp),
                            )
                        }
                    }
                }
            }
        }

        shiftDetail?.let { b ->
            AlertDialog(
                onDismissRequest = { shiftDetail = null },
                title = { Text("Shift schedule") },
                text = {
                    Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        b.shiftDays.forEach { day ->
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text(day)
                                Text("${b.shiftStart} – ${b.shiftEnd}", fontFamily = FontFamily.Monospace)
                            }
                        }
                        if (b.shiftDays.isEmpty()) {
                            Text("${b.shiftStart} – ${b.shiftEnd}", fontFamily = FontFamily.Monospace)
                        }
                    }
                },
                confirmButton = { TextButton({ shiftDetail = null }) { Text("OK") } },
            )
        }

        tripDetail?.let { b ->
            AlertDialog(
                onDismissRequest = { tripDetail = null },
                title = { Text("Trip details") },
                text = {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("${b.origin} → ${b.destination}", fontWeight = FontWeight.Medium)
                        Text(b.tripDate, color = Color(0xFF6B7280), fontSize = 14.sp)
                        Text("${b.tripStart} – ${b.tripEnd}", fontFamily = FontFamily.Monospace, fontSize = 14.sp)
                    }
                },
                confirmButton = { TextButton({ tripDetail = null }) { Text("OK") } },
            )
        }

        declineTarget?.let { _ ->
            AlertDialog(
                onDismissRequest = { declineTarget = null },
                title = { Text("Decline this assignment?") },
                text = { Text("This will notify your Fleet Operator.") },
                confirmButton = {
                    TextButton({ declineTarget = null }) { Text("Yes, decline", color = Color.Red) }
                },
                dismissButton = { TextButton({ declineTarget = null }) { Text("Cancel") } },
            )
        }
    }
}

@Composable
internal fun TransactionsTab(
    filter: String,
    onFilter: (String) -> Unit,
    rows: List<DriverTxnRowParse>,
) {
    Column(Modifier.background(Color.White)) {
        Column {
            Row(
                Modifier
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                listOf("all" to "All", "successful" to "Successful", "failed" to "Failed").forEach { (f, label) ->
                    val selected = filter == f
                    TextButton(onClick = { onFilter(f) }, contentPadding = PaddingValues(0.dp)) {
                        Text(
                            text = label,
                            modifier =
                                Modifier
                                    .clip(RoundedCornerShape(999.dp))
                                    .background(if (selected) Green600 else Gray100)
                                    .padding(horizontal = 16.dp, vertical = 6.dp),
                            color = if (selected) Color.White else Color(0xFF4B5563),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium,
                        )
                    }
                }
            }
            HorizontalDivider(color = Color(0xFFF3F4F6))
        }
        val filtered =
            rows.filter { t ->
                when (filter) {
                    "successful" -> t.status.trim().equals("SUCCESS", ignoreCase = true)
                    "failed" -> !t.status.trim().equals("SUCCESS", ignoreCase = true)
                    else -> true
                }
            }
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            if (filtered.isEmpty()) {
                val emptyTitle =
                    when {
                        rows.isEmpty() -> "No transactions yet"
                        filter == "successful" -> "No successful transactions"
                        filter == "failed" -> "No failed transactions"
                        else -> "No transactions"
                    }
                val emptySub =
                    if (rows.isEmpty()) {
                        "Fuel payments and wallet activity will show here once you use Scan & Pay."
                    } else {
                        "Nothing matches this filter. Try All or another tab."
                    }
                Card(
                    Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    border = BorderStroke(1.dp, Color(0xFFF3F4F6)),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                ) {
                    Column(
                        Modifier.padding(horizontal = 16.dp, vertical = 56.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Box(
                            Modifier
                                .size(56.dp)
                                .clip(CircleShape)
                                .background(Color(0xFFF9FAFB)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.History, null, tint = Color(0xFF9CA3AF), modifier = Modifier.size(28.dp))
                        }
                        Spacer(Modifier.height(16.dp))
                        Text(emptyTitle, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = ReactTextPrimary)
                        Text(
                            emptySub,
                            fontSize = 12.sp,
                            color = ReactTextMuted,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(top = 8.dp),
                        )
                    }
                }
            } else {
                val nf = NumberFormat.getNumberInstance(Locale("en", "IN"))
                filtered.forEach { txn ->
                    Card(
                        Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        border = BorderStroke(1.dp, Color(0xFFE5E7EB)),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                    ) {
                        Column(Modifier.padding(12.dp)) {
                            Row(
                                Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.Top,
                            ) {
                                Column(Modifier.weight(1f)) {
                                    Text(
                                        txn.serverTxnId.ifEmpty { "—" },
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = ReactTextPrimary,
                                    )
                                    Text(
                                        buildString {
                                            append(txn.vehicleRegNo)
                                            if (txn.driverName.isNotBlank()) {
                                                append(" · ")
                                                append(txn.driverName)
                                            }
                                        },
                                        fontSize = 12.sp,
                                        color = Color(0xFF4B5563),
                                        maxLines = 2,
                                    )
                                }
                                Text(
                                    "₹${nf.format(kotlin.math.abs(txn.amountINR))}",
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFFDC2626),
                                )
                            }
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .padding(top = 8.dp),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                val st = txn.status.trim()
                                val success = st.equals("SUCCESS", ignoreCase = true)
                                Text(
                                    st.ifEmpty { "—" },
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = if (success) Color(0xFF166534) else Color(0xFF92400E),
                                    modifier =
                                        Modifier
                                            .clip(RoundedCornerShape(999.dp))
                                            .background(if (success) Color(0xFFF0FDF4) else Color(0xFFFFFBEB))
                                            .padding(horizontal = 8.dp, vertical = 4.dp),
                                )
                                Text(txn.createdOn, fontSize = 12.sp, color = Color(0xFF4B5563))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
internal fun ProfileTab(
    driverDisplayName: String,
    initials: String,
    subtitle: String,
    maskedMobile: String,
    registeredDisplay: String,
    fleetOperatorDisplay: String,
    driverId: String,
    licenceLine: String,
    apiAssignments: List<DriverAssignmentJson>,
    onLogout: () -> Unit,
) {
    Column(Modifier.background(Color.White).padding(16.dp).padding(bottom = 32.dp)) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                Modifier
                    .size(64.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFD1FAE5)),
                contentAlignment = Alignment.Center,
            ) {
                Text(initials, color = Green700, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(8.dp))
            Text(driverDisplayName, fontWeight = FontWeight.Bold, fontSize = 18.sp, color = ReactTextPrimary)
            Text(subtitle, fontSize = 12.sp, color = Color(0xFF6B7280))
        }
        Card(
            Modifier.fillMaxWidth().padding(top = 24.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            border = BorderStroke(1.dp, ReactCardBorder),
        ) {
            Column {
                Text(
                    "Account",
                    Modifier
                        .fillMaxWidth()
                        .background(Color.White)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    fontWeight = FontWeight.SemiBold,
                    color = ReactTextPrimary,
                )
                HorizontalDivider(color = Color(0xFFE5E7EB))
                ProfileRow("Mobile", maskedMobile)
                HorizontalDivider(color = Color(0xFFE5E7EB))
                ProfileRow("Registered", registeredDisplay)
                HorizontalDivider(color = Color(0xFFE5E7EB))
                ProfileRow("Fleet Operator", fleetOperatorDisplay)
                HorizontalDivider(color = Color(0xFFE5E7EB))
                ProfileRow("Driver ID", driverId)
                HorizontalDivider(color = Color(0xFFE5E7EB))
                ProfileRow("Licence Number", licenceLine)
            }
        }
        val showApiVehicles = apiAssignments.isNotEmpty()
        if (showApiVehicles) {
            Card(
                Modifier.fillMaxWidth().padding(top = 16.dp),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, ReactCardBorder),
            ) {
                Column {
                    Text(
                        "My Vehicles",
                        Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        fontWeight = FontWeight.SemiBold,
                        color = ReactTextPrimary,
                    )
                    HorizontalDivider(color = Color(0xFFE5E7EB))
                    apiAssignments.forEachIndexed { i, a ->
                        Column(Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
                            Text(a.vehicleRegNo, fontWeight = FontWeight.Medium, color = ReactTextPrimary)
                            Row(
                                Modifier.padding(top = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                Text(
                                    a.status,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = Color(0xFF15803D),
                                    modifier =
                                        Modifier
                                            .clip(RoundedCornerShape(4.dp))
                                            .background(Color(0xFFDCFCE7))
                                            .padding(horizontal = 8.dp, vertical = 4.dp),
                                )
                                Box(Modifier.size(8.dp).clip(CircleShape).background(Color(0xFF16A34A)))
                            }
                        }
                        if (i < apiAssignments.lastIndex) HorizontalDivider(color = Color(0xFFE5E7EB))
                    }
                }
            }
        }
        OutlinedButton(
            onClick = onLogout,
            Modifier
                .fillMaxWidth()
                .padding(top = 24.dp),
            border = BorderStroke(2.dp, Color(0xFFFECACA)),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFDC2626)),
        ) {
            Text("Sign out", fontWeight = FontWeight.Medium)
        }
    }
}

@Composable
internal fun ProfileRow(k: String, v: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(k, fontSize = 13.sp, color = Color.Gray)
        Text(v, fontWeight = FontWeight.Medium, fontSize = 13.sp)
    }
}

@Composable
internal fun AssignmentOverlay(
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
internal fun ForgotPinReactScreen(onBackToLogin: () -> Unit) {
    Column(Modifier.fillMaxWidth()) {
        OnboardingBackRow(onBackToLogin)
        Text("Reset PIN", fontWeight = FontWeight.Bold, fontSize = 20.sp, color = ReactTextPrimary)
        Spacer(Modifier.height(8.dp))
        Text(
            "Sign out and open Login with your mobile OTP, or contact your fleet operator for help.",
            fontSize = 14.sp,
            color = ReactGray500,
        )
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = onBackToLogin,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Green700),
        ) { Text("Back to login", fontWeight = FontWeight.Medium) }
    }
}

@Composable
internal fun AssignmentAcceptedOverlay(
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
internal fun PairingOverlayExtended(
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
internal fun BottomNav(current: String?, onTab: (String) -> Unit) {
    val items =
        listOf(
            Triple("card", Icons.Filled.Home, "Home"),
            Triple("scan", Icons.Filled.QrCode2, "Scan & Pay"),
            Triple("assignments", Icons.Filled.LocalShipping, "My Vehicles"),
            Triple("profile", Icons.Filled.Person, "Profile"),
        )
    val inactive = Color(0xFF6B7280)
    Row(
        Modifier
            .fillMaxWidth()
            .background(Color.White)
            .border(BorderStroke(1.dp, Color(0xFFE5E7EB)))
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        items.forEach { (id, icon, label) ->
            val selected = current != null && current == id
            Column(
                Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .heightIn(min = 48.dp)
                    .clickable { onTab(id) }
                    .padding(vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(icon, null, tint = if (selected) Green700 else inactive, modifier = Modifier.size(24.dp))
                Text(
                    label,
                    fontSize = 11.sp,
                    lineHeight = 13.sp,
                    textAlign = TextAlign.Center,
                    fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal,
                    color = if (selected) Green700 else inactive,
                    modifier = Modifier.widthIn(max = 88.dp),
                )
            }
        }
    }
}

