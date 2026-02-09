import 'dart:convert';

import 'package:app_core/logger.dart';
import 'package:app_core/object.dart';
import 'package:app_core/utils.dart';

import 'property.dart';
import 'stored_config.dart';

part 'property_config.freezed.dart';
part 'property_config.g.dart';

@freezed
abstract class StaticSourceConfig with _$StaticSourceConfig {
  const factory StaticSourceConfig({
    required String processorId,
    required Map<String, dynamic> raw,
  }) = _StaticSourceConfig;

  factory StaticSourceConfig.fromJson(Map<String, dynamic> json) =>
      _$StaticSourceConfigFromJson(json);
}

@freezed
abstract class TransformerConfig with _$TransformerConfig {
  const factory TransformerConfig({
    required String transformerId,
    required Map<String, dynamic> raw,
  }) = _TransformerConfig;

  factory TransformerConfig.fromJson(Map<String, dynamic> json) =>
      _$TransformerConfigFromJson(json);
}

@freezed
abstract class AggConfig with _$AggConfig {
  const factory AggConfig({
    required String aggregatorId,
    required Map<String, dynamic> raw,
  }) = _AggConfig;

  factory AggConfig.fromJson(Map<String, dynamic> json) =>
      _$AggConfigFromJson(json);
}

@freezed
sealed class PropertyConfig with _$PropertyConfig {
  const PropertyConfig._();

  // --- 1. 定义公共字段的 getter ---
  abstract final PropertyKey key;

  // --- 2. 在每个 Factory 中包含该字段 ---

  // 1. Single Static
  const factory PropertyConfig.singleStatic({
    required PropertyKey key, // <--- 加回这里
    required StaticSourceConfig source,
  }) = SingleStaticPropertyConfig;

  // 2. Single Ref
  const factory PropertyConfig.singleRef({
    required PropertyKey key, // <--- 加回这里
    required PropertyKey? target,
    required TransformerConfig transformer,
  }) = SingleRefPropertyConfig;

  // 3. Multi Static
  const factory PropertyConfig.multiStatic({
    required PropertyKey key, // <--- 加回这里
    required AggConfig aggregator,
    required Map<String, StaticSourceConfig> sources,
  }) = MultiStaticPropertyConfig;

  // 4. Multi Ref
  const factory PropertyConfig.multiRef({
    required PropertyKey key, // <--- 加回这里
    required AggConfig aggregator,
    required Map<String, ({PropertyKey? target, TransformerConfig transformer})> sources,
  }) = MultiRefPropertyConfig;

  // 5. Hybrid
  const factory PropertyConfig.hybrid({
    required PropertyKey key, // <--- 加回这里
    required AggConfig aggregator,
    required Map<String, StaticSourceConfig> staticSources,
    required Map<String, ({PropertyKey? target, TransformerConfig transformer})> refSources,
  }) = HybridPropertyConfig;

  // --- 3. 解析逻辑更新 ---

  /// 解析入口：需要传入 key，因为 StoredConfig 列表本身通常属于某个 Key
  factory PropertyConfig.parse(PropertyKey key, List<StoredConfig> storedConfigs) {
    // ... 原有的提取 helper ...
    // 1. 提取 Mode
    final modeConfig = storedConfigs.firstWhere(
          (e) => e.configKey == ConfigKey.mode,
      orElse: () => throw const FormatException("Missing mode config"),
    );
    final mode = SourceMode.values.byName(modeConfig.config);

    // 2. 提取 Aggregator
    AggConfig? parseAgg() {
      final agg = storedConfigs.firstWhereOrNull((e) => e.configKey == ConfigKey.aggregate);
      if (agg == null) return null;
      return AggConfig.fromJson(jsonDecode(agg.config));
    }

    // 3. 辅助解析函数
    ({PropertyKey? target, TransformerConfig transformer}) parseRef(StoredConfig c) {
      final target = (c.targetNodeId != null && c.targetDefId != null)
          ? PropertyKey(nodeId: c.targetNodeId!, defId: c.targetDefId!)
          : null;
      final transformer = TransformerConfig.fromJson(jsonDecode(c.config));
      return (target: target, transformer: transformer);
    }

    StaticSourceConfig parseStatic(StoredConfig c) {
      return StaticSourceConfig.fromJson(jsonDecode(c.config));
    }

    try {
      final sources = storedConfigs.where((e) => e.configKey == ConfigKey.source);

      // --- 注意：每个构造函数都传入了 key ---
      return switch (mode) {
        SourceMode.singleStatic => PropertyConfig.singleStatic(
          key: key,
          source: parseStatic(sources.first),
        ),
        SourceMode.singleRef => PropertyConfig.singleRef(
          key: key,
          target: (sources.first.targetNodeId != null && sources.first.targetDefId != null)
              ? PropertyKey(nodeId: sources.first.targetNodeId!, defId: sources.first.targetDefId!)
              : null,
          transformer: TransformerConfig.fromJson(jsonDecode(sources.first.config)),
        ),
        SourceMode.multiStatic => PropertyConfig.multiStatic(
          key: key,
          aggregator: parseAgg()!,
          sources: {
            for (final s in sources) s.mapKey!: parseStatic(s),
          },
        ),
        SourceMode.multiRef => PropertyConfig.multiRef(
          key: key,
          aggregator: parseAgg()!,
          sources: {
            for (final s in sources) s.mapKey!: parseRef(s),
          },
        ),
        SourceMode.hybrid => _parseHybrid(key, sources, parseAgg()!),
      };
    } catch (e, s) {
      logger.e("Failed to parse PropertyConfig: $e", error: e, stackTrace: s);
      throw FormatException("Invalid config structure for mode ${mode.name}");
    }
  }

  static PropertyConfig _parseHybrid(PropertyKey key, Iterable<StoredConfig> sources, AggConfig agg) {
    final staticSources = <String, StaticSourceConfig>{};
    final refSources = <String, ({PropertyKey? target, TransformerConfig transformer})>{};

    for (final s in sources) {
      final jsonMap = jsonDecode(s.config) as Map<String, dynamic>;
      // 简单的启发式判断：有 transformerId 则是引用源
      if (jsonMap.containsKey('transformerId')) {
        refSources[s.mapKey!] = (
        target: (s.targetNodeId != null && s.targetDefId != null)
            ? PropertyKey(nodeId: s.targetNodeId!, defId: s.targetDefId!)
            : null,
        transformer: TransformerConfig.fromJson(jsonMap),
        );
      } else {
        staticSources[s.mapKey!] = StaticSourceConfig.fromJson(jsonMap);
      }
    }

    return PropertyConfig.hybrid(
      key: key, // <--- 传入 key
      aggregator: agg,
      staticSources: staticSources,
      refSources: refSources,
    );
  }
}