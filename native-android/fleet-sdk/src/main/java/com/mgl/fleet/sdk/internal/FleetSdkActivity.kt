package com.mgl.fleet.sdk.internal

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.mgl.fleet.sdk.FleetPresentationBridge
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.demo.ui.FleetDriverFlow
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Full-screen native Fleet driver demo (parity with repo `app/page.tsx`), Jetpack Compose.
 */
internal class FleetSdkActivity : AppCompatActivity() {

    private val completionHandled = AtomicBoolean(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        FleetPresentationBridge.emit(
            "FLOW_STARTED",
            FleetPresentationBridge.pendingSession?.correlationId?.let {
                mapOf("correlationId" to it)
            },
        )

        setContent {
            Surface(modifier = Modifier.fillMaxSize()) {
                FleetDriverFlow(onFinished = ::deliverFinish)
            }
        }
    }

    private fun deliverFinish(result: FleetSdkResult) {
        if (!completionHandled.compareAndSet(false, true)) return
        val cb = FleetPresentationBridge.pendingCallback
        FleetPresentationBridge.pendingCallback = null
        FleetPresentationBridge.pendingSession = null
        cb?.onComplete(result)
        finish()
    }
}
