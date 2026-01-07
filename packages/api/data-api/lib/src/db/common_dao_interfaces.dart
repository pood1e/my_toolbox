import 'package:drift/drift.dart';

abstract class PrimaryKeyDao {
  Expression<bool> whereById(List<dynamic> ids);
}

abstract class CommonDao<E> {
  Future<void> upsert(Insertable<E> entry);

  Future<bool> updateIfExist(Insertable<E> entry);

  Future<bool> createIfNotExist(Insertable<E> entry);
}
