import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/invites/data/invite_models.dart';
import 'package:teacher/features/invites/data/invite_repository.dart';
import 'package:teacher/features/invites/data/invite_sharer.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

InviteLink linkOf(String guardianId, {String id = 'inv1'}) => InviteLink(
  id: id,
  guardianId: guardianId,
  url: 'https://dayhoc.app/i#t=tok-$guardianId',
  shortCode: '7K3QZ9XM',
  expiresAt: '2026-12-21T09:00:00+07:00',
  shortCodeExpiresAt: '2026-12-16T09:00:00+07:00',
);

RosterGuardian guardianOf(
  String id,
  GuardianInviteStatus status, {
  String relation = 'father',
  String name = 'Nguyễn Văn Hải',
  String? inviteId,
}) => RosterGuardian(
  id: id,
  fullName: name,
  relation: relation,
  inviteStatus: status,
  latestInvite: inviteId == null
      ? null
      : LatestInvite(id: inviteId, expiresAt: '2026-12-01T09:00:00+07:00'),
);

RosterEntry entryOf(
  String studentId,
  String name,
  List<RosterGuardian> guardians,
) => RosterEntry(
  enrollmentId: 'e-$studentId',
  studentId: studentId,
  fullName: name,
  studentStatus: 'active',
  joinedOn: '2026-12-14',
  guardians: guardians,
);

class FakeInviteRepository implements InviteRepository {
  /// `create:<studentId>:<guardianId>` hoặc `resend:<inviteId>`, kèm khóa.
  final calls = <({String op, String key})>[];

  /// Lỗi ném ở lần gọi kế tiếp (rồi tự xóa), theo thứ tự.
  final errors = <Object>[];

  Future<InviteLink> _next(String op, String key, String guardianId) async {
    calls.add((op: op, key: key));
    if (errors.isNotEmpty) throw errors.removeAt(0);
    return linkOf(guardianId, id: 'inv-${calls.length}');
  }

  @override
  Future<InviteLink> create(
    String studentId,
    String guardianId, {
    required String idempotencyKey,
  }) => _next('create:$studentId:$guardianId', idempotencyKey, guardianId);

  @override
  Future<InviteLink> resend(
    String inviteId, {
    required String idempotencyKey,
  }) => _next('resend:$inviteId', idempotencyKey, 'g-of-$inviteId');
}

class FakeInviteSharer implements InviteSharer {
  final shared = <String>[];

  @override
  Future<void> share(String text) async => shared.add(text);
}

ApiException conflict() => const ApiException(
  code: ApiErrorCode.conflictStale,
  wireCode: 'CONFLICT_STALE',
  status: 409,
);
