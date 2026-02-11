import 'package:app_core/object.dart';

import 'compute_engine.dart';
import 'property_config.dart';
import 'stored_config.dart';

part 'config_spec.freezed.dart';

@freezed
abstract class ComponentSpec with _$ComponentSpec {
  const factory ComponentSpec({required dynamic Function() createDefault}) =
      _ComponentSpec;
}

// --- 接口定义，方便在使用时统一调用 ---
abstract class HasProcessors {
  Map<String, Processor> get processorMap;

  Map<String, ComponentSpec> get processorSpecs;
}

abstract class HasTransformers {
  Set<String> get propertyIds;

  Map<String, Transformer> get transformerMap;

  Map<String, ComponentSpec> get transformerSpecs;
}

abstract class HasAggs {
  Map<String, Aggregator> get aggregatorMap;

  Map<String, ComponentSpec> get aggregatorSpecs;
}

@freezed
sealed class ConfigSpecDefinition with _$ConfigSpecDefinition {
  const ConfigSpecDefinition._();

  @override
  abstract final ConfigMode mode;
  @override
  abstract final String id;

  // --------------------
  // Single
  // --------------------
  const factory ConfigSpecDefinition.singleStatic({
    required String id,
    @Default(ConfigMode.singleStatic) ConfigMode mode,
    required Map<String, ComponentSpec> processSpecs,
  }) = SingleStaticConfigSpecDefinition;

  const factory ConfigSpecDefinition.singleRef({
    required String id,
    @Default(ConfigMode.singleRef) ConfigMode mode,
    required Set<String> propertyIds,
    required Map<String, ComponentSpec> transformerSpecs,
  }) = SingleRefConfigSpecDefinition;

  // --------------------
  // Multi
  // --------------------
  const factory ConfigSpecDefinition.multiStatic({
    required String id,
    @Default(ConfigMode.multiStatic) ConfigMode mode,
    required Map<String, ComponentSpec> processorSpecs,
    required Map<String, ComponentSpec> aggregatorSpecs,
  }) = MultiStaticConfigSpecDefinition;

  const factory ConfigSpecDefinition.multiRef({
    required String id,
    @Default(ConfigMode.multiRef) ConfigMode mode,
    required Set<String> propertyIds,
    required Map<String, ComponentSpec> transformerSpecs,
    required Map<String, ComponentSpec> aggregatorSpecs,
  }) = MultiRefConfigSpecDefinition;

  // --------------------
  // Hybrid
  // --------------------
  const factory ConfigSpecDefinition.hybrid({
    required String id,
    @Default(ConfigMode.hybrid) ConfigMode mode,
    required Map<String, ComponentSpec> processorSpecs,
    required Set<String> propertyIds,
    required Map<String, ComponentSpec> transformerSpecs,
    required Map<String, ComponentSpec> aggregatorSpecs,
  }) = HybridConfigSpecDefinition;
}

@freezed
sealed class ConfigSpecDescriptor with _$ConfigSpecDescriptor {
  const ConfigSpecDescriptor._();

  @override
  abstract final ConfigMode mode;
  @override
  abstract final String id;

  @Implements<HasProcessors>()
  const factory ConfigSpecDescriptor.singleStatic({
    required String id,
    required Map<String, Processor> processorMap,
    required Map<String, ComponentSpec> processorSpecs,
    @Default(ConfigMode.singleStatic) ConfigMode mode,
    PropertyConfigBody Function()? createDefault
  }) = SingleStaticConfigSpecDescriptor;

  @Implements<HasTransformers>()
  const factory ConfigSpecDescriptor.singleRef({
    required String id,
    @Default(ConfigMode.singleRef) ConfigMode mode,
    required Set<String> propertyIds,
    required Map<String, Transformer> transformerMap,
    required Map<String, ComponentSpec> transformerSpecs,
    PropertyConfigBody Function()? createDefault
  }) = SingleRefConfigSpecDescriptor;

  @Implements<HasProcessors>()
  @Implements<HasAggs>()
  const factory ConfigSpecDescriptor.multiStatic({
    required String id,
    @Default(ConfigMode.multiStatic) ConfigMode mode,
    required Map<String, Processor> processorMap,
    required Map<String, ComponentSpec> processorSpecs,
    required Map<String, Aggregator> aggregatorMap,
    required Map<String, ComponentSpec> aggregatorSpecs,
    PropertyConfigBody Function()? createDefault
  }) = MultiStaticConfigSpecDescriptor;

  @Implements<HasAggs>()
  @Implements<HasTransformers>()
  const factory ConfigSpecDescriptor.multiRef({
    required String id,
    @Default(ConfigMode.multiRef) ConfigMode mode,
    required Set<String> propertyIds,
    required Map<String, Transformer> transformerMap,
    required Map<String, ComponentSpec> transformerSpecs,
    required Map<String, Aggregator> aggregatorMap,
    required Map<String, ComponentSpec> aggregatorSpecs,
    PropertyConfigBody Function()? createDefault
  }) = MultiRefConfigSpecDescriptor;

  @Implements<HasProcessors>()
  @Implements<HasAggs>()
  @Implements<HasTransformers>()
  const factory ConfigSpecDescriptor.hybrid({
    required String id,
    @Default(ConfigMode.hybrid) ConfigMode mode,
    required Map<String, Processor> processorMap,
    required Map<String, ComponentSpec> processorSpecs,
    required Set<String> propertyIds,
    required Map<String, Transformer> transformerMap,
    required Map<String, ComponentSpec> transformerSpecs,
    required Map<String, Aggregator> aggregatorMap,
    required Map<String, ComponentSpec> aggregatorSpecs,
    PropertyConfigBody Function()? createDefault
  }) = HybridConfigSpecDescriptor;
}
