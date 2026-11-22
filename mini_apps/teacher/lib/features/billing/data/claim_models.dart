import 'package:equatable/equatable.dart';

import 'billing_models.dart';

/// Mô hình báo chuyển khoản (US-7.7) khớp `PaymentClaim`,
/// `ResolvePaymentClaimRequest`, `ResolvePaymentClaimResult` trong
/// `contracts/openapi.json`. Tiền là số nguyên đồng.
enum ClaimStatus {
  pending,
  confirmed,
  rejected;

  /// Hợp đồng: giá trị lạ coi như `pending`.
  static ClaimStatus fromWire(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => pending);
}

const claimRejectReasonMax = 300;

class PaymentClaim extends Equatable {
  const PaymentClaim({
    required this.id,
    required this.invoiceId,
    required this.status,
    required this.amount,
    required this.note,
    required this.receiptFileId,
    required this.claimedByName,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedByName,
    this.rejectReason,
    this.paymentId,
  });

  factory PaymentClaim.fromJson(Map<String, dynamic> j) => PaymentClaim(
    id: j['id'] as String,
    invoiceId: j['invoiceId'] as String,
    status: ClaimStatus.fromWire(j['status']),
    amount: j['amount'] as int,
    note: j['note'] as String?,
    receiptFileId: j['receiptFileId'] as String,
    claimedByName: (j['claimedBy'] as Map<String, dynamic>)['name'] as String,
    createdAt: j['createdAt'] as String,
    resolvedAt: j['resolvedAt'] as String?,
    resolvedByName: j['resolvedBy'] == null
        ? null
        : (j['resolvedBy'] as Map<String, dynamic>)['name'] as String,
    rejectReason: j['rejectReason'] as String?,
    paymentId: j['paymentId'] as String?,
  );

  final String id;
  final String invoiceId;
  final ClaimStatus status;

  /// Số phụ huynh khai, chỉ để đối chiếu; giáo viên quyết số ghi thu.
  final int amount;
  final String? note;
  final String receiptFileId;
  final String claimedByName;

  /// ISO 8601; hiện bằng `formatIsoDateTime`.
  final String createdAt;
  final String? resolvedAt;
  final String? resolvedByName;
  final String? rejectReason;
  final String? paymentId;

  bool get isPending => status == ClaimStatus.pending;

  @override
  List<Object?> get props => [
    id,
    invoiceId,
    status,
    amount,
    note,
    receiptFileId,
    claimedByName,
    createdAt,
    resolvedAt,
    resolvedByName,
    rejectReason,
    paymentId,
  ];
}

/// Quyết định của giáo viên: xác nhận (số ghi thu, mặc định số khai) hoặc từ
/// chối (lý do bắt buộc).
class ClaimResolution extends Equatable {
  const ClaimResolution.confirm(int this.amount) : reason = null;
  const ClaimResolution.reject(String this.reason) : amount = null;

  final int? amount;
  final String? reason;

  bool get isConfirm => reason == null;

  Map<String, dynamic> toJson() => isConfirm
      ? {'decision': 'confirm', 'amount': amount}
      : {'decision': 'reject', 'reason': reason!.trim()};

  /// Tên các trường sai theo hợp đồng.
  Set<String> validate() => {
    if (isConfirm && (amount! < 1 || amount! > paymentAmountMax)) 'amount',
    if (!isConfirm &&
        (reason!.trim().isEmpty ||
            reason!.trim().length > claimRejectReasonMax))
      'reason',
  };

  @override
  List<Object?> get props => [amount, reason];
}

/// `result` là thanh toán sinh ra khi xác nhận; từ chối thì `null`.
class ClaimResolveResult extends Equatable {
  const ClaimResolveResult({required this.claim, required this.result});

  factory ClaimResolveResult.fromJson(Map<String, dynamic> j) =>
      ClaimResolveResult(
        claim: PaymentClaim.fromJson(j['claim'] as Map<String, dynamic>),
        result: j['result'] == null
            ? null
            : PaymentResult.fromJson(j['result'] as Map<String, dynamic>),
      );

  final PaymentClaim claim;
  final PaymentResult? result;

  @override
  List<Object?> get props => [claim, result];
}
