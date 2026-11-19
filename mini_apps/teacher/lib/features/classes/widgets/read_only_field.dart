import 'package:flutter/material.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

/// Ô chỉ đọc mở bộ chọn khi chạm (ngày, giờ). Giữ một controller, cập nhật
/// chữ khi [text] đổi.
class ReadOnlyField extends StatefulWidget {
  const ReadOnlyField({
    super.key,
    required this.text,
    required this.label,
    required this.onTap,
    this.hint,
    this.required = false,
    this.errorText,
    this.suffix,
  });
  final String text;
  final String label;
  final String? hint;
  final bool required;
  final String? errorText;
  final Widget? suffix;
  final VoidCallback onTap;

  @override
  State<ReadOnlyField> createState() => _ReadOnlyFieldState();
}

class _ReadOnlyFieldState extends State<ReadOnlyField> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(ReadOnlyField old) {
    super.didUpdateWidget(old);
    if (_controller.text != widget.text) _controller.text = widget.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppInput(
    controller: _controller,
    label: widget.label,
    hint: widget.hint,
    required: widget.required,
    readOnly: true,
    onTap: widget.onTap,
    errorText: widget.errorText,
    suffix: widget.suffix,
  );
}
