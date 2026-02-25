// (ComputeServiceImpl 的声明部分不变)

import '../../meta/property_meta_service.dart';
import '../compute_service.dart';
import 'compute_node.dart';

/// 私有任务类
class ComputeTask {
  final Map<String, Source> sourceMap;
  final Map<String, Processor> processorMap;
  final Map<String, Aggregator> aggregatorMap;
  final PropertyId self;

  // 记录所有涉及的节点 (用于寻找 Sink)
  final Set<ComputeNode> _allNodes = {};

  // 【优化核心】: 全部改用 ComputeNode 对象本身作为 Key！
  final Map<ComputeNode, List<ComputeNode>> _parentsMap = {};
  final Map<ComputeNode, Future<dynamic>> _cache = {};
  final Set<ComputeNode> _resolvingStack = {};

  ComputeTask({
    required List<ComputeMeta> metas,
    required this.sourceMap,
    required this.processorMap,
    required this.aggregatorMap,
    required this.self,
  }) {
    _buildGraph(metas);
  }

  void _buildGraph(List<ComputeMeta> metas) {
    for (var meta in metas) {
      final current = meta.compute;
      _allNodes.add(current);

      if (meta.next != null) {
        final nextNode = meta.next!;
        _allNodes.add(nextNode);
        // Freezed 会自动处理相同配置节点的合并
        _parentsMap.putIfAbsent(nextNode, () => []).add(current);
      }
    }
  }

  Future<dynamic> run() {
    // 探测终点：寻找没有任何子节点的 Node
    final allParentNodes = _parentsMap.values
        .expand((parents) => parents)
        .toSet();
    final sinkNodes = _allNodes
        .where((node) => !allParentNodes.contains(node))
        .toList();

    if (sinkNodes.isEmpty) {
      throw ComputeException(
        error: ComputeError.cycleDependencies,
        message: 'Graph Error: No sink node found.',
      );
    }
    return _resolveNode(sinkNodes.first);
  }

  Future<dynamic> _resolveNode(ComputeNode node) {
    // 1. 命中缓存：即使是两次实例化的 ReuseComputeNode，只要 config 和 computeId 一致，
    // Freezed 就会判定它们 hashCode 相同，从而命中这里的缓存！(天生防重复计算)
    if (_cache.containsKey(node)) return _cache[node]!;

    // 2. 循环依赖检查
    if (_resolvingStack.contains(node)) {
      throw ComputeException(error: ComputeError.cycleDependencies);
    }
    _resolvingStack.add(node);

    final futureResult = () async {
      switch (node.type) {
        case ComputeType.source:
          return _handleSource(node);
        case ComputeType.processor:
          return _handleProcessor(node);
        case ComputeType.aggregator:
          return _handleAggregator(node);
      }
    }();

    _cache[node] = futureResult;
    futureResult.whenComplete(() => _resolvingStack.remove(node));
    return futureResult;
  }

  Future<dynamic> _handleSource(ComputeNode node) {
    if (node is InlineSourceNode) {
      return node.create();
    } else if (node is ReuseComputeNode) {
      final source = sourceMap[node.computeId];
      if (source == null) {
        throw ComputeException(error: ComputeError.referenceInvalid);
      }
      return source.create(self, node.config);
    }
    throw UnimplementedError();
  }

  Future<dynamic> _handleProcessor(ComputeNode node) async {
    final parents = _parentsMap[node];
    if (parents == null || parents.isEmpty) {
      throw ComputeException(error: ComputeError.referenceInvalid);
    }

    final input = await _resolveNode(parents.first);

    if (node is InlineProcessorNode) {
      return node.process(input);
    } else if (node is ReuseComputeNode) {
      final processor = processorMap[node.computeId];
      if (processor == null) {
        throw ComputeException(error: ComputeError.referenceInvalid);
      }
      return processor.process(input, node.config);
    }
    throw UnimplementedError();
  }

  Future<dynamic> _handleAggregator(ComputeNode node) async {
    final parents = _parentsMap[node] ?? [];
    if (parents.isEmpty) {
      throw ComputeException(error: ComputeError.referenceInvalid);
    }

    final results = await Future.wait(parents.map(_resolveNode));
    final inputMap = <String, dynamic>{};

    for (var i = 0; i < parents.length; i++) {
      final p = parents[i];
      // 【策略优化】如果提供了自定义 id，使用 id；
      // 如果是复用节点，降级使用 computeId；
      // 如果是匿名内联节点，降级使用 hashCode 字符串（为了绝对安全兜底）。
      final key =
          p.id ?? (p is ReuseComputeNode ? p.computeId : p.hashCode.toString());
      inputMap[key] = results[i];
    }

    if (node is InlineAggregatorNode) {
      return node.aggregate(inputMap);
    } else if (node is ReuseComputeNode) {
      final aggregator = aggregatorMap[node.computeId];
      if (aggregator == null) {
        throw ComputeException(error: ComputeError.referenceInvalid);
      }
      return aggregator.aggregate(inputMap, node.config);
    }
    throw UnimplementedError();
  }
}
