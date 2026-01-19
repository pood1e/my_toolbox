import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../note_database.dart';
import 'handlers/document_sync_handler.dart';

part 'note_sync_delegate.g.dart';

class NoteSyncDelegate extends CompositeSyncDelegate<NoteDatabase> {
  NoteSyncDelegate({required super.dio, required super.resourceUse})
    : super(handlers: [DocumentSyncHandler()]);

  @override
  String get resourceId => 'note';

  @override
  selectResource(NoteDatabase db, String key) {
    return switch (key) {
      'document' => db.documents,
      String() => throw UnimplementedError(),
    };
  }
}

@Riverpod(keepAlive: true)
Future<NoteSyncDelegate> noteSyncDelegate(Ref ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return NoteSyncDelegate(
    dio: dio,
    resourceUse: (action) async {
      final sub = ref.listen(noteDatabaseProvider, (prev, next) {});
      try {
        final db = await ref.read(noteDatabaseProvider.future);
        await action(db);
      } finally {
        sub.close();
      }
    },
  );
}
