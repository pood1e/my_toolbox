import 'package:core/object.dart';

part 'remote_server.freezed.dart';
part 'remote_server.g.dart';

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
