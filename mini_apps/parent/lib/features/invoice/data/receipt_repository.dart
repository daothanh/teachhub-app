import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'receipt_models.dart';

/// Tải biên lai và báo chuyển khoản (US-7.7). Lỗi ra ngoài là [ApiException]
/// (PUT lên kho: mất mạng là [ApiException.network], kho từ chối mang status của kho).
abstract interface class ReceiptRepository {
  /// `POST /files/upload-urls` (`purpose = receipt`, `entityId` = hóa đơn).
  Future<UploadTicket> requestUpload(
    String invoiceId,
    ReceiptImage image, {
    required String idempotencyKey,
  });

  /// `PUT` thẳng lên URL ký sẵn, không qua API, không Bearer.
  Future<void> put(
    UploadTicket ticket,
    ReceiptImage image, {
    void Function(double fraction)? onProgress,
  });

  /// `POST /files/{id}/complete`: gọi lại trên tệp đã `ready` vẫn 200.
  Future<void> complete(String fileId);

  /// `POST /family/invoices/{id}/payment-claims`.
  Future<PaymentClaim> createClaim(
    String invoiceId, {
    required String receiptFileId,
    required int amount,
    String? note,
    required String idempotencyKey,
  });
}

class DioReceiptRepository implements ReceiptRepository {
  /// [_storage]: `Dio` của host cho URL presigned (không baseURL, không Bearer).
  DioReceiptRepository(this._api, this._storage);
  final Dio _api;
  final Dio _storage;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on Object catch (e) {
      final parseFailure =
          e is TypeError ||
          e is FormatException ||
          (e is DioException &&
              (e.error is TypeError || e.error is FormatException));
      throw (parseFailure ? null : ApiException.fromDio(e)) ??
          const ApiException.unexpected();
    }
  }

  Options _key(String key) => Options(headers: {'Idempotency-Key': key});

  @override
  Future<UploadTicket> requestUpload(
    String invoiceId,
    ReceiptImage image, {
    required String idempotencyKey,
  }) => _guard(() async {
    final res = await _api.post<Map<String, dynamic>>(
      '/files/upload-urls',
      data: {
        'purpose': 'receipt',
        'entityId': invoiceId,
        'fileName': image.fileName,
        'mimeType': image.mimeType,
        'sizeBytes': image.size,
      },
      options: _key(idempotencyKey),
    );
    return UploadTicket.fromJson(res.data!);
  });

  @override
  Future<void> put(
    UploadTicket ticket,
    ReceiptImage image, {
    void Function(double fraction)? onProgress,
  }) => _guard(() async {
    await _storage.put<void>(
      ticket.uploadUrl,
      data: image.bytes,
      // URL ký cả Content-Type và Content-Length: gửi đúng như đã khai.
      options: Options(
        headers: {...ticket.headers, Headers.contentLengthHeader: image.size},
        contentType: image.mimeType,
      ),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
  });

  @override
  Future<void> complete(String fileId) => _guard(() async {
    await _api.post<Map<String, dynamic>>(
      '/files/${Uri.encodeComponent(fileId)}/complete',
    );
  });

  @override
  Future<PaymentClaim> createClaim(
    String invoiceId, {
    required String receiptFileId,
    required int amount,
    String? note,
    required String idempotencyKey,
  }) => _guard(() async {
    final res = await _api.post<Map<String, dynamic>>(
      '/family/invoices/${Uri.encodeComponent(invoiceId)}/payment-claims',
      data: {
        'receiptFileId': receiptFileId,
        'amount': amount,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      options: _key(idempotencyKey),
    );
    return PaymentClaim.fromJson(res.data!);
  });
}
