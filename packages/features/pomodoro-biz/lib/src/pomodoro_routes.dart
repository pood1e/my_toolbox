import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'ui/screen/pomodoro_main_screen.dart';

part 'pomodoro_routes.g.dart';

@riverpod
List<RouteBase> pomodoroRoutes(Ref ref) {
  return [GoRoute(path: '/pomodoro', builder: (_, _) => PomodoroMainScreen())];
}
