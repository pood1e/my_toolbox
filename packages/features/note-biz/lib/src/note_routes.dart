import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'ui/page/document_editor_page.dart';
import 'ui/page/inbox_page.dart';

part 'note_routes.g.dart';

@riverpod
List<RouteBase> noteRoutes(Ref ref) {
  return [
    GoRoute(path: '/note/inbox', builder: (_, _) => InboxPage()),
    GoRoute(
      path: '/note/document/:id',
      builder: (context, state) {
        // 从路径参数中获取 id
        final id = state.pathParameters['id'];

        // 核心逻辑：约定 'new' 字符串代表新建 (null)
        // 如果是真实 ID，则传入 ID
        final docId = (id == 'new') ? null : id;

        return DocumentEditorPage(documentId: docId);
      },
    ),
  ];
}
