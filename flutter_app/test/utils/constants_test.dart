import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/utils/constants.dart';

void main() {
  group('AppConstants', () {
    test('appName is Quickpass', () {
      expect(AppConstants.appName, 'Quickpass');
    });

    test('tagline is correct', () {
      expect(AppConstants.tagline, 'Smart Gatepass & Leave Management');
    });

    test('QR labels are correct', () {
      expect(AppConstants.outQrLabel, 'EXIT PASS');
      expect(AppConstants.inQrLabel, 'ENTRY PASS');
    });

    test('employeeIdHint is 000001', () {
      expect(AppConstants.employeeIdHint, '000001');
    });

    test('employeeIdLength is 6', () {
      expect(AppConstants.employeeIdLength, 6);
    });

    test('qrCountdownInterval is 1 second', () {
      expect(AppConstants.qrCountdownInterval, const Duration(seconds: 1));
    });

    test('scanTimeout is 30 seconds', () {
      expect(AppConstants.scanTimeout, const Duration(seconds: 30));
    });

    test('support contact info is correct', () {
      expect(AppConstants.supportEmail, 'support@zaneco.com');
      expect(AppConstants.supportPhone, 'Ext. 4200');
      expect(AppConstants.supportHours, '8:00 AM - 6:00 PM');
    });
  });
}
