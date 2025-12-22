import 'dart:io';

import 'package:auth_biz/auth_biz.dart';

import '../../scope/data_scope.dart';
import '../../scope/data_scope_impl.dart';
import '../data_path_service.dart';
import '../data_scope_service.dart';

class DataScopeServiceImpl implements DataScopeService {
  final DataPathService _pathService;
  final Map<String, DataScope> _activeScopes = {};

  DataScopeServiceImpl({required DataPathService pathService})
    : _pathService = pathService;

  @override
  Future<DataScope> getGuestScope() async {
    final path = _pathService.guestRoot;
    return await _getOrOpen('guest', path);
  }

  @override
  Future<DataScope> getUserScope(UserIdentity user) async {
    final path = _pathService.getUserRoot(user);
    return await _getOrOpen(user.hash, path);
  }

  Future<DataScope> _getOrOpen(String id, String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _activeScopes.putIfAbsent(
      id,
      () => DataScopeImpl(id: id, rootPath: path),
    );
  }

  @override
  Future<void> closeScope(String id) async {
    final scope = _activeScopes.remove(id);
    if (scope != null) {
      await scope.close();
    }
  }
}
