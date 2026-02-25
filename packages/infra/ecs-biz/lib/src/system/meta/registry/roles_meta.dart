import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../compute/compute_service.dart';
import '../../compute/impl/compute_node.dart';
import '../../config/config_service.dart';
import '../../relation/relation_service.dart';
import '../../role/role_service.dart';
import '../../ui/property_common_ui.dart';
import '../../value/value_service.dart';
import '../property_meta_service.dart';

part 'roles_meta.freezed.dart';
part 'roles_meta.g.dart';

@freezed
abstract class RolesConfig with _$RolesConfig {
  const factory RolesConfig({@Default({}) Map<String, bool> roleMap}) =
      _RolesConfig;

  factory RolesConfig.fromJson(Map<String, dynamic> json) =>
      _$RolesConfigFromJson(json);
}

class RoleMeta extends PropertyMeta
    with
        PropertyConfigMeta<RolesConfig>,
        PropertyUiMeta,
        PropertyValueMeta,
        PropertyRelationMeta<RolesConfig>,
        PropertyComputeMeta<RolesConfig> {
  final RoleRegistry _roleRegistry;

  RoleMeta({required RoleRegistry roleRegistry}) : _roleRegistry = roleRegistry;

  @override
  String get metaId => '_roles';

  @override
  String get dataTypeId => 'roles';

  @override
  IconData get icon => Icons.supervised_user_circle;

  @override
  String get name => '角色';

  @override
  StorageType get storageType => StorageType.json;

  @override
  RolesConfig fromDb(Map<String, dynamic> cfg) => RolesConfig.fromJson(cfg);

  @override
  Map<String, dynamic> toDb(RolesConfig cfg) => cfg.toJson();

  @override
  RolesConfig? get defaultConfig => const RolesConfig();

  @override
  List<ComputeMeta> buildComputeGraph(PropertyId self, RolesConfig cfg) => [
    ComputeMeta(
      compute: ReuseComputeNode(
        computeId: 'roles_check_source',
        type: ComputeType.source,
        config: cfg,
      ),
    ),
  ];

  @override
  List<PropertyRelation> buildRelations(PropertyId self, RolesConfig config) {
    final requiredMetas = config.roleMap.keys
        .map((roleId) => _roleRegistry.getById(roleId)!)
        .expand((role) => role.constraints)
        .where((constraint) => constraint.isMandatory)
        .map((constraint) => constraint.metaId)
        .toSet();
    return requiredMetas
        .map(
          (meta) => PropertyRelation(
            src: self,
            dst: PropertyId(nodeId: self.nodeId, metaId: meta),
            type: RelationType.dependency,
          ),
        )
        .toList();
  }
}

