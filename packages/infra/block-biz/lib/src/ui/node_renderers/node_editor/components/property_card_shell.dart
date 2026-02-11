import 'package:flutter/material.dart';

import '../property_editor_definition.dart';

class PropertyCardShell extends StatelessWidget {
  final IconData icon;
  final String name;
  final PropertyViewLayout layout;
  final Widget content;
  final List<Widget> actions;
  final VoidCallback? onDelete;

  const PropertyCardShell({
    super.key,
    required this.icon,
    required this.name,
    required this.layout,
    required this.content,
    required this.actions,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isHorizontal = layout == PropertyViewLayout.horizontal;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Header + (Optional Content) + Actions
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),

                // Horizontal Content Area
                if (isHorizontal) Expanded(child: content) else const Spacer(),

                // Actions
                ...actions,
                const SizedBox(width: 4),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    tooltip: 'Delete property',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ],
            ),

            if (!isHorizontal) ...[const SizedBox(height: 8), content],
          ],
        ),
      ),
    );
  }
}
