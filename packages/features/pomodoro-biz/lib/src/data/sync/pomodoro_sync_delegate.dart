import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../pomodoro_database.dart';
import 'pomodoro_session_sync_handler.dart';
import 'pomodoro_sync_handler.dart';

part 'pomodoro_sync_delegate.g.dart';

class PomodoroSyncDelegate extends CompositeSyncDelegate<PomodoroDatabase> {
  PomodoroSyncDelegate({required super.dio, required super.resourceUse})
    : super(handlers: [PomodoroSyncHandler(), PomodoroSessionSyncHandler()]);

  @override
  String get resourceId => 'pomodoro';

  @override
  selectResource(PomodoroDatabase db, String key) {
    return switch (key) {
      'pomodoro' => db.pomodoroDao,
      'session' => db.pomodoroSessionDao,
      String() => throw UnimplementedError(),
    };
  }
}

@Riverpod(keepAlive: true)
Future<PomodoroSyncDelegate> pomodoroSyncDelegate(Ref ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return PomodoroSyncDelegate(
    dio: dio,
    resourceUse: (action) async {
      final sub = ref.listen(pomodoroDatabaseProvider, (prev, next) {});
      try {
        final db = await ref.read(pomodoroDatabaseProvider.future);
        await action(db);
      } finally {
        sub.close();
      }
    },
  );
}
