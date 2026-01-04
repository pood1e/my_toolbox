import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'ui/timeline_screen.dart';

part 'event_routes.g.dart';

@riverpod
List<RouteBase> eventRoutes(Ref ref) {
  return [
    GoRoute(path: '/event/timeline', builder: (_, _) => TimelineScreen()),
  ];
}
