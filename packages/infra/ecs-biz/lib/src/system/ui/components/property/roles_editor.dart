import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../config/config_service.dart';
import '../../../meta/property_meta_service.dart';
import '../../../meta/registry/roles_meta.dart';
import '../../../role/role_service.dart';
import '../../component_widget.dart';
import '../action/show_role_picker.dart';
import 'property_card.dart';
import 'val_widget.dart';

part 'roles_editor.freezed.dart';
part 'roles_editor.g.dart';

@freezed
abstract class RolesEditorState with _$RolesEditorState {
  const factory RolesEditorState({
    required List<Role> configuredRoles,
    required RolesConfig config,
  }) = _RolesEditorState;
}

@riverpod
class RolesEditorController extends _$RolesEditorController {
  @override
  Future<RolesEditorState> build(String nodeId) async {
    final cfg = await ref.watch(
      watchPropertyConfigProvider(
        PropertyId(nodeId: nodeId, metaId: '_roles'),
      ).future,
    );
    cfg as RolesConfig;
    final registry = ref.watch(roleRegistryProvider);

    return RolesEditorState(
      configuredRoles: cfg.roleMap.keys
          .map((roleId) => registry.getById(roleId)!)
          .toList(),
      config: cfg,
    );
  }

  Future<void> addRole(String roleId) async {
    final snapshot = await future;
    final roleMap = {...snapshot.config.roleMap, roleId: true};

    final service = await ref.read(configServiceProvider.future);
    await service.update(
      PropertyId(nodeId: nodeId, metaId: '_roles'),
      snapshot.config,
      RolesConfig(roleMap: roleMap),
    );

    // final role = ref.read(roleRegistryProvider).getById(roleId)!;
    //
    // final metas = await ref.read(watchMetasByNodeProvider(nodeId).future);
    // final ops = role.constraints
    //     .where(
    //       (constraint) =>
    //           constraint.isMandatory && !metas.contains(constraint.metaId),
    //     )
    //     .map((constraint) {
    //       final val =
    //           constraint.config ??
    //           (ref.read(propertyMetaServiceProvider).getById(constraint.metaId)!
    //                   as PropertyConfigMeta)
    //               .defaultConfig;
    //       if (val == null) throw UnimplementedError();
    //       return ConfigBatchOp.create(
    //         propertyId: PropertyId(nodeId: nodeId, metaId: constraint.metaId),
    //         config: val,
    //       );
    //     })
    //     .toList();
    // await service.batchApply(ops);
  }

  Future<void> rmRole(String roleId) async {
    final snapshot = await future;
    final roleMap = {...snapshot.config.roleMap}..remove(roleId);

    final service = await ref.read(configServiceProvider.future);
    await service.update(
      PropertyId(nodeId: nodeId, metaId: '_roles'),
      snapshot.config,
      RolesConfig(roleMap: roleMap),
    );
  }

  Future<void> deleteProperty() async {
    final service = await ref.read(configServiceProvider.future);
    await service.delete(PropertyId(nodeId: nodeId, metaId: '_roles'));
  }
}

class RolesPropertyComponent implements PropertyWidget {
  @override
  PropertyComponentBuilder get builder =>
      (nodeId, _) => RolesEditorWidget(nodeId: nodeId);

  @override
  String get id => 'roles_editor';

  @override
  String get metaId => '_roles';
}

class RolesEditorWidget extends ConsumerWidget {
  final String _nodeId;
  final PropertyId _propertyId;

  RolesEditorWidget({super.key, required String nodeId})
    : _nodeId = nodeId,
      _propertyId = PropertyId(nodeId: nodeId, metaId: '_roles');

  final ShowRolePicker _picker = const ShowRolePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(rolesEditorControllerProvider(_nodeId));
    final notifier = ref.read(rolesEditorControllerProvider(_nodeId).notifier);

    return stateAsync.whenUI(
      data: (state) => PropertyCardWidget(
        config: PropertyCardConfig(
          metaId: '_roles',
          actions: [
            if (state.configuredRoles.isEmpty)
              IconButton(
                onPressed: notifier.deleteProperty,
                icon: const Icon(Icons.delete),
              ),
          ],
          content: Column(
            spacing: AppSpacings.m,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValWidget(propertyId: _propertyId),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacings.s,
                    children: [
                      ...state.configuredRoles.map(
                        (role) => InputChip(
                          label: Text(role.name),
                          onDeleted: () async {
                            await notifier.rmRole(role.id);
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final add = await _picker.func(
                            context,
                            ref,
                            state.config.roleMap.keys.toSet(),
                          );
                          if (add != null) {
                            notifier.addRole(add);
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
