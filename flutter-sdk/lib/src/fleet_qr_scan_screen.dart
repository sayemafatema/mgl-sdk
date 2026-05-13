import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen QR scan for Fleetpay `fleetpay://` URIs.
class FleetpayQrScanScreen extends StatefulWidget {
  const FleetpayQrScanScreen({super.key});

  @override
  State<FleetpayQrScanScreen> createState() => _FleetpayQrScanScreenState();
}

class _FleetpayQrScanScreenState extends State<FleetpayQrScanScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          for (final b in capture.barcodes) {
            final raw = b.rawValue;
            if (raw != null && raw.trim().isNotEmpty) {
              _handled = true;
              Navigator.of(context).pop(raw.trim());
              return;
            }
          }
        },
      ),
    );
  }
}
