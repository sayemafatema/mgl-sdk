package com.mgl.fleet.sdk.demo.ui

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import androidx.annotation.DrawableRes
import androidx.core.content.FileProvider
import com.mgl.fleet.sdk.R
import java.io.File
import java.io.FileOutputStream
import kotlin.math.roundToInt

internal object FuelingReceiptShare {
    fun shareReceiptImage(
        context: Context,
        @DrawableRes logoRes: Int = R.drawable.mgl_logo,
        payFailed: Boolean,
        station: String,
        vehicle: String,
        driverName: String?,
        amountDisplay: String,
        newBalance: String?,
        authCode: String?,
        txnId: String,
        txnDate: String,
    ) {
        val bmp =
            renderReceiptBitmap(
                context = context,
                logoRes = logoRes,
                payFailed = payFailed,
                station = station,
                vehicle = vehicle,
                driverName = driverName,
                amountDisplay = amountDisplay,
                newBalance = newBalance,
                authCode = authCode,
                txnId = txnId,
                txnDate = txnDate,
            )
        val dir = File(context.cacheDir, "share").apply { mkdirs() }
        val out = File(dir, "mgl-fueling-receipt.png")
        FileOutputStream(out).use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
        val authority = "${context.packageName}.mglfleet.share"
        val uri = FileProvider.getUriForFile(context, authority, out)
        val title = if (payFailed) "MGL — Transaction failed" else "MGL — Fueling complete"
        val text =
            buildString {
                append(if (payFailed) "Transaction failed" else "Fueling complete")
                append("\nStation: ").append(station)
                append("\nVehicle: ").append(vehicle)
                if (!driverName.isNullOrBlank()) append("\nDriver: ").append(driverName)
                append("\nAmount: ").append(amountDisplay)
                if (!payFailed && !newBalance.isNullOrBlank()) append("\nNew balance: ").append(newBalance)
                if (!authCode.isNullOrBlank()) append("\nAuth code: ").append(authCode)
                append("\nTXN ID: ").append(txnId)
                append("\nTransaction date: ").append(txnDate)
                if (payFailed) append("\nStatus: FAILED")
            }
        val send =
            Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, title)
                putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        context.startActivity(Intent.createChooser(send, title))
    }

    @Suppress("SameParameterValue")
    private fun renderReceiptBitmap(
        context: Context,
        logoRes: Int,
        payFailed: Boolean,
        station: String,
        vehicle: String,
        driverName: String?,
        amountDisplay: String,
        newBalance: String?,
        authCode: String?,
        txnId: String,
        txnDate: String,
    ): Bitmap {
        val w = 1080
        val pad = 48f
        val lineGap = 72f
        val titlePaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (payFailed) Color.parseColor("#B91C1C") else Color.parseColor("#2E7D32")
                textSize = 56f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            }
        val labelPaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#6B7280")
                textSize = 36f
            }
        val valuePaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#111827")
                textSize = 40f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                textAlign = Paint.Align.RIGHT
            }
        val hdrPaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#064E3B")
            }
        val officialPaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.argb(230, 255, 255, 255)
                textSize = 32f
                textAlign = Paint.Align.CENTER
            }
        val footPaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#6B7280")
                textSize = 30f
                typeface = Typeface.MONOSPACE
                textAlign = Paint.Align.CENTER
            }
        val linePaint =
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#F3F4F6")
                strokeWidth = 2f
            }

        val headline = if (payFailed) "Transaction Failed" else "Fueling Complete"
        val estH =
            (
                pad * 2 + titlePaint.textSize + 200f + lineGap * (
                    5 +
                        (if (!driverName.isNullOrBlank()) 1 else 0) +
                        (if (payFailed) 1 else 0) +
                        (if (!newBalance.isNullOrBlank()) 1 else 0) +
                        (if (!authCode.isNullOrBlank()) 1 else 0)
                ) + 120f
            ).roundToInt()
                .coerceIn(1400, 3200)
        val bmp = Bitmap.createBitmap(w, estH, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        c.drawColor(Color.WHITE)

        var y = pad + titlePaint.textSize
        c.drawText(headline, pad, y, titlePaint)
        y += 48f

        val hdrTop = y
        val hdrH = 200f
        c.drawRect(0f, hdrTop, w.toFloat(), hdrTop + hdrH, hdrPaint)
        val logo = BitmapFactory.decodeResource(context.resources, logoRes)
        if (logo != null && !logo.isRecycled) {
            val targetH = 100f
            val lw = (logo.width * (targetH / logo.height)).roundToInt().coerceIn(80, 280)
            val lh = (logo.height * (lw.toFloat() / logo.width)).roundToInt().coerceAtMost(130)
            val lx = (w - lw) / 2f
            val ly = hdrTop + (hdrH - lh) / 2f - 16f
            c.drawBitmap(
                logo,
                null,
                Rect(lx.roundToInt(), ly.roundToInt(), (lx + lw).roundToInt(), (ly + lh).roundToInt()),
                null,
            )
        }
        c.drawText("Official Receipt", w / 2f, hdrTop + hdrH - 32f, officialPaint)
        y = hdrTop + hdrH + pad

        fun row(label: String, value: String, valColor: Int = Color.parseColor("#111827")) {
            valuePaint.color = valColor
            c.drawText(label, pad, y + labelPaint.textSize * 0.85f, labelPaint)
            c.drawText(value, w - pad, y + valuePaint.textSize * 0.85f, valuePaint)
            y += lineGap
            c.drawLine(pad, y - 16f, w - pad, y - 16f, linePaint)
        }

        row("Station", station)
        row("Vehicle", vehicle)
        if (!driverName.isNullOrBlank()) row("Driver", driverName)
        if (payFailed) row("Status", "FAILED", Color.parseColor("#DC2626"))
        row(
            "Amount",
            amountDisplay,
            if (payFailed) Color.parseColor("#DC2626") else Color.parseColor("#2E7D32"),
        )
        if (!payFailed && !newBalance.isNullOrBlank()) {
            row("New balance", newBalance, Color.parseColor("#2E7D32"))
        }
        if (!authCode.isNullOrBlank()) row("Auth code", authCode)

        y += 32f
        val tid = if (txnId == "—") "TXN ID: —" else "TXN ID: $txnId"
        c.drawText(tid, w / 2f, y + footPaint.textSize, footPaint)
        y += footPaint.textSize + 24f
        c.drawText(txnDate, w / 2f, y + footPaint.textSize, footPaint)

        return bmp
    }
}
