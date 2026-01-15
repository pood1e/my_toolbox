import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'repository/repository_providers.dart';

part 'providers.g.dart';

@riverpod
Future<void> eventChangesListener(Ref ref) async {
  final db = await ref.watch(eventDatabaseProvider.future);

  final sub = db.tableUpdates(TableUpdateQuery.onTable(db.events)).listen((
    updates,
  ) async {
    if (await ref.read(autoSyncEnabledProvider.future)) {
      final autoSyncService = await ref.watch(autoSyncServiceProvider.future);
      autoSyncService.markSync('event');
    }
  });

  ref.onDispose(() {
    sub.cancel();
  });
}
