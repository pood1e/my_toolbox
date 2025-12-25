import 'package:drift/drift.dart';

extension DriftSyncHelper on DatabaseConnectionUser {
  /// 智能合并：基于 Companion 直接操作
  ///
  /// [table]: Drift 表定义
  /// [companion]: 待插入的数据 (由 DTO.toCompanion() 生成)
  /// [newId]: 这条数据的主键 ID (用于查重)
  /// [businessKeyFilter]: (可选) 业务主键查重条件
  Future<void> mergeCompanion<T extends DataClass, tbl extends Table>({
    required TableInfo<tbl, T> table,
    required UpdateCompanion<T> companion,
    required String newId,
    Expression<bool> Function(tbl)? businessKeyFilter,
  }) async {
    // 1. 双重检查 (仅当提供了业务查重条件时)
    if (businessKeyFilter != null) {
      final conflictingRow =
          await (select(table)
                ..where((t) => businessKeyFilter(t))
                // 假设所有同步表的主键都叫 'id'
                ..where((t) => (t as dynamic).id.isNotValue(newId)))
              .getSingleOrNull();

      if (conflictingRow != null) {
        // 删除本地冲突的旧数据
        final dynamic oldId = (conflictingRow as dynamic).id;
        await (delete(
          table,
        )..where((t) => (t as dynamic).id.equals(oldId))).go();
      }
    }

    // 2. 正常插入或更新
    await into(table).insertOnConflictUpdate(companion);
  }
}
