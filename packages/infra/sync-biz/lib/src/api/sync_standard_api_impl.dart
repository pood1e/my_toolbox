import 'package:app_core/http.dart';
import 'package:app_core/object.dart';
import 'package:sync_api/sync_api.dart';

class SyncStandardApiImpl<T> extends SyncStandardApi<T> {
  final Dio _dio;
  final String _apiPath;
  final FromJson<T> _fromJson;
  final ToJson<T> _toJson;

  SyncStandardApiImpl({
    required Dio dio,
    required String apiPath,
    required FromJson<T> fromJson,
    required ToJson<T> toJson,
  }) : _dio = dio,
       _apiPath = apiPath,
       _fromJson = fromJson,
       _toJson = toJson;

  @override
  Future<void> push(T t) async {
    final req = SyncPushRequest(payload: t);
    final json = req.toJson((t) => _toJson(t));
    await _dio.post('$_apiPath/push', data: json);
  }

  @override
  Future<SyncPullResponse<T>> pull(int? cursor) async {
    final response = await _dio.get(
      '$_apiPath/pull',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );

    final data = R<SyncPullResponse<T>>.fromJson(
      response.data,
      (json) => SyncPullResponse<T>.fromJson(
        json as Map<String, dynamic>,
        (tJson) => _fromJson(tJson as Map<String, dynamic>),
      ),
    );
    return data.data as SyncPullResponse<T>;
  }
}
