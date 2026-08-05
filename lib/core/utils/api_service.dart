import 'package:dio/dio.dart';
import 'package:libris_app/constants/api_constants.dart';
import 'package:libris_app/core/errors/failure.dart';

class ApiService {
  final String baseUrl = "https://www.googleapis.com/books/v1/volumes?";
  final String apiKey = ApiConstants.apiKey;
  final Dio _dio;

  ApiService({required this._dio});

  Future<Map<String, dynamic>> getData({required String endPoint}) async {
    String url = "$baseUrl$endPoint&key=$apiKey";
    try {
      Response response = await _dio.get(url);
      return response.data;
    } on DioException catch (e) {
      throw ServerFailure.fromDioError(e);
    }
  }
}
