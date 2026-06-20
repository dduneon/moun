const String appName = '모운';

// --dart-define=BASE_URL=http://localhost:8000  (iOS 시뮬레이터)
// --dart-define=BASE_URL=http://10.0.2.2:8000   (Android 에뮬레이터, 기본값)
const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);
