import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../data/billing_repository.dart';

/// Xem ảnh biên lai (US-7.7 AC2). Mỗi lần mở xin một URL mới (sống 10 phút);
/// ảnh chỉ nằm trong bộ nhớ đệm hình của Flutter và bị gỡ khi đóng. Không có
/// nút lưu: biên lai không được ghi xuống thư viện ảnh hay đĩa.
class ReceiptViewer extends StatefulWidget {
  const ReceiptViewer({
    super.key,
    required this.repository,
    required this.fileId,
  });
  final BillingRepository repository;
  final String fileId;

  @override
  State<ReceiptViewer> createState() => _ReceiptViewerState();
}

class _ReceiptViewerState extends State<ReceiptViewer> {
  late Future<String> _url = widget.repository.receiptUrl(widget.fileId);
  String? _shown;

  @override
  void dispose() {
    final u = _shown;
    if (u != null) PaintingBinding.instance.imageCache.evict(NetworkImage(u));
    super.dispose();
  }

  void _retry() => setState(() {
    _shown = null;
    _url = widget.repository.receiptUrl(widget.fileId);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.claimReceiptTitle),
          leading: IconButton(
            tooltip: l10n.claimReceiptClose,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<String>(
          future: _url,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || snap.data == null) {
              return _Failed(onRetry: _retry);
            }
            _shown = snap.data;
            return InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.network(
                  snap.data!,
                  semanticLabel: l10n.claimReceiptTitle,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, _, _) => _Failed(onRetry: _retry),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.claimReceiptFailed),
          TextButton(onPressed: onRetry, child: Text(l10n.classesRetry)),
        ],
      ),
    );
  }
}
