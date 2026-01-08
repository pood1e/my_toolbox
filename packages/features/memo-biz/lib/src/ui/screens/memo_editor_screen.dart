import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../memo_domain.dart';
import '../../memo_service.dart';

class MemoEditorScreen extends ConsumerStatefulWidget {
  final MemoDomain? memo; // null 代表新建

  const MemoEditorScreen({super.key, this.memo});

  @override
  ConsumerState<MemoEditorScreen> createState() => _MemoEditorScreenState();
}

class _MemoEditorScreenState extends ConsumerState<MemoEditorScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.memo?.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _controller.text;
    if (content.trim().isEmpty) return;

    final service = await ref.read(memoServiceProvider.future);

    if (widget.memo == null) {
      await service.createMemo(content);
    } else {
      await service.updateMemo(widget.memo!.id, content);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.memo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Memo' : 'New Memo'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.check))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          autofocus: !isEditing,
          maxLines: null,
          // 无限高度
          expands: true,
          // 撑满屏幕
          textAlignVertical: TextAlignVertical.top,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
            border: InputBorder.none, // 无边框，像便签一样
          ),
        ),
      ),
    );
  }
}
