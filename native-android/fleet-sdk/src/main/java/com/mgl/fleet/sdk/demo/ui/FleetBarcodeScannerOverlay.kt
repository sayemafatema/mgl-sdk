@file:Suppress("DEPRECATION", "MissingPermission")

package com.mgl.fleet.sdk.demo.ui

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Fullscreen QR scanner — emits decoded URI/raw payload ([Fleetpay URI parsing](../../../../../fleet-pay-parse])). */
@Composable
internal fun FleetBarcodeScannerOverlay(onBarcodeRaw: (String) -> Unit, onClose: () -> Unit) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    var granted by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED,
        )
    }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok ->
        granted = ok
    }
    LaunchedEffect(Unit) {
        if (!granted) launcher.launch(Manifest.permission.CAMERA)
    }

    val scanner = remember {
        val opts = BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build()
        BarcodeScanning.getClient(opts)
    }
    val exec = remember { Executors.newSingleThreadExecutor() }
    val decodedOnce = remember { AtomicBoolean(false) }

    DisposableEffect(Unit) {
        onDispose {
            scanner.close()
            exec.shutdownNow()
        }
    }

    Box(
        Modifier
            .fillMaxSize()
            .background(Color.Black),
    ) {
        TextButton(onClose, Modifier.align(Alignment.TopEnd).padding(8.dp)) { Text("Close", color = Color.White) }

        if (!granted) {
            Text(
                "Camera permission required to scan Fleetpay QR",
                Modifier
                    .align(Alignment.Center)
                    .padding(24.dp),
                color = Color.White,
            )
            return
        }

        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { ctx ->
                val previewView = PreviewView(ctx)
                bindBarcodeScanner(
                    ctx,
                    previewView,
                    lifecycleOwner,
                    exec,
                    decodedOnce,
                    scanner,
                    onBarcodeRaw,
                )
                previewView
            },
        )
        Column(
            Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .background(Color.Black.copy(alpha = 0.55f))
                .padding(16.dp),
        ) {
            Text("Point camera at Fleetpay QR code", color = Color.White)
        }
    }
}

private fun bindBarcodeScanner(
    ctx: android.content.Context,
    previewView: PreviewView,
    lifecycleOwner: androidx.lifecycle.LifecycleOwner,
    exec: ExecutorService,
    decodedOnce: AtomicBoolean,
    scanner: com.google.mlkit.vision.barcode.BarcodeScanner,
    onBarcodeRaw: (String) -> Unit,
) {
    val cameraFuture = ProcessCameraProvider.getInstance(ctx)
    cameraFuture.addListener(
        {
            runCatching {
                val provider = cameraFuture.get()
                val preview = Preview.Builder().build()
                preview.setSurfaceProvider(previewView.surfaceProvider)
                val analysis =
                    ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .build()
                analysis.setAnalyzer(exec) { imageProxy ->
                    val media = imageProxy.image
                    if (media == null) {
                        imageProxy.close()
                        return@setAnalyzer
                    }
                    val img = InputImage.fromMediaImage(media, imageProxy.imageInfo.rotationDegrees)
                    scanner
                        .process(img)
                        .addOnSuccessListener { codes ->
                            val raw = codes.firstOrNull { !it.rawValue.isNullOrBlank() }?.rawValue
                            if (raw != null && decodedOnce.compareAndSet(false, true)) {
                                ContextCompat.getMainExecutor(ctx).execute { onBarcodeRaw(raw) }
                            }
                        }
                        .addOnFailureListener { }
                        .addOnCompleteListener { imageProxy.close() }
                }
                provider.unbindAll()
                provider.bindToLifecycle(
                    lifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    analysis,
                )
            }
        },
        ContextCompat.getMainExecutor(ctx),
    )
}
