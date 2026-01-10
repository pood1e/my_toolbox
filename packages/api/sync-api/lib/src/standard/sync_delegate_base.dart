import 'package:app_core/http.dart';
import 'package:drift/drift.dart';

import '../domain/sync_delegate.dart';

abstract class TransactionalResource {
  Future<T> syncTranscation<T>(Future<T> Function() action);
}

mixin SyncTransactionalDaoMixin<DB extends GeneratedDatabase> on DatabaseAccessor<DB>
    implements TransactionalResource {
  @override
  Future<T> syncTranscation<T>(Future<T> Function() action) {
    return transaction(action);
  }
}

mixin SyncTransactionalDbMixin on GeneratedDatabase
    implements TransactionalResource {
  @override
  Future<T> syncTranscation<T>(Future<T> Function() action) {
    return transaction(action);
  }
}

abstract class ResourceSelector<Db, Dao> {
  Dao selectResource(Db db, String key);
}

typedef ResourceBorrower<Res extends TransactionalResource> =
    Future<void> Function(Future<void> Function(Res resource));

abstract class SyncDelegateBase<Res extends TransactionalResource, Req, Resp>
    extends SyncDelegate {
  final Dio dio;
  final ResourceBorrower<Res> resourceUse;

  SyncDelegateBase({required this.dio, required this.resourceUse});
}
