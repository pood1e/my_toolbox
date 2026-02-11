import 'package:app_core/object.dart';

part 'stored_config.freezed.dart';

enum ConfigType {
  /// 配置规格
  spec,

  /// 一个引用
  ref,

  /// 一个静态数据
  processor,

  /// 一个聚合配置
  aggregate,
}

enum ConfigMode {
  // simple_text, icon ...
  singleStatic,
  // icon
  singleRef,
  // dates
  multiStatic,
  // tag
  multiRef,
  // template_text
  hybrid,
}


@freezed
abstract class StoredConfig with _$StoredConfig {
  const StoredConfig._();

  @internal
  const factory StoredConfig({
    required ConfigType configType,
    String? mapKey,
    String? targetNodeId,
    String? targetDefId,
    required String config,
    @Default(true) bool affectValue,
  }) = _StoredConfig;
}
