
import 'package:app_core/object.dart';

part 'memo_domain.freezed.dart';
part 'memo_domain.g.dart';

@freezed
abstract class MemoDomain with _$MemoDomain {
  const factory MemoDomain({
    required String id,
    required String content,
    required DateTime updatedAt,
    required DateTime createdAt,
    @Default(true) bool isDirty,
    @Default(false) bool isArchived,
  }) = _MemoDomain;

  factory MemoDomain.fromJson(Map<String, dynamic> json) =>
      _$MemoDomainFromJson(json);
}