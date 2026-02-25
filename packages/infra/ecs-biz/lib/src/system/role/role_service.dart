import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../config/config_service.dart';
import '../meta/property_meta_service.dart';
import '../meta/registry/roles_meta.dart';
import 'impl/role_service_impl.dart';
import 'registry/graph_node_role.dart';

/// 约束property
/// 角色暂时内置, 不支持动态编辑
part 'role_service.freezed.dart';
part 'role_service.g.dart';

@freezed
abstract class PropertyConstraint with _$PropertyConstraint {
  const factory PropertyConstraint({
    required String metaId,
    required bool isMandatory,
    required dynamic config,
  }) = _PropertyConstraint;
}

mixin PropertyRoleMeta on PropertyMeta {
  bool get availableWhenRefered => true;
}

abstract class Role {
  String get id;

  String get name;

  IconData get icon;

  List<PropertyConstraint> get constraints;
}

abstract class RoleService {
  List<Role> getAllRoles();

  Role? getById(String id);

  List<Role> getSugguestedRoles(Set<String> metas);

  Set<String> analyzeRequiredMetas(Set<String> roleIds);
}

@Riverpod(keepAlive: true)
RoleService roleService(Ref ref) => RoleServiceImpl(roles: [GraphNodeRole()]);

@riverpod
Future<Set<String>> getNodeMandatories(Ref ref, String nodeId) async {
  final roleCfg = await ref.watch(
    watchPropertyConfigProvider(
      PropertyId(nodeId: nodeId, metaId: '_roles'),
    ).future,
  );
  final roleIds = roleCfg != null
      ? (roleCfg as RolesConfig).roleMap.keys.toSet()
      : <String>{};
  return ref.read(roleServiceProvider).analyzeRequiredMetas(roleIds);
}

@riverpod
Future<bool> checkMetaIsMandatory(Ref ref, PropertyId propertyId) async {
  final mandatories = await ref.watch(
    getNodeMandatoriesProvider(propertyId.nodeId).future,
  );
  return mandatories.contains(propertyId.metaId);
}
