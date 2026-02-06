import 'package:app_core/di.dart';

import '../data/daos/property_dao.dart';
import '../domain/property.dart';
import '../domain/stored_value.dart';
import 'impl/property_repository_impl.dart';

part 'property_repository.g.dart';

abstract class PropertyRepository {
  Stream<List<Property>> watchProperties(Map<PropertyKey, StorageType> typeMap);

  Stream<Property?> watchSingle(PropertyKey key, StorageType type);
}

@riverpod
Future<PropertyRepository> propertyRepository(Ref ref) async {
  final dao = await ref.watch(propertyDaoProvider.future);
  return PropertyRepositoryImpl(dao: dao);
}
