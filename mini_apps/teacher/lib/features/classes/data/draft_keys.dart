import 'dart:math';

import 'package:teachhub_shared/teachhub_shared.dart';

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
    final key = uuidV4(_random ?? Random.secure());
    _byOp[op] = (draft: draft, key: key);
    return key;
  }

  /// Đã có khóa đang chờ cho đúng draft này (lần gửi trước lỗi mạng, chưa biết
  /// server đã làm chưa): đây là lần thử lại, server sẽ phát lại kết quả.
  bool pending(String op, String draft) => _byOp[op]?.draft == draft;

  void done(String op) => _byOp.remove(op);
}
