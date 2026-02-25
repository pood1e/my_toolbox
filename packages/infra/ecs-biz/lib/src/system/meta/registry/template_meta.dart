import 'package:app_core/object.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../compute/compute_service.dart';
import '../../config/config_service.dart';
import '../../relation/relation_service.dart';
import '../../ui/property_common_ui.dart';
import '../../value/value_service.dart';
import '../property_meta_service.dart';

part 'template_meta.freezed.dart';
part 'template_meta.g.dart';

@freezed
abstract class TemplateConfig with _$TemplateConfig {
  const factory TemplateConfig({
    @Default([]) List<PropertyId> refTemplates,
    @Default({}) Map<String, dynamic> metaConfigs,
  }) = _TemplateConfig;

  factory TemplateConfig.fromJson(Map<String, dynamic> json) =>
      _$TemplateConfigFromJson(json);
}

class TemplateMeta extends PropertyMeta
    with
        PropertyConfigMeta<TemplateConfig>,
        PropertyUiMeta,
        PropertyValueMeta,
        PropertyRelationMeta<TemplateConfig>,
        PropertyComputeMeta<TemplateConfig> {
  @override
  String get metaId => '_template';

  @override
  String get dataTypeId => 'template';

  @override
  IconData get icon => Symbols.video_template;

  @override
  String get name => '模板';

  @override
  StorageType get storageType => StorageType.json;

  @override
  TemplateConfig fromDb(Map<String, dynamic> cfg) =>
      TemplateConfig.fromJson(cfg);

  @override
  Map<String, dynamic> toDb(TemplateConfig cfg) => cfg.toJson();

  @override
  List<ComputeMeta> buildComputeGraph(PropertyId self,TemplateConfig cfg) {
    throw UnimplementedError();
  }

  @override
  List<PropertyRelation> buildRelations(
    PropertyId self,
    TemplateConfig config,
  ) => config.refTemplates
      .map(
        (id) =>
            PropertyRelation(src: self, dst: id, type: RelationType.dependency),
      )
      .toList();
}
