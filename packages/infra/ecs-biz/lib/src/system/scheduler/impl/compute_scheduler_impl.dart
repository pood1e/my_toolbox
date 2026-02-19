import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../value/value_service.dart';
import '../data/scheduler_dao.dart';
import '../scheduler_service.dart';
import 'compute_scheduler.dart';
import 'compute_worker.dart';
import 'cycle_detector.dart';

class ComputeSchedulerImpl extends ComputeScheduler {
  final ValueService _valueService;
  final ComputePriorityService _priorityService;
  final ComputeWorker _worker;
  final SchedulerDao _dao;
  bool _isRunning = false;
  bool _hasPending = false;

  ComputeSchedulerImpl({
    required ValueService valueService,
    required ComputePriorityService priorityService,
    required ComputeWorker worker,
    required SchedulerDao dao,
  }) : _valueService = valueService,
       _priorityService = priorityService,
       _worker = worker,
       _dao = dao;

  @override
  Future<void> notifyDirty() async {
    if (_isRunning) {
      _hasPending = true;
      return;
    }
    _isRunning = true;
    _hasPending = false;

    await _schedule();
    while (_hasPending) {
      _hasPending = false;
      await _schedule();
    }
  }

  Future<void> _schedule() async {
    final dirties = await _dao.getDirties();
    if (dirties.isEmpty) return;

    List<QueryRow> rows = await _dao.getDirtyDependencyEdges(dirties);
    final edges = rows.map((row) => row.toEdge()).toList();

    final errors = CycleDetector.analyzeErrors(dirties, edges);
    if (errors.isNotEmpty) {
      await _valueService.markAsError(errors);
      dirties.removeWhere(errors.containsKey);
      if (dirties.isEmpty) return;
    }

    final Set<PropertyId> pendingNodes = dirties.toSet();
    while (pendingNodes.isNotEmpty) {
      final state = _priorityService.getHighPriorityState();
      final uiMap = _buildUiReachabilityMap(
        pendingNodes,
        edges,
        state.propertyIds,
      );
      final queue = _buildExecutionQueue(pendingNodes, edges, uiMap);

      if (queue.isEmpty && pendingNodes.isNotEmpty) {
        queue.add(pendingNodes.first);
      }

      for (final key in queue) {
        if (state.version != _priorityService.getHighPriorityVersion()) {
          break;
        }
        final computeSuccess = await _worker.work(key);
        if (computeSuccess) {
          pendingNodes.remove(key);
        } else {
          _hasPending = true;
          return;
        }
      }
    }
  }

  // --- 内部算法 ---

  /// 构建 UI 染色图 (仅针对 subset 范围)
  Map<PropertyId, bool> _buildUiReachabilityMap(
    Set<PropertyId> subset,
    List<DependencyEdge> allEdges,
    Set<PropertyId> highPriorityIds,
  ) {
    final isUiVital = <PropertyId, bool>{};
    // 只有 subset 中的才参与初始化
    for (var k in subset) {
      isUiVital[k] = false;
    }

    // 反向邻接表: Effect -> [Causes]
    final reverseGraph = <PropertyId, List<PropertyId>>{};
    for (var edge in allEdges) {
      // 过滤：只关心两端都在 subset 中的边
      if (subset.contains(edge.source) && subset.contains(edge.target)) {
        reverseGraph.putIfAbsent(edge.source, () => []).add(edge.target);
      }
    }

    final queue = <PropertyId>[];
    // 种子节点
    for (var key in subset) {
      if (highPriorityIds.contains(key)) {
        isUiVital[key] = true;
        queue.add(key);
      }
    }

    // BFS 反向扩散
    int head = 0;
    while (head < queue.length) {
      final current = queue[head++];
      final causes = reverseGraph[current];
      if (causes != null) {
        for (var cause in causes) {
          if (isUiVital[cause] == false) {
            isUiVital[cause] = true;
            queue.add(cause);
          }
        }
      }
    }
    return isUiVital;
  }

  /// 构建局部执行队列
  List<PropertyId> _buildExecutionQueue(
    Set<PropertyId> subset,
    List<DependencyEdge> allEdges,
    Map<PropertyId, bool> uiVitalMap,
  ) {
    final graph = <PropertyId, List<PropertyId>>{};
    final inDegree = <PropertyId, int>{};

    for (var k in subset) {
      graph[k] = [];
      inDegree[k] = 0;
    }

    // 构建图，仅包含 subset 内部的依赖
    // 关键点：如果 A(已完成) -> B(未完成)，A 不在 subset 中，
    // 这里就不会增加 B 的入度。B 会自然变为入度 0 (就绪)。
    for (var edge in allEdges) {
      if (subset.contains(edge.source) && subset.contains(edge.target)) {
        graph[edge.target]!.add(edge.source);
        inDegree[edge.source] = inDegree[edge.source]! + 1;
      }
    }

    // 双队列优先级调度
    final vitalQueue = <PropertyId>[];
    final normalQueue = <PropertyId>[];

    void addToQueue(PropertyId key) {
      if (uiVitalMap[key] == true) {
        vitalQueue.add(key);
      } else {
        normalQueue.add(key);
      }
    }

    inDegree.forEach((key, degree) {
      if (degree == 0) addToQueue(key);
    });

    final result = <PropertyId>[];

    while (vitalQueue.isNotEmpty || normalQueue.isNotEmpty) {
      // 优先取 vital
      final current = vitalQueue.isNotEmpty
          ? vitalQueue.removeLast()
          : normalQueue.removeLast();

      result.add(current);

      final neighbors = graph[current];
      if (neighbors != null) {
        for (var neighbor in neighbors) {
          inDegree[neighbor] = inDegree[neighbor]! - 1;
          if (inDegree[neighbor] == 0) {
            addToQueue(neighbor);
          }
        }
      }
    }
    return result;
  }
}

class DependencyEdge {
  final PropertyId source; // 依赖者 (Effect / result) -> 需要等待
  final PropertyId target; // 被依赖者 (Cause / dependency) -> 需要先算

  DependencyEdge({required this.source, required this.target});
}

extension RowToDependencyEdge on QueryRow {
  DependencyEdge toEdge() => DependencyEdge(
    source: PropertyId(nodeId: read('src_node'), metaId: read('src_meta')),
    target: PropertyId(nodeId: read('dst_node'), metaId: read('dst_meta')),
  );
}
