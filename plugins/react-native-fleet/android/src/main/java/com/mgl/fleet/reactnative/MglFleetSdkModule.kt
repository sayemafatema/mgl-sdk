package com.mgl.fleet.reactnative

import androidx.fragment.app.FragmentActivity
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.mgl.fleet.sdk.FleetSdk
import com.mgl.fleet.sdk.FleetSdkCompletionCallback
import com.mgl.fleet.sdk.FleetSdkOptions
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.FleetSessionOptions

class MglFleetSdkModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "MglFleetSdk"

    @ReactMethod
    fun initialize(opts: ReadableMap, promise: Promise) {
        val apiBaseUrl = opts.getString("apiBaseUrl") ?: run {
            promise.reject("BAD_ARGS", "apiBaseUrl required")
            return
        }
        val useMock = if (opts.hasKey("useMock")) opts.getBoolean("useMock") else true
        val authToken = if (opts.hasKey("authToken")) opts.getString("authToken") else null
        FleetSdk.initialize(
            reactApplicationContext.applicationContext,
            FleetSdkOptions(apiBaseUrl = apiBaseUrl, authToken = authToken, useMock = useMock),
        )
        promise.resolve(null)
    }

    @ReactMethod
    fun presentFleetFlow(opts: ReadableMap?, promise: Promise) {
        val activity = currentActivity as? FragmentActivity ?: run {
            promise.reject("NO_ACTIVITY", "Host Activity must extend FragmentActivity")
            return
        }
        val corr = opts?.takeIf { it.hasKey("correlationId") }?.getString("correlationId")
        FleetSdk.presentFleetFlow(
            activity,
            corr?.let { FleetSessionOptions(correlationId = it) },
            object : FleetSdkCompletionCallback {
                override fun onComplete(result: FleetSdkResult) {
                    activity.runOnUiThread {
                        when (result) {
                            is FleetSdkResult.Success -> {
                                val map = Arguments.createMap()
                                map.putString("event", result.event)
                                val payload = Arguments.createMap()
                                result.payload.forEach { (k, v) ->
                                    when (v) {
                                        null -> payload.putNull(k)
                                        is Boolean -> payload.putBoolean(k, v)
                                        is Int -> payload.putInt(k, v)
                                        is Long -> payload.putDouble(k, v.toDouble())
                                        is Double -> payload.putDouble(k, v)
                                        else -> payload.putString(k, v.toString())
                                    }
                                }
                                map.putMap("payload", payload)
                                promise.resolve(map)
                            }

                            is FleetSdkResult.Failure -> {
                                promise.reject(
                                    result.exception.code.toString(),
                                    result.exception.message,
                                    result.exception,
                                )
                            }
                        }
                    }
                }
            },
        )
    }
}
