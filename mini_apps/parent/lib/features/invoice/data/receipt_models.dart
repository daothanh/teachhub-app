import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Trần kích thước biên lai: backend `PURPOSE_POLICY.receipt.maxBytes` (10 MB thập phân).
const receiptMaxBytes = 10000000;

/// Loại ảnh biên lai server nhận (`FilePurpose.receipt`); không có PDF.
const receiptMimeTypes = {'image/jpeg', 'image/png', 'image/heic'};

const claimNoteMax = 300;
const claimAmountMax = 100000000000;

enum ReceiptIssue { tooLarge, typeNotAllowed }

/// Kiểm ở máy trước khi tải để khỏi tốn một lượt xin URL; server vẫn kiểm lại.
ReceiptIssue? checkReceipt(String mimeType, int sizeBytes) {
  if (!receiptMimeTypes.contains(mimeType)) return ReceiptIssue.typeNotAllowed;
  final badSize = sizeBytes < 1 || sizeBytes > receiptMaxBytes;
  return badSize ? ReceiptIssue.tooLarge : null;
}

/// MIME theo đuôi tên tệp khi bộ chọn ảnh không báo (`null` nếu không nhận ra).
String? mimeFromFileName(String name) {
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' || 'heif' => 'image/heic',
    _ => null,
  };
}

/// Ảnh biên lai đã chọn (đã nén bởi bộ chọn). Byte nằm trong bộ nhớ ≤ 10 MB;
/// không ghi ra thư viện ảnh.
class ReceiptImage extends Equatable {
  const ReceiptImage({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  int get size => bytes.length;

  @override
  List<Object?> get props => [fileName, mimeType, size];
}

/// `UploadUrl`: URL PUT ký sẵn Content-Type và Content-Length, hạn ngắn.
class UploadTicket extends Equatable {
  const UploadTicket({
    required this.fileId,
    required this.uploadUrl,
    required this.headers,
    required this.expiresAt,
  });

  factory UploadTicket.fromJson(Map<String, dynamic> j) => UploadTicket(
    fileId: j['fileId'] as String,
    uploadUrl: j['uploadUrl'] as String,
    headers: (j['headers'] as Map).cast<String, String>(),
    expiresAt: DateTime.parse(j['expiresAt'] as String),
  );

  final String fileId;
  final String uploadUrl;
  final Map<String, String> headers;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [fileId, uploadUrl, headers, expiresAt];
}

enum ClaimStatus {
  pending,
  confirmed,
  rejected;

  /// Giá trị lạ coi như `pending` (hợp đồng).
  static ClaimStatus fromWire(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => pending);
}

/// `PaymentClaim` (rút gọn: phụ huynh chỉ cần id và trạng thái).
class PaymentClaim extends Equatable {
  const PaymentClaim({
    required this.id,
    required this.status,
    required this.amount,
  });

  factory PaymentClaim.fromJson(Map<String, dynamic> j) => PaymentClaim(
    id: j['id'] as String,
    status: ClaimStatus.fromWire(j['status']),
    amount: j['amount'] as int,
  );

  final String id;
  final ClaimStatus status;
  final int amount;

  @override
  List<Object?> get props => [id, status, amount];
}
