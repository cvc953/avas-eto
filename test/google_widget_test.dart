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
          onAuthenticated: (ctx) async {},
        ),
      ),
    );
  }

  testWidgets(
    'requests Drive access when login is authenticated without Drive',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
      expect(started, isTrue);

      await tester.pump(const Duration(milliseconds: 50));
      expect(ensureCalled, 1);

      await tester.pump(const Duration(milliseconds: 50));
      expect(finished, isTrue);
    },
  );

  testWidgets('does not request Drive access when already granted in login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var ensureCalled = 0;
    var finished = false;

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
        onFinish: () => finished = true,
      ),
    );

    await tester.tap(find.text('Inicia con Google'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(ensureCalled, 0);
    expect(finished, isTrue);
  });
}
