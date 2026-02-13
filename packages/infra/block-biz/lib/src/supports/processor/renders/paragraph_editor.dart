/// 简单的纯文本段落编辑器
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/component_renderer.dart';

class ParagraphRenderer implements ContentRenderer {
  @override
  Widget build(
    config,
    ValueChanged<dynamic> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
    VoidCallback onCancel,
  ) => ParagraphEditor(
    text: config,
    onChanged: onValueChanged,
    onFocusChanged: onFocusChanged,
    onCancel: onCancel,
  );

  @override
  String get id => 'paragraph';
}

class ParagraphEditor extends StatelessWidget {
  final String _text;
  final ValueChanged<String> _onChanged;
  final ValueChanged<bool> _onFocusChanged;
  final VoidCallback _onCancel;

  const ParagraphEditor({
    super.key,
    required String text,
    required ValueChanged<String> onChanged,
    required ValueChanged<bool> onFocusChanged,
    required VoidCallback onCancel,
  }) : _text = text,
       _onChanged = onChanged,
       _onFocusChanged = onFocusChanged,
       _onCancel = onCancel;

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: _onFocusChanged,
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _onCancel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: TextFormField(
      minLines: 1,
      maxLines: null,
      initialValue: _text,
      onChanged: _onChanged,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ),
  );
}
