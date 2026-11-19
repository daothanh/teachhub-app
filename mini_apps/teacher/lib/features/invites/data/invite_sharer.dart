import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

/// Mở bảng chia sẻ của hệ điều hành với tin nhắn soạn sẵn (US-1.6 AC2).
/// Tách ra để test không gọi kênh nền tảng.
abstract class InviteSharer {
  /// [origin] là vùng nút bấm (iPad cần để neo popover). Trả `false` khi không
  /// mở được bảng chia sẻ; không ném lỗi.
  Future<bool> share(String text, {Rect? origin});
}

InviteSharer inviteSharer() => GetIt.I<InviteSharer>();

/// Vùng của widget tại [context] theo tọa độ màn hình, `null` khi chưa bố cục.
Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

class SharePlusInviteSharer implements InviteSharer {
  const SharePlusInviteSharer();

  @override
  Future<bool> share(String text, {Rect? origin}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
      return true;
    } catch (e, st) {
      // Không log nội dung: tin nhắn chứa link mời (bí mật).
      log('Mở bảng chia sẻ lỗi', name: 'invites', error: e, stackTrace: st);
      return false;
    }
  }
}
