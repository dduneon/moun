Flutter 앱에 백엔드의 JWT 인증을 연동해줘.

## 구조
lib/features/auth/ 하위에 구현:
- 로그인 화면 (이메일/비밀번호)
- 회원가입 화면
- riverpod로 인증 상태 관리 (AuthState: unauthenticated, authenticating, authenticated)

## 토큰 저장
- access token, refresh token은 flutter_secure_storage 패키지로 기기에 암호화 저장 (절대 SharedPreferences 같은 평문 저장소 사용 금지)

## API 클라이언트
- dio의 Interceptor를 사용해서:
  - 모든 요청에 자동으로 Authorization: Bearer {access_token} 헤더 추가
  - 401 응답 받으면 자동으로 refresh token으로 갱신 시도 후 원래 요청 재시도
  - refresh도 실패하면 로그아웃 처리하고 로그인 화면으로 리다이렉트

## 라우팅
- go_router 사용해서 인증 상태에 따라 자동 리다이렉트 (미인증 상태에서 보호된 화면 접근 시 로그인 화면으로)

## 앱 시작 시 처리
- 앱 시작 시 저장된 토큰 확인 → 있으면 /auth/me 호출해서 유효성 검증 → 유효하면 메인 화면, 무효하면 로그인 화면

지금은 메인 화면(대시보드)은 빈 화면(placeholder)으로 두고, 인증 플로우 완성에만 집중해줘. 로그인/회원가입/토큰 갱신/로그아웃 관련 위젯 테스트도 작성해줘.
