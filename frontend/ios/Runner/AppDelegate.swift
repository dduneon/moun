import Flutter
import UIKit
import KakaoSDKAuth

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 카카오톡 앱 전환 로그인 후 돌아오는 커스텀 스킴 콜백(kakao{APP_KEY}://oauth/?code=...)을
  // 카카오 SDK가 먼저 처리하도록 가로챈다. 그렇지 않으면 Flutter 엔진이 이 URL을
  // 화면 전환 요청으로 오인해 go_router가 "no routes for location" 에러를 낸다.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if AuthApi.isKakaoTalkLoginUrl(url) {
      return AuthController.handleOpenUrl(url: url)
    }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
