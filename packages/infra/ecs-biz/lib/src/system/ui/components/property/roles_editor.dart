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
  Stream<RolesEditorState> build(String nodeId) async* {
    final srv = await ref.watch(configServiceProvider.future);

    final roleService = ref.watch(roleServiceProvider);

    yield* srv.watch(PropertyId(nodeId: nodeId, metaId: '_roles')).map((cfg) {
      cfg as RolesConfig;
      return RolesEditorState(
        configuredRoles: cfg.roleMap.keys
            .map((roleId) => roleService.getById(roleId)!)
            .toList(),
        config: cfg,
      );
    });
  }

  Future<void> addRole(String roleId) async {
    final snapshot = await future;
    final roleMap = {...snapshot.config.roleMap, roleId: true};
    await _updateRoleConfig(snapshot.config, roleMap);
  }

  Future<void> rmRole(String roleId) async {
    final snapshot = await future;
    final roleMap = {...snapshot.config.roleMap}..remove(roleId);
    await _updateRoleConfig(snapshot.config, roleMap);
  }

  Future<void> _updateRoleConfig(
    RolesConfig snapshot,
    Map<String, bool> roleMap,
  ) async {
    final service = await ref.read(configServiceProvider.future);
    await service.update(
      PropertyId(nodeId: nodeId, metaId: '_roles'),
      snapshot,
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
          compactContent: ValWidget(propertyId: _propertyId),
          content: Row(
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
        ),
      ),
    );
  }
}
