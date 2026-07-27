import 'package:dio/dio.dart';

String friendlyError(dynamic e) {
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet and try again.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server. Check your internet connection.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final msg = e.response?.data is Map
            ? (e.response!.data as Map)['message']?.toString()
            : null;
        if (msg != null && msg.isNotEmpty) return msg;
        if (status == 401) return 'Session expired. Please log in again.';
        if (status == 403) return 'You do not have permission to do that.';
        if (status == 404) return 'The requested resource was not found.';
        if (status == 409) return msg ?? 'A conflict occurred. Please try again.';
        if (status != null && status >= 500) return 'Server error. Please try again later.';
        return msg ?? 'Something went wrong. Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Connection security error. Please update your app.';
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true) {
          return 'Could not reach the server. Check your internet connection.';
        }
        return 'An unexpected error occurred. Please try again.';
      case DioExceptionType.transformTimeout:
        return 'Request timed out while processing. Please try again.';
    }
  }
  final msg = e.toString().replaceFirst('Exception: ', '');
  if (msg.isEmpty) return 'An unexpected error occurred.';
  return msg;
}
