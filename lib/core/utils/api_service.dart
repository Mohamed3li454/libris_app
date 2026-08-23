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

  Future<Map<String, dynamic>> fetchTrendingBooks({int limit = 50}) async {
    return await getData(endPoint: "trending/weekly.json?limit=$limit");
  }

  Future<Map<String, dynamic>> searchBooks(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final encodedQuery = Uri.encodeComponent(query);
    return await getData(
      endPoint: "search.json?q=$encodedQuery&limit=$limit&page=$page",
    );
  }

  Future<Map<String, dynamic>> fetchBooksBySubject(
    String subject, {
    int page = 1,
    int limit = 20,
  }) async {
    final cleanSubject = subject.toLowerCase().replaceAll(' ', '_');
    final int offset = (page - 1) * limit;
    return await getData(
      endPoint: "subjects/$cleanSubject.json?limit=$limit&offset=$offset",
    );
  }
}
