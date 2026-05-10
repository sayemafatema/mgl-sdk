package com.mgl.fleet.sdk.internal

import com.mgl.fleet.sdk.FleetSdkOptions
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.FormBody
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLEncoder
import java.util.concurrent.TimeUnit

/** Live driver-app HTTP; mirrors `driver-api.ts`. Use when `!FleetSdkOptions.useMock`. */
internal class DriverAppApiClient(
    private val opts: FleetSdkOptions,
    private val client: OkHttpClient =
        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build(),
) {
    private val base: String get() = opts.apiBaseUrl.trimEnd('/')

    suspend fun driverCheckMobile(mobile: String): Result<CheckMobileStatus> =
        runCatchingSuspend {
            parseCheckMobile(requireJsonBody(postJsonRaw("/api/v0/driver-app/auth/check-mobile", JSONObject().put("mobile", mobile), bearer = null)))
        }

    suspend fun driverSendLoginOtp(mobile: String): Result<Unit> =
        runCatchingSuspend {
            val q = URLEncoder.encode(mobile, Charsets.UTF_8.name())
            getRaw("/api/v0/otp/login?username=$q", bearer = null)
            Unit
        }

    suspend fun driverInviteMobileSendOtp(mobile: String): Result<String> =
        runCatchingSuspend {
            unwrapInviteSendOtpInner(
                requireJsonBody(postJsonRaw("/api/v0/driver-app/auth/mobile/send-otp", JSONObject().put("mobile", mobile), bearer = null)),
            )
        }

    suspend fun driverInviteMobileVerifyOtp(
        mobile: String,
        otpRefNumber: String,
        otp: String,
    ): Result<String> =
        runCatchingSuspend {
            val body =
                JSONObject(
                    mapOf(
                        "mobile" to mobile,
                        "otpRefNumber" to otpRefNumber,
                        "otp" to otp,
                    ),
                )
            val o = requireJsonObject(unwrapDriverBodyJson(postJsonRaw("/api/v0/driver-app/auth/mobile/verify-otp", body, bearer = null)))
            val tok = o.optString("mobileVerificationToken", "").trim()
            if (tok.isEmpty()) throw DriverApiException("Unexpected verify-otp response")
            tok
        }

    suspend fun driverInviteValidate(
        mobile: String,
        inviteCode: String,
        mobileVerificationToken: String,
    ): Result<InviteValidateResult> =
        runCatchingSuspend {
            val body =
                JSONObject(
                    mapOf(
                        "mobile" to mobile,
                        "inviteCode" to inviteCode,
                        "mobileVerificationToken" to mobileVerificationToken,
                    ),
                )
            val o = requireJsonObject(unwrapDriverBodyJson(postJsonRaw("/api/v0/driver-app/auth/invite/validate", body, bearer = null)))
            InviteValidateResult(
                sessionToken = o.getString("sessionToken"),
                driverName = o.optString("driverName", ""),
                foName = o.optString("foName", ""),
                foCompanyId = o.optLong("foCompanyId"),
            )
        }

    suspend fun driverInviteSetPin(sessionToken: String, pin: String): Result<String> =
        runCatchingSuspend {
            val body = JSONObject(mapOf("sessionToken" to sessionToken, "pin" to pin))
            val unwrapped = unwrapDriverBodyJson(postJsonRaw("/api/v0/driver-app/auth/invite/set-pin", body, bearer = null))
            oauthAccessTokenFromAny(parseJsonFlexibleObj(unwrapped))
                ?: oauthAccessTokenFromAny(unwrapped)
                ?: throw DriverApiException("Missing access token")
        }

    suspend fun driverOauthOtpGrant(mobile: String, otp: String): Result<String> =
        withContext(Dispatchers.IO) {
            try {
                val form =
                    FormBody.Builder(Charsets.UTF_8)
                        .add("grant_type", "otp")
                        .add("username", mobile.trim())
                        .add("otp", otp.trim())
                        .add("client_id", "mgl-driver-app-client")
                        .add("client_secret", "driver-app-secret")
                        .build()
                val req =
                    Request.Builder()
                        .url("$base/oauth/token")
                        .post(form)
                        .header("Accept", "application/json")
                        .header("User-Agent", USER_AGENT)
                        .build()
                client.newCall(req).execute().use { resp ->
                    val text = resp.body?.string().orEmpty()
                    if (!resp.isSuccessful) {
                        val parsed = try { parseJsonFlexible(text) } catch (_: Exception) { null }
                        return@withContext Result.failure(DriverApiException(peelOAuthError(parsed)))
                    }
                    val jo = JSONObject(text)
                    val token =
                        jo.optString("access_token", "").takeIf { it.isNotEmpty() }
                            ?: jo.optString("accessToken", "").takeIf { it.isNotEmpty() }
                    if (token == null) Result.failure(DriverApiException("OAuth: no token"))
                    else Result.success(token)
                }
            } catch (e: DriverApiException) {
                Result.failure(e)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    suspend fun driverFoList(bearerPartial: String): Result<List<FoListEntry>> =
        runCatchingSuspend {
            val data = unwrapDriverBodyJson(getRaw("/api/v0/driver-app/auth/fo-list", bearerPartial))
            foListFromAny(data)
        }

    suspend fun driverFoSelect(
        bearerPartial: String,
        foCompanyId: Long,
        pin: String,
    ): Result<String> =
        runCatchingSuspend {
            val body = JSONObject(mapOf("foCompanyId" to foCompanyId, "pin" to pin))
            val unwrapped = unwrapDriverBodyJson(postJsonRaw("/api/v0/driver-app/auth/fo-select", body, bearer = bearerPartial))
            oauthAccessTokenFromAny(parseJsonFlexibleObj(unwrapped))
                ?: oauthAccessTokenFromAny(unwrapped)
                ?: throw DriverApiException("Missing fleet token")
        }

    suspend fun driverGetHome(token: String): Result<DriverHomeJson> =
        runCatchingSuspend { parseHome(requireJsonObject(unwrapDriverBodyJson(getRaw("/api/v0/driver-app/home", token)))) }

    suspend fun driverGetProfile(token: String): Result<DriverProfileJson> =
        runCatchingSuspend { parseProfile(requireJsonObject(unwrapDriverBodyJson(getRaw("/api/v0/driver-app/profile", token)))) }

    suspend fun driverGetAssignments(token: String): Result<List<DriverAssignmentJson>> =
        runCatchingSuspend { parseAssignments(unwrapDriverBodyJson(getRaw("/api/v0/driver-app/assignments", token))) }

    suspend fun driverAcceptPairing(token: String, pairingCode: String): Result<Pair<String, String>> =
        runCatchingSuspend {
            val o =
                requireJsonObject(
                    unwrapDriverBodyJson(
                        postJsonRaw(
                            "/api/v0/driver-app/vehicle/accept-pairing",
                            JSONObject().put("pairingCode", pairingCode),
                            bearer = token,
                        ),
                    ),
                )
            o.optString("vehicleRegNo", "") to o.optString("status", "")
        }

    suspend fun driverQrPay(
        token: String,
        txnId: String,
        vehicleRegNoNorm: String,
        pin: String,
        mid: String,
        terminalId: String,
        amountPaise: Long,
        expiryEpoch: Long,
        sign: String,
    ): Result<QrPayResultJson> =
        runCatchingSuspend {
            val body =
                JSONObject(
                    mapOf(
                        "txnId" to txnId,
                        "vehicleRegNo" to vehicleRegNoNorm,
                        "pin" to pin,
                        "mid" to mid,
                        "terminalId" to terminalId,
                        "amountPaise" to amountPaise,
                        "expiryEpoch" to expiryEpoch,
                        "sign" to sign,
                    ),
                )
            val o = requireJsonObject(unwrapDriverBodyJson(postJsonRaw("/api/v0/driver-app/qr/pay", body, bearer = token)))
            val stRaw = o.optString("status", "")
            val st = if (stRaw.isEmpty()) null else stRaw.uppercase()
            QrPayResultJson(
                serverTxnId = o.optString("serverTxnId").ifEmpty { null },
                vehicleRegNo = o.optString("vehicleRegNo").ifEmpty { null },
                amountINR = o.optNullableDouble("amountINR"),
                newBalanceINR = o.optNullableDouble("newBalanceINR"),
                authCode = o.optString("authCode").ifEmpty { null },
                txnTime = o.optString("txnTime").ifEmpty { null },
                status = if (st == "FAILED") "FAILED" else "SUCCESS",
                quantityKg = o.optNullableDouble("quantityKg"),
            )
        }

    suspend fun driverGetTransactions(
        token: String,
        vehicleId: String,
        page: Int = 0,
    ): Result<TxnsPageParsed> =
        runCatchingSuspend {
            val q = if (page > 0) "?page=$page" else ""
            val vid = URLEncoder.encode(vehicleId, Charsets.UTF_8.name())
            normalizeDriverTransactionsPayload(unwrapDriverBodyJson(getRaw("/api/v0/driver-app/vehicles/$vid/transactions$q", token)))
        }

    private suspend inline fun <T> runCatchingSuspend(crossinline block: suspend () -> T): Result<T> =
        withContext(Dispatchers.IO) {
            try {
                Result.success(block())
            } catch (e: DriverApiException) {
                Result.failure(e)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    private suspend fun getRaw(path: String, bearer: String?): String =
        withContext(Dispatchers.IO) {
            val url = "$base$path"
            val rb =
                Request.Builder()
                    .url(url)
                    .get()
                    .header("Accept", "application/json")
                    .header("User-Agent", USER_AGENT)
            bearer?.takeIf { it.isNotBlank() }?.let { rb.header("Authorization", "Bearer $it") }
            client.newCall(rb.build()).execute().use { resp ->
                val text = resp.body?.string().orEmpty()
                if (!resp.isSuccessful) failHttp(text, resp.code)
                text
            }
        }

    private suspend fun postJsonRaw(
        path: String,
        json: JSONObject,
        bearer: String?,
    ): String =
        withContext(Dispatchers.IO) {
            val body = json.toString().toRequestBody(JSON_MEDIA)
            val rb =
                Request.Builder()
                    .url("$base$path")
                    .post(body)
                    .header("Accept", "application/json")
                    .header("Content-Type", "application/json")
                    .header("User-Agent", USER_AGENT)
            bearer?.takeIf { it.isNotBlank() }?.let { rb.header("Authorization", "Bearer $it") }
            client.newCall(rb.build()).execute().use { resp ->
                val text = resp.body?.string().orEmpty()
                if (!resp.isSuccessful) failHttp(text, resp.code)
                text
            }
        }

    private fun failHttp(body: String, code: Int): Nothing {
        val msg =
            try {
                extractFleetApiErrorMessage(parseJsonFlexible(body))
            } catch (_: Exception) {
                null
            }
        throw DriverApiException(msg ?: "HTTP $code")
    }

    private fun requireJsonBody(text: String): Any? = unwrapDriverBody(parseJsonFlexible(text))

    private fun foListFromAny(data: Any?): List<FoListEntry> =
        when (data) {
            is JSONArray ->
                List(data.length()) { i ->
                    data.getJSONObject(i).let { fo ->
                        FoListEntry(
                            foCompanyId = fo.optLong("foCompanyId"),
                            foName = fo.optString("foName"),
                            foStatus = fo.optString("foStatus"),
                        )
                    }
                }
            else -> emptyList()
        }

    private fun parseHome(o: JSONObject): DriverHomeJson =
        DriverHomeJson(
            hasActiveVehicle = o.optBoolean("hasActiveVehicle"),
            foName = o.optNullableString("foName"),
            vehicleRegNo = o.optNullableString("vehicleRegNo"),
            vehicleId = o.optNullableString("vehicleId"),
            assignmentType = o.optNullableString("assignmentType"),
            isCurrentlyEligible = if (o.has("isCurrentlyEligible")) o.optBoolean("isCurrentlyEligible") else null,
            currentlyEligible = if (o.has("currentlyEligible")) o.optBoolean("currentlyEligible") else null,
            totalBalanceINR = o.optNullableDouble("totalBalanceINR"),
            shiftDaysOfWeek = o.optNullableString("shiftDaysOfWeek"),
            shiftStartTime = o.optNullableString("shiftStartTime"),
            shiftEndTime = o.optNullableString("shiftEndTime"),
            tripDate = o.optNullableString("tripDate"),
            tripStartTime = o.optNullableString("tripStartTime"),
            tripEndTime = o.optNullableString("tripEndTime"),
            tripStartLocation = o.optNullableString("tripStartLocation"),
        )

    private fun parseProfile(o: JSONObject): DriverProfileJson =
        DriverProfileJson(
            driverId = o.optString("driverId", ""),
            name = o.optString("name", ""),
            maskedMobile = o.optNullableString("maskedMobile"),
        )

    private fun parseAssignments(data: Any?): List<DriverAssignmentJson> =
        when (data) {
            is JSONArray ->
                List(data.length()) { i ->
                    data.getJSONObject(i).let { a ->
                        DriverAssignmentJson(
                            vehicleDriverId = a.optLong("vehicleDriverId"),
                            vehicleId = a.optString("vehicleId"),
                            vehicleRegNo = a.optString("vehicleRegNo"),
                            assignmentType = a.optString("assignmentType"),
                            status = a.optString("status"),
                            requiresPairing = a.optBoolean("requiresPairing"),
                            shiftDaysOfWeek = a.optNullableString("shiftDaysOfWeek"),
                            shiftStartTime = a.optNullableString("shiftStartTime"),
                            shiftEndTime = a.optNullableString("shiftEndTime"),
                            tripDate = a.optNullableString("tripDate"),
                            tripStartTime = a.optNullableString("tripStartTime"),
                            tripEndTime = a.optNullableString("tripEndTime"),
                            tripStartLocation = a.optNullableString("tripStartLocation"),
                            assignedAt = a.optNullableString("assignedAt"),
                        )
                    }
                }
            else -> emptyList()
        }

    private fun parseJsonFlexibleObj(unwrapped: Any?): Any? =
        when (unwrapped) {
            is String ->
                try {
                    parseJsonFlexible(unwrapped)
                } catch (_: Exception) {
                    unwrapped
                }
            else -> unwrapped
        }

    private fun requireJsonObject(any: Any?): JSONObject {
        require(any is JSONObject) { "Expected JSON object" }
        return any
    }

    private fun JSONObject.optNullableString(key: String): String? {
        if (!has(key) || JSONObject.NULL == opt(key)) return null
        return optString(key).ifBlank { null }
    }

    private fun JSONObject.optNullableDouble(key: String): Double? {
        if (!has(key) || JSONObject.NULL == opt(key)) return null
        return optDouble(key).let { if (it.isNaN()) null else it }
    }

    companion object {
        private val JSON_MEDIA = "application/json; charset=utf-8".toMediaType()
        private const val USER_AGENT = "mgl-fleet-android-sdk/1.0"
    }
}
