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
  }) {
    final now = timeService.nowMs;

    // 1. 构建只包含业务和审计字段的 Companion
    // ✅ 核心修正: 在这里手动设置 createdAt
    final companion = ActivitiesCompanion.insert(
      id: '',
      name: name,
      icon: Value(icon),
      colorHex: Value(colorHex),
      createdAt: now,
      updatedAt: now,
    );

    // 2. 调用基类的 create 方法
    // super.create 会自动处理 id, updatedAt, isDirty 的注入
    return super.create(companion);
  }

  @override
  Stream<List<Activity>> watchAll() {
    return dao.watchAll().map(
      (entities) => entities.map((e) => e.toDomain()).toList(),
    );
  }

  // watchAll, getById, update, delete 方法都已由 CoreSyncRepositoryBase 自动实现
}
