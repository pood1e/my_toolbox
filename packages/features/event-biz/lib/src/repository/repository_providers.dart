import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../data/event_dao.dart';
import '../data/event_database.dart';
import '../providers.dart';
import 'event_repository.dart';
import 'impl/event_repository_impl.dart';

part 'repository_providers.g.dart';

@riverpod
Future<EventDatabase> eventDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(DatabaseId('event', (e) => EventDatabase(e))).future,
  );
}

@riverpod
Future<EventDao> eventDao(Ref ref) async {
  return EventDao(await ref.watch(eventDatabaseProvider.future));
}

@riverpod
Future<EventRepository> eventRepository(Ref ref) async {
  final dao = await ref.watch(eventDaoProvider.future);
  ref.watch(eventChangesListenerProvider);
  return EventRepositoryImpl(dao: dao);
}
