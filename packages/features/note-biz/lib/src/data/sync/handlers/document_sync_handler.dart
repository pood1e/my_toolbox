import 'package:framework_api/framework_api.dart';

import '../../note_daos.dart';
import '../../note_database.dart';
import '../note_dtos.dart';
import '../sync_mappers.dart';

class DocumentSyncHandler
    extends
        CocSyncHandler<
          NoteDatabase,
          Documents,
          DocumentEntity,
          SimpleCocSnapshot,
          DocumentDto,
          SimpleCocAck,
          DocumentDao
        >
    implements
        CompositeSyncHandler<
          DocumentDao,
          CommonSyncRequestPart<DocumentDto>,
          CommonSyncResponsePart<SimpleCocAck, DocumentDto>
        > {
  @override
  DocumentDto fromEntity(DocumentEntity entity) {
    return entity.toDto();
  }

  @override
  SimpleCocAck fromJsonACK(Map<String, dynamic> json) {
    return SimpleCocAck.fromJson(json);
  }

  @override
  DocumentDto fromJsonP(Map<String, dynamic> json) {
    return DocumentDto.fromJson(json);
  }

  @override
  SimpleCocSnapshot fromPayload(DocumentDto payload) {
    return SimpleCocSnapshot(id: payload.id, updatedAt: payload.updatedAt);
  }

  @override
  Map<String, dynamic> payloadToJson(DocumentDto payload) {
    return payload.toJson();
  }

  @override
  String get key => 'document';
}
