import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Inline QR preview on Scan tab (Android `FleetInlineQrScanner` parity).
class FleetInlineQrScanner extends StatefulWidget {
  const FleetInlineQrScanner({
    super.key,
    required this.active,
    required this.scanResetKey,
    required this.onBarcodeRaw,
  });

  final bool active;
  final Object? scanResetKey;
  final void Function(String raw) onBarcodeRaw;

  @override
  State<FleetInlineQrScanner> createState() => _FleetInlineQrScannerState();
}

class _FleetInlineQrScannerState extends State<FleetInlineQrScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _decoded = false;

  @override
  void didUpdateWidget(FleetInlineQrScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scanResetKey != widget.scanResetKey) {
      _decoded = false;
    }
    if (widget.active && !oldWidget.active) {
      _decoded = false;
    }
    if (!widget.active && _controller.value.isRunning) {
      _controller.stop();
    } else if (widget.active && !_controller.value.isRunning) {
      _controller.start();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        color: const Color(0xff111827),
        alignment: Alignment.center,
        child: const Icon(Icons.qr_code_2, size: 72, color: Colors.white54),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_decoded) return;
          for (final b in capture.barcodes) {
            final raw = b.rawValue?.trim();
            if (raw != null && raw.isNotEmpty) {
              _decoded = true;
              widget.onBarcodeRaw(raw);
              return;
            }
          }
        },
      ),
    );
  }
}
