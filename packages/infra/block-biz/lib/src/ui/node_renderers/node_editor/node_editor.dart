import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../property_renderers/property_editor_registry.dart';
import 'node_editor_controller.dart';
import 'property_card.dart';

class NodeEditor extends ConsumerWidget {
  final String _nodeId;

  const NodeEditor({super.key, required String nodeId}) : _nodeId = nodeId;

  Future<void> _addDefaultPropertyAction(
    BuildContext context,
    Future<void> Function(String) action,
    String defId,
  ) async {
    // todo: 用户体验, 滑动至新添加的位置 ,自动聚焦
    try {
      await action(defId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('success')));
      }
      // SnackbarService.showSuccess('add trait success');
    } catch (e, s) {
      logger.e('error ${e.toString()}', error: e, stackTrace: s);
      // SnackbarService.showError('add trait failed: ${e.toString()}');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('failed')));
      }
    }
  }

  Widget? _buildFab(
    BuildContext context,
    WidgetRef ref,
    Set<PropertyKey> exist,
  ) {
    final notifier = ref.read(nodeEditorControllerProvider(_nodeId).notifier);
    final supportEditors = ref.read(propertyRenderersProvider);
    final existProperties = exist.map((property) => property.defId).toSet();

    // 1. 筛选可用属性
    final availableAppend = supportEditors
        .where((descriptor) => !existProperties.contains(descriptor.propertyId))
        .toList();

    // 2. 这里的 buttons 是作为 ExpandableFab 的 children (子菜单项)
    // 子菜单项通常不显示在屏幕上，直到展开，所以给它们 heroTag: null 是对的，防止报错
    final fabChildren = availableAppend
        .map(
          (descriptor) => FloatingActionButton.extended(
            icon: Icon(descriptor.icon),
            heroTag: null, // 子按钮不需要 Hero
            label: Text(descriptor.name),
            onPressed: () {
              _addDefaultPropertyAction(
                context, // 注意：这里可能需要修改 _addDefaultPropertyAction 签名接收 context
                notifier.createWithDefaultConfig,
                descriptor.propertyId,
              );
            },
          ),
        )
        .toList();

    // 3. 逻辑分叉
    if (fabChildren.isNotEmpty) {
      // === 多按钮模式 (ExpandableFab) ===
      return ExpandableFab(
        // 关键：给主按钮一个唯一的字符串 Tag，彻底切断与上一页 FAB 的联系
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          heroTag: null,
          child: const Icon(Icons.add),
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          heroTag: null, // 关闭按钮通常不需要 Tag
        ),
        overlayStyle: const ExpandableFabOverlayStyle(blur: 5.0),
        children: fabChildren,
      );
    } else {
      // 没有可添加的属性
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(nodeEditorControllerProvider(_nodeId));
    final supportKeys = ref
        .read(propertyRenderersProvider)
        .map((descriptor) => descriptor.propertyId)
        .toSet();
    return controllerAsync.whenUI(
      data: (propertKeys) {
        final fab = _buildFab(context, ref, propertKeys);
        Widget body;
        final supportProperties = propertKeys
            .where((key) => supportKeys.contains(key.defId))
            .toList();
        if (supportProperties.isEmpty) {
          body = const Center(child: Text('no properties supports.'));
        } else {
          body = ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: supportProperties.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final key = supportProperties[index];
              return PropertyCard(propertyKey: key);
            },
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text('Edit Node: $_nodeId')),
          body: body,
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: fab,
        );
      },
    );
  }
}
