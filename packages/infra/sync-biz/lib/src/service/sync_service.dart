abstract class SyncService {
  Future<void> sync(String resourceId);

  bool get anySyncing;
}
