import 'package:app_core/object.dart';

import '../../compute/compute_service.dart';
import '../../compute/impl/compute_node.dart';
import '../../config/config_service.dart';
import '../../value/value_service.dart';
import '../property_meta_service.dart';

part 'text_meta.freezed.dart';
part 'text_meta.g.dart';

@freezed
abstract class TextConfig with _$TextConfig {
  const factory TextConfig({required String text}) = _TextConfig;

  factory TextConfig.fromJson(Map<String, dynamic> json) =>
      _$TextConfigFromJson(json);
}

abstract class TextMeta extends PropertyMeta
    with
        PropertyConfigMeta<TextConfig>,
        PropertyValueMeta,
        PropertyComputeMeta<TextConfig> {
  @override
  TextConfig fromDb(Map<String, dynamic> cfg) => TextConfig.fromJson(cfg);

  @override
  Map<String, dynamic> toDb(TextConfig cfg) => cfg.toJson();

  @override
  List<ComputeMeta> buildComputeGraph(PropertyId self,TextConfig cfg) => [
    ComputeMeta(
      compute: InlineSourceNode<String>(create: () async => cfg.text),
    ),
  ];

  @override
  StorageType get storageType => StorageType.text;

  @override
  String get dataTypeId => 'simple_text';
}
