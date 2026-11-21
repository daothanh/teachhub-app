import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fee_models.dart';

/// API mức riêng và tài khoản nhận tiền (US-1.3, US-7.3 AC5). Mọi lỗi ra
/// ngoài là [ApiException]; test thay bằng bản giả của lớp này.
///
/// Mọi lệnh ghi nhận [idempotencyKey] (hợp đồng bắt buộc; interceptor của host
/// chỉ tự gắn cho POST/PATCH nên PUT/DELETE phải gắn tay).
abstract class FeeRepository {
  /// `PUT /enrollments/{id}/fee-override`; [override] rỗng = xóa mức riêng.
  /// Trả mức riêng sau khi lưu (`null` khi không còn).
  Future<FeeOverride?> putFeeOverride(
    String enrollmentId,
    FeeOverride override, {
    required String idempotencyKey,
  });

  Future<List<PayoutAccount>> listPayoutAccounts();

  /// Gửi OTP `payout_account` tới email của tài khoản đang đăng nhập.
  Future<void> sendPayoutOtp();

  /// [otpCode] bắt buộc với tài khoản mới (hợp đồng).
  Future<PayoutAccount> createPayoutAccount(
    PayoutAccountInput input, {
    required String otpCode,
    required String idempotencyKey,
  });

  /// Chỉ gửi các trường có giá trị. [otpCode] bắt buộc khi đổi `bankBin` hoặc
  /// `accountNo`; [makePrimary] đặt làm tài khoản chính.
  Future<PayoutAccount> updatePayoutAccount(
    String id, {
    String? bankBin,
    String? accountNo,
    String? accountName,
    bool makePrimary = false,
    String? otpCode,
    required String idempotencyKey,
  });

  Future<void> deletePayoutAccount(String id, {required String idempotencyKey});
}

FeeRepository feeRepository() => GetIt.I.isRegistered<FeeRepository>()
    ? GetIt.I<FeeRepository>()
    : DioFeeRepository(GetIt.I<Dio>(instanceName: TeachHubDiKey.api));

class DioFeeRepository implements FeeRepository {
  DioFeeRepository(this._dio);
  final Dio _dio;

  /// Email của user đang đăng nhập, lấy từ `/auth/me` một lần cho mỗi repository.
  String? _email;

  @override
  Future<FeeOverride?> putFeeOverride(
    String enrollmentId,
    FeeOverride override, {
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.put<Map<String, dynamic>>(
      '/enrollments/$enrollmentId/fee-override',
      data: override.toJson(),
      options: _key(idempotencyKey),
    );
    return switch (r.data!['feeOverride']) {
      final Map<String, dynamic> m => FeeOverride.fromJson(m),
      _ => null,
    };
  });

  @override
  Future<List<PayoutAccount>> listPayoutAccounts() => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/payout-accounts');
    return [
      for (final e in r.data!['items'] as List)
        PayoutAccount.fromJson(e as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> sendPayoutOtp() => _call(() async {
    final email = _email ??=
        (await _dio.get<Map<String, dynamic>>('/auth/me')).data!['email']
            as String;
    await _dio.post<void>(
      '/auth/otp/send',
      data: {'email': email, 'purpose': 'payout_account'},
      // Endpoint công khai: AuthInterceptor không gắn token, không refresh.
      options: Options(extra: const {'requiresAuth': false}),
    );
  });

  @override
  Future<PayoutAccount> createPayoutAccount(
    PayoutAccountInput input, {
    required String otpCode,
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/payout-accounts',
      data: {
        'bankBin': input.bankBin,
        'accountNo': input.accountNo,
        'accountName': input.accountName.trim(),
        'otpCode': otpCode,
      },
      options: _key(idempotencyKey),
    );
    return PayoutAccount.fromJson(r.data!);
  });

  @override
  Future<PayoutAccount> updatePayoutAccount(
    String id, {
    String? bankBin,
    String? accountNo,
    String? accountName,
    bool makePrimary = false,
    String? otpCode,
    required String idempotencyKey,
  }) => _call(() async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/payout-accounts/$id',
      data: {
        'bankBin': ?bankBin,
        'accountNo': ?accountNo,
        'accountName': ?accountName?.trim(),
        if (makePrimary) 'isPrimary': true,
        'otpCode': ?otpCode,
      },
      options: _key(idempotencyKey),
    );
    return PayoutAccount.fromJson(r.data!);
  });

  @override
  Future<void> deletePayoutAccount(
    String id, {
    required String idempotencyKey,
  }) => _call(
    () => _dio.delete<void>(
      '/payout-accounts/$id',
      options: _key(idempotencyKey),
    ),
  );
}

Options _key(String key) => Options(headers: {'Idempotency-Key': key});

/// Mọi lỗi ra ngoài là [ApiException]; lỗi đọc phản hồi thành lỗi máy chủ chung
/// (giống `ClassesRepository`) để cubit không kẹt ở trạng thái đang tải.
Future<T> _call<T>(Future<T> Function() run) async {
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
