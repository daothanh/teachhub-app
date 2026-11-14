import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/model/user_model.dart';

void main() {
  group('UserModel and PermissionItem', () {
    test('PermissionItem parses from Map and String', () {
      final p1 = PermissionItem.fromJson({
        'name': 'Xem đơn',
        'uri': '/cop/crm/order',
        'type': 'MENU',
      });
      expect(p1.name, 'Xem đơn');
      expect(p1.uri, '/cop/crm/order');
      expect(p1.type, 'MENU');
      expect(p1.toJson(), {
        'name': 'Xem đơn',
        'uri': '/cop/crm/order',
        'type': 'MENU',
      });

      final p2 = PermissionItem.fromJson('orders.read');
      expect(p2.name, 'orders.read');
      expect(p2.uri, isNull);
      expect(p2.type, isNull);
    });

    test('fromLoginJson maps username -> name, no permissions', () {
      final u = UserModel.fromLoginJson({
        'id': '1',
        'username': 'alice',
        'role': 'admin',
      });
      expect(u.id, '1');
      expect(u.name, 'alice');
      expect(u.role, 'admin');
      expect(u.permissions, isEmpty);
    });

    test('fromLoginJson decodes JWT access_token claims', () {
      final jwtPayload = {
        'sub': 'uid-123',
        'name': 'Đào Xuân Thanh',
        'preferred_username': 'thanhdx',
        'realm_access': {
          'roles': ['admin', 'manager'],
        },
      };
      final jwtPayloadB64 = base64Url
          .encode(utf8.encode(jsonEncode(jwtPayload)))
          .replaceAll('=', '');
      final fakeJwt = 'eyJhbGciOiJIUzI1NiJ9.$jwtPayloadB64.signature';

      final u = UserModel.fromLoginJson({
        'body': {
          'tokenData': {'access_token': fakeJwt},
        },
      });

      expect(u.id, 'uid-123');
      expect(u.username, 'thanhdx');
      expect(u.name, 'Đào Xuân Thanh');
      expect(u.role, 'admin');
      expect(u.permissions, ['admin', 'manager']);
      expect(u.permissionItems.first.type, 'ROLE');
    });

    test('fromLoginJson decodes JWT with empty roles fallback', () {
      final jwtPayload = {
        'sub': 'uid-123',
        'name': 'Đào Xuân Thanh',
        'realm_access': {'roles': <String>[]},
      };
      final jwtPayloadB64 = base64Url
          .encode(utf8.encode(jsonEncode(jwtPayload)))
          .replaceAll('=', '');
      final fakeJwt = 'eyJhbGciOiJIUzI1NiJ9.$jwtPayloadB64.signature';

      final u = UserModel.fromLoginJson({
        'body': {
          'role': 'custom_role',
          'tokenData': {'access_token': fakeJwt},
        },
      });

      expect(u.id, 'uid-123');
      expect(u.role, 'custom_role');
    });

    test('fromLoginJson falls back gracefully when token is not valid JWT', () {
      final u = UserModel.fromLoginJson({
        'user_id': '10',
        'full_name': 'bob',
        'role_code': 'user',
        'tokenData': {'access_token': 'not-a-jwt'},
      });
      expect(u.id, '10');
      expect(u.name, 'bob');
      expect(u.role, 'user');
    });

    test('fromProfileJson maps profile fields + object permissions', () {
      final u = UserModel.fromProfileJson({
        'user_id': '7',
        'full_name': 'Alice Nguyen',
        'role_code': 'mgr',
        'permissions': [
          {'name': 'Đơn hàng', 'uri': '/orders', 'type': 'MENU'},
          'users.manage',
        ],
      });
      expect(u.id, '7');
      expect(u.name, 'Alice Nguyen');
      expect(u.role, 'mgr');
      expect(u.permissions, ['Đơn hàng', 'users.manage']);
      expect(u.permissionItems.first.uri, '/orders');
      expect(u.permissionItems.first.type, 'MENU');
    });

    test('fromProfileJson tolerates nested body / data structure', () {
      final u = UserModel.fromProfileJson({
        'data': {'id': '77', 'name': 'Bob', 'role': 'lead'},
      });
      expect(u.id, '77');
      expect(u.name, 'Bob');
      expect(u.role, 'lead');
    });

    test('fromProfileJson tolerates missing permissions', () {
      final u = UserModel.fromProfileJson({'user_id': '7', 'full_name': 'X'});
      expect(u.permissions, isEmpty);
      expect(u.role, isNull);
    });

    test('storage json round-trips with permission objects', () {
      final u = UserModel(
        id: '1',
        name: 'A',
        role: 'r',
        permissionItems: [
          const PermissionItem(name: 'Order', uri: '/order', type: 'MENU'),
        ],
      );
      final back = UserModel.fromStorageJson(u.toStorageJson());
      expect(back.id, u.id);
      expect(back.name, u.name);
      expect(back.role, u.role);
      expect(back.permissions, ['Order']);
      expect(back.permissionItems.first.uri, '/order');
    });
  });

  group('hasPermission', () {
    test('reflects the permission list and uri matching', () {
      final u = UserModel(
        id: '1',
        name: 'A',
        permissionItems: [
          const PermissionItem(name: 'orders.read', uri: '/cop/orders'),
        ],
      );
      expect(u.hasPermission('orders.read'), isTrue);
      expect(u.hasPermission('/cop/orders'), isTrue);
      expect(u.hasPermission('orders.write'), isFalse);
    });
  });
}
