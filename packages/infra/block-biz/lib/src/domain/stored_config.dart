import 'package:app_core/object.dart';

import 'property.dart';

part 'stored_config.freezed.dart';

@freezed
abstract class StoredConfig with _$StoredConfig {
  const factory StoredConfig({
    String? configKey,
    String? mapKey,
    String? targetNodeId,
    String? targetDefId,
    String? config,
    @Default(true) bool affectValue,
  }) = _StoredConfig;

  factory StoredConfig.simple({required String config}) =>
      StoredConfig(config: config);

  factory StoredConfig.keyed({
    required String configKey,
    required String config,
  }) => StoredConfig(configKey: configKey, config: config);

  factory StoredConfig.keyedRef({
    required String configKey,
    required PropertyKey target,
    String? config,
  }) => StoredConfig(
    configKey: configKey,
    targetNodeId: target.nodeId,
    targetDefId: target.defId,
    config: config,
  );
}
