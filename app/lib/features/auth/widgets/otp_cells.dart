import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

enum OtpCellsState { normal, error, locked }

/// `Inputs/OTP Cell` ×6 (44×52) — Empty / Focus / Filled / Error / Locked.
///
/// Một [TextField] ẩn nhận bàn phím, dán và autofill mã một lần của hệ điều
/// hành; các ô chỉ hiển thị.
class OtpCells extends StatefulWidget {
  const OtpCells({
    super.key,
    required this.controller,
    required this.semanticLabel,
    this.state = OtpCellsState.normal,
    this.onChanged,
    this.length = 6,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final OtpCellsState state;
  final ValueChanged<String>? onChanged;
  final int length;

  @override
  State<OtpCells> createState() => _OtpCellsState();
}

class _OtpCellsState extends State<OtpCells> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(OtpCells old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final locked = widget.state == OtpCellsState.locked;
    final code = widget.controller.text;
    final tokens = context.tasco;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Ô nhập thật: trong suốt, phủ cả hàng để chạm vào đâu cũng mở bàn phím.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: !locked,
              enabled: !locked,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              showCursor: false,
              enableInteractiveSelection: false,
              decoration: InputDecoration(
                semanticCounterText: '',
                labelText: widget.semanticLabel,
                border: InputBorder.none,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
        IgnorePointer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) SizedBox(width: tokens.spacingControl),
                _Cell(
                  digit: locked ? '•' : (i < code.length ? code[i] : null),
                  focused:
                      _focus.hasFocus &&
                      !locked &&
                      i == code.length.clamp(0, widget.length - 1),
                  state: widget.state,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.digit,
    required this.focused,
    required this.state,
  });

  final String? digit;
  final bool focused;
  final OtpCellsState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tasco;
    final locked = state == OtpCellsState.locked;
    final (Color border, double width) = switch (state) {
      OtpCellsState.error => (scheme.error, 2),
      OtpCellsState.locked => (scheme.outlineVariant, 1.5),
      OtpCellsState.normal when focused => (tokens.focusRingColor, 2),
      OtpCellsState.normal => (scheme.outlineVariant, 1.5),
    };
    return Container(
      width: 44,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: locked ? scheme.surfaceContainerLow : scheme.surface,
        borderRadius: BorderRadius.circular(tokens.controlRadius),
        border: Border.all(color: border, width: width),
      ),
      child: focused && digit == null
          ? Container(width: 2, height: 24, color: scheme.onSurface)
          : Text(
              digit ?? '',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: locked ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
    );
  }
}
