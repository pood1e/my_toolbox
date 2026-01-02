import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'ui/screens/activity_management_screen.dart';

part 'route.g.dart';

@riverpod
List<RouteBase> lifeflowRoutes(Ref ref) {
  return [
    GoRoute(path: '/lifeflow', builder: (_, _) => ActivityManagementScreen()),
  ];
}
