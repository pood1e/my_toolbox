// test/mocks.dart
import 'package:auth_biz/src/data/interfaces/auth_remote_api.dart';
import 'package:auth_biz/src/data/interfaces/auth_session_storage.dart';
import 'package:auth_biz/src/state/auth_state_notifier.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';

// 使用 @GenerateNiceMocks 生成宽容的 Mock 对象
@GenerateNiceMocks([
  MockSpec<AuthRemoteApi>(),
  MockSpec<TokenRemoteApi>(),
  MockSpec<AuthSessionStorage>(),
  MockSpec<ConnectionAvailabiltyNotifier>(),
  MockSpec<FlutterSecureStorage>(),
])
void main() {}
