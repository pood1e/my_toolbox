import '../config_service.dart';

/// 封装展平后的结果
class FlattenedEntry {
  final dynamic value;
  /// true: 强制更新 (FullUpdate), false: 差异更新 (DiffUpdate)
  final bool forceUpdate;

  FlattenedEntry(this.value, this.forceUpdate);
}

class ConfigFlattenUtil {
  /// data: 通过 meta.toDb() 转换后的 Map
  /// rules: 通过 meta.buildUpdateMap() 返回的规则
  static Map<String, FlattenedEntry> flatten(
      Map<String, dynamic> data,
      Map<String, bool> rules,
      ) {
    final result = <String, FlattenedEntry>{};

    // 预处理通配符规则，提取父路径 (例如 "style.*" -> "style")
    final wildcardRules = <String, bool>{};
    rules.forEach((key, isFull) {
      if (key.endsWith('.*')) {
        wildcardRules[key.substring(0, key.length - 2)] = isFull;
      }
    });

    void recurse(String currentPath, dynamic currentValue) {
      // 1. 确定当前路径的策略
      bool? explicitStrategy = rules[currentPath]; // 精确匹配
      bool? wildcardStrategy; // 通配符匹配

      // 检查父级是否有通配符规则 (仅当当前不在 Root 时)
      if (currentPath.isNotEmpty) {
        final lastDot = currentPath.lastIndexOf('.');
        if (lastDot != -1) {
          final parent = currentPath.substring(0, lastDot);
          wildcardStrategy = wildcardRules[parent];
        } else {
          // 第一级 Key，没有父级点号，但要在 wildcardRules 查 root 级通配符(虽然通常 key.* 格式指 key 下的)
        }
      }

      // 2. 决定最终策略
      // 优先级: 精确规则 > 父级通配符规则 > 默认第一级 FullUpdate > 默认深层 DiffUpdate
      bool finalForceUpdate = false;

      if (explicitStrategy != null) {
        finalForceUpdate = explicitStrategy;
      } else if (wildcardStrategy != null) {
        finalForceUpdate = wildcardStrategy;
      } else {
        // 默认规则：第一级默认 FullUpdate (true)，深层默认 DiffUpdate (false)
        if (!currentPath.contains('.')) {
          finalForceUpdate = true;
        } else {
          finalForceUpdate = false;
        }
      }

      // 3. 判断是否需要递归展开
      // 展开条件：值是 Map AND (有明确规则 OR 是第一级 OR 命中通配符父级)
      // 简单处理：只要是 Map，且不是明确指定"不展开"(虽然规则里没体现不展开，通常 map 都会展开除非被视为叶子)，我们就尝试展开
      // 但为了匹配 key.* 逻辑，我们需要识别。

      bool shouldRecurse = false;
      if (currentValue is Map<String, dynamic>) {
        if (currentPath.isEmpty) {
          shouldRecurse = true; // Root 总是展开
        } else if (explicitStrategy != null) {
          shouldRecurse = true; // 规则中显式提到了 (如 'style': true)
        } else if (wildcardRules.containsKey(currentPath)) {
          shouldRecurse = true; // 它是通配符的父级 (如 'style' 对应 'style.*')
        } else if (wildcardStrategy != null) {
          shouldRecurse = true; // 它是通配符的子级 (如 'style.border' 对应 'style.*')
        }

        // 特殊修正：默认第一层 Map 都展开
        if (!currentPath.contains('.')) {
          shouldRecurse = true;
        }
      }

      if (shouldRecurse) {
        final map = currentValue as Map<String, dynamic>;
        for (final entry in map.entries) {
          final nextPath = currentPath.isEmpty
              ? entry.key
              : '$currentPath.${entry.key}';
          recurse(nextPath, entry.value);
        }
      } else {
        // 叶子节点 (或不需要展开的 Map)
        if (currentPath.isNotEmpty) {
          result[currentPath] = FlattenedEntry(currentValue, finalForceUpdate);
        }
      }
    }

    recurse('', data);
    return result;
  }

  /// 反展平：将扁平的 Map 还原为嵌套结构
  /// [flatMap] key: "style.color", value: "red"
  static Map<String, dynamic> unflatten(Map<String, dynamic> flatMap) {
    final result = <String, dynamic>{};

    for (final entry in flatMap.entries) {
      final path = entry.key;
      final value = entry.value;

      // 如果值为 null，通常意味着该字段被删除，不写入结果 Map
      if (value == null) continue;

      final keys = path.split('.');
      Map<String, dynamic> current = result;

      for (int i = 0; i < keys.length; i++) {
        final key = keys[i];
        final isLast = i == keys.length - 1;

        if (isLast) {
          current[key] = value;
        } else {
          // 如果当前层级不存在，或者不是 Map（可能是之前被作为叶子写入了），则初始化
          // 注意：这里简单的覆盖策略，假设路径设计是规范的
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

  /// 需要更新时间戳的 Key 集合
  final Set<String> keysToSync;

  ConfigDelta(this.deltaMap, this.keysToSync);

  bool get isEmpty => keysToSync.isEmpty;
}

class ConfigDiffTool {
  /// 纯函数：计算 Snapshot 和 NewConfig 之间的差异
  static ConfigDelta calculateDelta({
    required PropertyConfigMeta meta,
    required dynamic snapshot,
    required dynamic config,
    required Map<String, bool> rules,
  }) {
    // 1. 准备数据
    final snapMap = snapshot != null ? meta.toDb(snapshot) : <String, dynamic>{};
    final newMap = meta.toDb(config);
    // 使用新配置的结构作为规则

    // 2. 展平
    final snapFlat = ConfigFlattenUtil.flatten(snapMap, rules);
    final newFlat = ConfigFlattenUtil.flatten(newMap, rules);

    final deltaMap = <String, dynamic>{};
    final keysToSync = <String>{};

    // 3. 计算并集 Key
    final allKeys = {...newFlat.keys, ...snapFlat.keys};

    for (final key in allKeys) {
      final newEntry = newFlat[key];
      final snapEntry = snapFlat[key];

      bool needsSync = false;
      dynamic deltaValue;

      if (newEntry == null) {
        // Client 删除
        needsSync = true;
        deltaValue = null;
      } else if (snapEntry == null) {
        // Client 新增
        needsSync = true;
        deltaValue = newEntry.value;
      } else {
        // Client 修改 或 强制更新
        if (newEntry.forceUpdate || newEntry.value != snapEntry.value) {
          needsSync = true;
          deltaValue = newEntry.value;
        }
      }

      if (needsSync) {
        keysToSync.add(key);
        // 只有当由值变动（非 forceUpdate 导致的单纯时间戳更新）或者是删除时，才写入 deltaMap
        // 但为了简化 merge 逻辑，我们将所有 needsSync 的值都放入 deltaMap (除了仅强制更新值未变的场景)
        // 优化：如果值没变仅仅是 forceUpdate，merge 时覆盖也没关系
        deltaMap[key] = deltaValue;
      }
    }

    return ConfigDelta(deltaMap, keysToSync);
  }

  /// 纯函数：将 Delta 应用到数据库的原始 Map 上 (三路合并的核心)
  static Map<String, dynamic> mergeDeltaToDbConfig({
    required Map<String, dynamic> dbRawMap,
    required Map<String, dynamic> deltaMap,
    required Map<String, bool> rules,
  }) {
    // 1. 展平 DB 数据
    final dbFlatEntries = ConfigFlattenUtil.flatten(dbRawMap, rules);

    // 转换为纯 Value Map
    final dbFlatMap = <String, dynamic>{};
    for (var e in dbFlatEntries.entries) {
      dbFlatMap[e.key] = e.value.value;
    }

    // 2. 应用 Patch
    for (final entry in deltaMap.entries) {
      if (entry.value == null) {
        dbFlatMap.remove(entry.key); // 执行删除
      } else {
        dbFlatMap[entry.key] = entry.value; // 执行覆盖
      }
    }

    // 3. 反展平回 JSON 结构
    return ConfigFlattenUtil.unflatten(dbFlatMap);
  }
}