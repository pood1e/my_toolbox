import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../config/config_service.dart';
import '../../../meta/property_meta_service.dart';
import '../../../meta/registry/icon_meta.dart';
import '../../../relation/relation_service.dart';
import '../../component_widget.dart';
import '../action/show_icon_picker.dart';
import '../action/show_ref_picker.dart';
import 'property_card.dart';
import 'val_widget.dart';

part 'icon_editor.g.dart';

@riverpod
class IconEditorController extends _$IconEditorController {
  @override
  Stream<IconConfig> build(String nodeId) async* {
    final srv = await ref.watch(configServiceProvider.future);
    yield* srv
        .watch(PropertyId(nodeId: nodeId, metaId: '_icon'))
        .map((cfg) => cfg as IconConfig);
  }

  Future<void> updatePicked(IconData icon) async {
    final service = await ref.read(configServiceProvider.future);
    final snapshot = await future;
    await service.update(
      PropertyId(nodeId: nodeId, metaId: '_icon'),
      snapshot,
      IconConfig(mode: IconMode.pick, picked: icon),
    );
  }

  Future<void> updateRef(RelationData data) async {
    final service = await ref.read(configServiceProvider.future);
    final snapshot = await future;
    await service.update(
      PropertyId(nodeId: nodeId, metaId: '_icon'),
      snapshot,
      IconConfig(mode: IconMode.ref, ref: data),
    );
  }

  Future<void> deleteProperty() async {
    final service = await ref.read(configServiceProvider.future);
    await service.delete(PropertyId(nodeId: nodeId, metaId: '_icon'));
  }
}

class IconPropertyComponent implements PropertyWidget {
  @override
  PropertyComponentBuilder get builder =>
      (nodeId, _) => IconEditorWidget(nodeId: nodeId);

  @override
  String get id => 'icon_editor';

  @override
  String get metaId => '_icon';
}

class IconEditorWidget extends ConsumerWidget {
  final String _nodeId;
  final PropertyId _propertyId;

  IconEditorWidget({super.key, required String nodeId})
    : _nodeId = nodeId,
      _propertyId = PropertyId(nodeId: nodeId, metaId: '_icon');

  final ComponentAction _action = const SimpleIconPicker();
  final ComponentAction _refPicker = const RefPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerAsync = ref.watch(iconEditorControllerProvider(_nodeId));
    final notifier = ref.read(iconEditorControllerProvider(_nodeId).notifier);
    final affectsAsync = ref.watch(watchAffectsProvider(_propertyId));

    return PropertyCardWidget(
      config: PropertyCardConfig(
        metaId: '_icon',
        onDeleted: notifier.deleteProperty,
        compactContent: ValWidget(propertyId: _propertyId),
        actions: [
          SelectIconButton(
            onPressed: () async {
              final val = await _action.func(context, ref, null);
              if (val != null) {
                await notifier.updatePicked(val);
              }
            },
            icon: Icons.edit,
            selected: controllerAsync.value?.mode == IconMode.pick,
          ),

          SelectIconButton(
            onPressed: () {
              _refPicker.func(
                context,
                ref,
                ReferenceSearchConfig(
                  properties: {'_icon'},
                  excludes: {_propertyId},
                  actionBuilder: (val, onExit) {
                    final actions = [
                      IconButton(
                        onPressed: () async {
                          await notifier.updatePicked(val.value);
                          onExit();
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ];
                    if (!affectsAsync.requireValue.contains(val.propertyId) &&
                        val.propertyId != controllerAsync.value?.ref?.dst) {
                      actions.add(
                        IconButton(
                          onPressed: () async {
                            await notifier.updateRef(
                              RelationData(
                                dst: val.propertyId,
                                type: RelationType.dependency,
                              ),
                            );
                            onExit();
                          },
                          icon: const Icon(Icons.add_link_outlined),
                        ),
                      );
                    }
                    return actions;
                  },
                ),
              );
            },
            icon: Icons.link,
            selected: controllerAsync.value?.mode == IconMode.ref,
          ),
        ],
      ),
    );
  }
}
