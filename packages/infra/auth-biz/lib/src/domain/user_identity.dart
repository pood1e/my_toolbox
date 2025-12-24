import 'dart:convert';

import 'package:app_core/crypto.dart';
import 'package:app_core/object.dart';

part 'user_identity.freezed.dart';
part 'user_identity.g.dart';

@freezed
abstract class UserIdentity with _$UserIdentity {
  const UserIdentity._();

  const factory UserIdentity({
    required String userId,
    required RemoteServer server,
  }) = _UserIdentity;

  String get hash {
    return md5
        .convert(utf8.encode('${server.host}:${server.port}_$userId'))
        .toString()
        .substring(0, 16);
  }
}

@freezed
abstract class RemoteServer with _$RemoteServer {
  const RemoteServer._();

  const factory RemoteServer({
    required String host,
    required int port,
    required bool tls,
  }) = _RemoteServer;

  factory RemoteServer.fromJson(Map<String, dynamic> json) =>
      _$RemoteServerFromJson(json);

  String get baseUrl {
    final scheme = tls ? 'https' : 'http';
    // 标准端口 (80, 443) 可以省略显示，但带上也无妨
    return '$scheme://$host:$port';
  }
}
