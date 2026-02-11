import 'package:flutter/material.dart';

import '../../supports/processor/simple_text_processor.dart';
import 'component_renderer.dart';

class SimpleTextRenderer implements ProcessorRenderer<SimpleText> {
  @override
  String get id => 'simple_text';

  @override
  Widget build(
    SimpleText config,
    ValueChanged<SimpleText> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
  ) => SimpleTextEditor(
    text: config,
    onChanged: onValueChanged,
    onFocusChanged: onFocusChanged,
  );
}

class SimpleTextEditor extends StatelessWidget {
  final SimpleText _text;
  final ValueChanged<SimpleText> _onChanged;
  final ValueChanged<bool> _onFocusChanged;

  const SimpleTextEditor({
    super.key,
    required SimpleText text,
    required ValueChanged<SimpleText> onChanged,
    required ValueChanged<bool> onFocusChanged,
  }) : _text = text,
       _onChanged = onChanged,
       _onFocusChanged = onFocusChanged;

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: _onFocusChanged,
    child: TextFormField(
      initialValue: _text.data,
      onChanged: (newVal) {
        _onChanged(SimpleText(data: newVal));
      },
    ),
  );
}
