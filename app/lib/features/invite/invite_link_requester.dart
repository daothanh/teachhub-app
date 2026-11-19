import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum InviteLinkRequestOutcome {
  /// Đã mở Zalo; tin soạn sẵn nằm trong clipboard để dán.
  zaloOpened,

  /// Máy không có Zalo: đã mở bảng chia sẻ của hệ điều hành.
  shared,
}

/// "Nhắn giáo viên xin link" (US-0.12 AC3, US-0.3 AC5): mở Zalo, không có Zalo
/// thì bảng chia sẻ. Zalo không có URL điền sẵn tin cho chat riêng, nên tin
/// được chép vào clipboard rồi mở Zalo để dán.
class InviteLinkRequester {
  const InviteLinkRequester({
    this.canOpenZalo = _canOpenZalo,
    this.openZalo = _openZalo,
    this.copy = _copy,
    this.share = _share,
  });

  final Future<bool> Function() canOpenZalo;
  final Future<bool> Function() openZalo;
  final Future<void> Function(String text) copy;
  final Future<void> Function(String text) share;

  static final _zalo = Uri.parse('zalo://');

  static Future<bool> _canOpenZalo() => canLaunchUrl(_zalo);
  static Future<bool> _openZalo() =>
      launchUrl(_zalo, mode: LaunchMode.externalApplication);
  static Future<void> _copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
  static Future<void> _share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  Future<InviteLinkRequestOutcome> request(String message) async {
    if (await canOpenZalo()) {
      await copy(message);
      if (await openZalo()) return InviteLinkRequestOutcome.zaloOpened;
    }
    await share(message);
    return InviteLinkRequestOutcome.shared;
  }
}
