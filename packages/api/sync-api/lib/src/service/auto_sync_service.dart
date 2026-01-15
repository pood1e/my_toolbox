abstract class AutoSyncService {
  void markSync(
    String resourceId, {
    Duration debounce = const Duration(seconds: 5),
  });

  void flushPending(String resourceId);
}
