import 'package:drift/drift.dart';

import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import 'property_config_crdt.dart';

part 'crdt_dao.g.dart';

/// DAO: 负责数据存取
@DriftAccessor(tables: [PropertyConfigCrdts])
class CrdtDao extends DatabaseAccessor<EcsDatabase> with _$CrdtDaoMixin {
  CrdtDao(super.db);

  /// 批量更新或插入 CRDT 记录 (Upsert)
  Future<void> upsertBatch(List<PropertyConfigCrdtsCompanion> rows) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(propertyConfigCrdts, rows);
    });
  }

  Future<void> softDeleteByPropertyId(PropertyId id, int deletedAt) =>
      (update(propertyConfigCrdts)..where(
            (t) => t.metaId.equals(id.metaId) & t.nodeId.equals(id.nodeId),
          ))
          .write(PropertyConfigCrdtsCompanion(deletedAt: Value(deletedAt)));
}
