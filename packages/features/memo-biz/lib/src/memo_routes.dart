import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'ui/screens/memo_list_screen.dart';

part 'memo_routes.g.dart';

@riverpod
List<RouteBase> memoRoutes(Ref ref) {
  return [GoRoute(path: '/memo', builder: (_, _) => MemoListScreen())];
}
