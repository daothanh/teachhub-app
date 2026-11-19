import '../consent/consent_cubit.dart';
import '../role_picker/membership_cubit.dart';
import 'invite_repository.dart';

/// Sau khi nhận lời mời: server đã coi là đồng ý, tải lại vai trò và mở vai
/// trò Phụ huynh vừa có.
Future<void> completeInvite({
  required InviteAccepted accepted,
  required MembershipCubit memberships,
  required ConsentCubit consent,
}) async {
  consent.markAccepted();
  await memberships.load(silent: true);
  final joined = memberships.state.memberships
      .where((m) => m.id == accepted.membershipId)
      .firstOrNull;
  if (joined != null) await memberships.select(joined);
}
