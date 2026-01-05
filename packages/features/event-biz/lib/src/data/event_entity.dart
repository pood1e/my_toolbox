import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

part 'event_entity.freezed.dart';

@freezed
abstract class EventEntity
    with _$EventEntity, AuditEntity, SoftDeleteEntity
    implements LwwEntity {
  const EventEntity._();

  const factory EventEntity({
    required String id,
    required String name,
    required int timestamp,
    required String source,

    // Sync Meta
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    required int serverUpdatedAt,
    required bool isDirty,
  }) = _EventEntity;

  @override
  List<dynamic> get primaryKey => [id, source];
}
