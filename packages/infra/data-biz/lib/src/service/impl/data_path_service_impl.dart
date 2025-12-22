import 'package:auth_biz/auth_biz.dart';
import 'package:path/path.dart';

import '../data_path_service.dart';

class DataPathServiceImpl implements DataPathService {
  static const _data = 'my-toolbox';
  static const _guestScope = 'guest';

  final String _root;

  DataPathServiceImpl({required String storagePath})
    : _root = join(storagePath, _data);

  @override
  String get guestRoot => join(_root, _guestScope);

  @override
  String get root => _root;

  @override
  String getUserRoot(UserIdentity userId) => join(_root, userId.hash);
}
