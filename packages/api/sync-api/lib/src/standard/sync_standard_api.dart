import 'sync_api_dto.dart';

abstract class SyncStandardApi<T> {
  Future<void> push(T t);

  Future<SyncPullResponse<T>> pull(int? cursor);
}
