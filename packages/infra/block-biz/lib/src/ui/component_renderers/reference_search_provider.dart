import 'package:app_core/di.dart';

import '../../data/node_database.dart';
import '../../domain/config_spec.dart';
import '../../domain/property.dart';
import '../../supports/config_spec_registry.dart';
import '../../supports/property_descriptor_registry.dart';

// 根据你的项目结构调整 import

part 'reference_search_provider.g.dart';

/// 搜索结果模型：按 Node 分组的 Property 列表
typedef ReferenceCandidates = Map<String, List<String>>;

@riverpod
Future<ReferenceCandidates> referenceCandidates(
  Ref ref, {
  required PropertyKey propertyKey,
  required String specId,
}) async {
  // 1. 获取 Spec 描述符
  final specDescriptor = ref.watch(configSpecDescriptorProvider(specId));

  // 检查是否支持引用 (HasTransformers 是你在 domain/config_spec.dart 定义的接口)
  if (specDescriptor is! HasTransformers) {
    return {};
  }

  // 强转以访问 HasTransformers 接口成员
  final refSpec = specDescriptor as HasTransformers;

  // --- L1: 基于 Transformer 的输入类型 (sTypeId) 进行筛选 ---
  // 获取所有 transformer 支持的源数据类型
  final supportedSourceTypes = refSpec.transformerMap.values
      .map((t) => t.sTypeId)
      .toSet();

  // 获取系统中所有的属性定义
  final allPropDefs = ref.watch(propertyDefinitionsProvider);

  // 找出 dataType 符合 sTypeId 的属性定义 ID
  Set<String> validDefIds = allPropDefs
      .where((def) => supportedSourceTypes.contains(def.dateTypeId))
      .map((def) => def.propertyId)
      .toSet();

  // --- L2: 如果 spec 定义了白名单 (propertyIds)，取交集 ---
  if (refSpec.propertyIds.isNotEmpty) {
    validDefIds = validDefIds.intersection(refSpec.propertyIds);
  }

  if (validDefIds.isEmpty) {
    return {};
  }

  // --- 3. 数据库查询 ---
  final db = await ref.watch(nodeDatabaseProvider.future);

  // 查询 property_atom_configs 表
  // 逻辑：只要节点上有在这个 validDefIds 列表里的配置，就认为该节点拥有该属性
  final query = db.select(db.propertyAtomConfigs)
    ..where((t) => t.defId.isIn(validDefIds))
    ..where((t) => t.nodeId.isNotValue(propertyKey.nodeId)); // 排除自身

  // 只选取 nodeId 和 defId 去重
  final results = await query.get();

  // --- 4. 分组 ---
  final ReferenceCandidates grouped = {};
  for (final row in results) {
    if (!grouped.containsKey(row.nodeId)) {
      grouped[row.nodeId] = [];
    }
    // 简单的防重 (虽然 DB 层面应该唯一，但保险起见)
    if (!grouped[row.nodeId]!.contains(row.defId)) {
      grouped[row.nodeId]!.add(row.defId);
    }
  }

  return grouped;
}
