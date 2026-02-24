import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../config/config_service.dart';
import '../meta/property_meta_service.dart';
import 'data/relation_dao.dart';
import 'impl/relation_service_impl.dart';

part 'relation_service.freezed.dart';
part 'relation_service.g.dart';

@freezed
abstract class RelationData with _$RelationData {
  const factory RelationData({
    required PropertyId dst,
    required RelationType type,
  }) = _RelationData;

  factory RelationData.fromJson(Map<String, dynamic> json) =>
      _$RelationDataFromJson(json);
}

@freezed
abstract class PropertyRelation with _$PropertyRelation {
  const factory PropertyRelation({
    required PropertyId src,
    required PropertyId dst,
    required RelationType type,
  }) = _PropertyRelation;
}

mixin PropertyRelationMeta<C> on PropertyConfigMeta<C> {
  List<PropertyRelation> buildRelations(PropertyId self, C config);
}

enum RelationType {
  lock(affectValue: true),
  dependency(affectValue: true),
  mark(affectValue: false);

  final bool affectValue;

  const RelationType({required this.affectValue});
}

abstract class RelationService {
  Future<Set<PropertyId>> findAffects(List<PropertyId> srcIds);

  Stream<Set<PropertyId>> watchAffects(PropertyId id);

  Future<void> create(List<PropertyRelation> relations);

  Future<void> replaceById(PropertyId id, List<PropertyRelation> relations);

  Future<void> deleteById(PropertyId id);
}

@riverpod
Future<RelationService> relationService(Ref ref) async {
  final dao = await ref.watch(relationDaoProvider.future);
  return RelationServiceImpl(dao);
}

@riverpod
Stream<Set<PropertyId>> watchAffects(Ref ref, PropertyId propertyId) async* {
  final srv = await ref.watch(relationServiceProvider.future);
  yield* srv.watchAffects(propertyId);
}
