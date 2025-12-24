import 'package:app_core/http.dart';

import '../api/sync_envelopes.dart';
import '../api/sync_remote_api.dart';
import 'sync_delegate.dart';

/// 通用同步委托基类
abstract class BaseSyncDelegate<T> implements SyncDelegate<T> {
  final SyncRemoteApi<T> _api;

  BaseSyncDelegate({required SyncRemoteApi<T> api}) : _api = api;

  @override
  Future<void> push(T changes) async {
    await _api.push(changes);
  }

  @override
  Future<SyncPullResponse<T>> pull(int? cursor) async {
    return await _api.pull(cursor);
  }
}

abstract class StandardSyncDelegate<T> extends BaseSyncDelegate<T> {
  StandardSyncDelegate({
    required Dio dio,
    required String apiPath,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) : super(
    api: SyncRemoteApi<T>(
      dio: dio,
      apiPath: apiPath,
      fromJson: fromJson,
      toJson: toJson,
    ),
  );
}
