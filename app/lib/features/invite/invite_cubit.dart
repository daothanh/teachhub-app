import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_utils/tasco_utils.dart';

import 'package:teachhub_shared/teachhub_shared.dart';

import '../../core/network/api_error.dart';
import '../role_picker/membership_cubit.dart';

class InviteState extends Equatable {
  const InviteState({
    this.statusAccept = LoadingStatus.initial,
    this.consentTermsVersion,
    this.errorCode,
  });

  final LoadingStatus statusAccept;

  /// Có giá trị khi API trả `CONSENT_REQUIRED`: phiên bản điều khoản cần đồng
  /// ý trước khi nhận lời mời (FR-0.14).
  final String? consentTermsVersion;
  final ApiErrorCode? errorCode;

  @override
  List<Object?> get props => [statusAccept, consentTermsVersion, errorCode];
}

/// Nhận lời mời từ link `dayhoc.app/i/<token>` (spec §5.2c).
class InviteCubit extends Cubit<InviteState> {
  InviteCubit({
    required Dio api,
    required MembershipCubit memberships,
    required this.token,
  }) : _api = api,
       _memberships = memberships,
       super(const InviteState());

  final Dio _api;
  final MembershipCubit _memberships;
  final String token;

  /// `POST /invites/{token}/accept` → `{ membershipId }`; mở vai trò vừa nhận.
  Future<void> accept() async {
    emit(const InviteState(statusAccept: LoadingStatus.loading));
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/invites/${Uri.encodeComponent(token)}/accept',
      );
      await _memberships.load(silent: true);
      final id = res.data?['membershipId'];
      final joined = _memberships.state.memberships
          .where((m) => m.id == id)
          .firstOrNull;
      if (joined != null) await _memberships.select(joined);
      if (!isClosed) {
        emit(const InviteState(statusAccept: LoadingStatus.success));
      }
    } on DioException catch (e) {
      if (isClosed) return;
      final error = apiException(e);
      final version = error?.details['termsVersion'];
      emit(
        InviteState(
          statusAccept: LoadingStatus.failure,
          errorCode: error?.code,
          consentTermsVersion:
              error?.code == ApiErrorCode.consentRequired && version is String
              ? version
              : null,
        ),
      );
    }
  }

  /// `POST /consents { role: parent, termsVersion }` rồi nhận lại lời mời.
  Future<void> consentAndAccept() async {
    final version = state.consentTermsVersion;
    if (version == null) return;
    emit(const InviteState(statusAccept: LoadingStatus.loading));
    try {
      await _api.post<void>(
        '/consents',
        data: {'role': 'parent', 'termsVersion': version},
      );
    } on DioException catch (e) {
      if (!isClosed) {
        emit(
          InviteState(
            statusAccept: LoadingStatus.failure,
            errorCode: apiException(e)?.code,
          ),
        );
      }
      return;
    }
    await accept();
  }
}
