import 'package:freezed_annotation/freezed_annotation.dart';

import '../../meta/property_meta_service.dart';

part 'compute_node.freezed.dart';

enum ComputeType { source, processor, aggregator }

abstract class ReuseCompute {
  String get computeId;
}

/// 图计算节点 (DAG Node) 基类
abstract class ComputeNode {
  /// 【优化】改为可选的 id。只有在作为 Aggregator 的前置节点时，才需要为了方便取值而传入
  String? get id;

  ComputeType get type;
}

/// =========================================
/// 1. 复用节点
/// =========================================
@Freezed(genericArgumentFactories: true)
abstract class ReuseComputeNode<C>
    with _$ReuseComputeNode<C>
    implements ComputeNode {
  const factory ReuseComputeNode({
    String? id, // 可选
    required String computeId,
    required ComputeType type,
    required C config,
  }) = _ReuseComputeNode<C>;
}

/// =========================================
/// 2. 内联节点 (彻底匿名化)
/// =========================================
@Freezed(genericArgumentFactories: true)
abstract class InlineSourceNode<T>
    with _$InlineSourceNode<T>
    implements ComputeNode {
  const InlineSourceNode._();

  const factory InlineSourceNode({
    String? id, // 可选
    required Future<T> Function() create,
  }) = _InlineSourceNode<T>;

  @override
  ComputeType get type => ComputeType.source;
}

@Freezed(genericArgumentFactories: true)
abstract class InlineProcessorNode<S, T>
    with _$InlineProcessorNode<S, T>
    implements ComputeNode {
  const InlineProcessorNode._();

  const factory InlineProcessorNode({
    String? id, // 可选
    required Future<T> Function(S source) process,
  }) = _InlineProcessorNode<S, T>;

  @override
  ComputeType get type => ComputeType.processor;
}

@Freezed(genericArgumentFactories: true)
abstract class InlineAggregatorNode<T>
    with _$InlineAggregatorNode<T>
    implements ComputeNode {
  const InlineAggregatorNode._();

  const factory InlineAggregatorNode({
    String? id, // 可选
    required Future<T> Function(Map<String, dynamic> sMap) aggregate,
  }) = _InlineAggregatorNode<T>;

  @override
  ComputeType get type => ComputeType.aggregator;
}

/// =========================================
/// 全局注册逻辑 Handlers
/// =========================================
abstract class Source<C, T> implements ReuseCompute {
  Future<T> create(PropertyId self, C config);
}

@Freezed(genericArgumentFactories: true)
abstract class Processor<S, C, T>
    with _$Processor<S, C, T>
    implements ReuseCompute {
  const Processor._();

  const factory Processor({
    required String computeId,
    required Future<T> Function(S source, C config) process,
  }) = _Processor<S, C, T>;
}

@Freezed(genericArgumentFactories: true)
abstract class Aggregator<C, T>
    with _$Aggregator<C, T>
    implements ReuseCompute {
  const Aggregator._();

  const factory Aggregator({
    required String computeId,
    required Future<T> Function(Map<String, dynamic> sMap, C config) aggregate,
  }) = _Aggregator<C, T>;
}
