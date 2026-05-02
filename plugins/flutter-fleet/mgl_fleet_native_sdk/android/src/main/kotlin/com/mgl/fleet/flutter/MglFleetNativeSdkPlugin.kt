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
            "initialize" -> {
                val args = call.arguments as? Map<*, *> ?: run {
                    result.error("BAD_ARGS", "Expected argument map", null)
                    return
                }
                val base = args["apiBaseUrl"] as? String ?: run {
                    result.error("BAD_ARGS", "apiBaseUrl required", null)
                    return
                }
                val useMock = args["useMock"] as? Boolean ?: true
                val token = args["authToken"] as? String
                val ctx = activity?.applicationContext ?: run {
                    result.error("NO_ACTIVITY", "Attach before initialize", null)
                    return
                }
                FleetSdk.initialize(ctx, FleetSdkOptions(apiBaseUrl = base, authToken = token, useMock = useMock))
                result.success(null)
            }

            "presentFleetFlow" -> {
                val act = activity ?: run {
                    result.error("NO_ACTIVITY", "Need FragmentActivity", null)
                    return
                }
                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                val corr = args["correlationId"] as? String
                FleetSdk.presentFleetFlow(
                    act,
                    corr?.let { FleetSessionOptions(correlationId = it) },
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

            else -> result.notImplemented()
        }
    }
}
