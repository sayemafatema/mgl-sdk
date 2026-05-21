import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'fleet_live_models.dart';
import 'fleet_scan_receipt.dart';

/// Receipt PNG share — Android `FuelingReceiptShare`.
abstract final class FleetFuelingReceiptShare {
  static Future<void> shareReceiptImage({
    required QrPayResultLive pay,
    required String vrn,
    String? driverName,
    String? stationName,
  }) async {
    final failed = pay.payFailed;
    final amount = formatReceiptAmount(pay.amountINR);
    final station = stationName?.trim().isNotEmpty == true ? stationName!.trim() : '—';
    final txnId = pay.serverTxnId?.trim().isNotEmpty == true ? pay.serverTxnId! : '—';
    final auth = pay.authCode?.trim() ?? '';
    final bal = pay.newBalanceINR != null && pay.newBalanceINR!.isFinite
        ? formatReceiptAmount(pay.newBalanceINR)
        : null;
    final date = formatReceiptDate(pay.txnTime);

    final bytes = await _renderReceiptPng(
      payFailed: failed,
      station: station,
      vehicle: vrn,
      driverName: driverName?.trim().isNotEmpty == true ? driverName!.trim() : null,
      amountDisplay: amount,
      newBalance: failed ? null : bal,
      authCode: auth.isNotEmpty ? auth : null,
      txnId: txnId,
      txnDate: date,
    );

    final title = failed ? 'MGL — Transaction failed' : 'MGL — Fueling complete';
    final text = StringBuffer()
      ..writeln(failed ? 'Transaction failed' : 'Fueling complete')
      ..writeln('Station: $station')
      ..writeln('Vehicle: $vrn');
    if (driverName != null && driverName.trim().isNotEmpty) {
      text.writeln('Driver: ${driverName.trim()}');
    }
    text
      ..writeln('Amount: $amount')
      ..writeln('TXN ID: $txnId')
      ..writeln('Transaction date: $date');
    if (failed) text.writeln('Status: FAILED');
    if (!failed && bal != null) text.writeln('New balance: $bal');
    if (auth.isNotEmpty) text.writeln('Auth code: $auth');

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
          name: 'mgl-fueling-receipt.png',
        ),
      ],
      subject: title,
      text: text.toString(),
    );
  }

  static Future<Uint8List> _renderReceiptPng({
    required bool payFailed,
    required String station,
    required String vehicle,
    required String? driverName,
    required String amountDisplay,
    required String? newBalance,
    required String? authCode,
    required String txnId,
    required String txnDate,
  }) async {
    const w = 1080.0;
    const pad = 48.0;
    const lineGap = 72.0;
    const hdrH = 200.0;

    var rows = 4;
    if (driverName != null) rows++;
    if (payFailed) rows++;
    if (newBalance != null) rows++;
    if (authCode != null) rows++;
    final h = (pad * 2 + 56 + hdrH + pad + lineGap * rows + 120).clamp(1400.0, 3200.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bg = Paint()..color = const Color(0xffffffff);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

    final titleColor = payFailed ? const Color(0xffb91c1c) : const Color(0xff2e7d32);
    final title = payFailed ? 'Transaction Failed' : 'Fueling Complete';

    var y = pad + 56;
    _drawText(canvas, title, pad, y, 56, titleColor, FontWeight.bold);
    y += 48;

    final hdrTop = y;
    canvas.drawRect(
      Rect.fromLTWH(0, hdrTop, w, hdrH),
      Paint()..color = const Color(0xff064e3b),
    );
    try {
      final data = await rootBundle.load('assets/mgl_logo.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final logo = frame.image;
      const targetH = 100.0;
      final lw = (logo.width * (targetH / logo.height)).clamp(80.0, 280.0);
      final lh = logo.height * (lw / logo.width);
      final lx = (w - lw) / 2;
      final ly = hdrTop + (hdrH - lh) / 2 - 16;
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        Rect.fromLTWH(lx, ly, lw, lh),
        Paint(),
      );
      logo.dispose();
    } catch (_) {
      _drawText(
        canvas,
        'MGL',
        w / 2 - 40,
        hdrTop + hdrH / 2 - 20,
        40,
        const Color(0xffffffff),
        FontWeight.bold,
        align: TextAlign.left,
      );
    }
    _drawText(
      canvas,
      'Official Receipt',
      w / 2,
      hdrTop + hdrH - 32,
      32,
      const Color(0xe6ffffff),
      FontWeight.normal,
      align: TextAlign.center,
    );
    y = hdrTop + hdrH + pad;

    void row(String label, String value, {Color valueColor = const Color(0xff111827)}) {
      _drawText(canvas, label, pad, y + 36, 36, const Color(0xff6b7280), FontWeight.normal);
      _drawText(
        canvas,
        value,
        w - pad,
        y + 40,
        40,
        valueColor,
        FontWeight.bold,
        align: TextAlign.right,
      );
      y += lineGap;
      canvas.drawLine(
        Offset(pad, y - 16),
        Offset(w - pad, y - 16),
        Paint()
          ..color = const Color(0xfff3f4f6)
          ..strokeWidth = 2,
      );
    }

    row('Station', station);
    row('Vehicle', vehicle);
    if (driverName != null) row('Driver', driverName);
    if (payFailed) row('Status', 'FAILED', valueColor: const Color(0xffdc2626));
    row(
      'Amount',
      amountDisplay,
      valueColor: payFailed ? const Color(0xffdc2626) : const Color(0xff2e7d32),
    );
    if (!payFailed && newBalance != null) {
      row('New balance', newBalance, valueColor: const Color(0xff2e7d32));
    }
    if (authCode != null) row('Auth code', authCode);

    y += 32;
    final tid = txnId == '—' ? 'TXN ID: —' : 'TXN ID: $txnId';
    _drawText(canvas, tid, w / 2, y + 30, 30, const Color(0xff6b7280), FontWeight.normal, align: TextAlign.center);
    y += 54;
    _drawText(canvas, txnDate, w / 2, y + 30, 30, const Color(0xff6b7280), FontWeight.normal, align: TextAlign.center);

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  }

  static void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double size,
    Color color,
    FontWeight weight, {
    TextAlign align = TextAlign.left,
  }) {
    final builder = ParagraphBuilder(
      ParagraphStyle(
        textAlign: align,
        fontSize: size,
        fontWeight: weight,
      ),
    )
      ..pushStyle(TextStyle(color: color))
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ParagraphConstraints(width: 900));
    double dx = x;
    if (align == TextAlign.center) {
      dx = x - paragraph.maxIntrinsicWidth / 2;
    } else if (align == TextAlign.right) {
      dx = x - paragraph.maxIntrinsicWidth;
    }
    canvas.drawParagraph(paragraph, Offset(dx, y - size));
  }
}
