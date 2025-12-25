import '../domain/sync_delegate.dart';
import 'sync_api_dto.dart';
import 'sync_standard_api.dart';

/// 通用同步委托基类
abstract class SyncStandardDelegate<T> implements SyncDelegate<T> {
  final SyncStandardApi<T> _api;

  SyncStandardDelegate({required SyncStandardApi<T> api}) : _api = api;

  @override
  Future<void> push(T changes) async {
    await _api.push(changes);
  }

  @override
  Future<SyncPullResponse<T>> pull(int? cursor) async {
    return await _api.pull(cursor);
  }
}
