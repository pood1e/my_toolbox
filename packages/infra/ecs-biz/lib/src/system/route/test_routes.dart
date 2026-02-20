import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import '../ui/component_widget.dart';
import '../ui/components/basic/reuse_widget.dart';
import '../ui/components/page/node_editor.dart';

part 'test_routes.g.dart';

@riverpod
List<RouteBase> ecsRoutes(Ref ref) => [
  GoRoute(
    path: '/node',
    builder: (_, _) => const ReuseWidget(
      config: ReuseComponentConfig(
        componentId: 'node_list',
        type: WidgetType.page,
        config: null,
      ),
    ),
  ),

  GoRoute(
    path: '/node/:id',
    builder: (_, state) => ReuseWidget(
      config: ReuseComponentConfig(
        componentId: 'node_editor',
        type: WidgetType.page,
        config: NodeEditorConfig(nodeId: state.pathParameters['id']!),
      ),
    ),
  ),
];
