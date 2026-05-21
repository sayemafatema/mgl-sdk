package com.mgl.fleet.sdk

/** Options mirror TS `FleetSDKConfig` / Flutter `FleetConfig`. */
data class FleetSdkOptions(
    val apiBaseUrl: String,
    val authToken: String? = null,
    val useMock: Boolean = true,
    /** When opening the flow already FO-authenticated (`authToken` set), pass this so Profile → Change PIN can call `pin/reset`. */
    val foCompanyId: Long? = null,
)

/** Optional per-session overrides for native presentation. */
data class FleetSessionOptions(
    val correlationId: String? = null,
)

sealed class FleetSdkResult {
    data class Success(
        val event: String,
        val payload: Map<String, Any?> = emptyMap(),
    ) : FleetSdkResult()

    data class Failure(
        val exception: FleetSdkException,
    ) : FleetSdkResult()
}

fun interface FleetSdkCompletionCallback {
    fun onComplete(result: FleetSdkResult)
}
