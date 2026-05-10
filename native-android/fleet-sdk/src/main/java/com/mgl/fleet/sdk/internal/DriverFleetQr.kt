package com.mgl.fleet.sdk.internal

import java.net.URI
import java.net.URLDecoder

internal fun parseFleetpayPayUri(raw: String): FleetpayQrPayload? {
    val s = raw.trim()
    if (!Regex("^fleetpay://", RegexOption.IGNORE_CASE).containsMatchIn(s)) return null

    val uri =
        try {
            URI.create(s)
        } catch (_: Exception) {
            return null
        }
    val pathNorm = uri.path?.trim('/')?.lowercase()?.trimEnd('/') ?: ""
    val payPathOk = pathNorm.isEmpty() || pathNorm.endsWith("/pay")
    val host = uri.host?.lowercase() ?: ""
    val payHostOk = host == "pay"
    if (!payHostOk && !payPathOk) return null

    fun qp(name: String): String? {
        val q = uri.query ?: return null
        for (part in q.split('&')) {
            val idx = part.indexOf('=')
            val k = if (idx >= 0) part.substring(0, idx) else part
            val v = if (idx >= 0) part.substring(idx + 1) else ""
            if (k == name) {
                return try {
                    URLDecoder.decode(v.replace('+', ' '), Charsets.UTF_8.name())
                } catch (_: Exception) {
                    v
                }
            }
        }
        return null
    }

    val txnId = qp("txn") ?: return null
    val mid = qp("mid") ?: return null
    val terminalId = qp("tid") ?: return null
    val am = qp("am") ?: return null
    val exp = qp("exp") ?: return null
    val sign = qp("sign") ?: return null
    val amountPaise = am.toDoubleOrNull()?.toLong() ?: return null
    val expiryEpoch = exp.toDoubleOrNull()?.toLong() ?: return null
    val mn = qp("mn")

    val merchantName =
        mn?.let { m ->
            try {
                URLDecoder.decode(m.replace('+', ' '), Charsets.UTF_8.name())
            } catch (_: Exception) {
                m
            }
        }

    return FleetpayQrPayload(
        txnId = txnId,
        mid = mid,
        terminalId = terminalId,
        amountPaise = amountPaise,
        expiryEpoch = expiryEpoch,
        sign = sign,
        merchantName = merchantName,
        currency = qp("cu"),
    )
}

internal fun paiseToInrDisplay(amountPaise: Long): String {
    val inr = amountPaise.toDouble() / 100.0
    return String.format(java.util.Locale("en", "IN"), "%.2f", inr)
}

internal fun validIndianMobile10(digitsOnly: String): Boolean {
    val d = digitsOnly.filter(Char::isDigit).takeLast(10)
    if (d.length != 10) return false
    val first = d[0].digitToIntOrNull() ?: return false
    return first in 6..9
}
