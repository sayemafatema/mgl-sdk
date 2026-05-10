package com.mgl.fleet.sdk.internal

import org.json.JSONArray
import org.json.JSONObject

internal fun parseJsonFlexible(text: String): Any {
    val t = text.trim()
    if (t.isEmpty()) return JSONObject()
    return try {
        JSONObject(t)
    } catch (_: Exception) {
        JSONArray(t)
    }
}

internal fun extractFleetApiErrorMessage(body: Any?): String? {
    if (body !is JSONObject) return null
    val er = body.opt("errorResponse")
    if (er is JSONObject) {
        listOf("errorMessage", "message", "error", "detail").forEach { k ->
            er.optString(k).trim().takeIf { it.isNotEmpty() }?.let { return it }
        }
    }
    listOf("errorMessage", "message", "error", "detail").forEach { k ->
        body.optString(k).trim().takeIf { it.isNotEmpty() }?.let { return it }
    }
    val p = body.opt("payload")
    if (p is String && p.isNotBlank() && body.optString("response_message") == "FAILURE") return p.trim()
    return null
}

/** Mirrors `driver-api.ts` peelFleetEnvelope. */
internal fun peelFleetEnvelope(raw: Any?): Any? {
    if (raw !is JSONObject) return raw
    if (!raw.has("payload") || !raw.has("response_message")) return raw
    val msg = raw.optString("response_message", "")
    val code = raw.opt("response_code")
    val errDetail = extractFleetApiErrorMessage(raw)
    val errorResponseBad =
        raw.has("errorResponse") &&
            raw.opt("errorResponse") != null &&
            raw.opt("errorResponse") !== JSONObject.NULL
    val codeNum = if (code is Number) code.toInt() else 0
    val isError =
        errorResponseBad ||
            msg == "FAILURE" ||
            codeNum >= 400
    if (isError) {
        throw DriverApiException(
            errDetail?.takeIf { it.isNotEmpty() }
                ?: msg.takeIf { it.isNotEmpty() && it != "FAILURE" }
                ?: (if (code is Number && codeNum != 0) "Error ${codeNum}" else null)
                ?: "Request failed",
        )
    }
    return raw.opt("payload")
}

internal fun unwrapIfWrapped(raw: Any?): Any? {
    val peeled = peelFleetEnvelope(raw)
    if (peeled is JSONObject && peeled.has("status") && peeled.has("data")) {
        val st = peeled.optString("status", "")
        if (st == "FAILURE") {
            val detail =
                peeled.optString("errorMessage").trim().ifEmpty { null }
                    ?: peeled.optString("message").trim().ifEmpty { null }
            throw DriverApiException(detail ?: "Request failed")
        }
        return peeled.opt("data")
    }
    return peeled
}

internal fun unwrapDriverBody(raw: Any?): Any? {
    val step = unwrapIfWrapped(raw) ?: return null
    if (step is JSONObject) {
        val keys = step.keys().asSequence().toList()
        if (keys.size == 1 && keys[0] == "data") {
            return step.opt("data")
        }
    }
    return step
}

internal fun unwrapDriverBodyJson(raw: String): Any? = unwrapDriverBody(parseJsonFlexible(raw))

internal fun oauthAccessTokenFromAny(o: Any?): String? =
    when (o) {
        is JSONObject ->
            sequenceOf(
                o.optNullableString("accessToken"),
                o.optNullableString("access_token"),
            ).firstOrNull { !it.isNullOrBlank() }
        else -> null
    }

private fun JSONObject.optNullableString(key: String): String? {
    if (!has(key) || JSONObject.NULL == opt(key)) return null
    return optString(key).ifBlank { null }
}

internal fun parseCheckMobile(data: Any?): CheckMobileStatus {
    require(data is JSONObject) { "Unexpected check-mobile response" }
    return when (data.optString("status", "").trim()) {
        "NEW_USER" -> CheckMobileStatus.NEW_USER
        "RETURNING_USER" -> CheckMobileStatus.RETURNING_USER
        else -> throw DriverApiException("Unexpected check-mobile response")
    }
}

internal fun unwrapInviteSendOtpInner(rawParsed: Any?): String {

    unwrapDriverBody(rawParsed)?.let {
        val s = it as? String ?: return@let
        if (s.isNotEmpty()) return s
    }
    unwrapIfWrapped(rawParsed)?.let { u ->
        if (u is String && u.isNotEmpty()) return u
    }

    peelFleetEnvelope(rawParsed)?.let { p ->
        if (p is String && p.isNotEmpty()) return p
    }

    throw DriverApiException("Unexpected send-otp response")
}

internal fun peelOAuthError(body: Any?): String {
    if (body !is JSONObject) return "OAuth failed"
    extractFleetApiErrorMessage(body)?.let { return it }
    body.optString("error_description").trim().takeIf { it.isNotEmpty() }?.let { return it }
    body.optString("error").takeIf { it.isNotEmpty() }?.let { return it }
    return "OAuth failed"
}

internal class DriverApiException(message: String) : Exception(message)

internal data class DriverTxnRowParse(
    val serverTxnId: String,
    val vehicleRegNo: String,
    val amountINR: Double,
    val status: String,
    val driverName: String,
    val createdOn: String,
)

internal data class TxnsPageParsed(
    val rows: List<DriverTxnRowParse>,
    val page: Int,
    val limit: Int,
    val totalElements: Int,
    val totalPages: Int,
)

internal fun normalizeDriverTransactionsPayload(data: Any?): TxnsPageParsed =
    when (data) {
        is JSONArray -> {
            val rows = txnRowsFromArr(data)
            TxnsPageParsed(rows, 0, rows.size, rows.size, if (rows.isNotEmpty()) 1 else 0)
        }
        is JSONObject -> {
            val content = data.optJSONArray("content") ?: JSONArray()
            val rows = txnRowsFromArr(content)
            TxnsPageParsed(
                rows,
                data.optInt("page", 0),
                data.optInt("limit", if (rows.isEmpty()) 0 else rows.size),
                data.optInt("totalElements", rows.size),
                data.optInt("totalPages", 0),
            )
        }
        else -> TxnsPageParsed(emptyList(), 0, 0, 0, 0)
    }

private fun txnRowsFromArr(arr: JSONArray): List<DriverTxnRowParse> =
    List(arr.length()) { i ->
        arr.getJSONObject(i).let { o ->
            DriverTxnRowParse(
                serverTxnId = o.optString("serverTxnId"),
                vehicleRegNo = o.optString("vehicleRegNo"),
                amountINR = o.optDouble("amountINR"),
                status = o.optString("status"),
                driverName = o.optString("driverName"),
                createdOn = o.optString("createdOn"),
            )
        }
    }
