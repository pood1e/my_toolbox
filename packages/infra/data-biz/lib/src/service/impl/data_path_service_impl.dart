import 'dart:convert';

import 'package:auth_biz/auth_biz.dart';
import 'package:core/crypto.dart';
import 'package:path/path.dart';

import '../data_path_service.dart';

class DataPathServiceImpl implements DataPathService {
  static const _data = 'my-toolbox';
  static const _gusetScope = 'guest';

  final String _root;

  DataPathServiceImpl({required String storagePath})
    : _root = join(storagePath, _data);

  @override
  String getUserRoot(String userId, RemoteServer server) {
    final scope = md5
        .convert(utf8.encode('${server.host}:${server.port}_$userId'))
        .toString()
        .substring(0, 16);
    return join(_root, scope);
  }

  @override
  String get guestRoot => join(_root, _gusetScope);

  @override
  String get root => _root;
}
