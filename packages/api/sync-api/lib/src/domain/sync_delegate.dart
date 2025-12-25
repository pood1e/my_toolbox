import '../standard/sync_api_dto.dart';

abstract class SyncDelegate<T> {
  String get resourceId;

  Future<T?> load(int? cursor);

  /// 判断 Payload 是否为空 (用于避免发送空请求)
  bool isEmpty(T changes);

  Future<void> push(T change);

  Future<SyncPullResponse<T>> pull(int? cursor);

  bool needMerge(T pulled, T pushed);

  Future<void> merge(T change);
}
