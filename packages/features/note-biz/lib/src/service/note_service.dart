import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

import '../data/note_repositories.dart';
import 'impl/note_service_impl.dart';

part 'note_service.freezed.dart';
part 'note_service.g.dart';

abstract class NoteService {
  Future<String> createDocument({
    required String title,
    required Map<String, dynamic> content,
  });

  Future<void> updateDocument({
    required String id,
    required String title,
    required Map<String, dynamic> content,
  });

  Future<List<DocSearchResult>> searchByKeyword(String keyword);

  Future<List<DocSearchResult>> searchBySemantic(String semantic);

  Future<List<DocSearchResult>> searchHybrid(String text);
}

@freezed
abstract class DocSearchResult with _$DocSearchResult {
  const factory DocSearchResult({
    required String id,
    required String title,
    required List<BlockSearchResult> blocks,
  }) = _DocSearchResult;
}

@freezed
abstract class BlockSearchResult with _$BlockSearchResult {
  const factory BlockSearchResult({
    required String id,
    required String content,
    @Default(false) bool isSemanticOnly,
  }) = _BlockSearchResult;
}

@riverpod
Future<NoteService> noteService(Ref ref) async {
  return NoteServiceImpl(
    docRepository: await ref.watch(documentRepositoryProvider.future),
    timeService: await ref.watch(serverTimeServiceProvider.future),
    textEncoder: await ref.watch(textEncoderProvider.future),
  );
}
