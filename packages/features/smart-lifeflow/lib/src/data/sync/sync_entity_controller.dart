import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../dtos/sync_dtos.dart';
import '../lifeflow_database.dart';

/// 全能同步控制器 (配置化 & 无状态化改造)
/// 现在它主要充当"配置容器"，具体的 DB 操作在方法调用时传入 db 实例
class SyncEntityController<
  T extends Table,
  D,
  DTO,
  C extends UpdateCompanion<D>
> {
  // --- 1. 动态获取器 (不再持有 DAO 实例) ---
  final GenericLwwSyncDaoMixin<LifeflowDatabase, T, D> Function(
    LifeflowDatabase,
  )
  daoGetter;
  final Future<int> Function(LifeflowDatabase)? gcAction;

  // --- 2. 静态配置 ---
  final String key; // JSON Key

  // 转换逻辑
  final DTO Function(D) toDto;
  final C Function(DTO) toCompanion;
  final Map<String, dynamic> Function(DTO) toJson;

  // 映射逻辑
  final String Function(D) getId;
  final String Function(C) getCompId;
  final int Function(D) getUpdatedAt;
  final int Function(C) getCompServerTime;

  final List<DTO> Function(SyncPayload) pullSelector;

  // --- 3. 运行时状态 (Stateful per sync session) ---
  // 注意: 假定 Sync 是串行执行的。如果并发，需将这些状态封装为 Context 对象返回
  List<DTO> _pushDtos = [];
  Map<String, int> _snapshot = {};
  int _cursor = 0;

  SyncEntityController({
    required this.daoGetter, // 🆕 传入 getter 而不是实例
    required this.key,
    required this.toDto,
    required this.toCompanion,
    required this.toJson,
    required this.getId,
    required this.getCompId,
    required this.getUpdatedAt,
    required this.getCompServerTime,
    required this.pullSelector,
    this.gcAction, // 🆕
  });

  // ===========================================================================
  // Phase 1: 准备 (Prepare) - 需传入 DB
  // ===========================================================================

  Future<void> prepare(LifeflowDatabase db) async {
    // 运行时获取 DAO
    final dao = daoGetter(db);

    final dirtyItems = await dao.getDirtyItems();
    _cursor = await dao.getMaxCursor();

    _snapshot = {for (var item in dirtyItems) getId(item): getUpdatedAt(item)};

    _pushDtos = dirtyItems.map(toDto).toList();
  }

  // 获取 Payload 片段
  MapEntry<String, int> get cursorEntry => MapEntry(key, _cursor);

  MapEntry<String, List<Map<String, dynamic>>> get pushJsonEntry {
    final jsonList = _pushDtos.map((dto) => toJson(dto)).toList();
    return MapEntry(key, jsonList);
  }

  // ===========================================================================
  // Phase 2: 响应处理 - 需传入 DB
  // ===========================================================================

  Future<void> handleResponse(
    LifeflowDatabase db,
    SyncResponse response,
  ) async {
    final dao = daoGetter(db); // 运行时获取 DAO

    // 1. Ack
    final acks = response.ackedIds?[key];
    if (acks != null && acks.isNotEmpty) {
      await dao.markSynced(acks, _snapshot);
    }

    // 2. Pull
    if (response.changes != null) {
      final remoteDtos = pullSelector(response.changes!);
      if (remoteDtos.isNotEmpty) {
        final companions = remoteDtos.map(toCompanion).toList();
        await dao.applyRemote(
          companions,
          getId: getCompId,
          getServerUpdatedAt: getCompServerTime,
        );
      }
    }
  }

  // ===========================================================================
  // Phase 3: GC - 需传入 DB
  // ===========================================================================

  Future<void> performGc(LifeflowDatabase db) async {
    if (gcAction != null) {
      await gcAction!(db);
    }
  }
}
