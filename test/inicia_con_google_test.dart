import 'package:avas_eto/services/inicia_con_google.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ensureDriveAccessAfterLoginWithOverrides', () {
    test('returns granted when drive is already granted', () async {
      var requestCalled = false;

      final result = await ensureDriveAccessAfterLoginWithOverrides(
        isDriveGranted: () async => true,
        requestDriveAccess: () async {
          requestCalled = true;
          return DriveAccessRequestStatus.granted;
        },
      );

      expect(result, DriveAccessRequestStatus.granted);
      expect(requestCalled, isFalse);
    });

    test('requests access when drive is not granted', () async {
      var requestCalled = false;

      final result = await ensureDriveAccessAfterLoginWithOverrides(
        isDriveGranted: () async => false,
        requestDriveAccess: () async {
          requestCalled = true;
          return DriveAccessRequestStatus.denied;
        },
      );

      expect(requestCalled, isTrue);
      expect(result, DriveAccessRequestStatus.denied);
    });
  });
}
