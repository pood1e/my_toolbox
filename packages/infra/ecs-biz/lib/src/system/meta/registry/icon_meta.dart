import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../compute/compute_service.dart';
import '../../compute/impl/compute_node.dart';
import '../../config/config_service.dart';
import '../../relation/relation_service.dart';
import '../../ui/property_common_ui.dart';
import '../../value/value_service.dart';
import '../property_meta_service.dart';

part 'icon_meta.freezed.dart';
part 'icon_meta.g.dart';

enum IconMode { pick, ref }

@freezed
abstract class IconConfig with _$IconConfig {
  const factory IconConfig({
    required IconMode mode,
    @IconDataConverter() IconData? picked,
    RelationData? ref,
  }) = _IconConfig;

  factory IconConfig.fromJson(Map<String, dynamic> json) =>
      _$IconConfigFromJson(json);
}

class IconMeta extends PropertyMeta
    with
        PropertyConfigMeta<IconConfig>,
        PropertyUiMeta,
        PropertyValueMeta,
        PropertyRelationMeta<IconConfig>,
        PropertyComputeMeta<IconConfig> {
  @override
  String get metaId => '_icon';

  @override
  String get dataTypeId => 'icon';

  @override
  IconData get icon => Icons.stars;

  @override
  String get name => '图标';

  @override
  StorageType get storageType => StorageType.json;

  @override
  IconConfig fromDb(Map<String, dynamic> cfg) => IconConfig.fromJson(cfg);

  @override
  Map<String, dynamic> toDb(IconConfig cfg) => cfg.toJson();

  @override
  List<ComputeMeta> buildComputeGraph(IconConfig cfg) {
    if (cfg.mode == IconMode.pick) {
      return [
        ComputeMeta(compute: InlineSourceNode(create: () async => cfg.picked!)),
      ];
    } else {
      return [
        ComputeMeta(
          compute: ReuseComputeNode(
            computeId: 'ref_source',
            type: ComputeType.source,
            config: cfg.ref,
          ),
        ),
      ];
    }
  }

  @override
  List<PropertyRelation> buildRelations(PropertyId self, IconConfig config) {
    if (config.mode == IconMode.ref) {
      return [
        PropertyRelation(
          src: self,
          dst: config.ref!.dst,
          type: config.ref!.type,
        ),
      ];
    }
    return [];
  }
}
