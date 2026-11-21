import 'package:app/features/role_picker/membership_cubit.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// Trả JSON cố định theo `METHOD path`, ghi lại các lệnh đã gửi.
class _FakeApi extends Interceptor {
  _FakeApi(this.routes);
  final Map<String, Object? Function()> routes;
  final calls = <String>[];

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    final key = '${o.method} ${o.path}';
    calls.add(key);
    final handler = routes[key];
    if (handler == null) {
      h.reject(DioException(requestOptions: o, message: 'no route $key'));
      return;
    }
    h.resolve(Response(requestOptions: o, statusCode: 200, data: handler()));
  }
}

Map<String, dynamic> _m(String id, String role) => {
  'id': id,
  'role': role,
  'label': role,
};

void main() {
  late SharedPreferences prefs;
  late ValueNotifier<Membership?> active;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    active = ValueNotifier(null);
  });

  MembershipCubit cubit(_FakeApi api) => MembershipCubit(
    api: Dio()..interceptors.add(api),
    prefs: prefs,
    activeMembership: active,
  );

  test(
    'a single membership opens directly and is published to mini-apps',
    () async {
      final c = cubit(
        _FakeApi({
          'GET /me/memberships': () => {
            'items': [_m('m1', 'parent')],
          },
        }),
      );
      await c.load();
      expect(c.state.statusLoad, LoadingStatus.success);
      expect(c.state.active?.id, 'm1');
      expect(active.value?.id, 'm1');
      expect(c.state.permissions, {'role:parent'});
    },
  );

  test(
    'several memberships: device choice wins over server last choice',
    () async {
      await prefs.setString('active_membership_id', 'm2');
      final c = cubit(
        _FakeApi({
          'GET /me/memberships': () => {
            'items': [_m('m1', 'tenant_owner'), _m('m2', 'parent')],
            'lastMembershipId': 'm1',
          },
        }),
      );
      await c.load();
      expect(c.state.active?.id, 'm2');
    },
  );

  test('several memberships and no remembered choice: none active', () async {
    final c = cubit(
      _FakeApi({
        'GET /me/memberships': () => {
          'items': [_m('m1', 'tenant_owner'), _m('m2', 'parent')],
        },
      }),
    );
    await c.load();
    expect(c.state.active, isNull);
  });

  test('adding the teacher role creates a workspace and opens it', () async {
    var items = <Map<String, dynamic>>[];
    final api = _FakeApi({
      'GET /me/memberships': () => {'items': items},
      'POST /workspaces': () {
        items = [_m('m9', 'tenant_owner')];
        return null;
      },
      'PUT /me/active-membership': () => null,
    });
    final c = cubit(api);
    await c.load();
    await c.addRole(MembershipRole.tenantOwner);
    expect(c.state.statusCreate, LoadingStatus.success);
    expect(c.state.active?.id, 'm9');
    expect(prefs.getString('active_membership_id'), 'm9');
    // PUT chạy nền, không chặn UI.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(api.calls, contains('PUT /me/active-membership'));
  });

  test('load failure is reported and clear() forgets the session', () async {
    final c = cubit(_FakeApi({}));
    await c.load();
    expect(c.state.statusLoad, LoadingStatus.failure);
    await c.clear();
    expect(c.state.statusLoad, LoadingStatus.initial);
    expect(active.value, isNull);
  });

  group('mở app khi mất mạng (#34)', () {
    final online = _FakeApi({
      'GET /me/memberships': () => {
        'items': [_m('m1', 'tenant_owner')],
      },
    });
    // Không có route → DioException không kèm phản hồi, như mất mạng.
    final offline = _FakeApi({});

    test('lỗi mạng dùng danh sách vai trò lần trước', () async {
      await cubit(online).load();
      final c = cubit(offline);
      await c.load();
      expect(c.state.statusLoad, LoadingStatus.success);
      expect(c.state.active?.id, 'm1');
    });

    test('chưa có bản lưu thì vẫn báo lỗi', () async {
      final c = cubit(offline);
      await c.load();
      expect(c.state.statusLoad, LoadingStatus.failure);
    });

    test('server trả lỗi (403) thì không dùng bản lưu', () async {
      await cubit(online).load();
      final c = MembershipCubit(
        api: Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (o, h) => h.reject(
                DioException(
                  requestOptions: o,
                  response: Response(requestOptions: o, statusCode: 403),
                ),
              ),
            ),
          ),
        prefs: prefs,
        activeMembership: active,
      );
      await c.load();
      expect(c.state.statusLoad, LoadingStatus.failure);
    });

    test('clear() (đăng xuất) xóa bản lưu', () async {
      final first = cubit(online);
      await first.load();
      await first.clear();
      final c = cubit(offline);
      await c.load();
      expect(c.state.statusLoad, LoadingStatus.failure);
    });
  });

  // S1-FL-06: một lần thao tác "thêm vai trò Giáo viên" = một Idempotency-Key.
  group('POST /workspaces giữ một khóa cho một lần thao tác', () {
    final keys = <String?>[];
    // Mỗi lần gọi lấy hành vi kế tiếp: lỗi mạng, lỗi chắc chắn, hoặc thành công.
    final script = <FutureOr<int?> Function()>[];
    late MembershipCubit c;

    setUp(() {
      keys.clear();
      script.clear();
      c = MembershipCubit(
        api: Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (o, h) async {
                if (o.path == '/workspaces') {
                  keys.add(o.headers['Idempotency-Key'] as String?);
                  final status = await script.removeAt(0)();
                  if (status == null) {
                    return h.reject(
                      DioException.connectionError(
                        requestOptions: o,
                        reason: 'offline',
                      ),
                    );
                  }
                  if (status >= 400) {
                    return h.reject(
                      DioException(
                        requestOptions: o,
                        response: Response(
                          requestOptions: o,
                          statusCode: status,
                        ),
                      ),
                    );
                  }
                }
                h.resolve(
                  Response(
                    requestOptions: o,
                    statusCode: 200,
                    data: o.path == '/me/memberships'
                        ? {'items': <Object>[]}
                        : null,
                  ),
                );
              },
            ),
          ),
        prefs: prefs,
        activeMembership: active,
      );
    });

    test('lỗi mạng rồi bấm lại: cùng một khóa', () async {
      script
        ..add(() => null)
        ..add(() => 201);
      await c.addRole(MembershipRole.tenantOwner);
      expect(c.state.statusCreate, LoadingStatus.failure);
      await c.addRole(MembershipRole.tenantOwner);
      expect(keys, hasLength(2));
      expect(keys[0], isNotNull);
      expect(keys[1], keys[0]);
    });

    test('thành công xong thì lần thêm sau dùng khóa mới', () async {
      script
        ..add(() => 201)
        ..add(() => 201);
      await c.addRole(MembershipRole.tenantOwner);
      await c.addRole(MembershipRole.tenantOwner);
      expect(keys[1], isNot(keys[0]));
    });

    test('server từ chối hẳn (422): lần sau là lệnh mới, khóa mới', () async {
      script
        ..add(() => 422)
        ..add(() => 201);
      await c.addRole(MembershipRole.tenantOwner);
      await c.addRole(MembershipRole.tenantOwner);
      expect(keys[1], isNot(keys[0]));
    });

    test('người dùng đổi ý (resetPendingAdd): khóa mới', () async {
      script
        ..add(() => null)
        ..add(() => 201);
      await c.addRole(MembershipRole.tenantOwner);
      c.resetPendingAdd();
      await c.addRole(MembershipRole.tenantOwner);
      expect(keys[1], isNot(keys[0]));
    });

    test('bấm lặp nhanh: chỉ một request', () async {
      final gate = Completer<int?>();
      script.add(() => gate.future);
      final first = c.addRole(MembershipRole.tenantOwner);
      await c.addRole(MembershipRole.tenantOwner);
      await c.addRole(MembershipRole.tenantOwner);
      gate.complete(201);
      await first;
      expect(keys, hasLength(1));
      expect(c.state.statusCreate, LoadingStatus.success);
    });
  });
}
