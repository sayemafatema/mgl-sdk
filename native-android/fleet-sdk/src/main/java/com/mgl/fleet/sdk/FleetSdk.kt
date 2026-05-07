package com.mgl.fleet.sdk

import android.content.Context
import android.content.Intent
import android.os.Looper
import androidx.fragment.app.FragmentActivity
import com.mgl.fleet.sdk.internal.FleetPresentationBridge
import com.mgl.fleet.sdk.internal.FleetSdkActivity

/**
 * Native Fleet SDK entry — initialize once, then present fullscreen flow.
 */
object FleetSdk {

    fun initialize(applicationContext: Context, options: FleetSdkOptions) {
        FleetSdkHolder.attach(applicationContext, options)
    }

    /** True once [initialize] has run successfully in this process. */
    fun isInitialized(): Boolean = FleetSdkHolder.isAttached()

    /**
     * Presents native Fleet UI over [activity]. Completion runs on main thread when flow finishes.
     */
    fun presentFleetFlow(
        activity: FragmentActivity,
        session: FleetSessionOptions?,
        callback: FleetSdkCompletionCallback,
    ) {
        FleetSdkHolder.applicationContext()
        FleetPresentationBridge.pendingSession = session
        FleetPresentationBridge.pendingCallback = callback
        val intent = Intent(activity, FleetSdkActivity::class.java)
        val launch = Runnable { activity.startActivity(intent) }
        if (Looper.myLooper() == Looper.getMainLooper()) {
            launch.run()
        } else {
            activity.runOnUiThread(launch)
        }
    }

    /** Optional analytics hooks — bridges may subscribe via JNI/reflection layers later. */
    fun addListener(tag: String, listener: FleetSdkEventListener) {
        FleetPresentationBridge.listeners.add(tag to listener)
    }

    fun removeListener(tag: String) {
        FleetPresentationBridge.listeners.removeAll { it.first == tag }
    }
}

fun interface FleetSdkEventListener {
    fun onEvent(name: String, payload: Map<String, Any?>?)
}
