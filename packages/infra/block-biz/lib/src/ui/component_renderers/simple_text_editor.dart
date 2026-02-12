import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../supports/processor/simple_text_processor.dart';
import 'component_renderer.dart';

class SimpleTextRenderer implements ContentRenderer {
  @override
  Widget build(
    config,
    ValueChanged<dynamic> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
    VoidCallback onCancel,
  ) => SimpleTextEditor(
    text: config,
    onChanged: onValueChanged,
    onFocusChanged: onFocusChanged,
    onSumbit: onSubmit,
    onCancel: onCancel,
  );

  @override
  String get id => 'simple_text';
}

class SimpleTextEditor extends StatelessWidget {
  final SimpleText _text;
  final ValueChanged<SimpleText> _onChanged;
  final ValueChanged<bool> _onFocusChanged;
  final VoidCallback _onSumbit;
  final VoidCallback _onCancel;

  const SimpleTextEditor({
    super.key,
    required SimpleText text,
    required ValueChanged<SimpleText> onChanged,
    required ValueChanged<bool> onFocusChanged,
    required VoidCallback onSumbit,
    required VoidCallback onCancel,
  }) : _text = text,
       _onChanged = onChanged,
       _onFocusChanged = onFocusChanged,
       _onSumbit = onSumbit,
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
      initialValue: _text.data,
      onChanged: (newVal) {
        _onChanged(SimpleText(data: newVal));
      },
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onFieldSubmitted: (_) {
        _onSumbit();
      },
    ),
  );
}
