import '../../domain/property.dart';
import '../../domain/stored_value.dart';
import '../../repository/property_compute_repository.dart';

class CycleDetector {
  /// 核心入口
  static Map<PropertyKey, ValueError> analyzeErrors(
    List<PropertyKey> allDirties,
    List<DependencyEdge> edges,
  ) {
    if (allDirties.isEmpty) return {};

    // 1. 构建图 & 计算入度
    // graph: Target -> [Source1, Source2] (Cause -> Effects)
    final Map<PropertyKey, List<PropertyKey>> graph = {};
    final Map<PropertyKey, int> inDegree = {};

    // 初始化
    for (var key in allDirties) {
      graph[key] = [];
      inDegree[key] = 0;
    }

    // 填充边
    for (var edge in edges) {
      // 确保边的两端都在当前 dirty 列表中 (局部图)
      if (inDegree.containsKey(edge.source) &&
          inDegree.containsKey(edge.target)) {
        graph[edge.target]!.add(edge.source); // 记录出边
        inDegree[edge.source] = inDegree[edge.source]! + 1; // 记录入度
      }
    }

    // 2. Kahn 算法剪枝 (移除健康节点)
    // 这里的逻辑是：移除入度为 0 的节点，并将其指向的节点的入度减 1
    final queue = <PropertyKey>[];
    inDegree.forEach((key, degree) {
      if (degree == 0) queue.add(key);
    });

    int processedCount = 0;
    while (queue.isNotEmpty) {
      final node = queue.removeLast();
      processedCount++;

      final neighbors = graph[node];
      if (neighbors != null) {
        for (var neighbor in neighbors) {
          final currentDegree = inDegree[neighbor]! - 1;
          inDegree[neighbor] = currentDegree;
          if (currentDegree == 0) {
            queue.add(neighbor);
          }
        }
      }
    }

    // 如果所有节点都处理完了，说明没有环
    if (processedCount == allDirties.length) {
      return {};
    }

    // 3. 提取"坏节点" (Bad Nodes)
    // 剩下的入度 > 0 的节点，要么是环，要么依赖环
    final badNodes = allDirties.where((k) => inDegree[k]! > 0).toList();

    // 优化点：构建坏节点 Set，用于 Tarjan 内部快速判断边界
    final badNodeSet = badNodes.toSet();

    // 4. 在残余图上运行 Tarjan (寻找 SCC)
    final sccs = _findSCCs(badNodes, badNodeSet, graph);

    // 5. 标记结果
    final Map<PropertyKey, ValueError> result = {};

    for (var scc in sccs) {
      bool isCycle = false;

      if (scc.length > 1) {
        // SCC 大小 > 1，绝对是环
        isCycle = true;
      } else {
        // SCC 大小 = 1，检查是否有自环 (A -> A)
        final node = scc.first;
        // 优化点：直接检查 graph[node] 中是否包含 node
        if (graph[node]?.contains(node) == true) {
          isCycle = true;
        }
      }

      final errorType = isCycle
          ? ValueError.cycleDependencies
          : ValueError.referenceInvalid;
      for (var node in scc) {
        result[node] = errorType;
      }
    }

    return result;
  }

  /// Tarjan 算法实现 (强连通分量)
  /// 优化：只遍历 badNodes，且利用 badNodeSet 快速过滤边
  static List<List<PropertyKey>> _findSCCs(
    List<PropertyKey> nodes,
    Set<PropertyKey> nodeSet,
    Map<PropertyKey, List<PropertyKey>> graph,
  ) {
    int indexCounter = 0;
    final Map<PropertyKey, int> indices = {};
    final Map<PropertyKey, int> lowLinks = {};
    final List<PropertyKey> stack = [];
    final Set<PropertyKey> onStack = {};
    final List<List<PropertyKey>> sccs = [];

    void strongConnect(PropertyKey v) {
      indices[v] = indexCounter;
      lowLinks[v] = indexCounter;
      indexCounter++;
      stack.add(v);
      onStack.add(v);

      final neighbors = graph[v];
      if (neighbors != null) {
        for (var w in neighbors) {
          // 关键优化：只处理 badNodeSet 中的邻居
          // 如果 w 不在 badNodeSet 中，说明 w 是已经被 Kahn 移除的健康节点
          // 虽然根据 Kahn 的性质，残余图中的节点只会指向残余图中的节点，
          // 但加上这个判断可以作为防御性编程，并明确算法边界。
          if (!nodeSet.contains(w)) continue;

          if (!indices.containsKey(w)) {
            // w 未访问
            strongConnect(w);
            if (lowLinks[w]! < lowLinks[v]!) {
              lowLinks[v] = lowLinks[w]!;
            }
          } else if (onStack.contains(w)) {
            // w 在栈中，发现后向边
            if (indices[w]! < lowLinks[v]!) {
              lowLinks[v] = indices[w]!;
            }
          }
        }
      }

      // 生成 SCC
      if (lowLinks[v] == indices[v]) {
        final List<PropertyKey> currentSCC = [];
        PropertyKey w;
        do {
          w = stack.removeLast();
          onStack.remove(w);
          currentSCC.add(w);
        } while (v != w);
        sccs.add(currentSCC);
      }
    }

    for (var node in nodes) {
      if (!indices.containsKey(node)) {
        strongConnect(node);
      }
    }

    return sccs;
  }
}
