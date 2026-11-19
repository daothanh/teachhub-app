import 'dart:math';

/// UUID v4 cho `Idempotency-Key`.
// shortcut: Random.secure tại chỗ vì mini-app không import được hàm của host;
// gộp vào teachhub_shared khi có chỗ dùng chung.
String newIdempotencyKey([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Giữ MỘT khóa cho mỗi lệnh ghi chừng nào draft chưa đổi: bấm thử lại sau lỗi
/// mạng/timeout dùng lại khóa cũ (server phát lại kết quả thay vì làm hai lần);
/// draft đổi thì khóa mới; lệnh xong thì quên.
class DraftKeys {
  DraftKeys({Random? random}) : _random = random;
  final Random? _random;
  final _byOp = <String, ({String draft, String key})>{};

  String of(String op, String draft) {
    final cur = _byOp[op];
    if (cur != null && cur.draft == draft) return cur.key;
    final key = newIdempotencyKey(_random);
    _byOp[op] = (draft: draft, key: key);
    return key;
  }

  void done(String op) => _byOp.remove(op);
}
