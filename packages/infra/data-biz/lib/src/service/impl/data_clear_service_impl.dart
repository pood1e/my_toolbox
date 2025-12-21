import 'package:auth_biz/auth_biz.dart';

import '../data_clear_service.dart';
import '../database_service.dart';

class DataClearServiceImpl implements DataClearService {
  final DatabaseService _databaseService;

  DataClearServiceImpl({required DatabaseService databaseService})
    : _databaseService = databaseService;

  @override
  Future<void> clearGuest() async {
    await _databaseService.clearGuest();
  }

  @override
  Future<void> clearUser(UserIdentity userId) async {
    await _databaseService.clearUser(userId);
  }
}
