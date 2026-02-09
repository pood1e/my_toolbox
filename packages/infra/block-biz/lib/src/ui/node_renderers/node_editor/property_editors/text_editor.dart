import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../../domain/property_config.dart';
import '../property_editor_controller.dart';

class TextInputEditor extends ConsumerStatefulWidget {
  final SingleStaticPropertyConfig config;
  final PropertyKey propertyKey;

  const TextInputEditor({
    super.key,
    required this.config,
    required this.propertyKey,
  });

  @override
  ConsumerState<TextInputEditor> createState() => _TextInputEditorState();
}

class _TextInputEditorState extends ConsumerState<TextInputEditor> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _extractText());
  }

  @override
  void didUpdateWidget(covariant TextInputEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果外部传入的 config 变了（比如 Remote 更新或 Undo），同步更新输入框
    // 注意：这里需要防止光标跳动，实际项目中通常只在 !isFocused 时更新
    if (oldWidget.config != widget.config) {
      final newText = _extractText();
      if (_ctrl.text != newText) {
        _ctrl.text = newText;
      }
    }
  }

  String _extractText() => widget.config.source.raw['data'] as String? ?? '';

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: _ctrl,
    decoration: const InputDecoration(
      isDense: true,
      hintText: 'Enter value',
      border: OutlineInputBorder(),
    ),
    onChanged: (val) {
      final controller = ref.read(
        propertyEditorControllerProvider(widget.propertyKey).notifier,
      );

      // 构造新的 Config 对象
      final newConfig = widget.config.copyWith(
        source: widget.config.source.copyWith(raw: {'data': val}),
      );

      // 提交到 Controller 更新 Draft
      controller.updateDraft(newConfig);
    },
  );
}
