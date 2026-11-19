import 'dart:typed_data';
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

/// PNG QR: mỗi module [px] điểm ảnh nguyên, viền trắng [quiet] module.
class QrPng {
  const QrPng(this.bytes, {required this.moduleCount});
  final Uint8List bytes;
  final int moduleCount;

  static const px = 12;

  /// Viền trắng tối thiểu theo chuẩn QR (4 module).
  static const quiet = 4;

  int get side => (moduleCount + 2 * quiet) * px;
}

/// Vẽ [qrPayload] thành PNG nền trắng. Module nguyên px và `gapless` để mọi
/// cạnh trùng lưới điểm ảnh (không mờ), app ngân hàng quét ảnh lưu được.
@visibleForTesting
Future<QrPng> renderQrPng(String qrPayload) async {
  final validation = QrValidator.validate(
    data: qrPayload,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
  );
  final code = validation.qrCode;
  if (!validation.isValid || code == null) throw StateError('qr_invalid');
  final n = code.moduleCount;
  final result = QrPng(Uint8List(0), moduleCount: n);
  final painter = QrPainter.withQr(
    qr: code,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Color(0xFF000000),
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Color(0xFF000000),
    ),
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = result.side.toDouble();
  canvas.drawRect(
    Rect.fromLTWH(0, 0, side, side),
    Paint()
      ..color = const Color(0xFFFFFFFF)
      ..isAntiAlias = false,
  );
  canvas.translate(
    (QrPng.quiet * QrPng.px).toDouble(),
    (QrPng.quiet * QrPng.px).toDouble(),
  );
  final inner = (n * QrPng.px).toDouble();
  painter.paint(canvas, Size(inner, inner));
  final image = await recorder.endRecording().toImage(result.side, result.side);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  if (png == null) throw StateError('qr_png');
  return QrPng(png.buffer.asUint8List(), moduleCount: n);
}

class GalQrImageSaver implements QrImageSaver {
  const GalQrImageSaver();

  @override
  Future<void> save(String qrPayload, {required String name}) async {
    final png = await renderQrPng(qrPayload);
    try {
      await Gal.putImageBytes(png.bytes, name: name);
    } on GalException catch (e) {
      if (e.type == GalExceptionType.permissionDenied) {
        throw const QrSaveDenied();
      }
      rethrow;
    }
  }
}
