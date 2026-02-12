import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'component_renderer.dart';

class SimpleTextRenderer implements ContentRenderer {
  @override
  Widget build(
    config,
    ValueChanged<dynamic> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
    VoidCallback onCancel,
  ) => StringEditor(
    text: config,
    onChanged: onValueChanged,
    onFocusChanged: onFocusChanged,
    onSumbit: onSubmit,
    onCancel: onCancel,
  );

  @override
  String get id => 'simple_text';
}

class StringEditor extends StatelessWidget {
  final String _text;
  final ValueChanged<String> _onChanged;
  final ValueChanged<bool> _onFocusChanged;
  final VoidCallback _onSumbit;
  final VoidCallback _onCancel;

  const StringEditor({
    super.key,
    required String text,
    required ValueChanged<String> onChanged,
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
      initialValue: _text,
      onChanged: _onChanged,
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
