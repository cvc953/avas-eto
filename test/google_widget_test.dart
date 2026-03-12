import 'package:avas_eto/services/inicia_con_google.dart';
import 'package:avas_eto/widgets/google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _buildTestable({
    required Future<GoogleLoginResult> Function({bool requestDriveAccess})
    signInWithGoogleFn,
    required Future<DriveAccessRequestStatus> Function() ensureDriveAccessFn,
    required VoidCallback onStart,
    required VoidCallback onFinish,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Google(
          onStart: onStart,
          onFinish: onFinish,
          signInWithGoogleFn: signInWithGoogleFn,
          ensureDriveAccessFn: ensureDriveAccessFn,
          onAuthenticated: (_) async {},
        ),
      ),
    );
  }

  testWidgets(
    'requests Drive access when login is authenticated without Drive',
    (tester) async {
      var started = false;
      var finished = false;
      var ensureCalled = 0;

      await tester.pumpWidget(
        _buildTestable(
          signInWithGoogleFn: ({requestDriveAccess = true}) async {
            return const GoogleLoginResult(
              status: GoogleLoginStatus.authenticatedWithoutDrive,
              driveGrantedOverride: false,
            );
          },
          ensureDriveAccessFn: () async {
            ensureCalled++;
            return DriveAccessRequestStatus.granted;
          },
          onStart: () => started = true,
          onFinish: () => finished = true,
        ),
      );

      await tester.tap(find.text('Inicia con Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(started, isTrue);
      expect(ensureCalled, 1);
      expect(finished, isTrue);
    },
  );

  testWidgets('does not request Drive access when already granted in login', (
    tester,
  ) async {
    var ensureCalled = 0;

    await tester.pumpWidget(
      _buildTestable(
        signInWithGoogleFn: ({requestDriveAccess = true}) async {
          return const GoogleLoginResult(
            status: GoogleLoginStatus.authenticatedWithDrive,
            driveGrantedOverride: true,
          );
        },
        ensureDriveAccessFn: () async {
          ensureCalled++;
          return DriveAccessRequestStatus.granted;
        },
        onStart: () {},
        onFinish: () {},
      ),
    );

    await tester.tap(find.text('Inicia con Google'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(ensureCalled, 0);
  });
}
