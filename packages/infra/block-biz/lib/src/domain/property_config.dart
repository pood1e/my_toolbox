import 'dart:convert';

import 'package:app_core/object.dart';

import 'compute_engine.dart';
import 'property.dart';

part 'property_config.freezed.dart';

sealed class ConfigurableComponent<C, COMP extends Configurable<C>> {
  // 必须提供 const 构造函数，否则 Freezed 无法生成 const 子类
  const ConfigurableComponent();

  // 定义抽象 getter，强制子类实现
  C get raw;

  COMP get component;

  // 公共逻辑放在基类中
  String toJsonString() =>
      jsonEncode({'componentId': component.id, 'raw': component.toDb(raw)});
}

// -----------------------------------------------------------------------------
// 实现类
// -----------------------------------------------------------------------------

@Freezed(genericArgumentFactories: true)
abstract class ProcessorComponent<C, T>
    extends ConfigurableComponent<C, Processor<C, T>>
    with _$ProcessorComponent<C, T> {
  const ProcessorComponent._(); // 必须有的私有构造函数

  const factory ProcessorComponent({
    required Processor<C, T> component,
    required C raw,
  }) = _ProcessorComponent<C, T>;
}

@Freezed(genericArgumentFactories: true)
abstract class TransformerComponent<S, C, T>
    extends ConfigurableComponent<C, Transformer<S, C, T>>
    with _$TransformerComponent<S, C, T> {
  const TransformerComponent._();

  const factory TransformerComponent({
    required Transformer<S, C, T> component,
    PropertyKey? target,
    required C raw,
  }) = _TransformerComponent<S, C, T>;
}

@Freezed(genericArgumentFactories: true)
abstract class AggregateComponent<C, T>
    extends ConfigurableComponent<C, Aggregator<C, T>>
    with _$AggregateComponent<C, T> {
  const AggregateComponent._();

  const factory AggregateComponent({
    required Aggregator<C, T> component,
    required C raw,
  }) = _AggregateComponent<C, T>;
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
