package com.mgl.fleet.sdk.demo

/**
 * User-visible API / validation banners aligned with [app/page.tsx]
 * (`bannerFromThrownError`, `bannerForOtpFailure`, `bannerForPinFailure`, `bannerForGenericFailure`).
 */
object ReactParityBanner {
    const val VALID_MOBILE_ERROR = "Please enter a valid mobile number"

    const val INVALID_FLEETPAY_QR = "Invalid Fleetpay QR. Point at the station QR (must include tid)."
    const val SELECT_VEHICLE_FIRST = "Select a vehicle first."
    const val LOGIN_FAILED_NO_TOKEN = "Login failed: no token."
    const val NO_ACTIVE_FLEET = "No active fleet — use your invite code."
    const val NEW_USER_CONTINUE_INVITE = "New user — continue with invite code."
    const val INVITE_VERIFY_MOBILE_FIRST = "Invite flow incomplete — verify mobile first."
    const val USE_SEND_OTP_ON_LOGIN = "Use “Send OTP” on the login screen."
    const val COMPLETE_MOBILE_OTP_FIRST = "Complete mobile OTP verification first."
    const val SESSION_MISSING_INVITE = "Session missing — go back to invite step."
    const val PINS_DONT_MATCH_1F = "PINs don't match. Try again."
    const val PINS_DONT_MATCH_CONFIRM = "PINs didn't match. Try again."
    const val COULD_NOT_REFRESH_TXN = "Could not refresh transactions (missing vehicle id)."

    private const val BANNER_MSG_MAX = 280

    private fun errTxt(t: Throwable): String =
        t.message?.trim().orEmpty().ifEmpty { t.javaClass.simpleName }

    private fun isLikelyNetworkFailure(msg: String): Boolean =
        Regex("network|fetch|failed to fetch|timeout|502|503|504|econn|aborted", RegexOption.IGNORE_CASE)
            .containsMatchIn(msg)

    fun fromThrowable(
        e: Throwable?,
        transportFallback: String,
    ): String {
        val m = e?.let { errTxt(it) }.orEmpty()
        if (isLikelyNetworkFailure(m)) return transportFallback
        val t = m.trim()
        if (t.isEmpty()) return "Request failed."
        return if (t.length <= BANNER_MSG_MAX) t else "${t.take(BANNER_MSG_MAX - 1)}…"
    }

    fun forOtpFailure(e: Throwable?) =
        fromThrowable(e, "Could not verify OTP. Check your connection and try again.")

    fun forPinFailure(e: Throwable?) =
        fromThrowable(e, "Could not verify PIN. Check your connection and try again.")

    fun forGenericFailure(e: Throwable?) =
        fromThrowable(e, "Something went wrong. Check your connection and try again.")
}
