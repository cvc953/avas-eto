import Flutter
import UIKit
import UserNotifications
import awesome_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set UNUserNotificationCenter delegate to receive notifications while app is foreground
    UNUserNotificationCenter.current().delegate = self

    // Initialize Awesome Notifications (channels and settings are configured in Dart side)
    // Keep this call minimal here; detailed channel setup should be handled in Dart.
    AwesomeNotifications().initialize(nil, [])

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Forward foreground notification to Dart via awesome_notifications
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .sound, .badge])
  }
}
