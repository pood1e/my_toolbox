import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import 'service/event_service.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Future<EventService> eventService(Ref ref) {
  throw NotOverrideError();
}
