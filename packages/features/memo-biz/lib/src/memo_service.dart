import 'dart:convert';

import 'package:app_core/crypto.dart';
import 'package:app_core/di.dart';
import 'package:app_core/uuid.dart';
import 'package:drift/drift.dart';
import 'package:event_api/event_api.dart';
import 'package:framework_api/framework_api.dart';

import 'data/memo_database.dart';
import 'memo_repository.dart';

part 'memo_service.g.dart';

// =============================================================================
// 1. 抽象接口 (Interface)
// UI 层只应该看到这个
// =============================================================================
abstract class MemoService {
  /// 创建 Memo
  Future<void> createMemo(String content);

  /// 更新 Memo
  Future<void> updateMemo(String id, String newContent);

  /// 归档 Memo
  Future<void> archiveMemo(String id);

  /// 取消归档 Memo
  Future<void> unarchiveMemo(String id);

  /// 删除 Memo
  Future<void> deleteMemo(String id);
}

class MemoServiceImpl implements MemoService {
  final MemoRepository _repository;
  final EventService _eventService;
  final ServerTimeService _serverTimeService;
  final Uuid _uuid = const Uuid();

  MemoServiceImpl({
    required MemoRepository repository,
    required EventService eventService,
    required ServerTimeService serverTimeService,
  }) : _repository = repository,
       _eventService = eventService,
       _serverTimeService = serverTimeService;

  @override
  Future<void> createMemo(String content) async {
    if (content.trim().isEmpty) return;

    final id = _uuid.v4();
    final timestamp = _serverTimeService.nowMs;

    await _repository.saveMemo(
      id: id,
      content: content,
      contentHash: _calculateHash(content),
      now: timestamp,
    );
    await _createEvent('create memo:$id, content:$content', timestamp);
  }

  @override
  Future<void> updateMemo(String id, String newContent) async {
    // 业务优化：可以在这里先判断内容是否为空
    if (newContent.trim().isEmpty) {
      // 尝试删除
      await deleteMemo(id);
    }
    final timestamp = _serverTimeService.nowMs;
    await _repository.saveMemo(
      id: id,
      content: newContent,
      contentHash: _calculateHash(newContent),
      now: timestamp,
    );
    await _createEvent('update memo:$id, content:$newContent', timestamp);
  }

  @override
  Future<void> archiveMemo(String id) async {
    final timestamp = _serverTimeService.nowMs;
    await _repository.toggleArchive(id, true, timestamp);
    await _createEvent('archive memo:$id', timestamp);
  }

  @override
  Future<void> unarchiveMemo(String id) async {
    final timestamp = _serverTimeService.nowMs;
    await _repository.toggleArchive(id, false, timestamp);
    await _createEvent('unarchive memo:$id', timestamp);
  }

  @override
  Future<void> deleteMemo(String id) async {
    final timestamp = _serverTimeService.nowMs;
    await _repository.deleteMemo(id, timestamp);
    await _createEvent('delete memo:$id', timestamp);
  }

  /// 内部方法：计算 MD5
  String _calculateHash(String content) {
    return md5.convert(utf8.encode(content)).toString();
  }

  Future<void> _createEvent(String message, int timestamp) async {
    await _eventService.createEvent(
      name: message,
      source: 'memo',
      timestamp: timestamp,
    );
  }
}

@riverpod
Future<MemoService> memoService(Ref ref) async {
  final repo = await ref.watch(memoRepositoryProvider.future);
  final serverTimeService = await ref.watch(serverTimeServiceProvider.future);
  final eventService = await ref.watch(eventServiceProvider.future);
  return MemoServiceImpl(
    repository: repo,
    eventService: eventService,
    serverTimeService: serverTimeService,
  );
}