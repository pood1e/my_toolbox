import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'supports/page_renderers/node_list/node_list_page.dart';
import 'supports/page_renderers/node_renderer_dispatchor.dart';

part 'test_routes.g.dart';

@riverpod
List<RouteBase> blockRoutes(Ref ref) => [
  GoRoute(path: '/node', builder: (_, _) => const NodeListPage()),

  GoRoute(
    path: '/node/:id',
    builder: (_, state) {
      final id = state.pathParameters['id']!;
      final dispatchor = NodeRendererDispatchor();
      return dispatchor.render(id);
    },
  ),
];
