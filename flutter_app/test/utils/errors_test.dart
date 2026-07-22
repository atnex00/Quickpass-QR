import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/utils/errors.dart';

void main() {
  group('friendlyError', () {
    group('DioException types', () {
      test('connectionTimeout returns timeout message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        );
        expect(friendlyError(e),
            'Connection timed out. Check your internet and try again.');
      });

      test('sendTimeout returns timeout message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.sendTimeout,
        );
        expect(friendlyError(e),
            'Connection timed out. Check your internet and try again.');
      });

      test('receiveTimeout returns timeout message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout,
        );
        expect(friendlyError(e),
            'Connection timed out. Check your internet and try again.');
      });

      test('connectionError returns server connection message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        );
        expect(friendlyError(e),
            'Could not connect to the server. Check your internet connection.');
      });

      test('cancel returns cancelled message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.cancel,
        );
        expect(friendlyError(e), 'Request was cancelled.');
      });

      test('badCertificate returns security error message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badCertificate,
        );
        expect(friendlyError(e),
            'Connection security error. Please update your app.');
      });

      test('transformTimeout returns processing timeout message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.transformTimeout,
        );
        expect(friendlyError(e),
            'Request timed out while processing. Please try again.');
      });

      test('unknown with SocketException returns server connection message',
          () {
        final e = DioException(
          requestOptions: RequestOptions(),
          message: 'SocketException: Connection refused',
        );
        expect(friendlyError(e),
            'Could not reach the server. Check your internet connection.');
      });

      test('unknown without SocketException returns generic message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
        );
        expect(friendlyError(e),
            'An unexpected error occurred. Please try again.');
      });
    });

    group('badResponse status codes', () {
      test('401 returns session expired', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
          ),
        );
        expect(friendlyError(e), 'Session expired. Please log in again.');
      });

      test('403 returns permission denied', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 403,
          ),
        );
        expect(friendlyError(e), 'You do not have permission to do that.');
      });

      test('404 returns not found', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 404,
          ),
        );
        expect(friendlyError(e), 'The requested resource was not found.');
      });

      test('409 returns conflict message from response data', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 409,
            data: {'message': 'Leave already exists'},
          ),
        );
        expect(friendlyError(e), 'Leave already exists');
      });

      test('409 with empty message returns empty string (known bug)', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 409,
            data: {'message': ''},
          ),
        );
        expect(friendlyError(e), '');
      });

      test('500 returns server error', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 500,
          ),
        );
        expect(friendlyError(e), 'Server error. Please try again later.');
      });

      test('unknown status with message returns that message', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 418,
            data: {'message': 'I am a teapot'},
          ),
        );
        expect(friendlyError(e), 'I am a teapot');
      });

      test('unknown status without message returns generic', () {
        final e = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 418,
          ),
        );
        expect(friendlyError(e), 'Something went wrong. Please try again.');
      });
    });

    group('non-Dio exceptions', () {
      test('Exception with message returns cleaned message', () {
        expect(friendlyError(Exception('Something broke')), 'Something broke');
      });

      test('Exception with prefix stripped', () {
        expect(friendlyError(Exception('Error: failed')),
            'Error: failed');
      });

      test('empty toString returns generic', () {
        expect(friendlyError(''), 'An unexpected error occurred.');
      });

      test('String message returned as-is', () {
        expect(friendlyError('just a string'), 'just a string');
      });
    });
  });
}
