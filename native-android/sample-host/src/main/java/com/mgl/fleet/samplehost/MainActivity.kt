package com.mgl.fleet.samplehost

import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton
import com.google.android.material.snackbar.Snackbar
import com.mgl.fleet.sdk.FleetSdk
import com.mgl.fleet.sdk.FleetSdkOptions
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.FleetSessionOptions

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        FleetSdk.initialize(
            applicationContext,
            FleetSdkOptions(
                apiBaseUrl = "https://api.example.com",
                useMock = true,
            ),
        )

        findViewById<MaterialButton>(R.id.btn_open_fleet).setOnClickListener {
            FleetSdk.presentFleetFlow(
                this,
                FleetSessionOptions(correlationId = "sample-host"),
            ) { result ->
                when (result) {
                    is FleetSdkResult.Success -> {
                        Log.i(TAG, "Success event=${result.event} payload=${result.payload}")
                        Snackbar.make(
                            findViewById(android.R.id.content),
                            "Fleet: ${result.event}",
                            Snackbar.LENGTH_LONG,
                        ).show()
                    }

                    is FleetSdkResult.Failure -> {
                        Log.w(TAG, "Failure code=${result.exception.code} msg=${result.exception.message}")
                        Snackbar.make(
                            findViewById(android.R.id.content),
                            "Fleet error: ${result.exception.code}",
                            Snackbar.LENGTH_LONG,
                        ).show()
                    }
                }
            }
        }
    }

    companion object {
        private const val TAG = "FleetSample"
    }
}
