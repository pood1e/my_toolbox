import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../memo_domain.dart';
import '../../memo_service.dart';

class MemoEditorScreen extends ConsumerStatefulWidget {
  final MemoDomain? memo;

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
    widget.memo == null
        ? await service.createMemo(content)
        : await service.updateMemo(widget.memo!.id, content);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memo != null ? 'Edit Memo' : 'New Memo'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
          Gaps.h8, // 右侧留点空隙
        ],
      ),
      body: Padding(
        // 统一使用页面边距
        padding: const EdgeInsets.all(AppSpacings.page),
        child: TextField(
          controller: _controller,
          autofocus: widget.memo == null,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: context.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            hintStyle: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.outline,
            ),
            border: InputBorder.none,
            // 移除默认 Padding，由外层 Padding 控制
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
