import 'package:flutter/material.dart';

import '../property_editor_descriptor.dart';

// --- A. 通用布局骨架 ---
class PropertyTileLayout extends StatelessWidget {
  final PropertyEditorDescriptor descriptor;
  final Widget body;
  final Widget trailing; // 直接接收构建好的按钮组
  final bool isLoading;
  final String? error;

  const PropertyTileLayout({
    super.key,
    required this.descriptor,
    required this.body,
    required this.trailing,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Wrap(
        spacing: 8,
        direction: Axis.horizontal,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(descriptor.icon),
          Text(descriptor.name, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
      title: body,
      trailing: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : error != null
          ? Tooltip(
              message: error,
              child: const Icon(Icons.error, color: Colors.red),
            )
          : trailing,
    ),
  );
}

// --- B. 按钮原子组件 (只负责样式) ---
class EditorActionButtons {
  static Widget save({required VoidCallback? onPressed, bool isValid = true}) =>
      IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.check, color: isValid ? Colors.green : Colors.grey),
        tooltip: 'Save',
      );

  static Widget cancel({
    required VoidCallback onPressed,
    String tooltip = 'Cancel',
  }) => IconButton(
    onPressed: onPressed,
    icon: const Icon(Icons.close),
    tooltip: tooltip,
  );

  static Widget edit({required VoidCallback onPressed}) => IconButton(
    onPressed: onPressed,
    icon: const Icon(Icons.edit),
    tooltip: 'Edit',
  );

  static Widget delete({required VoidCallback onPressed}) => IconButton(
    onPressed: onPressed,
    icon: const Icon(Icons.delete),
    tooltip: 'Delete',
  );
}
