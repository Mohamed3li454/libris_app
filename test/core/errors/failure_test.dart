import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/core/errors/failure.dart';

void main() {
  group('ServerFailure', () {
    test('fromDioError for each DioExceptionType', () {
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.connectionTimeout)).errMessage, contains('timeout'));
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.sendTimeout)).errMessage, contains('timeout'));
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.receiveTimeout)).errMessage, contains('timeout'));
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.badCertificate)).errMessage, contains('certificate'));
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.cancel)).errMessage, contains('canceled'));
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.connectionError)).errMessage, contains('No internet connection'));
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.unknown, error: const SocketException(''))).errMessage, contains('No internet connection'));
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.unknown)).errMessage, contains('Unexpected network error'));
      expect(ServerFailure.fromDioError(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.badResponse, response: Response(requestOptions: RequestOptions(path: ''), statusCode: 500))).errMessage, contains('Internal server error'));
    });

    test('fromResponse for status codes', () {
      expect(ServerFailure.fromResponse(400, null).errMessage, 'Authentication or request error. Please try again.');
      expect(ServerFailure.fromResponse(401, null).errMessage, 'Authentication or request error. Please try again.');
      expect(ServerFailure.fromResponse(403, null).errMessage, 'Authentication or request error. Please try again.');
      expect(ServerFailure.fromResponse(404, null).errMessage, 'Requested item not found. Please try again later.');
      expect(ServerFailure.fromResponse(408, null).errMessage, 'Request timeout. Please try again.');
      expect(ServerFailure.fromResponse(429, null).errMessage, 'Too many requests. Please try again later.');
      expect(ServerFailure.fromResponse(500, null).errMessage, 'Internal server error. Please try again later.');
      expect(ServerFailure.fromResponse(502, null).errMessage, 'Bad gateway. Please try again later.');
      expect(ServerFailure.fromResponse(503, null).errMessage, 'Service unavailable. Please try again later.');
      expect(ServerFailure.fromResponse(501, null).errMessage, 'An unexpected server error occurred. Please try again.');
    });

    test('fromResponse with Map error, String error, and null response', () {
      expect(ServerFailure.fromResponse(400, const {'error': {'message': 'Map Error'}}).errMessage, 'Map Error');
      expect(ServerFailure.fromResponse(400, const {'error': 'String Error'}).errMessage, 'String Error');
    });
  });

  group('FormatFailure', () {
    test('default message', () {
      expect(const FormatFailure().errMessage, 'Unable to process book data. Please try again.');
    });
  });

  group('CacheFailure', () {
    test('default message', () {
      expect(const CacheFailure().errMessage, 'Failed to load saved offline data.');
    });
  });

  group('Equality tests', () {
    test('Equatable', () {
      expect(const ServerFailure('Error'), const ServerFailure('Error'));
      expect(const FormatFailure(), const FormatFailure());
      expect(const CacheFailure(), const CacheFailure());
    });
  });
}
