import 'package:teachhub_shared/teachhub_shared.dart';
import 'package:teacher/features/fees/data/fee_models.dart';
import 'package:teacher/features/fees/data/fee_repository.dart';

PayoutAccount sampleAccount({
  String id = 'a1',
  String bin = '970436',
  String masked = '******6789',
  String name = 'NGUYEN VAN A',
  bool primary = true,
}) => PayoutAccount(
  id: id,
  bankBin: bin,
  accountNoMasked: masked,
  accountName: name,
  isPrimary: primary,
);

/// Bản giả: `calls` ghi tên lệnh, `bodies` ghi tham số quan trọng.
class FakeFeeRepository implements FeeRepository {
  final calls = <String>[];
  final keys = <String>[];
  final overrides = <FeeOverride>[];

  /// Số tài khoản đầy đủ và OTP đã gửi lên (để kiểm không lộ ra state).
  final sentAccountNos = <String?>[];
  final sentOtps = <String?>[];
  List<PayoutAccount> accounts = [];

  Object? putError;
  Object? listError;
  Object? otpError;
  Object? createError;
  Object? updateError;
  Object? deleteError;

  @override
  Future<FeeOverride?> putFeeOverride(
    String enrollmentId,
    FeeOverride override, {
    required String idempotencyKey,
  }) async {
    calls.add('put:$enrollmentId');
    keys.add(idempotencyKey);
    overrides.add(override);
    if (putError != null) throw putError!;
    return override.isEmpty ? null : override;
  }

  @override
  Future<List<PayoutAccount>> listPayoutAccounts() async {
    calls.add('list');
    if (listError != null) throw listError!;
    return accounts;
  }

  @override
  Future<void> sendPayoutOtp() async {
    calls.add('otp');
    if (otpError != null) throw otpError!;
  }

  @override
  Future<PayoutAccount> createPayoutAccount(
    PayoutAccountInput input, {
    required String otpCode,
    required String idempotencyKey,
  }) async {
    calls.add('create');
    keys.add(idempotencyKey);
    sentAccountNos.add(input.accountNo);
    sentOtps.add(otpCode);
    if (createError != null) throw createError!;
    final a = sampleAccount(
      id: 'new',
      bin: input.bankBin,
      masked: '******${input.accountNo.substring(input.accountNo.length - 4)}',
      name: input.accountName.trim(),
      primary: accounts.isEmpty,
    );
    accounts = [...accounts, a];
    return a;
  }

  @override
  Future<PayoutAccount> updatePayoutAccount(
    String id, {
    String? bankBin,
    String? accountNo,
    String? accountName,
    bool makePrimary = false,
    String? otpCode,
    required String idempotencyKey,
  }) async {
    calls.add(
      'update:$id'
      '${makePrimary ? ':primary' : ''}'
      '${bankBin != null ? ':bin' : ''}'
      '${accountNo != null ? ':no' : ''}'
      '${accountName != null ? ':name' : ''}',
    );
    keys.add(idempotencyKey);
    sentAccountNos.add(accountNo);
    sentOtps.add(otpCode);
    if (updateError != null) throw updateError!;
    final old = accounts.firstWhere((a) => a.id == id);
    final next = sampleAccount(
      id: id,
      bin: bankBin ?? old.bankBin,
      masked: old.accountNoMasked,
      name: accountName ?? old.accountName,
      primary: makePrimary || old.isPrimary,
    );
    accounts = [
      for (final a in accounts)
        if (a.id == id)
          next
        else
          sampleAccount(
            id: a.id,
            bin: a.bankBin,
            masked: a.accountNoMasked,
            name: a.accountName,
            primary: makePrimary ? false : a.isPrimary,
          ),
    ];
    return next;
  }

  @override
  Future<void> deletePayoutAccount(
    String id, {
    String? otpCode,
    required String idempotencyKey,
  }) async {
    calls.add('delete:$id');
    sentOtps.add(otpCode);
    keys.add(idempotencyKey);
    if (deleteError != null) throw deleteError!;
    accounts = [
      for (final a in accounts)
        if (a.id != id) a,
    ];
  }
}

ApiException validation(Map<String, List<String>> errors) => ApiException(
  code: ApiErrorCode.validationFailed,
  wireCode: 'VALIDATION_FAILED',
  status: 422,
  fieldErrors: errors,
);

ApiException apiErr(ApiErrorCode c) =>
    ApiException(code: c, wireCode: c.wire, status: c.http);
