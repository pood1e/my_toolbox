import 'package:app_core/http.dart';

class AuthInterceptor extends QueuedInterceptor {
  final String _baseUrl;
  final Future<String> Function() _accessGetter;
  final Future<void> Function() _refresh;

  AuthInterceptor({
    required String baseUrl,
    required Future<String> Function() accessGetter,
    required Future<void> Function() refresh,
  }) : _baseUrl = baseUrl,
       _accessGetter = accessGetter,
       _refresh = refresh;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.baseUrl = _baseUrl;
    final accessToken = await _accessGetter();
    options.headers['Authorization'] = 'Bearer $accessToken';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        await _refresh();
        final newToken = await _accessGetter();

        // retry
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        opts.baseUrl = _baseUrl;
        final dio = Dio();
        final cloneReq = await dio.fetch(opts);

        return handler.resolve(cloneReq);
      } catch (e) {
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}
