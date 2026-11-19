/// Thứ người dùng dán, nhập hoặc quét ra từ lời mời (US-0.12).
sealed class InviteInput {
  const InviteInput();

  /// Nhận: link `<base>#t=<token>`, link `/i/<token>`, token trần, mã ngắn 8 ký
  /// tự (không phân biệt hoa thường, bỏ khoảng trắng và gạch nối). Không nhận
  /// ra thì `null`.
  static InviteInput? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) {
      final fromFragment = uri.fragment.isEmpty
          ? null
          : Uri.tryParse('?${uri.fragment}')?.queryParameters['t'];
      final fromPath = RegExp(r'^/i/([A-Za-z0-9_-]+)/?$').firstMatch(uri.path);
      final token = fromFragment ?? fromPath?.group(1);
      return _validToken(token);
    }

    final compact = text.replaceAll(RegExp(r'[\s-]'), '');
    if (_code.hasMatch(compact)) return InviteCode(compact);
    return _validToken(text);
  }

  // Khớp `pattern` của RedeemInviteCodeRequest (Crockford, không có U).
  static final _code = RegExp(r'^[0-9A-TV-Za-tv-z]{8}$');
  static final _token = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

  static InviteToken? _validToken(String? t) =>
      t != null && _token.hasMatch(t) ? InviteToken(t) : null;
}

/// Token của link/QR. Là bí mật: không log, không lưu.
final class InviteToken extends InviteInput {
  const InviteToken(this.value);
  final String value;

  @override
  String toString() => 'InviteToken(***)';
}

/// Mã ngắn 8 ký tự. Là bí mật: không log, không lưu.
final class InviteCode extends InviteInput {
  const InviteCode(this.value);
  final String value;

  @override
  String toString() => 'InviteCode(***)';
}
