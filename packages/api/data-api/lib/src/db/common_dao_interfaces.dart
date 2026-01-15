import 'package:drift/drift.dart';

abstract class ColumnFinder {
  GeneratedColumn<C> findColumn<C extends Object>(String name);
}

abstract class TableGetter<T extends Table, E> {
  TableInfo<T, E> get table;
}

abstract class PrimaryKeyDao {
  Expression<bool> whereById(List<dynamic> ids);
}

abstract class CommonDao<E> {
  Future<void> upsert(Insertable<E> entry);

  Future<bool> updateIfExist(Insertable<E> entry);

  Future<bool> createIfNotExist(Insertable<E> entry);
}

abstract class GetOneDao<E> {
  Future<E?> getById(List<dynamic> id);
}
