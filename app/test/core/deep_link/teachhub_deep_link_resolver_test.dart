import 'package:app/core/deep_link/teachhub_deep_link_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = TeachHubDeepLinkResolver();

  test(
    'invite links over https and the custom scheme open /invite/<token>',
    () {
      for (final link in [
        'https://dayhoc.app/i/Ab3_x-9',
        'https://www.dayhoc.app/i/Ab3_x-9/',
        'teachhub://i/Ab3_x-9',
      ]) {
        final target = resolver.resolve(Uri.parse(link));
        expect(target?.path, '/invite/Ab3_x-9', reason: link);
        expect(target?.requiresAuth, isTrue);
      }
    },
  );

  test('foreign hosts, old tasco:// links and unknown paths are ignored', () {
    for (final link in [
      'https://evil.example/i/abc',
      'http://dayhoc.app/i/abc',
      'tasco://i/abc',
      'https://dayhoc.app/i/a/b',
      'teachhub://unknown/route',
    ]) {
      expect(resolver.resolve(Uri.parse(link)), isNull, reason: link);
    }
  });

  test('a path a mini-app owns resolves through the module resolver', () {
    final withModules = TeachHubDeepLinkResolver(
      moduleResolver: (path) => path.startsWith('/t/')
          ? (path: path, params: const {}, requiresAuth: true)
          : null,
    );
    final target = withModules.resolve(Uri.parse('teachhub://t/today?x=1'));
    expect(target?.path, '/t/today');
    expect(target?.queryParams, {'x': '1'});
  });
}
