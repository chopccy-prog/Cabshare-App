import 'package:dio/dio.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.7:5000', // Emulator -> backend running on host
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
  ));

  static Dio get dio => _dio;
}
