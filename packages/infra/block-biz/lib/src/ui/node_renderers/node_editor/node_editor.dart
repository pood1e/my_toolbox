import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/message.dart';
import 'package:flutter/material.dart';

import '../../../supports/property_def_registry.dart';
import 'node_editor_controller.dart';
import 'property_edit_tile.dart';

class NodeEditor extends ConsumerWidget {
  final String _nodeId;

  const NodeEditor({super.key, required String nodeId}) : _nodeId = nodeId;

  Future<void> _addDefaultPropertyAction(
    Future<void> Function(String) action,
    String defId,
  ) async {
    // todo: 用户体验, 滑动至新添加的位置
    try {
      await action(defId);
      SnackbarService.showSuccess('add trait success');
    } catch (e, s) {
      logger.e('error ${e.toString()}', error: e, stackTrace: s);
      SnackbarService.showError('add trait failed: ${e.toString()}');
    }
  }

  Widget _buildFab(WidgetRef ref) {
    final notifier = ref.read(nodeEditorControllerProvider(_nodeId).notifier);
    final defaultConfigDescriptors = ref.read(
      defaultConfigPropertyDefsProvider,
    );
    final fabBtns = defaultConfigDescriptors
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
      return fabBtns.first;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(nodeEditorControllerProvider(_nodeId));
    final fab = _buildFab(ref);
    return Scaffold(
      appBar: AppBar(title: Text('Edit Node: $_nodeId')),
      body: controllerAsync.whenUI(
        data: (propertKeys) {
          if (propertKeys.isEmpty) {
            return const Center(child: Text('No traits attached.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: propertKeys.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final key = propertKeys[index];
              return PropertyEditTile(propertyKey: key);
            },
          );
        },
      ),
      floatingActionButtonLocation: fab is ExpandableFab
          ? ExpandableFab.location
          : null,
      floatingActionButton: fab,
    );
  }
}
