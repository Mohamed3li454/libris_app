import 'package:dio/dio.dart';

class ApiService {
  final String baseUrl = "https://openlibrary.org/";
  final Dio _dio;

  ApiService(this._dio);

  Future<Map<String, dynamic>> getData({required String endPoint}) async {
    Response response = await _dio.get("$baseUrl$endPoint");
    return response.data;
  }
}
