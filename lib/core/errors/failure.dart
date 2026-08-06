import 'package:dio/dio.dart';

abstract class Failure {
  final String errMessage;

  const Failure(this.errMessage);
}

class ServerFailure extends Failure {
  ServerFailure(super.errMessage);

  factory ServerFailure.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure('Connection timeout. Please try again.');
      case DioExceptionType.sendTimeout:
        return ServerFailure('Send timeout. Please check your connection.');
      case DioExceptionType.receiveTimeout:
        return ServerFailure('Receive timeout. Please try again later.');
      case DioExceptionType.badCertificate:
        return ServerFailure('Bad certificate error with server.');
      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
          dioException.response?.statusCode,
          dioException.response?.data,
        );
      case DioExceptionType.cancel:
        return ServerFailure('Request to server was canceled.');
      case DioExceptionType.connectionError:
        return ServerFailure(
          'No internet connection. Please check your network.',
        );
      case DioExceptionType.unknown:
        if (dioException.message != null &&
            dioException.message!.contains('SocketException')) {
          return ServerFailure(
            'No internet connection. Please check your network.',
          );
        }
        return ServerFailure('Unexpected network error. Please try again.');
      default:
        return ServerFailure('An unexpected error occurred. Please try again.');
    }
  }

  factory ServerFailure.fromResponse(int? statusCode, dynamic response) {
    if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
      if (response is Map && response['error'] != null) {
        final err = response['error'];
        if (err is Map && err['message'] != null) {
          return ServerFailure(err['message'].toString());
        }
      }
      return ServerFailure(
        'Authentication or request error. Please try again.',
      );
    } else if (statusCode == 404) {
      return ServerFailure('Requested item not found. Please try again later.');
    } else if (statusCode == 500) {
      return ServerFailure('Internal server error. Please try again later.');
    } else {
      return ServerFailure(
        'An unexpected server error occurred. Please try again.',
      );
    }
  }
}

class FormatFailure extends Failure {
  const FormatFailure([
    String message = 'Unable to process book data. Please try again.',
  ]) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Failed to load saved offline data.'])
    : super(message);
}
