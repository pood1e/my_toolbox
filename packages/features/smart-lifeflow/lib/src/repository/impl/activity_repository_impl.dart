import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../../data/daos/reality_daos.dart';
import '../../data/lifeflow_database.dart';
import '../../data/mapper/reality_domain_mapper.dart';
import '../../data/tables/reality_tables.dart';
import '../../domain/reality_models.dart';
import '../reality_repositories.dart';

class ActivityRepositoryImpl
    extends
        CoreSyncRepositoryBase<
          Activity, // DomainModel
          ActivityEntity, // DbEntity
          Activities, // DbTable
          ActivitiesCompanion, // Companion
          ActivityDao // Dao
        >
    implements ActivityRepository {
  ActivityRepositoryImpl({required super.dao, required super.timeService});

  // ===========================================================================
  // 1. 抽象实现 (提供转换器)
  // ===========================================================================

  @override
  Activity Function(ActivityEntity) get toDomain =>
      (e) => e.toDomain();

  @override
  ActivitiesCompanion Function(Activity) get toCompanion =>
      (d) => d.toCompanion();

  // ===========================================================================
  // 2. 接口实现 (业务方法)
  // ===========================================================================

  @override
  Future<String> createActivity({
    required String name,
    String? icon,
    String? colorHex,
  }) async {
    final now = timeService.nowMs;
    final id = uuid.v4();

    // 1. 构建一个包含所有必填字段的 Companion
    final companion = ActivitiesCompanion.insert(
      // 业务字段
      name: name,
      icon: Value(icon),
      colorHex: Value(colorHex),
      id: id,
      createdAt: Value(now),
      updatedAt: now,
      isDirty: const Value(true),
    );

    // 2. 调用 DAO 的通用保存方法
    await dao.saveLocal(companion, now);

    return id;
  }

  @override
  Stream<List<Activity>> watchAll() {
    return dao.watchAll().map(
      (entities) => entities.map((e) => e.toDomain()).toList(),
    );
  }

  @override
  Future<void> update(Activity model) async {
    final now = timeService.nowMs;

    // 1. 使用具体的 ActivitiesCompanion，它有 copyWith 方法
    final companion = model.toCompanion();

    // 2. 注入最新的 Sync Meta
    final fullCompanion = companion.copyWith(
      updatedAt: Value(now),
      isDirty: const Value(true),
    );

    // 3. 保存
    await dao.saveLocal(fullCompanion, now);
  }
}
