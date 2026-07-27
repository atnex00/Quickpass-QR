import 'package:flutter_test/flutter_test.dart';
import 'package:quickpass/models/leave_request.dart';
import 'package:quickpass/services/cache_service.dart';

import '../helpers/test_setup.dart';

final _now = DateTime.now();

LeaveRequest _makeLeave(String id) {
  return LeaveRequest(
    leaveId: id,
    employeeId: '000001',
    employeeName: 'James Wilson',
    departmentId: 'DEP-001',
    supervisorId: '000015',
    supervisorName: 'Liam Thomas',
    leaveDate: DateTime(2026, 7, 21),
    startTime: '09:00',
    endTime: '17:00',
    reason: 'Medical appointment',
    status: LeaveStatus.pending,
    outQrCode: 'qr-out-data',
    inQrCode: 'qr-in-data',
    outQrImage: '/uploads/qr/out.png',
    inQrImage: '/uploads/qr/in.png',
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  setUp(() async {
    await setupTestInfrastructure();
  });

  group('CacheService', () {
    test('singleton returns same instance', () {
      expect(CacheService(), same(CacheService()));
    });

    group('leaves', () {
      test('save and load round-trip', () async {
        final leaves = [_makeLeave('LV-001')];
        await CacheService().saveLeaves(leaves);
        final loaded = await CacheService().loadLeaves();
        expect(loaded, isNotNull);
        expect(loaded!.length, 1);
        expect(loaded.first.leaveId, 'LV-001');
      });

      test('loadLeaves returns null when nothing cached', () async {
        final loaded = await CacheService().loadLeaves();
        expect(loaded, isNull);
      });

      test('sanitize strips QR fields before caching', () async {
        final leave = _makeLeave('LV-002');
        await CacheService().saveLeaves([leave]);
        final loaded = await CacheService().loadLeaves();
        expect(loaded!.first.outQrCode, isNull);
        expect(loaded.first.inQrCode, isNull);
        expect(loaded.first.outQrImage, isNull);
        expect(loaded.first.inQrImage, isNull);
      });
    });

    group('active leave', () {
      test('save and load round-trip', () async {
        final leave = _makeLeave('LV-003');
        await CacheService().saveActiveLeave(leave);
        final loaded = await CacheService().loadActiveLeave();
        expect(loaded, isNotNull);
        expect(loaded!.leaveId, 'LV-003');
      });

      test('save null removes key', () async {
        await CacheService().saveActiveLeave(_makeLeave('LV-004'));
        await CacheService().saveActiveLeave(null);
        final loaded = await CacheService().loadActiveLeave();
        expect(loaded, isNull);
      });

      test('loadActiveLeave returns null when nothing cached', () async {
        final loaded = await CacheService().loadActiveLeave();
        expect(loaded, isNull);
      });
    });

    group('pending requests', () {
      test('save and load round-trip', () async {
        final leaves = [_makeLeave('LV-005')];
        await CacheService().savePendingRequests(leaves);
        final loaded = await CacheService().loadPendingRequests();
        expect(loaded, isNotNull);
        expect(loaded!.length, 1);
        expect(loaded.first.leaveId, 'LV-005');
      });

      test('loadPendingRequests returns null when nothing cached', () async {
        final loaded = await CacheService().loadPendingRequests();
        expect(loaded, isNull);
      });
    });

    group('approved leaves', () {
      test('save and load round-trip', () async {
        final leaves = [_makeLeave('LV-006')];
        await CacheService().saveApprovedLeaves(leaves);
        final loaded = await CacheService().loadApprovedLeaves();
        expect(loaded, isNotNull);
        expect(loaded!.length, 1);
        expect(loaded.first.leaveId, 'LV-006');
      });

      test('loadApprovedLeaves returns null when nothing cached', () async {
        final loaded = await CacheService().loadApprovedLeaves();
        expect(loaded, isNull);
      });
    });

    group('profile', () {
      test('save and load round-trip', () async {
        final profile = {'employee_id': '000001', 'full_name': 'James Wilson'};
        await CacheService().saveProfile(profile);
        final loaded = await CacheService().loadProfile();
        expect(loaded, isNotNull);
        expect(loaded!['full_name'], 'James Wilson');
      });

      test('loadProfile returns null when nothing cached', () async {
        final loaded = await CacheService().loadProfile();
        expect(loaded, isNull);
      });
    });

    group('clearAll', () {
      test('removes all cached data', () async {
        await CacheService().saveLeaves([_makeLeave('LV-007')]);
        await CacheService().saveActiveLeave(_makeLeave('LV-008'));
        await CacheService().savePendingRequests([_makeLeave('LV-009')]);
        await CacheService().saveApprovedLeaves([_makeLeave('LV-010')]);
        await CacheService().saveProfile({'test': 'data'});

        await CacheService().clearAll();

        expect(await CacheService().loadLeaves(), isNull);
        expect(await CacheService().loadActiveLeave(), isNull);
        expect(await CacheService().loadPendingRequests(), isNull);
        expect(await CacheService().loadApprovedLeaves(), isNull);
        expect(await CacheService().loadProfile(), isNull);
      });
    });
  });
}
