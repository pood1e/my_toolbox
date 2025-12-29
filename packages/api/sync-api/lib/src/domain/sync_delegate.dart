abstract class SyncDelegate {
  String get resourceId;

  Future<void> sync(int? cursor, Future<void> Function(int) cursorSaver);
}
