package com.mgl.fleet.sdk.internal

import com.mgl.fleet.sdk.FleetSdkCompletionCallback
import com.mgl.fleet.sdk.FleetSdkEventListener
import com.mgl.fleet.sdk.FleetSessionOptions

internal object FleetPresentationBridge {
    var pendingSession: FleetSessionOptions? = null
    var pendingCallback: FleetSdkCompletionCallback? = null
    val listeners = mutableListOf<Pair<String, FleetSdkEventListener>>()

    fun emit(name: String, payload: Map<String, Any?>? = null) {
        listeners.forEach { (_, listener) ->
            listener.onEvent(name, payload)
        }
    }
}
