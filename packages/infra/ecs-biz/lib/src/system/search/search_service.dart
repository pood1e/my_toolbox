import 'package:app_core/di.dart';

import '../meta/property_meta_service.dart';
import '../value/value_service.dart';
import 'data/search_dao.dart';
import 'impl/search_service_impl.dart';

part 'search_service.g.dart';

mixin PropertySearchMeta on PropertyValueMeta {
  bool get searchable => false;
}

abstract class SearchService {
  Stream<Set<PropertyId>> watchPropertyIdsByMetas(
    Set<String> metas,
    Set<PropertyId> exculdes,
  );
}

@riverpod
Future<SearchService> searchService(Ref ref) async {
  final dao = await ref.watch(searchDaoProvider.future);
  return SearchServiceImpl(dao: dao);
}
