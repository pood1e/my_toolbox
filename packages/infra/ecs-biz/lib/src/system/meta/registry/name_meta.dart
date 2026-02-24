import 'package:app_core/object.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../compute/compute_service.dart';
import '../../compute/impl/compute_node.dart';
import '../../config/config_service.dart';
import '../../ui/property_common_ui.dart';
import '../../value/value_service.dart';
import '../property_meta_service.dart';

part 'name_meta.freezed.dart';
part 'name_meta.g.dart';

@freezed
abstract class NameConfig with _$NameConfig {
  const factory NameConfig({required String text}) = _NameConfig;

  factory NameConfig.fromJson(Map<String, dynamic> json) =>
      _$NameConfigFromJson(json);
}

class NameMeta extends PropertyMeta
    with
        PropertyConfigMeta<NameConfig>,
        PropertyUiMeta,
        PropertyValueMeta,
        PropertyComputeMeta<NameConfig> {
  @override
  String get metaId => '_name';

  @override
  NameConfig fromDb(Map<String, dynamic> cfg) => NameConfig.fromJson(cfg);

  @override
  Map<String, dynamic> toDb(NameConfig cfg) => cfg.toJson();

  @override
  IconData get icon => Symbols.id_card;

  @override
  String get name => '名称';

  @override
  List<ComputeMeta> buildComputeGraph(NameConfig cfg) => [
    ComputeMeta(
      compute: InlineSourceNode<String>(create: () async => cfg.text),
    ),
  ];

  @override
  StorageType get storageType => StorageType.text;

  @override
  String get dataTypeId => 'simple_text';
}
