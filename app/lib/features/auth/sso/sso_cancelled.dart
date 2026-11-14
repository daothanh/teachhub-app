import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Người dùng tự đóng hộp thoại đăng nhập Google/Apple.
bool isSsoCancelled(Object? error) => switch (error) {
  GoogleSignInException(code: GoogleSignInExceptionCode.canceled) => true,
  SignInWithAppleAuthorizationException(
    code: AuthorizationErrorCode.canceled,
  ) =>
    true,
  _ => false,
};
