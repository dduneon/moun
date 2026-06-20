"""
통합 테스트:
- 회원가입 → 로그인 → 인증 API 호출 전체 플로우
- 타 유저 데이터 접근 시 404
- 멀티디바이스 refresh token 시나리오
- rate limiting
"""
import pytest
from fastapi.testclient import TestClient


# ── helpers ───────────────────────────────────────────────────────────────────

def register(client, email="a@test.com", password="pass1234", name="유저A"):
    return client.post("/auth/register", json={"email": email, "password": password, "name": name})


def login(client, email="a@test.com", password="pass1234", device_id="device1"):
    return client.post("/auth/login", json={"email": email, "password": password, "device_id": device_id})


def auth_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


# ── 회원가입 / 로그인 ──────────────────────────────────────────────────────────

def test_register_and_login_flow(client: TestClient):
    r = register(client)
    assert r.status_code == 201
    assert r.json()["email"] == "a@test.com"

    r = login(client)
    assert r.status_code == 200
    tokens = r.json()
    assert "access_token" in tokens
    assert "refresh_token" in tokens


def test_register_duplicate_email(client: TestClient):
    register(client)
    r = register(client)
    assert r.status_code == 409


def test_login_wrong_password(client: TestClient):
    register(client)
    r = login(client, password="wrong")
    assert r.status_code == 401
    assert "이메일 또는 비밀번호" in r.json()["detail"]


def test_login_nonexistent_email(client: TestClient):
    r = login(client, email="nobody@test.com")
    assert r.status_code == 401
    # 이메일 존재 여부 노출 금지 — 동일한 메시지
    assert "이메일 또는 비밀번호" in r.json()["detail"]


def test_get_me(client: TestClient):
    register(client)
    tokens = login(client).json()
    r = client.get("/auth/me", headers=auth_header(tokens["access_token"]))
    assert r.status_code == 200
    assert r.json()["email"] == "a@test.com"


def test_get_me_unauthenticated(client: TestClient):
    r = client.get("/auth/me")
    assert r.status_code == 403  # HTTPBearer returns 403 when no token


# ── refresh token ─────────────────────────────────────────────────────────────

def test_refresh_token(client: TestClient):
    register(client)
    tokens = login(client).json()
    r = client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 200
    assert "access_token" in r.json()


def test_refresh_with_invalid_token(client: TestClient):
    r = client.post("/auth/refresh", json={"refresh_token": "invalid.token.here"})
    assert r.status_code == 401


def test_logout_invalidates_refresh_token(client: TestClient):
    register(client)
    tokens = login(client).json()

    # 로그아웃
    r = client.post("/auth/logout", json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 204

    # 로그아웃 후 refresh 시도 → 실패
    r = client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert r.status_code == 401


def test_multidevice_login_independent_sessions(client: TestClient):
    """기기1 로그인 상태에서 기기2 로그인해도 기기1 세션 유지."""
    register(client)
    tokens1 = login(client, device_id="device1").json()
    tokens2 = login(client, device_id="device2").json()

    # 기기2 로그아웃
    client.post("/auth/logout", json={"refresh_token": tokens2["refresh_token"]})

    # 기기1 refresh는 여전히 유효
    r = client.post("/auth/refresh", json={"refresh_token": tokens1["refresh_token"]})
    assert r.status_code == 200


# ── 인증 적용 확인 ────────────────────────────────────────────────────────────

def test_protected_endpoint_requires_auth(client: TestClient):
    r = client.get("/budget-cycles")
    assert r.status_code == 403


def test_protected_endpoint_with_valid_token(client: TestClient):
    register(client)
    tokens = login(client).json()
    r = client.get("/budget-cycles", headers=auth_header(tokens["access_token"]))
    assert r.status_code == 200


# ── 데이터 격리 (A 유저가 B 유저 리소스 접근 시 404) ─────────────────────────

def _setup_two_users(client):
    register(client, email="a@test.com", name="유저A")
    register(client, email="b@test.com", name="유저B")
    tokens_a = login(client, email="a@test.com").json()
    tokens_b = login(client, email="b@test.com").json()
    return tokens_a, tokens_b


def test_card_isolation_404(client: TestClient):
    tokens_a, tokens_b = _setup_two_users(client)

    # A가 카드 생성
    r = client.post("/cards", json={"name": "신한카드", "statement_day": 15},
                    headers=auth_header(tokens_a["access_token"]))
    assert r.status_code == 201
    card_id = r.json()["id"]

    # B가 A의 카드 조회 → 404
    r = client.get(f"/cards/{card_id}", headers=auth_header(tokens_b["access_token"]))
    assert r.status_code == 404


def test_card_patch_isolation_404(client: TestClient):
    tokens_a, tokens_b = _setup_two_users(client)

    r = client.post("/cards", json={"name": "신한카드", "statement_day": 15},
                    headers=auth_header(tokens_a["access_token"]))
    card_id = r.json()["id"]

    r = client.patch(f"/cards/{card_id}", json={"name": "해킹카드"},
                     headers=auth_header(tokens_b["access_token"]))
    assert r.status_code == 404


def test_fixed_expense_isolation_404(client: TestClient):
    tokens_a, tokens_b = _setup_two_users(client)

    r = client.post("/fixed-expenses",
                    json={"name": "넷플릭스", "amount": 17000, "payment_method": "card", "billing_day": 5},
                    headers=auth_header(tokens_a["access_token"]))
    obj_id = r.json()["id"]

    r = client.get(f"/fixed-expenses/{obj_id}", headers=auth_header(tokens_b["access_token"]))
    assert r.status_code == 404


def test_income_isolation_404(client: TestClient):
    tokens_a, tokens_b = _setup_two_users(client)

    r = client.post("/incomes",
                    json={"name": "월급"},
                    headers=auth_header(tokens_a["access_token"]))
    income_id = r.json()["id"]

    r = client.get(f"/incomes/{income_id}", headers=auth_header(tokens_b["access_token"]))
    assert r.status_code == 404


# ── rate limiting ─────────────────────────────────────────────────────────────

def test_rate_limit_on_login(client: TestClient):
    register(client)
    # 5회 실패 후 429
    for _ in range(5):
        client.post("/auth/login", json={"email": "a@test.com", "password": "wrong", "device_id": "d"})
    r = client.post("/auth/login", json={"email": "a@test.com", "password": "wrong", "device_id": "d"})
    assert r.status_code == 429


def test_rate_limit_resets_on_success(client: TestClient):
    register(client)
    # 4회 실패
    for _ in range(4):
        client.post("/auth/login", json={"email": "a@test.com", "password": "wrong", "device_id": "d"})
    # 성공 → 카운터 리셋
    r = login(client)
    assert r.status_code == 200
    # 이후 다시 실패해도 차단 안 됨 (카운터 0에서 시작)
    client.post("/auth/login", json={"email": "a@test.com", "password": "wrong", "device_id": "d"})
    r = login(client)
    assert r.status_code == 200
