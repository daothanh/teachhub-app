import 'dart:convert';

import 'package:tasco_auth/tasco_auth.dart';

class PermissionItem {
  final String name;
  final String? uri;
  final String? type;

  const PermissionItem({required this.name, this.uri, this.type});

  factory PermissionItem.fromJson(dynamic json) {
    if (json is String) {
      return PermissionItem(name: json);
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return PermissionItem(
        name:
            (map['name'] ??
                    map['rs_code'] ??
                    map['rsCode'] ??
                    map['code'] ??
                    map['uri'] ??
                    '')
                .toString(),
        uri: map['uri']?.toString(),
        type: map['type']?.toString(),
      );
    }
    return PermissionItem(name: json.toString());
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (uri != null) 'uri': uri,
    if (type != null) 'type': type,
  };
}

class UserModel implements TascoAuthUser {
  @override
  final String id;
  final String? username;
  final String name;
  final String? role;
  final List<PermissionItem> permissionItems;

  @override
  List<String> get permissions =>
      permissionItems.map((p) => p.name).where((n) => n.isNotEmpty).toList();

  const UserModel({
    required this.id,
    this.username,
    required this.name,
    this.role,
    this.permissionItems = const [],
  });

  factory UserModel.withPermissions({
    required String id,
    String? username,
    required String name,
    String? role,
    List<dynamic>? permissions,
  }) {
    return UserModel(
      id: id,
      username: username,
      name: name,
      role: role,
      permissionItems: permissions != null
          ? permissions.map(PermissionItem.fromJson).toList()
          : const [],
    );
  }

  factory UserModel.fromLoginJson(Map<String, dynamic> json) {
    final rootBody = json['body'] is Map<String, dynamic>
        ? json['body'] as Map<String, dynamic>
        : json;
    final tokenData = rootBody['tokenData'] is Map<String, dynamic>
        ? rootBody['tokenData'] as Map<String, dynamic>
        : (json['tokenData'] is Map<String, dynamic>
              ? json['tokenData'] as Map<String, dynamic>
              : null);

    final rawPermissions =
        rootBody['permissions'] ??
        rootBody['authorization'] ??
        json['permissions'] ??
        json['authorization'];

    final parsedPermissions = rawPermissions is List
        ? rawPermissions.map(PermissionItem.fromJson).toList()
        : <PermissionItem>[];

    final accessToken =
        tokenData?['access_token'] as String? ??
        json['access_token'] as String?;
    if (accessToken != null && accessToken.contains('.')) {
      try {
        final parts = accessToken.split('.');
        if (parts.length >= 2) {
          final normalized = base64Url.normalize(parts[1]);
          final payload =
              jsonDecode(utf8.decode(base64Url.decode(normalized)))
                  as Map<String, dynamic>;
          final roles =
              (payload['realm_access'] is Map &&
                  (payload['realm_access'] as Map)['roles'] is List)
              ? List<String>.from(
                  (payload['realm_access'] as Map)['roles'] as List,
                )
              : <String>[];
          final rawUsername =
              (payload['preferred_username'] ??
                      rootBody['username'] ??
                      rootBody['userName'] ??
                      '')
                  .toString();

          final jwtPermissionItems = roles
              .map((r) => PermissionItem(name: r, type: 'ROLE'))
              .toList();

          return UserModel(
            id: (payload['sub'] ?? rootBody['userId'] ?? rootBody['id'] ?? '')
                .toString(),
            username: rawUsername.isNotEmpty ? rawUsername : null,
            name:
                (payload['name'] ??
                        (rawUsername.isNotEmpty ? rawUsername : null) ??
                        rootBody['name'] ??
                        '')
                    .toString(),
            role: roles.isNotEmpty
                ? roles.first
                : (rootBody['role'] as String?),
            permissionItems: parsedPermissions.isNotEmpty
                ? parsedPermissions
                : jwtPermissionItems,
          );
        }
      } catch (_) {}
    }

    final rawUsername =
        (rootBody['username'] ??
                rootBody['userName'] ??
                rootBody['preferred_username'] ??
                '')
            .toString();
    return UserModel(
      id: (rootBody['userId'] ?? rootBody['id'] ?? rootBody['user_id'] ?? '')
          .toString(),
      username: rawUsername.isNotEmpty ? rawUsername : null,
      name:
          (rootBody['name'] ??
                  rootBody['fullName'] ??
                  rootBody['full_name'] ??
                  (rawUsername.isNotEmpty ? rawUsername : null) ??
                  '')
              .toString(),
      role: rootBody['role'] as String? ?? rootBody['role_code'] as String?,
      permissionItems: parsedPermissions,
    );
  }

  factory UserModel.fromProfileJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['body'] is Map<String, dynamic>
              ? json['body'] as Map<String, dynamic>
              : json);

    final rawPermissions =
        root['permissions'] ??
        root['authorization'] ??
        json['permissions'] ??
        json['authorization'];

    final parsedPermissions = rawPermissions is List
        ? rawPermissions.map(PermissionItem.fromJson).toList()
        : <PermissionItem>[];

    final rawUsername = (root['username'] ?? root['userName'] ?? '').toString();
    return UserModel(
      id: (root['user_id'] ?? root['id'] ?? root['userId'] ?? '').toString(),
      username: rawUsername.isNotEmpty ? rawUsername : null,
      name:
          (root['full_name'] ?? root['fullName'] ?? root['name'] ?? rawUsername)
              .toString(),
      role: root['role_code'] as String? ?? root['role'] as String?,
      permissionItems: parsedPermissions,
    );
  }

  factory UserModel.fromStorageJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'] as List?;
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      name: json['name'] as String,
      role: json['role'] as String?,
      permissionItems:
          rawPermissions?.map(PermissionItem.fromJson).toList() ?? const [],
    );
  }

  Map<String, dynamic> toStorageJson() => {
    'id': id,
    'username': username,
    'name': name,
    'role': role,
    'permissions': permissionItems.map((e) => e.toJson()).toList(),
  };

  bool hasPermission(String permission) =>
      permissionItems.any((p) => p.name == permission || p.uri == permission);
}
