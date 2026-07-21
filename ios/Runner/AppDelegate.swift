import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // API key del proyecto Firebase dtsdrop-85330 (Maps SDK iOS).
    // Sin esto, GoogleMap aborta la app en checkServicePreconditions.
    GMSServices.provideAPIKey("AIzaSyANpS7RJ7r3vkAwzmaMlnYm-tJKq4NP2Kw")
    GeneratedPluginRegistrant.register(with: self)
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
