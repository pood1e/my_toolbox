import 'package:app_core/di.dart';

import '../../data/note_repositories.dart';
import '../../note_domain.dart';

part 'ui_state.g.dart';

// 只负责读取文档数据
@riverpod
Future<Document?> document(Ref ref, String id) async {
  final repo = await ref.watch(documentRepositoryProvider.future);
  return await repo.getDocument(id);
}

@riverpod
Stream<List<Document?>> inboxDocuments(Ref ref) async* {
  final repo = await ref.watch(documentRepositoryProvider.future);
  yield* repo.watchDocumentsByStatus(DocumentStatus.inbox);
}
