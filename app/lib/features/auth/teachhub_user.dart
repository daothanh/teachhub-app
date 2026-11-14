import 'package:tasco_auth/tasco_auth.dart';

/// Người dùng TeachHub (`user` trong phản hồi `/auth/login`, `/auth/sso/*`
/// và thân phản hồi `/auth/me`).
///
/// Một dạng JSON duy nhất theo hợp đồng API; không đoán khóa thay thế.
final class TeachHubUser implements TascoAuthUser {
  const TeachHubUser({
    required this.id,
    required this.email,
    this.displayName,
    this.permissions = const [],
  });

  factory TeachHubUser.fromJson(Map<String, dynamic> json) => TeachHubUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
    permissions: [
      for (final p in json['permissions'] as List? ?? const []) p as String,
    ],
  );

  @override
  final String id;
  final String email;
  final String? displayName;

  /// Vai trò dạng `role:tenant_owner`, `role:parent`… (spec §3.7).
  @override
  final List<String> permissions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'permissions': permissions,
  };
}
