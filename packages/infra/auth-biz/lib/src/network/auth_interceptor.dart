import 'package:app_core/http.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Future<String> Function() _accessGetter;
  final Future<String> Function() _baseUrlGetter;
  final Future<void> Function() _refresh;

  AuthInterceptor({
    required Future<String> Function() accessGetter,
    required Future<void> Function() refresh,
    required Future<String> Function() baseUrlGetter,
  }) : _accessGetter = accessGetter,
       _refresh = refresh,
       _baseUrlGetter = baseUrlGetter;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.baseUrl = await _baseUrlGetter();
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
        opts.baseUrl = await _baseUrlGetter();
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
