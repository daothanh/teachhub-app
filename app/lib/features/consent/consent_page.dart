import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../l10n/l10n.dart';
import 'consent_cubit.dart';

/// Màn đồng ý xử lý dữ liệu cho vai trò Phụ huynh (US-0.3 AC2, FR-0.14).
///
/// Hai đường vào: guard của router (mở `/p/**` khi chưa đồng ý) → xong thì về
/// `/p`; hoặc `push` từ luồng nhận lời mời → xong thì `pop(true)` để luồng đó
/// gọi lại. Thoát không đồng ý thì `pop` trả `null`.
class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<ConsentCubit>();
    final s = cubit.state;
    final needsLoad =
        s.phase == ConsentPhase.unknown ||
        s.phase == ConsentPhase.failed ||
        (s.phase == ConsentPhase.required && s.termsVersion == null);
    if (needsLoad) cubit.load();
    // Đã đồng ý từ trước khi vào màn này thì không có chuyển trạng thái để nghe.
    if (s.accepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _done(context);
      });
    }
  }

  void _done(BuildContext context) {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(TeachHubRoutes.parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocConsumer<ConsentCubit, ConsentState>(
      listenWhen: (a, b) => a.phase != b.phase && b.accepted,
      listener: (context, _) => _done(context),
      builder: (context, state) {
        final cubit = context.read<ConsentCubit>();
        final loading =
            state.phase == ConsentPhase.unknown ||
            state.phase == ConsentPhase.loading ||
            state.accepted;
        final failedLoad = state.phase == ConsentPhase.failed;
        final accepting = state.phase == ConsentPhase.accepting;
        final canAccept =
            state.termsVersion != null &&
            (state.phase == ConsentPhase.required || accepting);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.consentTitle)),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.consentTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.consentBody),
                    if (state.termsVersion != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.consentVersion(state.termsVersion!),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (state.termsChanged || state.submitFailed || failedLoad)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            state.termsChanged
                                ? l10n.consentTermsChanged
                                : failedLoad
                                ? l10n.consentLoadFailed
                                : l10n.consentFailed,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (failedLoad)
                      FilledButton(
                        onPressed: cubit.load,
                        child: Text(l10n.retry),
                      )
                    else
                      FilledButton(
                        onPressed: canAccept && !accepting
                            ? cubit.accept
                            : null,
                        child: Text(
                          accepting ? l10n.loading : l10n.consentAccept,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(TeachHubRoutes.rolePicker),
                      child: Text(l10n.consentLater),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
