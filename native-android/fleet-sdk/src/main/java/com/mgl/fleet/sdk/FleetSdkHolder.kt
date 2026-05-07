package com.mgl.fleet.sdk

import android.content.Context

internal object FleetSdkHolder {
    private var applicationContext: Context? = null
    private var fleetSdkOptions: FleetSdkOptions? = null

    internal fun isAttached(): Boolean =
        applicationContext != null && fleetSdkOptions != null

    fun attach(context: Context, opts: FleetSdkOptions) {
        applicationContext = context.applicationContext
        fleetSdkOptions = opts
    }

    fun applicationContext(): Context =
        applicationContext ?: throw FleetSdkException(
            FleetSdkErrorCodes.NOT_INITIALIZED,
            "FleetSdk.initialize must be called before presenting the flow.",
        )

    fun requireOptions(): FleetSdkOptions =
        fleetSdkOptions ?: throw FleetSdkException(
            FleetSdkErrorCodes.NOT_INITIALIZED,
            "FleetSdk.initialize must be called before API client usage.",
        )
}
