package com.mgl.fleet.capacitor

import androidx.fragment.app.FragmentActivity
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.mgl.fleet.sdk.FleetSdk
import com.mgl.fleet.sdk.FleetSdkCompletionCallback
import com.mgl.fleet.sdk.FleetSdkOptions
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.FleetSessionOptions

@CapacitorPlugin(name = "MGLFleetSdk")
class FleetSdkPlugin : Plugin() {

    @PluginMethod
    fun initialize(call: PluginCall) {
        val apiBaseUrl = call.getString("apiBaseUrl") ?: run {
            call.reject("apiBaseUrl is required")
            return
        }
        val useMock = call.getBoolean("useMock", true)
        val authToken = call.getString("authToken")
        FleetSdk.initialize(
            bridge.activity.applicationContext,
            FleetSdkOptions(
                apiBaseUrl = apiBaseUrl,
                authToken = authToken,
                useMock = useMock,
            ),
        )
        call.resolve()
    }

    @PluginMethod
    fun presentFleetFlow(call: PluginCall) {
        val activity = bridge.activity as? FragmentActivity ?: run {
            call.reject("Host Activity must extend FragmentActivity")
            return
        }
        call.setKeepAlive(true)
        val correlationId = call.getString("correlationId")
        val session = correlationId?.let { FleetSessionOptions(correlationId = it) }

        FleetSdk.presentFleetFlow(activity, session, object : FleetSdkCompletionCallback {
            override fun onComplete(result: FleetSdkResult) {
                bridge.activity.runOnUiThread {
                    when (result) {
                        is FleetSdkResult.Success -> {
                            val payloadObj = JSObject()
                            result.payload.forEach { (k, v) ->
                                when (v) {
                                    null -> payloadObj.put(k, null)
                                    is Number -> payloadObj.put(k, v.toDouble())
                                    is Boolean -> payloadObj.put(k, v)
                                    else -> payloadObj.put(k, v.toString())
                                }
                            }
                            val root = JSObject()
                            root.put("event", result.event)
                            root.put("payload", payloadObj)
                            call.resolve(root)
                        }

                        is FleetSdkResult.Failure -> {
                            call.reject(
                                result.exception.message ?: "FleetSdk error",
                                result.exception,
                                result.exception.code.toString(),
                            )
                        }
                    }
                }
            }
        })
    }
}
