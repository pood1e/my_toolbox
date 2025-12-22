abstract class SyncService {
  Future<void> sync(String resourceId);
}

typedef TriggerSyncAction = Future<void> Function();
