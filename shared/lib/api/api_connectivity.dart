import 'package:dio/dio.dart';

import '../utils/app_exception.dart';
import '../utils/app_strings.dart';
import 'api_endpoints.dart';

/// Pre-flight reachability check against the token server.
/// Throws [AppException] with human copy when unreachable.
class ApiConnectivity {
  final Dio _dio;
  ApiConnectivity(this._dio);

  Future<void> ensureReachable() async {
    try {
      await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.health,
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
    } on DioException catch (e) {
      throw AppException(AppStrings.noConnection, e);
    }
  }
}
