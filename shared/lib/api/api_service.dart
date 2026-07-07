import 'package:dio/dio.dart';

import '../utils/app_exception.dart';
import '../utils/app_strings.dart';
import 'api_endpoints.dart';
import 'api_params.dart';
import 'api_service_interface.dart';
import 'interceptor/logging_interceptor.dart';

/// Dio implementation of [ApiServiceInterface]. Singleton — both apps
/// use [ApiService.instance].
class ApiService implements ApiServiceInterface {
  ApiService._(this._dio);

  static final ApiService instance = ApiService._(
    Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ))
      ..interceptors.add(LoggingInterceptor()),
  );

  final Dio _dio;

  @override
  Future<RtcCredentials> getAuthToken({
    required String userId,
    required String role,
    required String roomId,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.token,
        queryParameters: {
          ApiParams.userId: userId,
          ApiParams.role: role,
          ApiParams.roomId: roomId,
        },
      );
      final data = res.data!;
      return RtcCredentials(
        token: data[ApiParams.token] as String,
        appId: data[ApiParams.appId] as String,
        uid: data[ApiParams.uid] as int,
      );
    } on DioException catch (e) {
      throw AppException(AppStrings.tokenFetchFailed, e);
    }
  }

  @override
  Future<String> createRoom(String name) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.room,
        data: {ApiParams.name: name},
      );
      return res.data![ApiParams.roomId] as String;
    } on DioException catch (e) {
      throw AppException(AppStrings.roomCreateFailed, e);
    }
  }
}
