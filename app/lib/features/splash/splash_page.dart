import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';

import '../../core/widgets/brand_mark.dart';
import '../../l10n/l10n.dart';
import '../role_picker/membership_cubit.dart';

/// [T00s] Splash (Figma B00a): nền `brand/logo`, mark 160, tên app, khẩu hiệu.
/// Màn chờ khi kiểm phiên và tải vai trò; router tự rời màn này.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final onBrand = scheme.onPrimary;
    final failed = context.select(
      (MembershipCubit c) => c.state.statusLoad == LoadingStatus.failure,
    );

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacingSection),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 160),
                SizedBox(height: tokens.spacingControl),
                Text(
                  l10n.appName,
                  style: text.headlineLarge?.copyWith(color: onBrand),
                ),
                SizedBox(height: tokens.spacingControl),
                Text(
                  '${l10n.loginSlogan}\n${l10n.loginTagline}',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: onBrand),
                ),
                if (failed) ...[
                  SizedBox(height: tokens.spacingSection),
                  Text(
                    l10n.splashLoadFailed,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: onBrand),
                  ),
                  SizedBox(height: tokens.spacingContent),
                  // Nền lime: nút viền ink để tách khỏi nền (chữ trên lime luôn ink).
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: onBrand,
                      side: BorderSide(color: onBrand, width: 2),
                      minimumSize: const Size(160, 48),
                    ),
                    onPressed: () => context.read<MembershipCubit>().load(),
                    child: Text(l10n.retry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
