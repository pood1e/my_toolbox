import '../compute_service.dart';
import 'compute_node.dart';

// 定义一个类型别名，简化代码
typedef NodeKey = (String, ComputeType);

class ComputeServiceImpl implements ComputeService {
  final Map<String, Source> _sourceMap;
  final Map<String, Processor> _processorMap;
  final Map<String, Aggregator> _aggregatorMap;

  ComputeServiceImpl({
    required List<Source> sources,
    required List<Processor> processors,
    required List<Aggregator> aggregators,
  }) : _sourceMap = {for (final source in sources) source.computeId: source},
       _processorMap = {
         for (final processor in processors) processor.computeId: processor,
       },
       _aggregatorMap = {
         for (final aggregator in aggregators) aggregator.computeId: aggregator,
       };

  @override
  Future<dynamic> compute(List<ComputeMeta> metas) {
    if (metas.isEmpty) return Future.value(null);

    // 将单次计算的状态封装在 _ComputeTask 中
    final task = _ComputeTask(
      metas: metas,
      sourceMap: _sourceMap,
      processorMap: _processorMap,
      aggregatorMap: _aggregatorMap,
    );

    return task.run();
  }
}

/// 私有任务类：负责构建图、管理缓存和执行递归
class _ComputeTask {
  final Map<String, Source> sourceMap;
  final Map<String, Processor> processorMap;
  final Map<String, Aggregator> aggregatorMap;

  // 图索引
  final Map<NodeKey, ComputeMeta> _metaIndex = {};

  // 反向依赖图: Key(子) -> Value(父节点列表)
  final Map<NodeKey, List<ComputeMeta>> _parentsMap = {};

  // 缓存: 防止重复计算
  final Map<NodeKey, Future<dynamic>> _cache = {};

  _ComputeTask({
    required List<ComputeMeta> metas,
    required this.sourceMap,
    required this.processorMap,
    required this.aggregatorMap,
  }) {
    _buildGraph(metas);
  }

  // --- 1. 图构建逻辑 ---
  void _buildGraph(List<ComputeMeta> metas) {
    for (var meta in metas) {
      _metaIndex[(meta.computeId, meta.type)] = meta;

      // 记录父子关系：如果有 nextId，说明 nextId 的节点依赖当前节点
      if (meta.nextId != null && meta.nextType != null) {
        final childKey = (meta.nextId!, meta.nextType!);
        _parentsMap.putIfAbsent(childKey, () => []).add(meta);
      }
    }
  }

  // --- 2. 执行入口 ---
  Future<dynamic> run() {
    // 寻找终点 (Sink Node)
    final rootMeta = _metaIndex.values.firstWhere(
      (m) => m.nextId == null,
      orElse: () =>
          throw Exception('Graph Error: No sink node (nextId=null) found.'),
    );
    return _resolveNode(rootMeta);
  }

  // --- 3. 递归核心 ---
  Future<dynamic> _resolveNode(ComputeMeta meta) {
    final key = (meta.computeId, meta.type);

    // 命中缓存直接返回
    if (_cache.containsKey(key)) return _cache[key]!;

    Future<dynamic> result;
    switch (meta.type) {
      case ComputeType.source:
        result = _handleSource(meta);
        break;
      case ComputeType.processor:
        result = _handleProcessor(meta, key);
        break;
      case ComputeType.aggregator:
        result = _handleAggregator(meta, key);
        break;
    }

    return _cache[key] = result;
  }

  // --- 4. 具体节点处理逻辑 ---

  Future<dynamic> _handleSource(ComputeMeta meta) {
    final source = sourceMap[meta.computeId];
    if (source == null) throw Exception('Source missing: ${meta.computeId}');
    return source.create(meta.config);
  }

  Future<dynamic> _handleProcessor(ComputeMeta meta, NodeKey key) async {
    final parents = _parentsMap[key];
    if (parents == null || parents.isEmpty) {
      throw Exception('Processor detached: ${meta.computeId}');
    }

    // Processor 只取第一个输入
    final input = await _resolveNode(parents.first);

    final processor = processorMap[meta.computeId];
    if (processor == null) {
      throw Exception('Processor missing: ${meta.computeId}');
    }

    return processor.process(input, meta.config);
  }

  Future<dynamic> _handleAggregator(ComputeMeta meta, NodeKey key) async {
    final parents = _parentsMap[key] ?? [];
    if (parents.isEmpty) {
      throw Exception('Aggregator detached: ${meta.computeId}');
    }

    // 并行获取所有上游结果
    final results = await Future.wait(parents.map(_resolveNode));

    // 组装 Map<computeId, data>
    final inputMap = <String, dynamic>{};
    for (var i = 0; i < parents.length; i++) {
      inputMap[parents[i].computeId] = results[i];
    }

    final aggregator = aggregatorMap[meta.computeId];
    if (aggregator == null) {
      throw Exception('Aggregator missing: ${meta.computeId}');
    }

    return aggregator.aggregate(inputMap, meta.config);
  }
}
