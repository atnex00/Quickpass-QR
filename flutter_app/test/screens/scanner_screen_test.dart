import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:quickpass/config/theme.dart';
import 'package:quickpass/providers/auth_provider.dart';
import 'package:quickpass/providers/scan_provider.dart';
import 'package:quickpass/screens/security/scan_result_screen.dart';
import 'package:quickpass/screens/security/scanner_screen.dart';

import '../helpers/mocks.mocks.dart';
import '../helpers/test_setup.dart';

Widget _buildTestApp(MockApiService mockApi, {bool active = false}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(api: mockApi)),
      ChangeNotifierProvider<ScanProvider>(
          create: (_) => ScanProvider(api: mockApi)),
    ],
    child: MaterialApp(
      theme: QuickpassTheme.light,
      home: ScannerScreen(active: active),
    ),
  );
}

void _mockCameraPermissionGranted() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter.baseflow.com/permissions/methods'),
    (call) async {
      if (call.method == 'requestPermissions') {
        return <int, int>{1: 1};
      }
      if (call.method == 'checkPermissionStatus') {
        return 1;
      }
      return null;
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.steenbakker.mobile_scanner/scanner/method'),
    (call) async {
      if (call.method == 'state') {
        return 1;
      }
      if (call.method == 'start') {
        return <String, Object?>{
          'textureId': 1,
          'numberOfCameras': 1,
          'currentTorchState': 0,
          'size': <String, Object?>{'width': 1.0, 'height': 1.0},
        };
      }
      return null;
    },
  );
}

void main() {
  late MockApiService mockApi;

  setUp(() async {
    await setupTestInfrastructure();
    mockApi = MockApiService();
    when(mockApi.getStoredToken()).thenAnswer((_) async => null);
  });

  testWidgets('renders scanner shell with camera unavailable fallback',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(mockApi));
    await tester.pump();

    expect(find.text('Quickpass'), findsOneWidget);
    expect(find.text('Scanner inactive'), findsWidgets);
    expect(find.text('Open the Scan tab to activate the camera'),
        findsOneWidget);
    expect(find.byType(MobileScanner), findsNothing);
  });

  testWidgets('camera initializes on activation and releases on deactivation',
      (WidgetTester tester) async {
    _mockCameraPermissionGranted();

    await tester.pumpWidget(_buildTestApp(mockApi));
    await tester.pump();

    expect(find.byType(MobileScanner), findsNothing);

    await tester.pumpWidget(_buildTestApp(mockApi, active: true));
    await tester.pumpAndSettle();

    expect(find.byType(MobileScanner), findsOneWidget);

    await tester.pumpWidget(_buildTestApp(mockApi));
    await tester.pumpAndSettle();

    expect(find.byType(MobileScanner), findsNothing);
    expect(find.text('Scanner inactive'), findsWidgets);
  });

  testWidgets('manual entry validates a QR code and shows scan result',
      (WidgetTester tester) async {
    when(mockApi.validateScan(any)).thenAnswer((_) async => {
          'success': true,
          'data': {
            'qr_type': 'OUT',
            'type': 'OUT',
            'employee_name': 'James Wilson',
            'employee_id': '000001',
            'position': 'Staff',
            'department_name': 'TSD',
            'leave_date': '2026-08-04',
            'start_time': '09:00',
            'end_time': '17:00',
            'new_status': 'active',
          },
        });

    await tester.pumpWidget(_buildTestApp(mockApi));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.keyboard));
    await tester.pump();

    expect(find.text('Submit'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'qr-data-payload');
    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ScanResultScreen), findsOneWidget);
    expect(find.text('Exit Recorded'), findsOneWidget);
    expect(find.text('OUT SCAN'), findsOneWidget);
    expect(find.text('James Wilson'), findsOneWidget);
    expect(find.text('Scan Next'), findsOneWidget);
    verify(mockApi.validateScan('qr-data-payload')).called(1);

    await tester.pumpAndSettle();
  });
}
