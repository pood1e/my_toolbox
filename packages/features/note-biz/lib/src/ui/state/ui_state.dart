import 'package:app_core/di.dart';

import '../../data/note_repositories.dart';
import '../../note_domain.dart';
import '../../service/note_service.dart';

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

enum SearchType {
  hybrid,   // 默认：混合双打
  keyword,  // 仅关键词
  semantic, // 仅语义
}

@riverpod
class SearchTypeState extends _$SearchTypeState {
  @override
  SearchType build() => SearchType.hybrid; // 默认改为混合

  /// 循环切换模式
  void toggle() {
    state = switch (state) {
      SearchType.hybrid => SearchType.keyword,
      SearchType.keyword => SearchType.semantic,
      SearchType.semantic => SearchType.hybrid,
    };
  }
}

@riverpod
class SearchKeyword extends _$SearchKeyword {
  @override
  String build() {
    return ''; // 初始状态为空字符串
  }

  // 提供一个方法供 UI 调用来更新状态
  void set(String query) {
    state = query;
  }
}

@riverpod
Future<List<DocSearchResult>> searchResult(Ref ref) async {
  final keyword = ref.watch(searchKeywordProvider);
  final type = ref.watch(searchTypeStateProvider);

  if (keyword.trim().isEmpty) return [];

  final service = await ref.watch(noteServiceProvider.future);

  return switch (type) {
    SearchType.hybrid => service.searchHybrid(keyword),
    SearchType.keyword => service.searchByKeyword(keyword),
    SearchType.semantic => service.searchBySemantic(keyword),
  };
}