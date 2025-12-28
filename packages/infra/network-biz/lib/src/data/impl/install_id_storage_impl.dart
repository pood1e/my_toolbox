import 'package:data_api/data_api.dart';

import '../install_id_storage.dart';

class InstallIdStorageImpl implements InstallIdStorage {
  final KVStore _store;
  static const _installKey = 'install';

  InstallIdStorageImpl({required KVStore store}) : _store = store;

  @override
  Future<String?> getInstallId() async {
    return await _store.getString(_installKey);
  }

  @override
  Future<void> saveInstallId(String uid) async {
    await _store.saveString(_installKey, uid);
  }
}
