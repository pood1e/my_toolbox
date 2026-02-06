import 'package:app_core/logger.dart';

import '../../domain/property.dart';
import '../../domain/stored_value.dart';
import '../../repository/property_compute_repository.dart';
import '../compute_task_scheduler.dart';
import 'cycle_detector.dart';

class ComputeTaskWorkerImpl implements ComputeTaskWorker {
  final PropertyComputeRepository _repo;
  final ComputeTaskFactory _contextFactory;

  ComputeTaskWorkerImpl({
    required PropertyComputeRepository repo,
    required ComputeTaskFactory contextFactory,
  }) : _repo = repo,
       _contextFactory = contextFactory;

  /// work 方法不再直接处理中断，而是通过返回值请求重试
  /// @param watchState: 提供 UI 版本和快照的接口
  @override
  Future<WorkerResult> work(PropertyWatchCounter watchState) async {
    // ====================================================
    // Phase 1: IO 密集型 (获取数据与静态结构)
    // ====================================================
    logger.i('compute worker started');

    // 1. 获取所有脏节点
    List<PropertyKey> dirties = await _repo.getDirties();
    if (dirties.isEmpty) return WorkerResult.idle;

    // 2. 获取依赖边
    List<DependencyEdge> allEdges = await _repo.getDirtyDependencyEdges(
      dirties,
    );

    // 3. 静态环检测 (标记死循环节点)
    final errors = CycleDetector.analyzeErrors(dirties, allEdges);
    if (errors.isNotEmpty) {
      await _repo.saveProperties(
        errors.entries
            .map(
              (e) => Property(
                key: e.key,
                value: StoredValue.error(error: e.value),
              ),
            )
            .toList(),
      );
      dirties.removeWhere(errors.containsKey);
      if (dirties.isEmpty) return WorkerResult.completed;
    }

    // ====================================================
    // Phase 2: CPU 密集型 (队列构建与执行)
    // 使用 pendingNodes 维护剩余任务，避免重复计算
    // ====================================================
    final Set<PropertyKey> pendingNodes = dirties.toSet();

    while (pendingNodes.isNotEmpty) {
      // 记录本次内层循环开始时的 UI 版本
      final currentUiVersion = watchState.version;

      // A. 基于剩余节点构建局部图和优先级队列
      // 注意：必须传入 snapshot 副本
      final uiSnapshot = watchState.snapshot;
      final uiMap = _buildUiReachabilityMap(pendingNodes, allEdges, uiSnapshot);
      final queue = _buildExecutionQueue(pendingNodes, allEdges, uiMap);

      // 防兜底：如果有 pending 但队列为空 (理论上不应发生，除非有漏网的环)
      if (queue.isEmpty && pendingNodes.isNotEmpty) {
        queue.add(pendingNodes.first);
      }

      // B. 批量执行
      for (final key in queue) {
        // [Check Point]: 检查 UI 是否变化
        if (watchState.version != currentUiVersion) {
          // UI 变了 -> 当前队列优先级过时 -> 中断 For 循环
          // 这里的 break 会跳出 for，回到 while (pendingNodes.isNotEmpty)
          // 下一次 while 会基于剩余的 pendingNodes 和新的 UI Snapshot 重新建队
          break;
        }

        try {
          final task = _contextFactory.create(key);
          await task.run();

          // 执行成功，移除 pending
          pendingNodes.remove(key);
        } on RebuildGraphException {
          // 遇到结构性错误 (如 NoConfig)，必须重新查库
          // 退出 work，请求 Scheduler 重试
          return WorkerResult.retry;
        } catch (e) {
          // 其他计算错误 (如 EvalError)，已标记为 Error，视为处理完毕
          pendingNodes.remove(key);
          // print("Task error handled: $e");
        }
      }
    }

    return WorkerResult.completed;
  }

  // --- 内部算法 ---

  /// 构建 UI 染色图 (仅针对 subset 范围)
  Map<PropertyKey, bool> _buildUiReachabilityMap(
    Set<PropertyKey> subset,
    List<DependencyEdge> allEdges,
    Map<PropertyKey, int> uiCntMap,
  ) {
    final isUiVital = <PropertyKey, bool>{};
    // 只有 subset 中的才参与初始化
    for (var k in subset) {
      isUiVital[k] = false;
    }

    // 反向邻接表: Effect -> [Causes]
    final reverseGraph = <PropertyKey, List<PropertyKey>>{};
    for (var edge in allEdges) {
      // 过滤：只关心两端都在 subset 中的边
      if (subset.contains(edge.source) && subset.contains(edge.target)) {
        reverseGraph.putIfAbsent(edge.source, () => []).add(edge.target);
      }
    }

    final queue = <PropertyKey>[];
    // 种子节点
    for (var key in subset) {
      if ((uiCntMap[key] ?? 0) > 0) {
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
  List<PropertyKey> _buildExecutionQueue(
    Set<PropertyKey> subset,
    List<DependencyEdge> allEdges,
    Map<PropertyKey, bool> uiVitalMap,
  ) {
    final graph = <PropertyKey, List<PropertyKey>>{};
    final inDegree = <PropertyKey, int>{};

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
    final vitalQueue = <PropertyKey>[];
    final normalQueue = <PropertyKey>[];

    void addToQueue(PropertyKey key) {
      if (uiVitalMap[key] == true) {
        vitalQueue.add(key);
      } else {
        normalQueue.add(key);
      }
    }

    inDegree.forEach((key, degree) {
      if (degree == 0) addToQueue(key);
    });

    final result = <PropertyKey>[];

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
