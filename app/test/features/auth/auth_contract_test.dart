import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:app/features/auth/auth_config.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Đối chiếu mô hình auth/membership với `contracts/openapi.json` (bản chép từ
/// teachhub-backend, cập nhật bằng `dart run tool/sync_openapi.dart` trong
/// packages/teachhub_shared). Hợp đồng đổi tên trường mà app chưa theo → đỏ.
final _schemas =
    ((jsonDecode(
              File(
                '../packages/teachhub_shared/contracts/openapi.json',
              ).readAsStringSync(),
            )
            as Map)['components']['schemas']
        as Map<String, dynamic>);

Set<String> _props(String schema) =>
    ((_schemas[schema] as Map)['properties'] as Map).keys
        .cast<String>()
        .toSet();

/// Map ghi lại các khóa mà `fromJson` đọc.
class _Spy extends MapBase<String, dynamic> {
  _Spy(this._inner);
  final Map<String, dynamic> _inner;
  final reads = <String>{};

  @override
  dynamic operator [](Object? key) {
    reads.add(key as String);
    return _inner[key];
  }

  @override
  void operator []=(String key, dynamic value) => _inner[key] = value;
  @override
  void clear() => _inner.clear();
  @override
  Iterable<String> get keys => _inner.keys;
  @override
  dynamic remove(Object? key) => _inner.remove(key);
}

/// Một giá trị mẫu cho mọi trường của schema, đúng kiểu để fromJson không ném.
_Spy _sample(String schema, Map<String, dynamic> overrides) =>
    _Spy({for (final p in _props(schema)) p: 'v-$p', ...overrides});

void main() {
  test('TeachHubUser đọc đúng các trường của schema User', () {
    final spy = _sample('User', {'permissions': <String>[]});
    TeachHubUser.fromJson(spy);
    expect(spy.reads, _props('User'));
    expect(TeachHubUser.fromJson(spy).toJson().keys.toSet(), _props('User'));
  });

  test('Membership đọc đúng các trường của schema Membership', () {
    final spy = _sample('Membership', {'role': 'parent'});
    expect(Membership.fromJson(spy), isNotNull);
    expect(spy.reads, _props('Membership'));
  });

  test('MembershipRole khớp enum role của hợp đồng', () {
    final roles =
        (((_schemas['Membership'] as Map)['properties'] as Map)['role']
                as Map)['enum']
            as List;
    expect(MembershipRole.values.map((r) => r.wire), roles);
  });

  test('phản hồi login/SSO: app đọc `user`, tasco_auth đọc token', () {
    final login = _loginBody();
    expect(login['required'], contains('user'));
    expect(
      (login['properties'] as Map).keys,
      containsAll(['access_token', 'refresh_token', 'expires_in', 'user']),
    );
    final spy = _Spy({
      'user': _sample('User', {'permissions': <String>[]}),
    });
    teachHubAuthConfig.parseLoginUser(spy);
    expect(spy.reads, {'user'});
  });
}

Map<String, dynamic> _loginBody() {
  final paths =
      (jsonDecode(
                File(
                  '../packages/teachhub_shared/contracts/openapi.json',
                ).readAsStringSync(),
              )
              as Map)['paths']
          as Map;
  return paths['/v1/auth/login']['post']['responses']['200']['content']['application/json']['schema']
      as Map<String, dynamic>;
}
