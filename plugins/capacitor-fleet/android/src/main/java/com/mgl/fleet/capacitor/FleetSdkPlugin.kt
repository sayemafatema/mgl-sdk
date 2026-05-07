package com.mgl.fleet.capacitor

import androidx.fragment.app.FragmentActivity
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.mgl.fleet.sdk.FleetSdk
import com.mgl.fleet.sdk.FleetSdkCompletionCallback
import com.mgl.fleet.sdk.FleetSdkErrorCodes
import com.mgl.fleet.sdk.FleetSdkException
import com.mgl.fleet.sdk.FleetSdkOptions
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.FleetSessionOptions

@CapacitorPlugin(name = "MGLFleetSdk")
class FleetSdkPlugin : Plugin() {

    @PluginMethod
    fun initialize(call: PluginCall) {
        if (!performInitialize(call)) return
        call.resolve()
    }

    /** Single bridge call — initialize then present (avoids JS/plugin gaps between two native invokes). */
    @PluginMethod
    fun openFleetNativeFlow(call: PluginCall) {
        if (!performInitializeFromNested(call)) return
        executePresentFleetFlow(call)
    }

    @PluginMethod
    fun presentFleetFlow(call: PluginCall) {
        if (!FleetSdk.isInitialized()) {
            call.reject(
                "Fleet SDK is not initialized. Use openFleetNativeFlow() / openMglFleetNativeFlow() or await initialize() before presentFleetFlow().",
                "NOT_INITIALIZED",
                null,
            )
            return
        }
        executePresentFleetFlow(call)
    }

    /** @return false if rejected */
    private fun performInitialize(call: PluginCall): Boolean {
        val apiBaseUrlRaw = call.getString("apiBaseUrl") ?: run {
            call.reject("apiBaseUrl is required")
            return false
        }
        return applyFleetInitialize(call, apiBaseUrlRaw.trim())
    }

    /** @return false if rejected */
    private fun performInitializeFromNested(call: PluginCall): Boolean {
        val initObj = call.getObject("initialize") ?: run {
            call.reject("initialize object is required")
            return false
        }
        val apiBaseUrlRaw = initObj.getString("apiBaseUrl") ?: run {
            call.reject("apiBaseUrl is required")
            return false
        }
        val trimmed = apiBaseUrlRaw.trim()
        if (trimmed.isEmpty()) {
            call.reject("apiBaseUrl must not be blank")
            return false
        }
        val useMock = initObj.getBoolean("useMock", true)
        val authToken = initObj.getString("authToken")
        FleetSdk.initialize(
            bridge.activity.applicationContext,
            FleetSdkOptions(
                apiBaseUrl = trimmed,
                authToken = authToken,
                useMock = useMock,
            ),
        )
        return true
    }

    /** @return false if rejected */
    private fun applyFleetInitialize(call: PluginCall, apiBaseUrl: String): Boolean {
        if (apiBaseUrl.isEmpty()) {
            call.reject("apiBaseUrl must not be blank")
            return false
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
        return true
    }

    private fun executePresentFleetFlow(call: PluginCall) {
        val activity = bridge.activity as? FragmentActivity ?: run {
            call.reject("Host Activity must extend FragmentActivity")
            return
        }
        call.setKeepAlive(true)
        val correlationIdForSession =
            call.getString("correlationId")
                ?: call.getObject("present")?.getString("correlationId")
        val session = correlationIdForSession?.let { FleetSessionOptions(correlationId = it) }

        try {
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
                                val ex = result.exception
                                call.reject(ex.message ?: "FleetSdk error", ex.code.toString(), ex)
                            }
                        }
                    }
                }
            })
        } catch (e: FleetSdkException) {
            call.reject(e.message ?: "FleetSdk error", e.code.toString(), e)
        } catch (e: Exception) {
            call.reject(
                e.message ?: "FleetSdk error",
                FleetSdkErrorCodes.INTERNAL_SDK_ERROR.toString(),
                e,
            )
        }
    }
}
