import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';

/// Mở bảng chia sẻ của hệ điều hành với tin nhắn soạn sẵn (US-1.6 AC2).
/// Tách ra để test không gọi kênh nền tảng.
abstract class InviteSharer {
  Future<void> share(String text);
}

InviteSharer inviteSharer() => GetIt.I<InviteSharer>();

class SharePlusInviteSharer implements InviteSharer {
  const SharePlusInviteSharer();

  @override
  Future<void> share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}
