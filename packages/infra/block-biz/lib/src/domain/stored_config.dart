import 'dart:convert';

import 'package:app_core/object.dart';

import 'property.dart';

part 'stored_config.freezed.dart';

enum ConfigKey { source, aggregate, mode }

enum SourceMode {
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
    required ConfigKey configKey,
    String? mapKey,
    String? targetNodeId,
    String? targetDefId,
    required String config,
    @Default(true) bool affectValue,
  }) = _StoredConfig;
}

// extension StoredConfigFactory on StoredConfig {
//   static StoredConfig singleStaticSource({
//     required StaticSourceConfig config,
//   }) => StoredConfig(configKey: ConfigKey.source, config: jsonEncode(config));
//
//   static StoredConfig singleRefSource({
//     PropertyKey? target,
//     required TransformerConfig config,
//   }) => StoredConfig(
//     configKey: ConfigKey.source,
//     targetNodeId: target?.nodeId,
//     targetDefId: target?.defId,
//     config: jsonEncode(config),
//   );
//
//   static StoredConfig multiStaticSource({
//     required String mapKey,
//     required StaticSourceConfig config,
//     bool affectValue = true,
//   }) => StoredConfig(
//     configKey: ConfigKey.source,
//     mapKey: mapKey,
//     config: jsonEncode(config),
//     affectValue: affectValue,
//   );
//
//   static StoredConfig multiRefSource({
//     required String mapKey,
//     PropertyKey? target,
//     required TransformerConfig config,
//     bool affectValue = true,
//   }) => StoredConfig(
//     configKey: ConfigKey.source,
//     mapKey: mapKey,
//     targetNodeId: target?.nodeId,
//     targetDefId: target?.defId,
//     config: jsonEncode(config),
//     affectValue: affectValue,
//   );
//
//   static StoredConfig aggregate({required AggConfig config}) =>
//       StoredConfig(configKey: ConfigKey.aggregate, config: jsonEncode(config));
//
//   static StoredConfig mode({required SourceMode mode}) =>
//       StoredConfig(configKey: ConfigKey.mode, config: mode.name);
// }
