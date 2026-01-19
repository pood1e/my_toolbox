import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

class EditorAppBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onClose;

  const EditorAppBar({
    super.key,
    required this.isSaving,
    required this.onSave,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      // 随滚动消失
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onClose,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacings.m),
          child: FilledButton.tonal(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacings.l),
              visualDensity: VisualDensity.compact,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ),
      ],
    );
  }
}
