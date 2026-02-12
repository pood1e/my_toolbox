/// 简单的纯文本段落编辑器
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../supports/processor/simple_text_processor.dart';
import 'component_renderer.dart';

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
  final SimpleText _text;
  final ValueChanged<SimpleText> _onChanged;
  final ValueChanged<bool> _onFocusChanged;
  final VoidCallback _onCancel;

  const ParagraphEditor({
    super.key,
    required SimpleText text,
    required ValueChanged<SimpleText> onChanged,
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
      initialValue: _text.data,
      onChanged: (newVal) {
        _onChanged(SimpleText(data: newVal));
      },
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      )
    ),
  );
}
