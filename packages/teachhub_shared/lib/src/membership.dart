import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'routes.dart';

/// Vai trò của một membership (`memberships.role`, spec §4).
enum MembershipRole {
  tenantOwner('tenant_owner', TeachHubRoutes.teacher),
  parent('parent', TeachHubRoutes.parent),
  student('student', TeachHubRoutes.student);

  const MembershipRole(this.wire, this.rootRoute);

  /// Giá trị trên API.
  final String wire;

  /// Route gốc của mini-app ứng với vai trò.
  final String rootRoute;

  /// Quyền dạng `role:<wire>` mà `PermissionGuard` kiểm (spec §3.7).
  String get permission => 'role:$wire';

  static MembershipRole? fromWire(String? value) {
    for (final role in values) {
      if (role.wire == value) return role;
    }
    return null;
  }
}

/// Một vai trò của người dùng trong một tenant (`GET /v1/me/memberships`).
final class Membership extends Equatable {
  const Membership({
    required this.id,
    required this.role,
    required this.label,
    this.tenantId,
    this.studentId,
  });

  final String id;
  final MembershipRole role;

  /// Nhãn hiển thị do API trả (vd. "Giáo viên · Lớp cô Lan").
  final String label;
  final String? tenantId;

  /// Chỉ có ở vai trò học sinh.
  final String? studentId;

  /// Trả `null` khi vai trò không thuộc app (vd. vai trò Giai đoạn 2), để app
  /// cũ bỏ qua thay vì lỗi.
  static Membership? fromJson(Map<String, dynamic> json) {
    final role = MembershipRole.fromWire(json['role'] as String?);
    final id = json['id'];
    if (role == null || id is! String) return null;
    return Membership(
      id: id,
      role: role,
      label: json['label'] as String? ?? '',
      tenantId: json['tenantId'] as String?,
      studentId: json['studentId'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, role, label, tenantId, studentId];
}

/// Vai trò đang mở, do shell giữ và đăng ký trong `GetIt`. Mini-app chỉ đọc
/// để lọc dữ liệu theo phạm vi membership (US-0.11 AC2).
typedef ActiveMembership = ValueNotifier<Membership?>;
