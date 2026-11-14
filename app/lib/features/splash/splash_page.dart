import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../l10n/l10n.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryMyTasco, AppColors.primaryMyTascoDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Center Logo & Loading indicator
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      AppIcons.logo,
                      color: Colors.white,
                      width: 180.w,
                    ),
                    SizedBox(height: 32.h),
                    AppLoading(
                      color: Colors.white,
                      size: 28,
                      semanticLabel: l10n.loading,
                    ),
                  ],
                ),
              ),

              // Bottom Brand & Copyright Footer
              Positioned(
                bottom: 24.h,
                left: 16.w,
                right: 16.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.splashTagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      l10n.splashCopyright,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
