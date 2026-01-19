import 'package:app_core/uuid.dart';
import 'package:framework_api/framework_api.dart';

import '../../data/note_repositories.dart';
import '../note_service.dart';

class NoteServiceImpl implements NoteService {
  final DocumentRepository _docRepository;
  final ServerTimeService _timeService;
  final Uuid _uuid = Uuid();

  NoteServiceImpl({
    required DocumentRepository docRepository,
    required ServerTimeService timeService,
  }) : _docRepository = docRepository,
       _timeService = timeService;

  @override
  Future<String> createDocument({
    required String title,
    required Map<String, dynamic> content,
  }) async {
    final id = _uuid.v4();
    await _docRepository.createDocument(
      id: id,
      title: title,
      content: content,
      nowMs: _timeService.nowMs,
    );
    return id;
  }

  @override
  Future<void> updateDocument({
    required String id,
    required String title,
    required Map<String, dynamic> content,
  }) {
    return _docRepository.updateDocument(
      id: id,
      title: title,
      content: content,
      nowMs: _timeService.nowMs,
    );
  }
}
