import 'package:dio/dio.dart';

import '../../utils/wtf_logger.dart';

/// Logs every request/response with the [RTC] tag; WtfLog masks
/// token/secret values before they reach the buffer or console.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    WtfLog.d(LogTag.rtc,
        '→ ${options.method} ${options.path} ${options.queryParameters}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    WtfLog.d(LogTag.rtc,
        '← ${response.statusCode} ${response.requestOptions.path} ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    WtfLog.d(LogTag.rtc,
        '✗ ${err.requestOptions.path} ${err.type.name}: ${err.message}');
    handler.next(err);
  }
}
