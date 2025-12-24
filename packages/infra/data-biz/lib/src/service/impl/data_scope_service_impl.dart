import 'dart:io';

import 'package:data_api/data_api.dart';
import 'package:path/path.dart';

import '../../scope/data_scope_impl.dart';
import '../data_scope_service.dart';

class DataScopeServiceImpl implements DataScopeService {
  final String _root;
  final Map<String, DataScope> _activeScopes = {};

  DataScopeServiceImpl({required String root}) : _root = root;

  @override
  Future<void> close(String id) async {
    final scope = _activeScopes.remove(id);
    if (scope != null) {
      await scope.close();
    }
  }

  @override
  Future<DataScope> get(String id) async {
    final path = join(_root, id);
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _activeScopes.putIfAbsent(id, () => DataScopeImpl(scopePath: path));
  }

  @override
  Future<void> delete(String id) async {
    final scope = await get(id);
    await close(id);
    await scope.delete();
  }
}
