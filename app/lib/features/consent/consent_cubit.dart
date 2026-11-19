import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/network/api_error.dart';

enum ConsentPhase {
  /// Chưa hỏi server.
  unknown,
  loading,

  /// Chưa đồng ý điều khoản hiện hành ([ConsentState.termsVersion]).
  required,
  accepting,
  accepted,

  /// Không đọc được trạng thái (mạng, 5xx); chưa biết đã đồng ý hay chưa.
  failed,
}

class ConsentState extends Equatable {
  const ConsentState({
    this.phase = ConsentPhase.unknown,
    this.termsVersion,
    this.termsChanged = false,
    this.submitFailed = false,
  });

  const ConsentState.accepted() : this(phase: ConsentPhase.accepted);

  final ConsentPhase phase;
  final String? termsVersion;

  /// Server vừa đổi phiên bản điều khoản lúc bấm đồng ý (409): người dùng phải
  /// đọc lại bản mới.
  final bool termsChanged;

  /// Gửi đồng ý lỗi (mạng, 5xx): bấm lại để thử lần nữa.
  final bool submitFailed;

  bool get accepted => phase == ConsentPhase.accepted;

  @override
  List<Object?> get props => [phase, termsVersion, termsChanged, submitFailed];
}

/// Đồng ý xử lý dữ liệu theo vai trò Phụ huynh (US-0.3 AC2, FR-0.14).
///
/// Singleton: guard của router và interceptor 403 `CONSENT_REQUIRED` cùng đọc
/// trạng thái này.
class ConsentCubit extends Cubit<ConsentState> {
  ConsentCubit(Dio api) : _api = api, super(const ConsentState());

  final Dio _api;

  /// Số thế hệ: kết quả của lệnh gọi cũ (trước `clear`, `markAccepted`,
  /// `markRequired` hay một `load` mới hơn) bị bỏ, không ghi đè trạng thái mới.
  int _gen = 0;

  /// `GET /consents/status?role=parent`.
  Future<void> load() async {
    final gen = ++_gen;
    emit(const ConsentState(phase: ConsentPhase.loading));
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/consents/status',
        queryParameters: {'role': 'parent'},
      );
      final data = res.data;
      final version = data?['currentTermsVersion'];
      if (data == null || version is! String) {
        throw const ApiException.unexpected();
      }
      if (isClosed || gen != _gen) return;
      emit(
        data['accepted'] == true
            ? const ConsentState.accepted()
            : ConsentState(phase: ConsentPhase.required, termsVersion: version),
      );
    } catch (_) {
      if (!isClosed && gen == _gen) {
        emit(const ConsentState(phase: ConsentPhase.failed));
      }
    }
  }

  /// `POST /consents { role: parent, termsVersion }` với phiên bản người dùng
  /// vừa đọc. 409 = bản điều khoản đã đổi: tải lại bản mới, chưa ghi đồng ý.
  Future<void> accept() async {
    final version = state.termsVersion;
    if (version == null || state.phase == ConsentPhase.accepting) return;
    final gen = ++_gen;
    emit(ConsentState(phase: ConsentPhase.accepting, termsVersion: version));
    try {
      await _api.post<void>(
        '/consents',
        data: {'role': 'parent', 'termsVersion': version},
      );
      if (!isClosed && gen == _gen) emit(const ConsentState.accepted());
    } on DioException catch (e) {
      if (isClosed || gen != _gen) return;
      if (apiException(e)?.status == 409) {
        await load();
        if (!isClosed && state.phase == ConsentPhase.required) {
          emit(
            ConsentState(
              phase: ConsentPhase.required,
              termsVersion: state.termsVersion,
              termsChanged: true,
            ),
          );
        }
      } else {
        emit(
          ConsentState(
            phase: ConsentPhase.required,
            termsVersion: version,
            submitFailed: true,
          ),
        );
      }
    }
  }

  /// Một API trả 403 `CONSENT_REQUIRED` (kể cả khi bản điều khoản đổi giữa phiên).
  void markRequired(String? termsVersion) {
    if (state.phase == ConsentPhase.accepting) return;
    _gen++;
    emit(
      ConsentState(phase: ConsentPhase.required, termsVersion: termsVersion),
    );
  }

  /// Nhận lời mời thành công nghĩa là server đã coi là đã đồng ý.
  void markAccepted() {
    _gen++;
    emit(const ConsentState.accepted());
  }

  /// Đăng xuất / đổi người dùng.
  void clear() {
    _gen++;
    emit(const ConsentState());
  }
}
