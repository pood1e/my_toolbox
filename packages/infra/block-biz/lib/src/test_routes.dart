import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'ui/dispatchor/node_renderer_dispatchor.dart';
import 'ui/page_renderers/node_list/node_list_page.dart';

part 'test_routes.g.dart';

@riverpod
List<RouteBase> blockRoutes(Ref ref) {
  return [
    GoRoute(
      path: '/node',
      builder: (_, _) {
        return NodeListPage();
      },
    ),

    GoRoute(
      path: '/node/:id',
      builder: (_, state) {
        final id = state.pathParameters['id']!;
        final dispatchor = NodeRendererDispatchor();
        return dispatchor.render(id);
      },
    ),
  ];
}
