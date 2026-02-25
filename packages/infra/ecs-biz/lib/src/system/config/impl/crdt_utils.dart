// File: config_utils.dart

import '../config_service.dart';

/// 封装展平后的结果
class FlattenedEntry {
  final dynamic value;

  /// true: 强制更新 (覆盖写), false: 差异更新 (仅当值变化时写)
  final bool forceUpdate;

  FlattenedEntry(this.value, this.forceUpdate);

  @override
  String toString() => 'Entry($value, force:$forceUpdate)';
}

class ConfigFlattenUtil {
  /// data: 通过 meta.toDb() 转换后的 Map
  /// rules: 通过 meta.buildUpdateMap() 返回的规则
  ///
  /// 逻辑调整：
  /// 1. 默认展开 Root 层。
  /// 2. 遇到嵌套 Map 时，仅当 rules 中包含该路径(精确或通配符)时才继续展开，否则视为由上层管理的原子对象。
  static Map<String, FlattenedEntry> flatten(
    Map<String, dynamic> data,
    Map<String, bool> rules,
  ) {
    final result = <String, FlattenedEntry>{};

    // 预处理：找出所有通配符规则的"父路径"
    // 例如规则 "style.border.*": true
    // 则 wildcardParents 包含 "style.border"
    final wildcardParents = <String>{};
    rules.forEach((key, _) {
      if (key.endsWith('.*')) {
        wildcardParents.add(key.substring(0, key.length - 2));
      }
    });

    void recurse(String currentPath, dynamic currentValue) {
      // --- 1. 确定当前节点的更新策略 ---
      // 优先级: 精确规则 > 通配符规则 > 默认(Diff)
      bool forceUpdate = false; // 默认为 DiffUpdate (false)

      bool? explicitStrategy = rules[currentPath];

      // 查找通配符策略 (检查父级是否是 key.*)
      bool? wildcardStrategy;
      if (currentPath.isNotEmpty) {
        final lastDot = currentPath.lastIndexOf('.');
        if (lastDot != -1) {
          final parent = currentPath.substring(0, lastDot);
          // 检查是否有 parent.* 的规则
          wildcardStrategy = rules['$parent.*'];
        } else {
          // 顶级节点，父级是 Root，检查是否有 root.* (极少见但支持)
          wildcardStrategy = rules['*'];
        }
      }

      if (explicitStrategy != null) {
        forceUpdate = explicitStrategy;
      } else if (wildcardStrategy != null) {
        forceUpdate = wildcardStrategy;
      } else {
        // 如果没有任何规则命中，对于 Root 层以下的叶子节点，默认是 false
        // 但对于 Root 层直接的 Key，通常默认为 true (全量替换)，这里我们保持 false，
        // 让 diff 工具决定，除非业务层显式指定了规则。
        forceUpdate = false;
      }

      // --- 2. 判断是否展开 ---
      bool shouldExpand = false;

      if (currentValue is Map<String, dynamic>) {
        if (currentPath.isEmpty) {
          // Root 必须展开
          shouldExpand = true;
        } else {
          // 非 Root 层 Map，检查是否命中规则
          // A. 显式规则指定了当前路径 (例如 'style': true) -> 展开以应用策略?
          //    注意：通常显式规则给 Map 是为了控制它的 Update 策略，而不是为了展开。
          //    但在 Config 场景下，如果给一个 Map 配置了规则，通常意味着我们想细粒度控制它。
          //    *修正逻辑*: 只有当它是某个通配符的父级，或者规则显式指向它的子级时才需要展开。
          //    但为了简单和灵活性，我们约定：如果 rules map 里有这个 key，我们就展开它。

          final isExplicitlyInRules = rules.containsKey(currentPath);
          final isWildcardParent = wildcardParents.contains(currentPath);

          // 只有当规则系统明确关注这个 Map 的内部结构时，才展开
          if (isExplicitlyInRules || isWildcardParent) {
            shouldExpand = true;
          }
        }
      }

      // --- 3. 执行 ---
      if (shouldExpand) {
        final map = currentValue as Map<String, dynamic>;
        // 递归处理子节点
        for (final entry in map.entries) {
          final nextPath = currentPath.isEmpty
              ? entry.key
              : '$currentPath.${entry.key}';
          recurse(nextPath, entry.value);
        }
      } else {
        // 作为原子值写入结果 (Root 除外，Root 本身不写入，只写它的 children)
        if (currentPath.isNotEmpty) {
          result[currentPath] = FlattenedEntry(currentValue, forceUpdate);
        }
      }
    }

    recurse('', data);
    return result;
  }

  /// 反展平：将扁平的 Map 还原为嵌套结构
  /// 简单的路径分割还原逻辑
  static Map<String, dynamic> unflatten(Map<String, dynamic> flatMap) {
    final result = <String, dynamic>{};

    // 先对 key 排序，保证父级路径先处理 (虽然下面的逻辑其实不强依赖顺序，但排序更稳妥)
    final sortedKeys = flatMap.keys.toList()..sort();

    for (final path in sortedKeys) {
      final value = flatMap[path];

      // 值为空代表删除，不写入结果
      if (value == null) continue;

      final keys = path.split('.');
      Map<String, dynamic> current = result;

      for (int i = 0; i < keys.length; i++) {
        final key = keys[i];
        final isLast = i == keys.length - 1;

        if (isLast) {
          current[key] = value;
        } else {
          // 如果路径中间某一段不存在，或者是原子值(之前被写入过)，则初始化为 Map
          // 这里的覆盖逻辑：如果 'style' 之前是原子对象，现在来了 'style.color'，
          // 我们会把 'style' 变成 Map。这要求 flatten 和 unflatten 的规则必须一致。
          if (current[key] is! Map<String, dynamic>) {
            current[key] = <String, dynamic>{};
          }
          current = current[key] as Map<String, dynamic>;
        }
      }
    }
    return result;
  }
}

/// 封装 Diff 结果
class ConfigDelta {
  /// 变更的数据：Key -> Value (null 表示删除)
  final Map<String, dynamic> deltaMap;

  /// 需要触发 CRDT 同步的 Key 集合 (包含值变化的和强制更新的)
  final Set<String> keysToSync;

  ConfigDelta(this.deltaMap, this.keysToSync);

  bool get isEmpty => keysToSync.isEmpty;
}

class ConfigDiffTool {
  /// 计算 Snapshot 和 NewConfig 之间的差异
  static ConfigDelta calculateDelta({
    required PropertyConfigMeta meta,
    required dynamic snapshot,
    required dynamic config,
    required Map<String, bool> rules,
  }) {
    // 1. 转换并展平
    // 注意：snapshot 和 config 必须使用完全相同的规则进行展平，
    // 这样才能保证 atomic map vs expanded map 的对比是正确的。
    final snapMap = snapshot != null
        ? meta.toDb(snapshot)
        : <String, dynamic>{};
    final newMap = meta.toDb(config);

    final snapFlat = ConfigFlattenUtil.flatten(snapMap, rules);
    final newFlat = ConfigFlattenUtil.flatten(newMap, rules);

    final deltaMap = <String, dynamic>{};
    final keysToSync = <String>{};

    final allKeys = {...newFlat.keys, ...snapFlat.keys};

    for (final key in allKeys) {
      final newEntry = newFlat[key];
      final snapEntry = snapFlat[key];

      bool shouldSync = false;
      dynamic deltaValue;

      if (newEntry == null) {
        // 情况 A: 新配置里没了 -> 删除
        shouldSync = true;
        deltaValue = null;
      } else if (snapEntry == null) {
        // 情况 B: 旧配置里没 -> 新增
        shouldSync = true;
        deltaValue = newEntry.value;
      } else {
        // 情况 C: 都有 -> 比较
        final valueChanged = !_areValuesEqual(newEntry.value, snapEntry.value);

        // 触发同步的条件：值变了 OR 规则要求强制更新(即便值没变也要刷时间戳)
        if (valueChanged || newEntry.forceUpdate) {
          shouldSync = true;
          deltaValue = newEntry.value;
        }
      }

      if (shouldSync) {
        keysToSync.add(key);
        // 只有当是删除操作，或者值确实发生变化时，才写入 deltaMap 用于 DB 更新。
        // 如果仅仅是 forceUpdate 但值没变，DB 其实不需要执行 update 语句 (节省 IO)，
        // 但 CRDT 必须 upsert。
        // 为了简化逻辑，这里只要 sync 就写入 map，DAO 层 update 相同值通常开销也不大。
        deltaMap[key] = deltaValue;
      }
    }

    return ConfigDelta(deltaMap, keysToSync);
  }

  /// 将 Delta 应用到 DB 原始数据上 (三路合并/Patch)
  static Map<String, dynamic> mergeDeltaToDbConfig({
    required Map<String, dynamic> dbRawMap,
    required Map<String, dynamic> deltaMap,
    required Map<String, bool> rules,
  }) {
    // 1. 使用相同的规则展平 DB 数据
    // 这步至关重要：如果 rules 规定 'style' 不展开，那么 DB 里的 'style' 就是一个原子 Map。
    // 如果 deltaMap 里有 'style' 的新值，直接覆盖即可。
    final dbFlatEntries = ConfigFlattenUtil.flatten(dbRawMap, rules);

    // 提取纯值 Map
    final dbFlatMap = <String, dynamic>{};
    for (var e in dbFlatEntries.entries) {
      dbFlatMap[e.key] = e.value.value;
    }

    // 2. 应用 Patch
    for (final entry in deltaMap.entries) {
      if (entry.value == null) {
        dbFlatMap.remove(entry.key);
      } else {
        dbFlatMap[entry.key] = entry.value;
      }
    }

    // 3. 还原
    return ConfigFlattenUtil.unflatten(dbFlatMap);
  }

  /// 简单的深度比较，用于 Map/List 的值对比
  static bool _areValuesEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;

    // 如果没有 deep collection equality 库，这里简单处理 json encoding 对比
    // 或者引入 'package:collection/collection.dart' 的 DeepCollectionEquality
    // 这里为了不引入额外依赖，假设业务层使用的是标准 JSON 类型，简单的 String 对比足够应对 Map/List
    // (前提是 Map key 顺序一致，如果不可控建议使用 DeepCollectionEquality)
    if (a is Map || a is List) {
      return a.toString() == b.toString();
    }
    return false;
  }
}
