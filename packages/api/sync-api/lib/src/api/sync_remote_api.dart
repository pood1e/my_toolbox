import 'package:core/http.dart';
import 'package:core/object.dart';

import 'sync_envelopes.dart';

class SyncRemoteApi<T> {
  final Dio _dio;
  final String _apiPath;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;

  SyncRemoteApi({
    required Dio dio,
    required String apiPath,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  }) : _dio = dio,
       _apiPath = apiPath,
       _fromJson = fromJson,
       _toJson = toJson;

  /// 推送变更
  Future<void> push(T t) async {
    final req = SyncPushRequest(payload: t);
    await _dio.post('$_apiPath/push', data: req.toJson((t) => _toJson(t)));
  }

  /// 拉取变更
  Future<SyncPullResponse> pull(int? cursor) async {
    final response = await _dio.get(
      '$_apiPath/pull',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );

    final data = R<SyncPullResponse>.fromJson(
      response.data,
      (json) => SyncPullResponse.fromJson(
        json as Map<String, dynamic>,
        (tJson) => _fromJson(tJson as Map<String, dynamic>),
      ),
    );
    return data.data!;
  }
}
