import 'package:tasco_auth/tasco_auth.dart';

import '../../data/model/user_model.dart';

/// The shell's concrete auth cubit + state types: the generic `tasco_auth`
/// feature bound to the product `UserModel` (ADR-0019).
typedef AppAuthCubit = AuthCubit<UserModel>;
typedef AppAuthState = AuthState<UserModel>;
