import 'dart:math';

import 'package:teachhub_shared/teachhub_shared.dart';

/// Giữ MỘT khóa cho mỗi lệnh ghi chừng nào draft chưa đổi: bấm thử lại sau lỗi
/// mạng/timeout dùng lại khóa cũ (server phát lại kết quả thay vì làm hai lần);
/// draft đổi thì khóa mới; lệnh xong thì quên.
class DraftKeys {
  /// [seed] khôi phục khóa đã lưu (kill app giữa chừng); [onChanged] nhận bản
  /// chụp mỗi khi bộ khóa đổi để ghi bền vững.
  DraftKeys({
    Random? random,
    Map<String, ({String draft, String key})>? seed,
    this.onChanged,
  }) : _random = random {
    _byOp.addAll(seed ?? const {});
  }
  final Random? _random;
  final void Function(Map<String, ({String draft, String key})> keys)?
  onChanged;
  final _byOp = <String, ({String draft, String key})>{};

  String of(String op, String draft) {
    final cur = _byOp[op];
    if (cur != null && cur.draft == draft) return cur.key;
    final key = uuidV4(_random ?? Random.secure());
    _byOp[op] = (draft: draft, key: key);
    onChanged?.call({..._byOp});
    return key;
  }

  /// Đã có khóa đang chờ cho đúng draft này (lần gửi trước lỗi mạng, chưa biết
  /// server đã làm chưa): đây là lần thử lại, server sẽ phát lại kết quả.
  bool pending(String op, String draft) => _byOp[op]?.draft == draft;

  void done(String op) {
    if (_byOp.remove(op) != null) onChanged?.call({..._byOp});
  }
}
