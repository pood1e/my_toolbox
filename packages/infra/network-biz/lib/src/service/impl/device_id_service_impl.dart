import 'package:app_core/uuid.dart';
import 'package:network_api/network_api.dart';

import '../../data/install_id_storage.dart';

class DeviceIdServiceImpl extends DeviceIdService {
  final InstallIdStorage _installIdStorage;
  String? _deviceId;

  DeviceIdServiceImpl({required InstallIdStorage installIdStorage})
    : _installIdStorage = installIdStorage;

  @override
  Future<String> getDeviceId() async {
    if (_deviceId != null) {
      return _deviceId!;
    }
    _deviceId = await _installIdStorage.getInstallId();
    if (_deviceId != null) {
      return _deviceId!;
    }
    _deviceId = nanoid();
    await _installIdStorage.saveInstallId(_deviceId!);
    return _deviceId!;
  }
}
