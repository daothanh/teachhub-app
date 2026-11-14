import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:tasco_utils/tasco_utils.dart';

import '../../l10n/l10n.dart';
import '../role_picker/membership_cubit.dart';

/// Màn chờ khi kiểm phiên và tải vai trò. Router tự rời màn này.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failed = context.select(
      (MembershipCubit c) => c.state.statusLoad == LoadingStatus.failure,
    );
    return Scaffold(
      body: Center(
        child: failed
            ? AppEmptyState(
                message: l10n.splashLoadFailed,
                action: AppButton(
                  label: l10n.retry,
                  onPressed: () => context.read<MembershipCubit>().load(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.appName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: context.tasco.spacingSection),
                  AppLoading(semanticLabel: l10n.loading),
                ],
              ),
      ),
    );
  }
}
