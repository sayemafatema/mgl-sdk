package com.mgl.fleet.sdk.api

import com.mgl.fleet.sdk.FleetSdkHolder
import com.mgl.fleet.sdk.FleetSdkOptions
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * Minimal REST client aligned with [fleet-api.yaml](/docs/openapi/fleet-api.yaml).
 */
class FleetApiClient(
    private val options: FleetSdkOptions,
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build(),
) {

    fun listDrivers(): Result<List<Driver>> {
        if (options.useMock) {
            return Result.success(
                listOf(
                    Driver(
                        id = "DRV001",
                        name = "Demo Driver",
                        vrn = "MH 02 AB 1234",
                        status = "Active",
                        cardBalancePaise = 1_250_000L,
                    ),
                ),
            )
        }
        return getJson("/fleet/drivers") { json ->
            val arr = json.getJSONArray("drivers")
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    add(parseDriver(o))
                }
            }
        }
    }

    private fun parseDriver(o: JSONObject): Driver =
        Driver(
            id = o.getString("id"),
            name = o.getString("name"),
            vrn = o.getString("vrn"),
            status = o.getString("status"),
            cardBalancePaise = o.getLong("cardBalancePaise"),
        )

    private fun <T> getJson(path: String, parse: (JSONObject) -> T): Result<T> {
        val base = options.apiBaseUrl.trimEnd('/')
        val reqBuilder = Request.Builder().url("$base$path").get()
        options.authToken?.let { reqBuilder.header("Authorization", "Bearer $it") }
        val req = reqBuilder.build()
        return try {
            client.newCall(req).execute().use { resp ->
                val body = resp.body?.string().orEmpty()
                if (!resp.isSuccessful) {
                    return Result.failure(IOException("HTTP ${resp.code}: $body"))
                }
                Result.success(parse(JSONObject(body)))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    companion object {
        /** Resolved client using globally initialized options (throws if unset). */
        fun default(): FleetApiClient = FleetApiClient(FleetSdkHolder.requireOptions())
    }
}
