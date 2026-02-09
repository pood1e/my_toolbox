import 'package:app_core/object.dart';

import 'compute_engine.dart';
import 'property_definition.dart';
import 'stored_config.dart';

part 'source_definition.freezed.dart';

// --- 接口定义，方便在使用时统一调用 ---
abstract class HasProcessor {
  Processor get processor;
}

abstract class HasTransformers {
  Set<String> get propertyIds;

  Set<Transformer> get transformers;
}

abstract class HasAggs {
  Set<Aggregator> get aggregators;
}

@freezed
sealed class SourceDefinition with _$SourceDefinition {
  const SourceDefinition._();

  // 所有的子类都会自动实现这个 getter
  @override
  abstract final SourceMode mode;
  @override
  abstract final String name;

  // --------------------
  // Single
  // --------------------
  const factory SourceDefinition.singleStatic({
    required String name,
    @Default(SourceMode.singleStatic) SourceMode mode,
    required String processorId,
  }) = SingleStaticSourceDefinition;

  const factory SourceDefinition.singleRef({
    required String name,
    @Default(SourceMode.singleRef) SourceMode mode,
    required Set<String> propertyIds,
    required Set<String> transformerIds,
  }) = SingleRefSourceDefinition;

  // --------------------
  // Multi
  // --------------------
  const factory SourceDefinition.multiStatic({
    required String name,
    @Default(SourceMode.multiStatic) SourceMode mode,
    required String processorId,
    required Set<String> aggs,
  }) = MultiStaticSourceDefinition;

  const factory SourceDefinition.multiRef({
    required String name,
    @Default(SourceMode.multiRef) SourceMode mode,
    required Set<String> propertyIds,
    required Set<String> transformerIds,
    required Set<String> aggs,
  }) = MultiRefSourceDefinition;

  // --------------------
  // Hybrid
  // --------------------
  const factory SourceDefinition.hybrid({
    required String name,
    @Default(SourceMode.hybrid) SourceMode mode,
    required String processorId,
    required Set<String> propertyIds,
    required Set<String> transformerIds,
    required Set<String> aggs,
  }) = HybridSourceDefinition;
}

@freezed
sealed class SourceDescriptor with _$SourceDescriptor {
  const SourceDescriptor._();
  @override
  abstract final SourceMode mode;
  @override
  abstract final String name;

  @Implements<HasProcessor>()
  const factory SourceDescriptor.singleStatic({
    required String name,
    @Default(SourceMode.singleStatic) SourceMode mode,
    required Processor processor,
  }) = SingleStaticSourceDescriptor;

  @Implements<HasTransformers>()
  const factory SourceDescriptor.singleRef({
    required String name,
    @Default(SourceMode.singleRef) SourceMode mode,
    required Set<String> propertyIds,
    required Set<Transformer> transformers,
  }) = SingleRefSourceDescriptor;

  @Implements<HasProcessor>()
  @Implements<HasAggs>()
  const factory SourceDescriptor.multiStatic({
    required String name,
    @Default(SourceMode.multiStatic) SourceMode mode,
    required Processor processor,
    required Set<Aggregator> aggregators,
  }) = MultiStaticSourceDescriptor;

  @Implements<HasAggs>()
  @Implements<HasTransformers>()
  const factory SourceDescriptor.multiRef({
    required String name,
    @Default(SourceMode.multiRef) SourceMode mode,
    required Set<String> propertyIds,
    required Set<Transformer> transformers,
    required Set<Aggregator> aggregators,
  }) = MultiRefSourceDescriptor;

  @Implements<HasProcessor>()
  @Implements<HasAggs>()
  @Implements<HasTransformers>()
  const factory SourceDescriptor.hybrid({
    required String name,
    @Default(SourceMode.hybrid) SourceMode mode,
    required Processor processor,
    required Set<String> propertyIds,
    required Set<Transformer> transformers,
    required Set<Aggregator> aggregators,
  }) = HybridSourceDescriptor;
}