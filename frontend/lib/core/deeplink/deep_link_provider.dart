import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 딥링크(https://moun.app/invite/{token} 또는 moun://invite/{token})로 들어온
/// 초대 토큰을 보관한다. null이면 대기 중인 초대가 없다는 뜻.
final pendingInviteTokenProvider = StateProvider<String?>((ref) => null);

String? _extractInviteToken(Uri uri) {
  final segments = uri.pathSegments;
  final idx = segments.indexOf('invite');
  if (idx == -1 || idx + 1 >= segments.length) return null;
  return segments[idx + 1];
}

/// 앱 콜드 스타트/웜 스타트 양쪽에서 들어오는 딥링크를 감지해
/// pendingInviteTokenProvider에 반영한다.
class DeepLinkListener {
  DeepLinkListener(this._ref) {
    _init();
  }

  final Ref _ref;
  final _appLinks = AppLinks();

  Future<void> _init() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);
    _appLinks.uriLinkStream.listen(_handle);
  }

  void _handle(Uri uri) {
    final token = _extractInviteToken(uri);
    if (token != null) {
      _ref.read(pendingInviteTokenProvider.notifier).state = token;
    }
  }
}

final deepLinkListenerProvider = Provider<DeepLinkListener>((ref) {
  return DeepLinkListener(ref);
});
