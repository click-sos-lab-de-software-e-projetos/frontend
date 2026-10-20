import 'package:dio/dio.dart';

class Api {
  final Dio _dio;
  Api(this._dio);

  Future<List<dynamic>> getOccurrences(double lat, double lng, int radius) async {
    final r = await _dio.get('/occurrences',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radius});
    return r.data as List<dynamic>;
  }

  Future<void> postOccurrence(Map<String, dynamic> body) =>
      _dio.post('/occurrences', data: body);

  Future<void> postAlert(Map<String, dynamic> body) =>
      _dio.post('/alerts', data: body);

  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    final r = await _dio.post('/auth/login', data: body);
    return Map<String, dynamic>.from(r.data);
  }
}

Api buildApi() {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.alertaseguro.example/v1', // troque pela URL do seu backend
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  return Api(dio);
}

final api = buildApi();