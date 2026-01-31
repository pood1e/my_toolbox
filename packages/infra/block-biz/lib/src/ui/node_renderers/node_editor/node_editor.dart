import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/message.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'node_editor_controller.dart';
import 'trait_edit_tile.dart';

class NodeEditor extends ConsumerWidget {
  final String _nodeId;

  const NodeEditor({super.key, required String nodeId}) : _nodeId = nodeId;

  Future<void> _addDefaultTraitAction(Future<void> Function() action) async {
    // todo: 用户体验, 滑动至新添加的位置
    try {
      await action();
      SnackbarService.showSuccess('add trait success');
    } catch (e, s) {
      logger.e('error ${e.toString()}', error: e, stackTrace: s);
      SnackbarService.showError('add trait failed: ${e.toString()}');
    }
  }

  Widget _buildFab(NodeEditorController notifier) => ExpandableFab(
    openButtonBuilder: RotateFloatingActionButtonBuilder(
      child: const Icon(Icons.add),
    ),
    overlayStyle: ExpandableFabOverlayStyle(blur: 5.0),
    children: [
      FloatingActionButton.small(
        heroTag: null,
        child: const Icon(Symbols.id_card),
        onPressed: () {
          _addDefaultTraitAction(notifier.createDefaultNameTrait);
        },
      ),
      FloatingActionButton.small(
        heroTag: null,
        child: const Icon(Icons.stars),
        onPressed: () {
          _addDefaultTraitAction(notifier.createDefaultIconTrait);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(nodeEditorControllerProvider(_nodeId));
    final notifier = ref.read(nodeEditorControllerProvider(_nodeId).notifier);
    return Scaffold(
      appBar: AppBar(title: Text('Edit Node: $_nodeId')),
      body: controllerAsync.whenUI(
        data: (traits) {
          if (traits.isEmpty) {
            return const Center(child: Text('No traits attached.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: traits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final trait = traits[index];
              return TraitEditTile(trait: trait);
            },
          );
        },
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _buildFab(notifier),
    );
  }
}
