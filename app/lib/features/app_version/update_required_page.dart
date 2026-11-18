import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/brand_mark.dart';
import '../../l10n/l10n.dart';

/// Màn chặn khi bản đang cài thấp hơn `minSupportedVersion` (spec §5.1).
/// Figma chưa có frame cho màn này: dựng bằng token và thành phần DS sẵn có.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  Future<void> _openStore() async {
    final info = await PackageInfo.fromPlatform();
    // shortcut: iOS cần App Store ID (sau khi có tài khoản Apple Developer, S0-PO-01);
    // tới lúc đó chỉ mở được Google Play.
    if (!Platform.isAndroid) return;
    await launchUrl(
      Uri.parse(
        'https://play.google.com/store/apps/details?id=${info.packageName}',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tasco;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spacingSection),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(size: 64),
                  SizedBox(height: tokens.spacingSection),
                  Text(
                    l10n.updateTitle,
                    style: text.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tokens.spacingControl),
                  Text(
                    l10n.updateBody,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (Platform.isAndroid) ...[
                    SizedBox(height: tokens.spacingSection),
                    AppButton(label: l10n.updateAction, onPressed: _openStore),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
