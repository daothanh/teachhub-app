import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Người dùng từ chối quyền thư viện ảnh.
class QrSaveDenied implements Exception {
  const QrSaveDenied();
}

/// Lưu ảnh QR vào thư viện ảnh. Test thay bằng bản giả.
abstract interface class QrImageSaver {
  /// Vẽ [qrPayload] thành PNG nền trắng rồi lưu. Ném [QrSaveDenied] khi bị từ
  /// chối quyền; lỗi khác ném nguyên. Không log [qrPayload].
  Future<void> save(String qrPayload, {required String name});
}

class GalQrImageSaver implements QrImageSaver {
  const GalQrImageSaver();

  static const _size = 1024.0;
  static const _quiet = 64.0;

  @override
  Future<void> save(String qrPayload, {required String name}) async {
    final painter = QrPainter(
      data: qrPayload,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _size, _size),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.translate(_quiet, _quiet);
    painter.paint(canvas, const Size(_size - 2 * _quiet, _size - 2 * _quiet));
    final image = await recorder.endRecording().toImage(
      _size.toInt(),
      _size.toInt(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) throw StateError('qr_png');
    try {
      await Gal.putImageBytes(png.buffer.asUint8List(), name: name);
    } on GalException catch (e) {
      if (e.type == GalExceptionType.permissionDenied) {
        throw const QrSaveDenied();
      }
      rethrow;
    }
  }
}
