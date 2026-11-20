import 'package:app/features/invite/invite_link_requester.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  InviteLinkRequester make({
    required bool zalo,
    bool opens = true,
    required List<String> log,
  }) => InviteLinkRequester(
    canOpenZalo: () async => zalo,
    openZalo: () async {
      log.add('open');
      return opens;
    },
    copy: (t) async => log.add('copy:$t'),
    share: (t) async => log.add('share:$t'),
  );

  test('có Zalo: chép tin vào clipboard rồi mở Zalo', () async {
    final log = <String>[];
    final r = await make(zalo: true, log: log).request('tin');
    expect(r, InviteLinkRequestOutcome.zaloOpened);
    expect(log, ['copy:tin', 'open']);
  });

  test('không có Zalo: bảng chia sẻ', () async {
    final log = <String>[];
    final r = await make(zalo: false, log: log).request('tin');
    expect(r, InviteLinkRequestOutcome.shared);
    expect(log, ['share:tin']);
  });

  test('mở Zalo thất bại: bảng chia sẻ', () async {
    final log = <String>[];
    final r = await make(zalo: true, opens: false, log: log).request('tin');
    expect(r, InviteLinkRequestOutcome.shared);
    expect(log, ['copy:tin', 'open', 'share:tin']);
  });
}
