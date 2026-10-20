import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api.g.dart'; // gerado: dart run build_runner build --delete-conflicting-outputs

@RestApi(baseUrl: 'https://api.alertaseguro.example/v1') // TODO: troque pela URL do seu backend
abstract class Api {
  factory Api(Dio dio, {String? baseUrl}) = _Api;

  @GET('/occurrences')
  Future<List<dynamic>> getOccurrences(
      @Query('lat') double lat, @Query('lng') double lng, @Query('radius') int radius);

  @POST('/occurrences')
  Future<void> postOccurrence(@Body() Map<String, dynamic> body);

  @POST('/alerts')
  Future<void> postAlert(@Body() Map<String, dynamic> body);

  @POST('/auth/login')
  Future<Map<String, dynamic>> login(@Body() Map<String, dynamic> body);
}

Api buildApi() {
  final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
  return Api(dio);
}

final api = buildApi();
