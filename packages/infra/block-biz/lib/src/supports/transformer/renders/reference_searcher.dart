import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../../registry/property_descriptor_registry.dart';
import 'reference_search_provider.dart';

class ReferenceSearcher extends ConsumerWidget {
  final String specId;
  final PropertyKey _propertyKey;

  /// 当用户点击某个属性时的回调
  /// [key] 选中的目标属性 (Target Node + Target Def)
  final ValueChanged<PropertyKey> onSelect;

  const ReferenceSearcher({
    super.key,
    required this.specId,
    required PropertyKey propertyKey,
    required this.onSelect,
  }) : _propertyKey = propertyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidatesAsync = ref.watch(
      referenceCandidatesProvider(specId: specId, propertyKey: _propertyKey),
    );

    return candidatesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
      data: (candidates) {
        if (candidates.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No compatible properties found.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final nodeIds = candidates.keys.toList();

        return Column(
          children: nodeIds.map((nodeId) {
            final defIds = candidates[nodeId]!;

            return _NodeReferenceTile(
              nodeId: nodeId,
              defIds: defIds,
              onPropertySelect: (defId) {
                onSelect(PropertyKey(nodeId: nodeId, defId: defId));
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _NodeReferenceTile extends ConsumerWidget {
  final String nodeId;
  final List<String> defIds;
  final ValueChanged<String> onPropertySelect;

  const _NodeReferenceTile({
    required this.nodeId,
    required this.defIds,
    required this.onPropertySelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExpansionTile(
    leading: const Icon(Icons.hub, size: 20),
    title: Text(
      nodeId,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    subtitle: Text('${defIds.length} properties available'),
    childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
    initiallyExpanded: false,
    children: defIds.map((defId) {
      // 获取属性定义的详细信息（名称、图标等）
      final descriptor = ref.watch(propertyDescriptorProvider(defId));

      return ListTile(
        dense: true,
        leading: Icon(
          Icons.subdirectory_arrow_right,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(descriptor!.propertyId),
        // 如果 descriptor 有友好 name 字段更好
        subtitle: Text(
          descriptor.dateType.id,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        trailing: const Icon(Icons.check_circle_outline, size: 16),
        onTap: () => onPropertySelect(defId),
      );
    }).toList(),
  );
}
