import 'package:app_core/uuid.dart';
import 'package:drift/drift.dart';
import 'package:network_api/network_api.dart';

import '../dao/core_sync_table.dart';
import '../dao/generic_lww_sync_dao.dart';

/// 泛型核心同步仓库接口
/// [DomainModel]: 领域对象 (e.g. Activity, Plan)
/// [Companion]: Drift 生成的 Companion 类，用于创建
abstract class CoreSyncRepository<D, Companion extends Insertable> {
  /// 获取单个活跃实体
  Future<D?> getById(String id);

  /// 更新一个已存在的实体
  /// 基类实现会自动注入 updatedAt, isDirty
  Future<void> update(D model);

  /// 软删除一个实体
  Future<void> delete(String id);
}

/// 泛型仓库基类实现
///
/// [DomainModel]: 领域对象 (e.g. Activity)
/// [DbEntity]: Drift 生成的实体类 (e.g. ActivityEntity)
/// [DbTable]: Drift 表定义类 (e.g. Activities)
/// [Companion]: Drift 生成的 Companion 类 (e.g. ActivitiesCompanion)
/// [Dao]: 对应的 DAO 类 (必须混入 StandardLwwSyncDaoMixin)
abstract class CoreSyncRepositoryBase<
D,
DbEntity extends DataClass,
DbTable extends CoreSyncTable,
Companion extends Insertable<DbEntity>,
Dao extends StandardLwwSyncDaoMixin<dynamic, DbTable, DbEntity>>
    implements CoreSyncRepository<D, Companion> {

  final Dao dao;
  final ServerTimeService timeService;
  final Uuid uuid;

  D Function(DbEntity) get toDomain;
  UpdateCompanion<DbEntity> Function(D) get toCompanion;

  CoreSyncRepositoryBase({
    required this.dao,
    required this.timeService,
  }) : uuid = const Uuid();

  /// 🔒 私有辅助: 将 DAO 中的 TableInfo 强转为表定义 DbTable
  /// 运行时 DAO 中的 table 是 $ActivitiesTable，它继承自 Activities (DbTable)，所以转换是安全的
  DbTable get _table => dao.table as DbTable;

  @override
  Future<D?> getById(String id) async {
    // 使用 _table 访问 id 和 deletedAt
    final query = dao.select(dao.table)
      ..where((_) => _table.id.equals(id))
      ..where((_) => _table.deletedAt.isNull());

    final entity = await query.getSingleOrNull();
    return entity != null ? toDomain(entity as DbEntity) : null;
  }

  @override
  Future<void> delete(String id) async {
    final now = timeService.nowMs;
    await dao.deleteLocal(id, now);
  }
}