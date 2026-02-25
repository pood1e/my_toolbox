import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../compute/compute_service.dart';
import '../../compute/impl/compute_node.dart';
import '../../config/config_service.dart';
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
        PropertyComputeMeta<RolesConfig> {
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
}
