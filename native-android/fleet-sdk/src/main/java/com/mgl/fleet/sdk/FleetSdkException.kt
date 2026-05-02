package com.mgl.fleet.sdk

/** Structured SDK failure (Digitap-style numeric codes). */
data class FleetSdkException(
    val code: Int,
    override val message: String,
) : Exception(message)

object FleetSdkErrorCodes {
    const val INVALID_INPUT = 1001
    const val NOT_INITIALIZED = 1002
    const val USER_CANCELLED = 1003
    const val INTERNAL_SDK_ERROR = 1004
    const val PERMISSION_DENIED = 1005
    const val NETWORK_ERROR = 1007
}
