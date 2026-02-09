import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../../domain/property_config.dart';
import '../property_editor_controller.dart';

class NodeReferenceEditor extends ConsumerWidget {
  final SingleRefPropertyConfig config;
  final PropertyKey propertyKey;

  const NodeReferenceEditor({
    super.key,
    required this.config,
    required this.propertyKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      propertyEditorControllerProvider(propertyKey).notifier,
    );

    return InkWell(
      onTap: () async {
        // 模拟打开选择器
        // final selected = await showNodePicker(context);
        const selected = PropertyKey(
          nodeId: 'node_123',
          defId: '_name',
        ); // Mock

        final newConfig = config.copyWith(target: selected);
        controller.updateDraft(newConfig);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                config.target == null
                    ? 'Click to select source...'
                    : '${config.target!.nodeId} / ${config.target!.defId}',
                style: TextStyle(
                  color: config.target == null ? Colors.grey : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
