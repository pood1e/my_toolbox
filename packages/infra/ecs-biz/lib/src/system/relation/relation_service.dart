import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../meta/property_meta_service.dart';
import 'data/relation_dao.dart';
import 'impl/relation_service_impl.dart';

part 'relation_service.freezed.dart';
part 'relation_service.g.dart';

@freezed
abstract class RelationData with _$RelationData {
  const factory RelationData({
    required String dstNode,
    required String dstMeta,
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

mixin PropertyRelationMeta on PropertyMeta {
  List<PropertyRelation> buildRelations(dynamic config);
}

enum RelationType {
  lock(affectValue: true),
  dependency(affectValue: true),
  mark(affectValue: false);

  final bool affectValue;

  const RelationType({required this.affectValue});
}

abstract class RelationService {
  Future<List<PropertyId>> findAffects(List<PropertyId> srcIds);

  Future<void> create(List<PropertyRelation> relations);

  Future<void> replaceById(PropertyId id, List<PropertyRelation> relations);

  Future<void> deleteById(PropertyId id);
}

@riverpod
Future<RelationService> relationService(Ref ref) async {
  final dao = await ref.watch(relationDaoProvider.future);
  return RelationServiceImpl(dao);
}
