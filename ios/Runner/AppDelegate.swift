import Flutter
import ObjectiveC
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    _disablePdfDoubleTapZoom()
    return launched
  }

  private func _disablePdfDoubleTapZoom() {
    guard let cls = NSClassFromString("FLTPDFView") else { return }
    let selector = NSSelectorFromString("onDoubleTap:")
    guard let method = class_getInstanceMethod(cls, selector) else { return }
    let block: @convention(block) (AnyObject, AnyObject) -> Void = { _, _ in }
    method_setImplementation(method, imp_implementationWithBlock(block))
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
