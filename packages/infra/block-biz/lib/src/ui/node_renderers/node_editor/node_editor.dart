import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/message.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import 'node_editor_controller.dart';
import 'property_edit_tile.dart';
import 'property_editor_registry.dart';

class NodeEditor extends ConsumerWidget {
  final String _nodeId;

  const NodeEditor({super.key, required String nodeId}) : _nodeId = nodeId;

  Future<void> _addDefaultPropertyAction(
    Future<void> Function(String) action,
    String defId,
  ) async {
    // todo: 用户体验, 滑动至新添加的位置 ,自动聚焦
    try {
      await action(defId);
      SnackbarService.showSuccess('add trait success');
    } catch (e, s) {
      logger.e('error ${e.toString()}', error: e, stackTrace: s);
      SnackbarService.showError('add trait failed: ${e.toString()}');
    }
  }

  Widget? _buildFab(WidgetRef ref, List<PropertyKey> exist) {
    final notifier = ref.read(nodeEditorControllerProvider(_nodeId).notifier);
    final supportEditors = ref.read(editorDescriptorsProvider);
    final existProperties = exist.map((property) => property.defId).toSet();
    final availableAppend = supportEditors
        .where((descriptor) => !existProperties.contains(descriptor.propertyId))
        .toList();
    final fabBtns = availableAppend
        .map(
          (descriptor) => FloatingActionButton.small(
            heroTag: null,
            child: Icon(descriptor.icon),
            onPressed: () {
              _addDefaultPropertyAction(
                notifier.createWithDefaultConfig,
                descriptor.propertyId,
              );
            },
          ),
        )
        .toList();
    if (fabBtns.length > 1) {
      return ExpandableFab(
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
        ),
        overlayStyle: const ExpandableFabOverlayStyle(blur: 5.0),
        children: fabBtns,
      );
    } else {
      return fabBtns.firstOrNull;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(nodeEditorControllerProvider(_nodeId));
    final supportKeys = ref
        .read(editorDescriptorsProvider)
        .map((descriptor) => descriptor.propertyId)
        .toSet();
    return controllerAsync.whenUI(
      data: (propertKeys) {
        final fab = _buildFab(ref, propertKeys);
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
              final key = propertKeys[index];
              return PropertyEditTile(
                propertyKey: key,
                descriptor: ref.read(editorDescriptorProvider(key.defId)),
              );
            },
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text('Edit Node: $_nodeId')),
          body: body,
          floatingActionButtonLocation: fab is ExpandableFab
              ? ExpandableFab.location
              : null,
          floatingActionButton: fab,
        );
      },
    );
  }
}
