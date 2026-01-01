abstract class SyncDelegate {
  String get resourceId;

  Future<void> sync();
}
