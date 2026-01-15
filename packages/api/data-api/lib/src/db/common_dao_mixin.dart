import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'common_dao_interfaces.dart';

mixin TableInfoMixin<T extends Table, E>
    implements ColumnFinder, TableGetter<T, E> {
  @override
  @protected
  GeneratedColumn<C> findColumn<C extends Object>(String name) {
    return table.$columns.firstWhere(
          (c) => c.name == name,
          orElse: () => throw ArgumentError(
            'Column "$name" not found in ${table.actualTableName}',
          ),
        )
        as GeneratedColumn<C>;
  }
}

mixin PrimaryKeyDaoMixin<T extends Table, E> on TableGetter<T, E>
    implements PrimaryKeyDao {
  /// 根据主键自动生成 Where 条件
  /// [ids] 列表中的顺序必须与 Table 定义主键的顺序一致
  @override
  Expression<bool> whereById(List<dynamic> ids) {
    // 1. 将 Set 转为 List，以便通过下标访问
    // Dart 的 Set 默认保留插入顺序，所以这与 Table 定义的顺序是一致的
    final pkColumns = table.primaryKey.toList();

    // 2. 校验参数数量
    if (pkColumns.length != ids.length) {
      throw ArgumentError(
        'Table "${table.actualTableName}" expects ${pkColumns.length} primary keys '
        '(${pkColumns.map((e) => e.name).join(', ')}), '
        'but got ${ids.length} arguments.',
      );
    }

    // 3. 动态构建 AND 条件
    Expression<bool>? predicate;

    for (int i = 0; i < pkColumns.length; i++) {
      final column = pkColumns[i];
      final value = ids[i];

      // 使用 GeneratedColumn.equals (支持 dynamic 类型自动适配)
      final comparison = column.equals(value);

      if (predicate == null) {
        predicate = comparison;
      } else {
        // 使用 & 运算符连接多个主键条件 (composite key)
        predicate = predicate & comparison;
      }
    }

    // 防御性编程：如果没有主键 (极为罕见)
    if (predicate == null) {
      // 如果真的有无主键表，为了防止 delete whereById([]) 变成全表删除，
      // 这里抛出异常更安全。或者返回 const Constant(false)
      throw StateError(
        'Table "${table.actualTableName}" has no primary key defined.',
      );
    }

    return predicate;
  }
}

mixin GetOneDaoMixin<DB extends GeneratedDatabase, T extends Table, E>
    on PrimaryKeyDao, DatabaseAccessor<DB>, TableGetter<T, E>
    implements GetOneDao<E> {
  @override
  Future<E?> getById(List<dynamic> id) async {
    return await (select(table)..where((_) => whereById(id))).getSingleOrNull();
  }
}

mixin CommonDaoMixin<DB extends GeneratedDatabase, T extends Table, E>
    on DatabaseAccessor<DB>, PrimaryKeyDaoMixin<T, E>
    implements CommonDao<E>, TableGetter<T, E> {
  @override
  Future<void> upsert(Insertable<E> entry) async {
    await into(table).insert(entry, onConflict: DoUpdate((old) => entry));
  }

  @override
  Future<bool> updateIfExist(List<dynamic> id, Insertable<E> entry) async {
    final query = update(table)..where((_) => whereById(id));
    return (await query.write(entry)) > 0;
  }

  @override
  Future<bool> createIfNotExist(Insertable<E> entry) async {
    return (await into(table).insert(entry, mode: InsertMode.insertOrIgnore)) >
        0;
  }
}
