import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../repository/repository_providers.dart';
import 'event_sync_delegate.dart';

part 'sync_delegate_provider.g.dart';

@Riverpod(keepAlive: true)
Future<EventSyncDelegate> eventSyncDelegate(Ref ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return EventSyncDelegate(
    daoUse: (action) async {
      final sub = ref.listen(eventDaoProvider, (prev, next) {});
      try {
        final dao = await ref.read(eventDaoProvider.future);
        await action(dao);
      } finally {
        sub.close();
      }
    },
    dio: dio,
  );
}
