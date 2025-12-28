abstract class SyncDelegate {
  String get resourceId;

  Future<int> sync(int? cursor);
}
