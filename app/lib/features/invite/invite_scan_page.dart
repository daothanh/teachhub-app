import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/l10n.dart';
import 'invite_input.dart';

/// P05b: quét QR lời mời. Đóng lại với nội dung QR (chuỗi thô) khi nhận ra
/// một lời mời; QR khác chỉ báo, không đóng.
class InviteScanPage extends StatefulWidget {
  const InviteScanPage({super.key});

  @override
  State<InviteScanPage> createState() => _InviteScanPageState();
}

class _InviteScanPageState extends State<InviteScanPage> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  var _done = false;
  var _notInvite = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw != null && InviteInput.parse(raw) != null) {
        _done = true;
        context.pop(raw);
        return;
      }
    }
    if (!_notInvite) setState(() => _notInvite = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteScanTitle)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.inviteScanDenied,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _notInvite ? l10n.inviteScanNotInvite : l10n.inviteScanHint,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
