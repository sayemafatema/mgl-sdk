package com.mgl.fleet.flutter

import androidx.fragment.app.FragmentActivity
import com.mgl.fleet.sdk.FleetSdk
import com.mgl.fleet.sdk.FleetSdkCompletionCallback
import com.mgl.fleet.sdk.FleetSdkOptions
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.FleetSessionOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MglFleetNativeSdkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: FragmentActivity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "mgl_fleet_native_sdk")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? FragmentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "isInitialized" -> result.success(FleetSdk.isInitialized())
            "presentFleetFlow" -> handlePresent(call, result)
            "openFleetNativeFlow" -> handleOpenFleetNativeFlow(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            result.error("BAD_ARGS", "Expected argument map", null)
            return
        }
        val ctx = activity?.applicationContext ?: run {
            result.error("NO_ACTIVITY", "Attach Flutter engine to an Activity before initialize", null)
            return
        }
        val opts = parseFleetOptions(args) ?: run {
            result.error("BAD_ARGS", "apiBaseUrl required", null)
            return
        }
        FleetSdk.initialize(ctx, opts)
        result.success(null)
    }

    private fun handleOpenFleetNativeFlow(call: MethodCall, result: MethodChannel.Result) {
        val root = call.arguments as? Map<*, *> ?: run {
            result.error("BAD_ARGS", "Expected argument map", null)
            return
        }
        val initMap = root["initialize"] as? Map<*, *> ?: run {
            result.error("BAD_ARGS", "initialize object is required", null)
            return
        }
        val ctx = activity?.applicationContext ?: run {
            result.error("NO_ACTIVITY", "Attach Flutter engine to an Activity before openFleetNativeFlow", null)
            return
        }
        val opts = parseFleetOptions(initMap) ?: run {
            result.error("BAD_ARGS", "apiBaseUrl required", null)
            return
        }
        FleetSdk.initialize(ctx, opts)

        val presentMap = root["present"] as? Map<*, *>
        val corr = presentMap?.get("correlationId") as? String
        executePresent(corr, result)
    }

    private fun handlePresent(call: MethodCall, result: MethodChannel.Result) {
        if (!FleetSdk.isInitialized()) {
            result.error(
                "NOT_INITIALIZED",
                "Fleet SDK is not initialized. Use openFleetNativeFlow() or await initialize() before presentFleetFlow().",
                null,
            )
            return
        }
        val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
        val corr = args["correlationId"] as? String
        executePresent(corr, result)
    }

    private fun executePresent(correlationId: String?, result: MethodChannel.Result) {
        val act = activity ?: run {
            result.error("NO_ACTIVITY", "Need FragmentActivity (FlutterFragmentActivity)", null)
            return
        }
        FleetSdk.presentFleetFlow(
            act,
            correlationId?.let { FleetSessionOptions(correlationId = it) },
            object : FleetSdkCompletionCallback {
                override fun onComplete(sdk: FleetSdkResult) {
                    act.runOnUiThread {
                        when (sdk) {
                            is FleetSdkResult.Success -> {
                                val payloadMap = HashMap<String, Any?>()
                                sdk.payload.forEach { (k, v) -> payloadMap[k] = v }
                                result.success(
                                    mapOf(
                                        "event" to sdk.event,
                                        "payload" to payloadMap,
                                    ),
                                )
                            }

                            is FleetSdkResult.Failure -> {
                                result.error(
                                    sdk.exception.code.toString(),
                                    sdk.exception.message,
                                    null,
                                )
                            }
                        }
                    }
                }
            },
        )
    }

    private fun parseFleetOptions(args: Map<*, *>): FleetSdkOptions? {
        val base = (args["apiBaseUrl"] as? String)?.trim() ?: return null
        if (base.isEmpty()) return null
        val useMock = args["useMock"] as? Boolean ?: true
        val token = args["authToken"] as? String
        val foCompanyId = parseFoCompanyId(args["foCompanyId"])
        return FleetSdkOptions(
            apiBaseUrl = base,
            authToken = token,
            useMock = useMock,
            foCompanyId = foCompanyId,
        )
    }

    private fun parseFoCompanyId(raw: Any?): Long? {
        return when (raw) {
            null -> null
            is Long -> raw
            is Int -> raw.toLong()
            is Double -> raw.toLong()
            is Number -> raw.toLong()
            is String -> raw.trim().toLongOrNull()
            else -> null
        }
    }
}
