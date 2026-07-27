import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickpass/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> setupTestInfrastructure() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;
  AnalyticsService.setEnabled(false);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/device_info'),
    (call) async => <String, dynamic>{
      'id': 'test-device',
      'brand': 'test',
      'device': 'test',
      'fingerprint': 'test/fingerprint',
      'board': '',
      'bootloader': '',
      'display': '',
      'hardware': '',
      'host': '',
      'manufacturer': '',
      'model': '',
      'product': '',
      'serial': '',
      'tags': '',
      'type': '',
      'isPhysicalDevice': false,
      'systemFeatures': <String>[],
      'supported32BitAbis': <String>[],
      'supported64BitAbis': <String>[],
      'supportedAbis': <String>[],
      'name': '',
      'serialNumber': '',
      'freeDiskSize': 0,
      'totalDiskSize': 0,
      'isLowRamDevice': false,
      'physicalRamSize': 0,
      'availableRamSize': 0,
      'version': <String, dynamic>{
        'baseOS': '',
        'codename': '',
        'incremental': '',
        'previewSdkInt': 0,
        'release': '',
        'sdkInt': 0,
        'securityPatch': '',
      },
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('de.christiankappler.flutter_local_notifications'),
    (call) async => null,
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('safe_device'),
    (call) async => false,
  );
}
