import 'package:dio/dio.dart';

class ApiService {
  final String baseUrl = "https://openlibrary.org/";
  final Dio _dio;

  ApiService(this._dio);

  Future<Map<String, dynamic>> getData({required String endPoint}) async {
    Response response = await _dio.get("$baseUrl$endPoint");
    return response.data;
  }

  Future<Map<String, dynamic>> fetchBookDetails(String workKey) async {
    String cleanKey = workKey.startsWith('/') ? workKey.substring(1) : workKey;
    return await getData(endPoint: "$cleanKey.json");
  }

  Future<Map<String, dynamic>> fetchBookRating(String workKey) async {
    String cleanKey = workKey.startsWith('/') ? workKey.substring(1) : workKey;
    return await getData(endPoint: "$cleanKey/ratings.json");
  }

  Future<Map<String, dynamic>> searchBooks(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    return await getData(endPoint: "search.json?q=$encodedQuery&limit=20");
  }

  Future<Map<String, dynamic>> fetchBooksBySubject(String subject) async {
    final cleanSubject = subject.toLowerCase().replaceAll(' ', '_');
    return await getData(endPoint: "subjects/$cleanSubject.json?limit=20");
  }
}
