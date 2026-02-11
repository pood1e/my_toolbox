import 'dart:convert';

import 'package:app_core/object.dart';

import 'compute_engine.dart';
import 'property.dart';

part 'property_config.freezed.dart';

@freezed
abstract class ConfigurableComponent with _$ConfigurableComponent {
  const ConfigurableComponent._();

  const factory ConfigurableComponent.static({
    required Processor component,
    required dynamic raw,
  }) = ProcessorComponent;

  const factory ConfigurableComponent.ref({
    required Transformer component,
    PropertyKey? target,
    required dynamic raw,
  }) = TransformerComponent;

  const factory ConfigurableComponent.agg({
    required Aggregator component,
    required dynamic raw,
  }) = AggregateComponent;

  String toJsonString() => jsonEncode({
    'componentId': component.id,
    'raw': component.toDb(raw)
  });
}

@freezed
abstract class PropertyConfig with _$PropertyConfig {
  const factory PropertyConfig({
    required PropertyKey key,
    required String spec,
    required PropertyConfigBody body,
  }) = _PropertyConfig;
}

@freezed
sealed class PropertyConfigBody with _$PropertyConfigBody {
  const PropertyConfigBody._();

  const factory PropertyConfigBody.singleStatic({
    required ProcessorComponent processor,
  }) = SingleStaticPropertyConfig;

  const factory PropertyConfigBody.singleRef({
    required TransformerComponent transformer,
  }) = SingleRefPropertyConfig;

  // 3. Multi Static
  const factory PropertyConfigBody.multiStatic({
    required AggregateComponent aggregator,
    required Map<String, ProcessorComponent> processorMap,
  }) = MultiStaticPropertyConfig;

  // 4. Multi Ref
  const factory PropertyConfigBody.multiRef({
    required AggregateComponent aggregator,
    required Map<String, TransformerComponent> transformerMap,
  }) = MultiRefPropertyConfig;

  // 5. Hybrid
  const factory PropertyConfigBody.hybrid({
    required AggregateComponent aggregator,
    required Map<String, ProcessorComponent> processorMap,
    required Map<String, TransformerComponent> transformerMap,
  }) = HybridPropertyConfig;
}
