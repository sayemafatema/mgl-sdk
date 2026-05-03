package com.mgl.fleet.sdk.internal

import android.os.Bundle
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton
import com.mgl.fleet.sdk.FleetSdkErrorCodes
import com.mgl.fleet.sdk.FleetSdkException
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.R
import com.mgl.fleet.sdk.api.FleetApiClient
import java.util.concurrent.Executors

/**
 * Fullscreen native shell — placeholder UI until parity checklist screens ship.
 */
internal class FleetSdkActivity : AppCompatActivity() {

    private val ioExecutor = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_fleet_sdk)

        FleetPresentationBridge.emit(
            "FLOW_STARTED",
            FleetPresentationBridge.pendingSession?.correlationId?.let {
                mapOf("correlationId" to it)
            },
        )

        findViewById<MaterialButton>(R.id.fleet_sdk_btn_complete).setOnClickListener {
            ioExecutor.execute {
                val driversResult = try {
                    FleetApiClient.default().listDrivers()
                } catch (e: FleetSdkException) {
                    runOnUiThread { finishWith(FleetSdkResult.Failure(e)) }
                    return@execute
                }
                runOnUiThread {
                    driversResult.fold(
                        onSuccess = { drivers ->
                            val id = drivers.firstOrNull()?.id ?: "unknown"
                            finishWith(
                                FleetSdkResult.Success(
                                    event = "FLEET_FLOW_COMPLETED",
                                    payload = mapOf("driverId" to id, "driverCount" to drivers.size),
                                ),
                            )
                        },
                        onFailure = {
                            finishWith(
                                FleetSdkResult.Failure(
                                    FleetSdkException(
                                        FleetSdkErrorCodes.NETWORK_ERROR,
                                        it.message ?: it.javaClass.simpleName ?: "Network error",
                                    ),
                                ),
                            )
                        },
                    )
                }
            }
        }

        findViewById<MaterialButton>(R.id.fleet_sdk_btn_cancel).setOnClickListener {
            cancelFlow()
        }

        onBackPressedDispatcher.addCallback(
            this,
            object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    cancelFlow()
                    remove()
                }
            },
        )
    }

    override fun onDestroy() {
        ioExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun cancelFlow() {
        finishWith(
            FleetSdkResult.Failure(
                FleetSdkException(
                    FleetSdkErrorCodes.USER_CANCELLED,
                    "User cancelled.",
                ),
            ),
        )
    }

    private fun finishWith(result: FleetSdkResult) {
        val cb = FleetPresentationBridge.pendingCallback
        FleetPresentationBridge.pendingCallback = null
        FleetPresentationBridge.pendingSession = null
        cb?.onComplete(result)
        finish()
    }
}
