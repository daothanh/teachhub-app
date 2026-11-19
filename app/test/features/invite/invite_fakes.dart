import 'package:app/features/consent/consent_cubit.dart';
import 'package:app/features/invite/invite_repository.dart';
import 'package:app/features/role_picker/membership_cubit.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

const parentMembership = Membership(
  id: 'm-p',
  role: MembershipRole.parent,
  label: 'Phụ huynh',
);

ApiException apiError(
  int status,
  String code, {
  Map<String, Object?>? details,
}) => ApiException(
  code: ApiErrorCode.fromWire(code),
  wireCode: code,
  status: status,
  details: details ?? const {},
);

/// Repository giả: mỗi lệnh lấy kết quả (hoặc lỗi) kế tiếp trong hàng đợi.
class FakeInviteRepository implements InviteRepository {
  final previews = <Object>[];
  final accepts = <Object>[];
  final redeems = <Object>[];
  final calls = <String>[];

  static const accepted = InviteAccepted(
    membershipId: 'm-p',
    studentId: 's1',
    studentName: 'Nguyễn Minh Anh',
  );

  T _next<T>(List<Object> q) {
    final v = q.removeAt(0);
    if (v is Exception) throw v;
    return v as T;
  }

  @override
  Future<InvitePreview> preview(String token) async {
    calls.add('preview:$token');
    return _next(previews);
  }

  @override
  Future<InviteAccepted> accept(String token) async {
    calls.add('accept:$token');
    return _next(accepts);
  }

  @override
  Future<InviteAccepted> redeemCode(String code) async {
    calls.add('redeem:$code');
    return _next(redeems);
  }
}

final samplePreview = InvitePreview(
  teacherName: 'Cô Lan',
  studentGivenName: 'Anh',
  expiresAt: DateTime(2026, 12, 21),
);

/// MembershipCubit giả: sau `load` có sẵn vai trò Phụ huynh; ghi lại `select`.
class FakeMemberships extends MembershipCubit {
  FakeMemberships(SharedPreferences prefs)
    : super(api: Dio(), prefs: prefs, activeMembership: ActiveMembership(null));

  final selected = <String>[];

  @override
  Future<void> load({bool silent = false}) async => emit(
    state.copyWith(
      statusLoad: LoadingStatus.success,
      memberships: [parentMembership],
    ),
  );

  @override
  Future<void> select(Membership m) async => selected.add(m.id);
}

ConsentCubit fakeConsent() => ConsentCubit(Dio());
