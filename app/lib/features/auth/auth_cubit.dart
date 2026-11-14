import 'package:tasco_auth/tasco_auth.dart';

import 'teachhub_user.dart';

/// `tasco_auth` gắn với [TeachHubUser] (ADR-0019).
typedef AppAuthCubit = AuthCubit<TeachHubUser>;
typedef AppAuthState = AuthState<TeachHubUser>;
