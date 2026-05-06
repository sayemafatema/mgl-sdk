package com.mgl.fleet.sdk.internal

import android.os.Bundle
import android.view.View
import android.view.ViewParent
import android.widget.TextView
import android.util.Patterns
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.addTextChangedListener
import com.google.android.material.button.MaterialButton
import com.google.android.material.checkbox.MaterialCheckBox
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import com.mgl.fleet.sdk.FleetSdkErrorCodes
import com.mgl.fleet.sdk.FleetSdkException
import com.mgl.fleet.sdk.FleetSdkResult
import com.mgl.fleet.sdk.R
import com.mgl.fleet.sdk.api.Driver
import com.mgl.fleet.sdk.api.FleetApiClient
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Fullscreen native flow: welcome → sign-in / sign-up → fleet summary → complete.
 */
internal class FleetSdkActivity : AppCompatActivity() {

    private enum class FlowStep {
        WELCOME,
        AUTH,
        FLEET,
    }

    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val completionHandled = AtomicBoolean(false)

    private lateinit var subtitle: TextView
    private lateinit var stepWelcome: View
    private lateinit var stepAuthScroll: View
    private lateinit var stepFleet: View
    private lateinit var cbNewAccount: MaterialCheckBox
    private lateinit var ilName: TextInputLayout
    private lateinit var etName: TextInputEditText
    private lateinit var etEmail: TextInputEditText
    private lateinit var etPassword: TextInputEditText
    private lateinit var loading: View
    private lateinit var driversSummary: TextView
    private lateinit var completeBtn: MaterialButton

    private var step: FlowStep = FlowStep.WELCOME
    private var loadedDrivers: List<Driver>? = null
    private var fleetLoadInFlight = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_fleet_sdk)

        subtitle = findViewById(R.id.fleet_sdk_subtitle)
        stepWelcome = findViewById(R.id.fleet_step_welcome)
        stepAuthScroll = findViewById(R.id.fleet_step_auth_scroll)
        stepFleet = findViewById(R.id.fleet_step_fleet)
        cbNewAccount = findViewById(R.id.fleet_cb_new_account)
        ilName = findViewById(R.id.fleet_il_name)
        etName = findViewById(R.id.fleet_et_name)
        etEmail = findViewById(R.id.fleet_et_email)
        etPassword = findViewById(R.id.fleet_et_password)
        loading = findViewById(R.id.fleet_loading)
        driversSummary = findViewById(R.id.fleet_drivers_summary)
        completeBtn = findViewById(R.id.fleet_sdk_btn_complete)

        FleetPresentationBridge.emit(
            "FLOW_STARTED",
            FleetPresentationBridge.pendingSession?.correlationId?.let {
                mapOf("correlationId" to it)
            },
        )

        cbNewAccount.setOnCheckedChangeListener { _, isChecked ->
            ilName.visibility = if (isChecked) View.VISIBLE else View.GONE
            if (!isChecked) {
                ilName.error = null
                etName.text?.clear()
            }
        }

        listOf(etName, etEmail, etPassword).forEach { et ->
            et.addTextChangedListener { textInputLayoutOf(et)?.error = null }
        }

        completeBtn.setOnClickListener { onPrimaryAction() }

        findViewById<MaterialButton>(R.id.fleet_sdk_btn_cancel).setOnClickListener {
            cancelFlow()
        }

        onBackPressedDispatcher.addCallback(
            this,
            object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    when (step) {
                        FlowStep.WELCOME -> cancelFlow()
                        FlowStep.AUTH -> goToWelcome()
                        FlowStep.FLEET -> goToAuth()
                    }
                }
            },
        )

        renderStep()
    }

    override fun onDestroy() {
        ioExecutor.shutdownNow()
        super.onDestroy()
    }

    private fun goToWelcome() {
        step = FlowStep.WELCOME
        loadedDrivers = null
        fleetLoadInFlight = false
        completeBtn.isEnabled = true
        renderStep()
    }

    private fun goToAuth() {
        step = FlowStep.AUTH
        loadedDrivers = null
        fleetLoadInFlight = false
        completeBtn.isEnabled = true
        renderStep()
    }

    private fun renderStep() {
        stepWelcome.visibility = View.GONE
        stepAuthScroll.visibility = View.GONE
        stepFleet.visibility = View.GONE
        when (step) {
            FlowStep.WELCOME -> {
                stepWelcome.visibility = View.VISIBLE
                subtitle.text = getString(R.string.fleet_sdk_subtitle_welcome)
                completeBtn.setText(R.string.fleet_sdk_get_started)
                completeBtn.isEnabled = true
            }
            FlowStep.AUTH -> {
                stepAuthScroll.visibility = View.VISIBLE
                subtitle.text = getString(R.string.fleet_sdk_subtitle_auth)
                completeBtn.setText(R.string.fleet_sdk_continue)
                completeBtn.isEnabled = true
            }
            FlowStep.FLEET -> {
                stepFleet.visibility = View.VISIBLE
                subtitle.text = getString(R.string.fleet_sdk_subtitle_fleet)
                completeBtn.setText(R.string.fleet_sdk_complete)
                driversSummary.text = getString(R.string.fleet_sdk_fleet_loading)
                loading.visibility =
                    if (fleetLoadInFlight || loadedDrivers == null) View.VISIBLE else View.GONE
                completeBtn.isEnabled = !fleetLoadInFlight && loadedDrivers != null
            }
        }
    }

    private fun onPrimaryAction() {
        when (step) {
            FlowStep.WELCOME -> {
                step = FlowStep.AUTH
                renderStep()
            }
            FlowStep.AUTH -> {
                if (!validateAuth()) return
                step = FlowStep.FLEET
                fleetLoadInFlight = true
                loadedDrivers = null
                completeBtn.isEnabled = false
                renderStep()
                loadDriversFromApi()
            }
            FlowStep.FLEET -> completeSdkFlow()
        }
    }

    private fun validateAuth(): Boolean {
        var ok = true
        val signup = cbNewAccount.isChecked
        if (signup) {
            val name = etName.text?.toString()?.trim().orEmpty()
            if (name.length < 2) {
                ilName.error = getString(R.string.fleet_sdk_err_required)
                ok = false
            }
        }
        val email = etEmail.text?.toString()?.trim().orEmpty()
        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            textInputLayoutOf(etEmail)?.error = getString(R.string.fleet_sdk_err_email)
            ok = false
        }
        val password = etPassword.text?.toString().orEmpty()
        if (password.length < 1) {
            textInputLayoutOf(etPassword)?.error = getString(R.string.fleet_sdk_err_required)
            ok = false
        }
        return ok
    }

    private fun loadDriversFromApi() {
        ioExecutor.execute {
            val driversResult =
                try {
                    FleetApiClient.default().listDrivers()
                } catch (e: FleetSdkException) {
                    runOnUiThread { finishWith(FleetSdkResult.Failure(e)) }
                    return@execute
                }
            runOnUiThread {
                driversResult.fold(
                    onSuccess = { drivers ->
                        loadedDrivers = drivers
                        fleetLoadInFlight = false
                        summarizeDrivers(drivers)
                        renderStep()
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

    private fun summarizeDrivers(drivers: List<Driver>) {
        loading.visibility = View.GONE
        if (drivers.isEmpty()) {
            driversSummary.text = getString(R.string.fleet_sdk_no_drivers)
            return
        }
        val first = drivers.first()
        driversSummary.text =
            buildString {
                append("${drivers.size} driver(s).\n")
                append("Lead: ")
                append(first.name)
                append(" (${first.id})\nVRN ")
                append(first.vrn)
                append(" • ")
                append(first.status)
            }
    }

    private fun completeSdkFlow() {
        val drivers = loadedDrivers ?: return
        val id = drivers.firstOrNull()?.id ?: "unknown"
        finishWith(
            FleetSdkResult.Success(
                event = "FLEET_FLOW_COMPLETED",
                payload =
                    mapOf(
                        "driverId" to id,
                        "driverCount" to drivers.size,
                        "authFlow" to if (cbNewAccount.isChecked) "signup" else "signin",
                    ),
            ),
        )
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
        if (!completionHandled.compareAndSet(false, true)) return
        val cb = FleetPresentationBridge.pendingCallback
        FleetPresentationBridge.pendingCallback = null
        FleetPresentationBridge.pendingSession = null
        cb?.onComplete(result)
        finish()
    }

    private fun textInputLayoutOf(field: View): TextInputLayout? {
        var p: ViewParent? = field.parent
        while (p != null && p !is TextInputLayout) {
            p = (p as? View)?.parent
        }
        return p as? TextInputLayout
    }
}
