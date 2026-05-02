package com.mgl.fleet.sdk.api

/** Mirrors OpenAPI `Driver`. */
data class Driver(
    val id: String,
    val name: String,
    val vrn: String,
    val status: String,
    val cardBalancePaise: Long,
)

/** Mirrors OpenAPI `DriverPatch`. */
data class DriverPatch(
    val name: String? = null,
    val status: String? = null,
    val cardBalancePaise: Long? = null,
)
