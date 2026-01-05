import 'package:app_core/di.dart';
import 'package:event_api/event_api.dart';
import 'package:framework_api/framework_api.dart';

import 'repository/repository_providers.dart';
import 'service/event_service_impl.dart';

class EventApiOverride {
  EventApiOverride._();

  static Future<EventService> eventService(Ref ref) async {
    final repo = await ref.watch(eventRepositoryProvider.future);
    final service = await ref.watch(serverTimeServiceProvider.future);
    return EventServiceImpl(repository: repo, serverTimeService: service);
  }
}
