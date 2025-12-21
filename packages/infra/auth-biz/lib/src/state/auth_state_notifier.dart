import 'package:core/di.dart';

import '../data/interfaces/auth_session_storage.dart';
import '../domain/remote_server.dart';
import '../data/local/local_storage_providers.dart';

part 'auth_state_notifier.g.dart';

mixin _AsyncStorageMixin<T> on $AsyncNotifier<T?> {
  /// 供 build() 调用，用于初始化加载
  Future<T?> _buildInternal() async {
    final store = await ref.read(authSessionStorageProvider.future);
    return _loadFromStorage(store);
  }

  Future<T?> _loadFromStorage(AuthSessionStorage storage);

  Future<void> save(T newT) async {
    state = AsyncValue.data(newT);
  }

  Future<void> clear() async {
    state = AsyncValue.data(null);
  }
}

@Riverpod(keepAlive: true)
class RemoteServerNotifier extends _$RemoteServerNotifier
    with _AsyncStorageMixin<RemoteServer> {
  @override
  Future<RemoteServer?> build() {
    return _buildInternal();
  }

  @override
  Future<RemoteServer?> _loadFromStorage(AuthSessionStorage storage) =>
      storage.getServer();
}

@Riverpod(keepAlive: true)
class AccessTokenNotifier extends _$AccessTokenNotifier
    with _AsyncStorageMixin<String> {
  @override
  Future<String?> build() {
    return _buildInternal();
  }

  @override
  Future<String?> _loadFromStorage(AuthSessionStorage storage) =>
      storage.getAccessToken();
}

@Riverpod(keepAlive: true)
class RefreshTokenNotifier extends _$RefreshTokenNotifier
    with _AsyncStorageMixin<String> {
  @override
  Future<String?> build() {
    return _buildInternal();
  }

  @override
  Future<String?> _loadFromStorage(AuthSessionStorage storage) =>
      storage.getRefreshToken();
}

@Riverpod(keepAlive: true)
class UserIdNotifier extends _$UserIdNotifier with _AsyncStorageMixin<String> {
  @override
  Future<String?> build() {
    return _buildInternal();
  }

  @override
  Future<String?> _loadFromStorage(AuthSessionStorage storage) =>
      storage.getUserId();
}

@Riverpod(keepAlive: true)
class RoleNotifier extends _$RoleNotifier with _AsyncStorageMixin<String> {
  @override
  Future<String?> build() {
    return _buildInternal();
  }

  @override
  Future<String?> _loadFromStorage(AuthSessionStorage storage) =>
      storage.getRole();
}
