import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../../meta/property_meta_service.dart';
import '../../relation/relation_service.dart';
import '../../storage/ecs_database.dart';
import '../../sync/crdt_service.dart';
import '../../value/value_service.dart';
import '../config_service.dart';
import '../data/property_config_dao.dart';
import 'crdt_utils.dart';

class ConfigServiceImpl implements ConfigService {
  final PropertyConfigsDao _dao;
  final PropertyMetaService _metaService;
  final CrdtService _crdtService;
  final ServerTimeService _timeService;
  final ValueService _valueService;
  final RelationService _relationService;

  ConfigServiceImpl({
    required PropertyConfigsDao dao,
    required PropertyMetaService metaService,
    required CrdtService crdtService,
    required ServerTimeService timeService,
    required ValueService valueService,
    required RelationService relationService,
  }) : _dao = dao,
       _metaService = metaService,
       _crdtService = crdtService,
       _timeService = timeService,
       _valueService = valueService,
       _relationService = relationService;

  @override
  Future<void> create(PropertyId propertyId, dynamic config) async {
    final now = _timeService.nowMs;
    final meta = _metaService.getById(propertyId.metaId)!;

    if (meta is! PropertyConfigMeta) {
      return;
    }

    final dbMap = meta.toDb(config);
    final rules = meta.buildUpdateMap(config, null);

    final flattened = ConfigFlattenUtil.flatten(dbMap, rules);

    await _dao.transaction(() async {
      await _dao.insertConfig(
        PropertyConfigsCompanion.insert(
          nodeId: propertyId.nodeId,
          metaId: propertyId.metaId,
          config: dbMap,
          updatedAt: now,
          deletedAt: const Value(null),
          isDirty: const Value(true),
        ),
      );

      await _crdtService.upsert(
        flattened.keys
            .map(
              (key) => CrdtSync(
                propertyId: propertyId,
                syncKey: key,
                updatedAt: now,
              ),
            )
            .toList(),
      );

      Set<PropertyId> affects = {propertyId};
      final downstream = await _relationService.findAffects([propertyId]);
      affects.addAll(downstream);
      if (meta is PropertyRelationMeta) {
        final relations = meta.buildRelations(propertyId, config);
        await _relationService.create(relations);
      }
      if (meta is PropertyValueMeta) {
        await _valueService.markAsDirty(affects);
      }
    });
  }

  @override
  Future<void> update(
    PropertyId propertyId,
    dynamic snapshot,
    dynamic config,
  ) async {
    final meta = _metaService.getById(propertyId.metaId)!;

    if (meta is! PropertyConfigMeta) {
      return;
    }
    final rules = meta.buildUpdateMap(config, snapshot);
    final delta = ConfigDiffTool.calculateDelta(
      meta: meta,
      snapshot: snapshot,
      config: config,
      rules: rules,
    );

    if (delta.isEmpty) return;
    final now = _timeService.nowMs;

    await _dao.transaction(() async {
      final dbEntity = await _dao.findByNodeAndMeta(propertyId);
      final dbRawMap = dbEntity?.config ?? <String, dynamic>{};
      final mergedConfig = ConfigDiffTool.mergeDeltaToDbConfig(
        dbRawMap: dbRawMap,
        deltaMap: delta.deltaMap,
        rules: rules,
      );

      await _dao.updateConfig(
        propertyId,
        PropertyConfigsCompanion(
          config: Value(mergedConfig),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );

      if (delta.keysToSync.isNotEmpty) {
        await _crdtService.upsert(
          delta.keysToSync
              .map(
                (key) => CrdtSync(
                  propertyId: propertyId,
                  syncKey: key,
                  updatedAt: now,
                ),
              )
              .toList(),
        );
      }
      Set<PropertyId> affects = {propertyId};
      final downstream = await _relationService.findAffects([propertyId]);
      affects.addAll(downstream);
      if (meta is PropertyRelationMeta) {
        final relations = meta.buildRelations(propertyId, config);
        await _relationService.replaceById(propertyId, relations);
      }
      if (meta is PropertyValueMeta) {
        await _valueService.markAsDirty(affects);
      }
    });
  }

  @override
  Future<void> delete(PropertyId id) async {
    final now = _timeService.nowMs;
    final meta = _metaService.getById(id.metaId)!;
    await _dao.transaction(() async {
      await _dao.softDeleteById(id, now);
      await _crdtService.softDelete(id, now);
      if (meta is PropertyRelationMeta) {
        final downstream = await _relationService.findAffects([id]);
        await _valueService.markAsDirty(downstream);
        await _relationService.deleteById(id);
      }
      if (meta is PropertyValueMeta) {
        await _valueService.delete(id);
      }
    });
  }

  @override
  Future<dynamic> get(PropertyId propertyId) async {
    final meta = _metaService.getById(propertyId.metaId)!;
    if (meta is! PropertyConfigMeta) {
      return null;
    }
    final config = await _dao.findByNodeAndMeta(propertyId);
    if (config == null) {
      return null;
    }
    return meta.fromDb(config.config);
  }

  @override
  Stream<dynamic> watch(PropertyId propertyId) async* {
    final meta = _metaService.getById(propertyId.metaId)!;
    if (meta is! PropertyConfigMeta) {
      yield null;
    } else {
      yield* _dao.watchByProperty(propertyId).map((config) {
        if (config == null) {
          return null;
        }
        return meta.fromDb(config.config);
      });
    }
  }

  @override
  Stream<Set<String>> watchMetasByNode(String nodeId) =>
      _dao.watchPropertiesByNode(nodeId);

  @override
  Future<Set<PropertyId>> checkExist(Set<PropertyId> propertyIds) =>
      _dao.checkExist(propertyIds);

  @override
  Future<void> batchApply(List<ConfigBatchOp> operations) async {
    if (operations.isEmpty) return;

    final now = _timeService.nowMs;

    // 开启事务：保证增删改的原子性
    await _dao.transaction(() async {
      // --- 1. 准备阶段：收集器 ---
      final List<CrdtSync> crdtSyncsToUpsert = [];

      // 最终所有需要标记为 Dirty 的节点 (包含自身 + 影响到的下游)
      final Set<PropertyId> allDirtyIds = {};

      // 分类收集 ID，用于批量图计算
      final List<PropertyId> idsToDelete = [];
      final List<PropertyId> idsToUpdateRelations = [];

      // --- 2. 预处理 (Pre-Process)：处理删除的副作用 ---
      // 对于删除操作，必须在"关系被物理删除前"查找受影响的下游，
      // 否则一旦删了关系表，就再也找不到谁依赖这个节点了。
      for (final op in operations) {
        if (op is ConfigBatchOpDelete) {
          idsToDelete.add(op.propertyId);
          // 删除操作本身会让该节点变为 Dirty (因为值没了)
          allDirtyIds.add(op.propertyId);
        }
      }

      if (idsToDelete.isNotEmpty) {
        // 【关键】在删除前，找出所有依赖这些即将删除节点的下游
        final deleteImpacts = await _relationService.findAffects(idsToDelete);
        allDirtyIds.addAll(deleteImpacts);
      }

      // --- 3. 执行阶段 (Execution)：处理 DB 和内存逻辑 ---
      for (final op in operations) {
        final propertyId = op.propertyId;
        final meta = _metaService.getById(propertyId.metaId);

        // 如果 Meta 丢失或不匹配，跳过
        if (meta is! PropertyConfigMeta) continue;

        // === 分发处理 ===
        await op.map(
          create: (createOp) async {
            // [Create 逻辑]
            final dbMap = meta.toDb(createOp.config);
            final rules = meta.buildUpdateMap(createOp.config, null);
            final flattened = ConfigFlattenUtil.flatten(dbMap, rules);

            // 1. DB Insert
            await _dao.insertConfig(
              PropertyConfigsCompanion.insert(
                nodeId: propertyId.nodeId,
                metaId: propertyId.metaId,
                config: dbMap,
                updatedAt: now,
                deletedAt: const Value(null),
                isDirty: const Value(true),
              ),
            );

            // 2. CRDT
            crdtSyncsToUpsert.addAll(
              flattened.keys.map(
                (key) => CrdtSync(
                  propertyId: propertyId,
                  syncKey: key,
                  updatedAt: now,
                ),
              ),
            );

            // 3. Relations & Dirty
            if (meta is PropertyRelationMeta) {
              final relations = meta.buildRelations(
                propertyId,
                createOp.config,
              );
              await _relationService.create(relations);
              // 暂时不查图，等所有 update/create 结束后统一查
              idsToUpdateRelations.add(propertyId);
            }
            if (meta is PropertyValueMeta) {
              allDirtyIds.add(propertyId);
            }
          },
          update: (updateOp) async {
            // [Update 逻辑]
            final rules = meta.buildUpdateMap(
              updateOp.config,
              updateOp.snapshot,
            );
            final delta = ConfigDiffTool.calculateDelta(
              meta: meta,
              snapshot: updateOp.snapshot,
              config: updateOp.config,
              rules: rules,
            );

            if (delta.isEmpty) return; // 无变化直接跳过

            final dbEntity = await _dao.findByNodeAndMeta(propertyId);
            final dbRawMap = dbEntity?.config ?? <String, dynamic>{};
            final mergedConfig = ConfigDiffTool.mergeDeltaToDbConfig(
              dbRawMap: dbRawMap,
              deltaMap: delta.deltaMap,
              rules: rules,
            );

            // 1. DB Update
            await _dao.updateConfig(
              propertyId,
              PropertyConfigsCompanion(
                config: Value(mergedConfig),
                updatedAt: Value(now),
                isDirty: const Value(true),
              ),
            );

            // 2. CRDT
            if (delta.keysToSync.isNotEmpty) {
              crdtSyncsToUpsert.addAll(
                delta.keysToSync.map(
                  (key) => CrdtSync(
                    propertyId: propertyId,
                    syncKey: key,
                    updatedAt: now,
                  ),
                ),
              );
            }

            // 3. Relations & Dirty
            if (meta is PropertyRelationMeta) {
              final relations = meta.buildRelations(
                propertyId,
                updateOp.config,
              );
              await _relationService.replaceById(propertyId, relations);
              // 记录下来，稍后统一查图
              idsToUpdateRelations.add(propertyId);
            }
            if (meta is PropertyValueMeta) {
              allDirtyIds.add(propertyId);
            }
          },
          delete: (deleteOp) async {
            // [Delete 逻辑]
            // 1. DB Soft Delete
            await _dao.softDeleteById(propertyId, now);

            // 2. CRDT Soft Delete
            await _crdtService.softDelete(propertyId, now);

            // 3. Relations
            if (meta is PropertyRelationMeta) {
              await _relationService.deleteById(propertyId);
            }
            if (meta is PropertyValueMeta) {
              await _valueService.delete(propertyId);
            }
            // 注意：Delete 的 findAffects 已经在第 2 步预处理做完了
          },
        );
      }

      // --- 4. 收尾阶段 (Post-Calculation) ---

      // 4.1 批量插入 CRDT
      if (crdtSyncsToUpsert.isNotEmpty) {
        await _crdtService.upsert(crdtSyncsToUpsert);
      }

      // 4.2 计算 Create/Update 的图影响
      // 对于新增和修改关系的情况，必须在关系写入 DB 后（现在）查询图，才能得到最新的下游
      if (idsToUpdateRelations.isNotEmpty) {
        final updateImpacts = await _relationService.findAffects(
          idsToUpdateRelations,
        );
        allDirtyIds.addAll(updateImpacts);
      }

      // 4.3 终极批量标记 Dirty
      if (allDirtyIds.isNotEmpty) {
        await _valueService.markAsDirty(allDirtyIds);
      }
    });
  }
}
