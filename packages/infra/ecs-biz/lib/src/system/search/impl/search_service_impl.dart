import '../../meta/property_meta_service.dart';
import '../data/search_dao.dart';
import '../search_service.dart';

class SearchServiceImpl implements SearchService {
  final SearchDao _dao;

  SearchServiceImpl({required SearchDao dao}) : _dao = dao;

  @override
  Stream<Set<PropertyId>> watchPropertyIdsByMetas(
    Set<String> metas,
    Set<PropertyId> exculdes,
  ) => _dao
      .watchPropertiesByMetas(metas)
      .map((result) => result.difference(exculdes).toSet());
}
