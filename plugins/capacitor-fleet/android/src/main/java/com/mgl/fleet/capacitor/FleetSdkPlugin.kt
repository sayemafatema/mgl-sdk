package com.mgl.fleet.capacitor

import android.util.Log
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
import org.json.JSONException
import org.json.JSONObject

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
        try {
            if (!performInitializeFromNested(call)) return
            executePresentFleetFlow(call)
        } catch (t: Throwable) {
            Log.e(TAG, "openFleetNativeFlow crashed", t)
            val ex = t as? Exception ?: RuntimeException(t)
            call.reject(
                ex.message ?: "openFleetNativeFlow failed",
                FleetSdkErrorCodes.INTERNAL_SDK_ERROR.toString(),
                ex,
            )
        }
    }

    @PluginMethod
    fun presentFleetFlow(call: PluginCall) {
        if (!FleetSdk.isInitialized()) {
            call.reject(
                "Fleet SDK is not initialized. Use openFleetNativeFlow() / openMglFleetNativeFlow() or await initialize() before presentFleetFlow().",
                "NOT_INITIALIZED",
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
        val initObj = readNestedJSObject(call, "initialize") ?: run {
            call.reject(
                "initialize object is required (nested options missing or wrong shape). Re-run npx cap sync and rebuild.",
            )
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
        val useMock = initObj.getBoolean("useMock", true) ?: true
        val authToken = initObj.getString("authToken")
        val foCompanyId = initObj.optionalFoCompanyId()
        FleetSdk.initialize(
            bridge.activity.applicationContext,
            FleetSdkOptions(
                apiBaseUrl = trimmed,
                authToken = authToken,
                useMock = useMock,
                foCompanyId = foCompanyId,
            ),
        )
        Log.i(TAG, "FleetSdk.initialize ok, apiBaseUrl length=${trimmed.length}")
        return true
    }

    /** @return false if rejected */
    private fun applyFleetInitialize(call: PluginCall, apiBaseUrl: String): Boolean {
        if (apiBaseUrl.isEmpty()) {
            call.reject("apiBaseUrl must not be blank")
            return false
        }
        val useMock = call.getBoolean("useMock", true) ?: true
        val authToken = call.getString("authToken")
        val foCompanyId = call.data.optionalFoCompanyId()
        FleetSdk.initialize(
            bridge.activity.applicationContext,
            FleetSdkOptions(
                apiBaseUrl = apiBaseUrl,
                authToken = authToken,
                useMock = useMock,
                foCompanyId = foCompanyId,
            ),
        )
        return true
    }

    /**
     * Capacitor may deserialize nested plugin options as Map rather than JSONObject;
     * [PluginCall.getObject] then returns null and init would silently fail. Coerce here.
     */
    private fun readNestedJSObject(call: PluginCall, key: String): JSObject? {
        val direct = call.getObject(key)
        if (direct != null) return direct
        val raw = call.data.opt(key) ?: return null
        val coerced = coerceToJSObject(raw)
        if (coerced == null) {
            Log.w(TAG, "Could not coerce key=$key from ${raw.javaClass.name}")
        }
        return coerced
    }

    private fun coerceToJSObject(raw: Any?): JSObject? {
        if (raw == null) return null
        if (raw is JSObject) return raw
        if (raw is JSONObject) {
            return try {
                JSObject.fromJSONObject(raw)
            } catch (_: JSONException) {
                null
            }
        }
        if (raw is Map<*, *>) {
            val o = JSObject()
            for ((k, v) in raw) {
                val key = k as? String ?: continue
                putCoercedValue(o, key, v)
            }
            return o
        }
        return null
    }

    private fun putCoercedValue(o: JSObject, key: String, v: Any?) {
        when (v) {
            null -> o.put(key, JSONObject.NULL)
            is Boolean -> o.put(key, v)
            is Int -> o.put(key, v)
            is Long -> o.put(key, v)
            is Double -> o.put(key, v)
            is Float -> o.put(key, v.toDouble())
            is String -> o.put(key, v)
            is Map<*, *> -> coerceToJSObject(v)?.let { nested -> o.put(key, nested) }
            is JSONObject -> coerceToJSObject(v)?.let { nested -> o.put(key, nested) }
            else -> o.put(key, v.toString())
        }
    }

    private fun executePresentFleetFlow(call: PluginCall) {
        val activity = bridge.activity as? FragmentActivity ?: run {
            call.reject("Host Activity must extend FragmentActivity")
            return
        }
        call.setKeepAlive(true)
        val correlationIdForSession =
            call.getString("correlationId")
                ?: readNestedJSObject(call, "present")?.getString("correlationId")
        val session = correlationIdForSession?.let { FleetSessionOptions(correlationId = it) }

        Log.i(TAG, "presentFleetFlow starting, correlationId=${correlationIdForSession != null}")
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

    private companion object {
        private const val TAG = "MGLFleetSdk"
    }
}

private fun JSObject.optionalFoCompanyId(): Long? {
    return try {
        if (!has("foCompanyId")) return null
        val r = opt("foCompanyId")
        when {
            r == null || r === JSONObject.NULL -> null
            r is Int -> r.toLong()
            r is Long -> r
            r is Double -> r.toLong()
            r is Float -> r.toLong()
            r is Number -> r.toLong()
            r is String -> r.trim().toLongOrNull()
            else -> null
        }
    } catch (_: Exception) {
        null
    }
}
