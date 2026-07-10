import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:quickpass/models/employee.dart';
import 'package:quickpass/providers/auth_provider.dart';

import '../helpers/mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockApiService mockApi;
  late AuthProvider provider;

  setUp(() {
    mockApi = MockApiService();
    provider = AuthProvider(api: mockApi);
  });

  group('initialize', () {
    test('sets authenticated when token exists and profile loads', () async {
      when(mockApi.getStoredToken()).thenAnswer((_) async => 'token-123');
      when(mockApi.getProfile()).thenAnswer((_) async => Employee.fromJson({
            'employee_id': '000001',
            'full_name': 'Alice Chen',
            'position': 'Engineer',
            'department_id': '1',
            'department_name': 'Engineering',
            'email': 'alice@example.com',
            'is_supervisor': false,
            'is_admin': false,
            'is_security': false,
            'is_active': true,
          }));

      await provider.initialize();

      expect(provider.isAuthenticated, true);
      expect(provider.isLoading, false);
      expect(provider.user, isNotNull);
      expect(provider.user?.employeeId, '000001');
    });

    test('skips auth when no stored token', () async {
      when(mockApi.getStoredToken()).thenAnswer((_) async => null);

      await provider.initialize();

      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
      expect(provider.user, isNull);
    });

    test('handles error during initialization', () async {
      when(mockApi.getStoredToken()).thenAnswer((_) async => 'token-123');
      when(mockApi.getProfile()).thenThrow(Exception('Network error'));

      await provider.initialize();

      expect(provider.isAuthenticated, false);
      expect(provider.isLoading, false);
    });
  });

  group('login', () {
    test('succeeds with valid credentials', () async {
      when(mockApi.login('000001', 'pass1234')).thenAnswer((_) async => {
            'success': true,
            'token': 'jwt-token',
            'user': {
              'employee_id': '000001',
              'full_name': 'Alice Chen',
              'position': 'Engineer',
              'department_id': '1',
              'department_name': 'Engineering',
              'email': 'alice@example.com',
              'is_supervisor': false,
              'is_admin': false,
              'is_security': false,
              'is_active': true,
            },
          });

      final result = await provider.login('000001', 'pass1234');

      expect(result, true);
      expect(provider.isAuthenticated, true);
      expect(provider.loginLoading, false);
      expect(provider.error, isNull);
    });

    test('fails with invalid credentials', () async {
      when(mockApi.login('000001', 'wrong'))
          .thenThrow(Exception('Invalid credentials'));

      final result = await provider.login('000001', 'wrong');

      expect(result, false);
      expect(provider.isAuthenticated, false);
      expect(provider.error, 'Invalid credentials');
    });
  });

  group('logout', () {
    test('clears auth state', () async {
      when(mockApi.logout()).thenAnswer((_) async {});
      provider = AuthProvider(api: mockApi);

      // Simulate being logged in
      when(mockApi.getStoredToken()).thenAnswer((_) async => 'token');
      when(mockApi.getProfile()).thenAnswer((_) async => Employee.fromJson({
            'employee_id': '000001',
            'full_name': 'Alice',
            'position': '',
            'department_id': '',
            'department_name': '',
            'email': '',
            'is_supervisor': false,
            'is_admin': false,
            'is_security': false,
            'is_active': true,
          }));
      await provider.initialize();
      expect(provider.isAuthenticated, true);

      await provider.logout();

      expect(provider.isAuthenticated, false);
      expect(provider.user, isNull);
    });
  });

  group('updateProfile', () {
    test('updates user on success', () async {
      when(mockApi.updateProfile({'full_name': 'Alice Updated'})).thenAnswer(
        (_) async => Employee.fromJson({
          'employee_id': '000001',
          'full_name': 'Alice Updated',
          'position': 'Engineer',
          'department_id': '1',
          'department_name': 'Engineering',
          'email': 'alice@example.com',
          'is_supervisor': false,
          'is_admin': false,
          'is_security': false,
          'is_active': true,
        }),
      );

      final result =
          await provider.updateProfile({'full_name': 'Alice Updated'});

      expect(result, true);
      expect(provider.user?.fullName, 'Alice Updated');
    });

    test('sets error on failure', () async {
      when(mockApi.updateProfile({'full_name': 'Bad'}))
          .thenThrow(Exception('Update failed'));

      final result = await provider.updateProfile({'full_name': 'Bad'});

      expect(result, false);
      expect(provider.error, 'Update failed');
    });
  });
}
