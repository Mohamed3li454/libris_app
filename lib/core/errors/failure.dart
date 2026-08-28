import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String errMessage;

  const Failure(this.errMessage);

  @override
  List<Object?> get props => [errMessage];
}

class ServerFailure extends Failure {
  const ServerFailure(super.errMessage);

  factory ServerFailure.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return const ServerFailure('Connection timeout. Please try again.');
      case DioExceptionType.sendTimeout:
        return const ServerFailure('Send timeout. Please check your connection.');
      case DioExceptionType.receiveTimeout:
        return const ServerFailure('Receive timeout. Please try again later.');
      case DioExceptionType.badCertificate:
        return const ServerFailure('Bad certificate error with server.');
      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
          dioException.response?.statusCode,
          dioException.response?.data,
        );
      case DioExceptionType.cancel:
        return const ServerFailure('Request to server was canceled.');
      case DioExceptionType.connectionError:
        return const ServerFailure(
          'No internet connection. Please check your network.',
        );
      case DioExceptionType.unknown:
        if (dioException.error is SocketException ||
            (dioException.message != null &&
                dioException.message!.contains('SocketException'))) {
          return const ServerFailure(
            'No internet connection. Please check your network.',
          );
        }
        return const ServerFailure('Unexpected network error. Please try again.');
      default:
        return const ServerFailure('An unexpected error occurred. Please try again.');
    }
  }

  factory ServerFailure.fromResponse(int? statusCode, dynamic response) {
    if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
      if (response is Map && response['error'] != null) {
        final err = response['error'];
        if (err is Map && err['message'] != null) {
          return ServerFailure(err['message'].toString());
        }
        if (err is String) {
          return ServerFailure(err);
        }
      }
      return const ServerFailure(
        'Authentication or request error. Please try again.',
      );
    } else if (statusCode == 404) {
      return const ServerFailure('Requested item not found. Please try again later.');
    } else if (statusCode == 408) {
      return const ServerFailure('Request timeout. Please try again.');
    } else if (statusCode == 429) {
      return const ServerFailure('Too many requests. Please try again later.');
    } else if (statusCode == 500) {
      return const ServerFailure('Internal server error. Please try again later.');
    } else if (statusCode == 502) {
      return const ServerFailure('Bad gateway. Please try again later.');
    } else if (statusCode == 503) {
      return const ServerFailure('Service unavailable. Please try again later.');
    } else {
      return const ServerFailure(
        'An unexpected server error occurred. Please try again.',
      );
    }
  }
}

class FormatFailure extends Failure {
  const FormatFailure([
    super.message = 'Unable to process book data. Please try again.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load saved offline data.']);
}
