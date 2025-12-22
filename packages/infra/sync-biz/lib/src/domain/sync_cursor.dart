import 'package:core/object.dart';

part 'sync_cursor.freezed.dart';
part 'sync_cursor.g.dart';

@freezed
abstract class SyncCursor with _$SyncCursor {
  const factory SyncCursor({
    int? cursor,
    int? lastSyncedAt,
  }) = _SyncCursor;

  factory SyncCursor.fromJson(Map<String, dynamic> json) =>
      _$SyncCursorFromJson(json);
}
