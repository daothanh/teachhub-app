import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

/// Mô hình học phí khớp `contracts/openapi.json` (FeeType, FeeRules,
/// FeeOverride, FeeDiscount, PayoutAccount). Tiền là số nguyên đồng.

enum FeeType {
  perSession('per_session'),
  monthly('monthly'),
  course('course');

  const FeeType(this.wire);
  final String wire;

  /// `null` với giá trị lạ: lớp vẫn mở được, chỉ không hiện kiểu học phí.
  static FeeType? fromWire(String? v) =>
      values.where((t) => t.wire == v).firstOrNull;
}

const feeAmountMax = 1000000000;
const feeInstallmentsMax = 36;
const feeDiscountsMax = 5;

/// Quy tắc hiệu lực của lớp (đã điền mặc định).
class FeeRules extends Equatable {
  const FeeRules({
    this.chargeExcused = true,
    this.chargeUnexcused = true,
    this.deductCancelled = false,
    this.installments = 1,
  });

  factory FeeRules.fromJson(Map<String, dynamic> json) => FeeRules(
    chargeExcused: json['chargeExcused'] as bool,
    chargeUnexcused: json['chargeUnexcused'] as bool,
    deductCancelled: json['deductCancelled'] as bool,
    installments: json['installments'] as int,
  );

  final bool chargeExcused;
  final bool chargeUnexcused;
  final bool deductCancelled;
  final int installments;

  FeeRules copyWith({
    bool? chargeExcused,
    bool? chargeUnexcused,
    bool? deductCancelled,
    int? installments,
  }) => FeeRules(
    chargeExcused: chargeExcused ?? this.chargeExcused,
    chargeUnexcused: chargeUnexcused ?? this.chargeUnexcused,
    deductCancelled: deductCancelled ?? this.deductCancelled,
    installments: installments ?? this.installments,
  );

  Map<String, dynamic> toJson() => {
    'chargeExcused': chargeExcused,
    'chargeUnexcused': chargeUnexcused,
    'deductCancelled': deductCancelled,
    'installments': installments,
  };

  @override
  List<Object?> get props => [
    chargeExcused, chargeUnexcused, deductCancelled, installments, //
  ];
}

enum FeeDiscountKind { percent, amount }

/// Một khoản miễn giảm định kỳ: `percent` (1..100) hoặc `amount` (đồng).
class FeeDiscount extends Equatable {
  const FeeDiscount({
    required this.kind,
    required this.description,
    required this.value,
  });

  factory FeeDiscount.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] == 'amount'
        ? FeeDiscountKind.amount
        : FeeDiscountKind.percent;
    return FeeDiscount(
      kind: kind,
      description: json['description'] as String,
      value: json[kind.name] as int,
    );
  }

  final FeeDiscountKind kind;
  final String description;
  final int value;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'description': description.trim(),
    kind.name: value,
  };

  @override
  List<Object?> get props => [kind, description, value];
}

/// Mức riêng của một học viên. Trường `null` = kế thừa lớp.
class FeeOverride extends Equatable {
  const FeeOverride({
    this.feeAmount,
    this.chargeExcused,
    this.chargeUnexcused,
    this.deductCancelled,
    this.installments,
    this.discounts = const [],
  });

  factory FeeOverride.fromJson(Map<String, dynamic> json) => FeeOverride(
    feeAmount: json['feeAmount'] as int?,
    chargeExcused: json['chargeExcused'] as bool?,
    chargeUnexcused: json['chargeUnexcused'] as bool?,
    deductCancelled: json['deductCancelled'] as bool?,
    installments: json['installments'] as int?,
    discounts: [
      for (final d in json['discounts'] as List)
        FeeDiscount.fromJson(d as Map<String, dynamic>),
    ],
  );

  final int? feeAmount;
  final bool? chargeExcused;
  final bool? chargeUnexcused;
  final bool? deductCancelled;
  final int? installments;
  final List<FeeDiscount> discounts;

  /// Không có gì khác lớp: gửi `{}` để xóa mức riêng.
  bool get isEmpty =>
      feeAmount == null &&
      chargeExcused == null &&
      chargeUnexcused == null &&
      deductCancelled == null &&
      installments == null &&
      discounts.isEmpty;

  Map<String, dynamic> toJson() => isEmpty
      ? const {}
      : {
          'feeAmount': feeAmount,
          'chargeExcused': chargeExcused,
          'chargeUnexcused': chargeUnexcused,
          'deductCancelled': deductCancelled,
          'installments': installments,
          'discounts': [for (final d in discounts) d.toJson()],
        };

  @override
  List<Object?> get props => [
    feeAmount, chargeExcused, chargeUnexcused, deductCancelled, //
    installments, discounts,
  ];
}

/// Lỗi kiểm tra ở máy của mức riêng; khóa trùng khóa lỗi 422 của server.
enum FeeOverrideError {
  amountRange,
  installmentsRange,
  discountDescription,
  discountValue,
}

/// Chỉ kiểm phần chắc chắn (US-1.3); server vẫn là nguồn cuối. Khóa:
/// `feeAmount`, `installments`, `discounts.<i>.description|value`.
Map<String, FeeOverrideError> validateFeeOverride(FeeOverride o) {
  final e = <String, FeeOverrideError>{};
  final amount = o.feeAmount;
  if (amount != null && (amount < 1 || amount > feeAmountMax * 100)) {
    e['feeAmount'] = FeeOverrideError.amountRange;
  }
  final n = o.installments;
  if (n != null && (n < 1 || n > feeInstallmentsMax)) {
    e['installments'] = FeeOverrideError.installmentsRange;
  }
  for (final (i, d) in o.discounts.indexed) {
    if (d.description.trim().isEmpty || d.description.trim().length > 100) {
      e['discounts.$i.description'] = FeeOverrideError.discountDescription;
    }
    final max = d.kind == FeeDiscountKind.percent ? 100 : feeAmountMax;
    if (d.value < 1 || d.value > max) {
      e['discounts.$i.value'] = FeeOverrideError.discountValue;
    }
  }
  return e;
}

/// Tài khoản nhận tiền; chỉ có số đã che (`accountNoMasked`).
class PayoutAccount extends Equatable {
  const PayoutAccount({
    required this.id,
    required this.bankBin,
    required this.accountNoMasked,
    required this.accountName,
    required this.isPrimary,
  });

  factory PayoutAccount.fromJson(Map<String, dynamic> json) => PayoutAccount(
    id: json['id'] as String,
    bankBin: json['bankBin'] as String,
    accountNoMasked: json['accountNoMasked'] as String,
    accountName: json['accountName'] as String,
    isPrimary: json['isPrimary'] as bool,
  );

  final String id;
  final String bankBin;
  final String accountNoMasked;
  final String accountName;
  final bool isPrimary;

  @override
  List<Object?> get props => [
    id,
    bankBin,
    accountNoMasked,
    accountName,
    isPrimary,
  ];
}

const payoutAccountsMax = 5;

/// Dữ liệu form tài khoản. [accountNo] (số đầy đủ) chỉ sống trong form và
/// request: không đưa vào state, log hay `toString`.
class PayoutAccountInput {
  const PayoutAccountInput({
    required this.bankBin,
    required this.accountNo,
    required this.accountName,
  });

  final String bankBin;
  final String accountNo;
  final String accountName;

  @override
  String toString() => 'PayoutAccountInput(bankBin: $bankBin, ***)';
}

/// Lỗi kiểm tra ở máy của form tài khoản.
enum PayoutFieldError { required, accountNoFormat, nameTooLong }

Map<String, PayoutFieldError> validatePayoutInput(
  PayoutAccountInput i, {
  required bool accountNoRequired,
}) {
  final e = <String, PayoutFieldError>{};
  if (!RegExp(r'^\d{6}$').hasMatch(i.bankBin)) {
    e['bankBin'] = PayoutFieldError.required;
  }
  if (i.accountNo.isEmpty) {
    if (accountNoRequired) e['accountNo'] = PayoutFieldError.required;
  } else if (!RegExp(r'^\d{6,19}$').hasMatch(i.accountNo)) {
    e['accountNo'] = PayoutFieldError.accountNoFormat;
  }
  final name = i.accountName.trim();
  if (name.isEmpty) {
    e['accountName'] = PayoutFieldError.required;
  } else if (name.length > 50) {
    e['accountName'] = PayoutFieldError.nameTooLong;
  }
  return e;
}

/// `150000` → `150.000 đ`.
String formatVnd(int amount) => '${_group(amount.toString())} đ';

String _group(String digits) {
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Chỉ giữ chữ số; rỗng hoặc quá dài (vượt int an toàn) → `null`.
int? parseVnd(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty || digits.length > 12) return null;
  return int.parse(digits);
}

/// Ô tiền hiển thị `150.000 đ` khi gõ; con trỏ luôn đứng sau chữ số cuối.
class VndInputFormatter extends TextInputFormatter {
  const VndInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final capped = digits.length > 12 ? digits.substring(0, 12) : digits;
    final grouped = _group(int.parse(capped).toString());
    return TextEditingValue(
      text: '$grouped đ',
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }
}
