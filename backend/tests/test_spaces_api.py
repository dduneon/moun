"""
통합 테스트:
- Space 생성/조회/멤버십, 비멤버 접근 차단
- 초대 링크 생성 → 미리보기(비인증) → 수락 플로우
- 두 멤버가 각각 거래를 기록하고 합산 예산이 정확히 계산되는지
- 개인 공간(personal) 데이터와 완전히 분리되어 서로 영향이 없는지
"""
from fastapi.testclient import TestClient


def register_and_login(client, email, password="pass1234", name="유저"):
    client.post("/auth/register", json={"email": email, "password": password, "name": name})
    r = client.post("/auth/login", json={"email": email, "password": password, "device_id": "d1"})
    return r.json()["access_token"]


def auth_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def test_create_and_list_space(client: TestClient):
    token = register_and_login(client, "a@test.com")
    r = client.post("/spaces", json={"name": "우리집", "base_day": 25}, headers=auth_header(token))
    assert r.status_code == 201
    body = r.json()
    assert body["name"] == "우리집"
    assert body["base_day"] == 25
    assert body["member_count"] == 1

    r = client.get("/spaces", headers=auth_header(token))
    assert r.status_code == 200
    assert len(r.json()) == 1


def test_non_member_cannot_access_space(client: TestClient):
    token_a = register_and_login(client, "a@test.com")
    token_b = register_and_login(client, "b@test.com")

    r = client.post("/spaces", json={"name": "우리집"}, headers=auth_header(token_a))
    space_id = r.json()["id"]

    r = client.get(f"/spaces/{space_id}", headers=auth_header(token_b))
    assert r.status_code == 403

    r = client.get(f"/spaces/{space_id}/transactions", headers=auth_header(token_b))
    assert r.status_code == 403


def test_invite_preview_and_accept_flow(client: TestClient):
    token_a = register_and_login(client, "a@test.com")
    token_b = register_and_login(client, "b@test.com")

    r = client.post("/spaces", json={"name": "우리집"}, headers=auth_header(token_a))
    space_id = r.json()["id"]

    r = client.post(f"/spaces/{space_id}/invites", headers=auth_header(token_a))
    assert r.status_code == 201
    invite = r.json()
    assert "token" in invite and "url" in invite

    # 비인증 상태로 미리보기 가능
    r = client.get(f"/spaces/invites/{invite['token']}")
    assert r.status_code == 200
    preview = r.json()
    assert preview["space_name"] == "우리집"
    assert preview["member_count"] == 1
    assert preview["valid"] is True

    # B가 수락하면 멤버가 됨
    r = client.post(f"/spaces/invites/{invite['token']}/accept", headers=auth_header(token_b))
    assert r.status_code == 200
    assert r.json()["member_count"] == 2

    # 멱등 — 다시 수락해도 멤버 수 그대로
    r = client.post(f"/spaces/invites/{invite['token']}/accept", headers=auth_header(token_b))
    assert r.json()["member_count"] == 2

    # 이제 B도 space 조회 가능
    r = client.get(f"/spaces/{space_id}", headers=auth_header(token_b))
    assert r.status_code == 200


def test_invite_invalid_token_404(client: TestClient):
    token_a = register_and_login(client, "a@test.com")
    r = client.get("/spaces/invites/does-not-exist")
    assert r.status_code == 404
    r = client.post("/spaces/invites/does-not-exist/accept", headers=auth_header(token_a))
    assert r.status_code == 404


def test_leave_space(client: TestClient):
    token_a = register_and_login(client, "a@test.com")
    token_b = register_and_login(client, "b@test.com")

    r = client.post("/spaces", json={"name": "우리집"}, headers=auth_header(token_a))
    space_id = r.json()["id"]
    r = client.post(f"/spaces/{space_id}/invites", headers=auth_header(token_a))
    invite_token = r.json()["token"]
    client.post(f"/spaces/invites/{invite_token}/accept", headers=auth_header(token_b))

    r = client.delete(f"/spaces/{space_id}/members/me", headers=auth_header(token_b))
    assert r.status_code == 204

    r = client.get(f"/spaces/{space_id}", headers=auth_header(token_b))
    assert r.status_code == 403


def test_two_members_shared_transactions_and_budget(client: TestClient):
    token_a = register_and_login(client, "a@test.com")
    token_b = register_and_login(client, "b@test.com")

    r = client.post("/spaces", json={"name": "우리집", "base_day": 1}, headers=auth_header(token_a))
    space_id = r.json()["id"]
    r = client.post(f"/spaces/{space_id}/invites", headers=auth_header(token_a))
    invite_token = r.json()["token"]
    client.post(f"/spaces/invites/{invite_token}/accept", headers=auth_header(token_b))

    r = client.post(f"/spaces/{space_id}/categories", json={"name": "식비"}, headers=auth_header(token_a))
    category_id = r.json()["id"]

    from datetime import date
    today = date.today().isoformat()

    # A가 지출 기록
    r = client.post(
        f"/spaces/{space_id}/transactions",
        json={"amount": -10000, "category_id": category_id, "payment_method": "cash", "transaction_date": today},
        headers=auth_header(token_a),
    )
    assert r.status_code == 201
    assert r.json()["created_by_user_id"] is not None

    # B도 지출 기록
    r = client.post(
        f"/spaces/{space_id}/transactions",
        json={"amount": -5000, "category_id": category_id, "payment_method": "account", "transaction_date": today},
        headers=auth_header(token_b),
    )
    assert r.status_code == 201

    # B가 목록 조회 시 A의 거래도 함께 보임 (공유 공간)
    r = client.get(f"/spaces/{space_id}/transactions", headers=auth_header(token_b))
    assert r.status_code == 200
    assert len(r.json()) == 2

    # 합산 예산에 두 거래 모두 반영
    r = client.get(f"/spaces/{space_id}/budget-cycles/current/budget", headers=auth_header(token_a))
    assert r.status_code == 200
    budget = r.json()
    assert budget["spend_summary"]["total_spend"] == "-15000.00" or float(budget["spend_summary"]["total_spend"]) == -15000


def test_list_members_and_owner_can_remove(client: TestClient):
    token_a = register_and_login(client, "a@test.com", name="에이")
    token_b = register_and_login(client, "b@test.com", name="비")

    r = client.post("/spaces", json={"name": "우리집"}, headers=auth_header(token_a))
    space_id = r.json()["id"]
    r = client.post(f"/spaces/{space_id}/invites", headers=auth_header(token_a))
    invite_token = r.json()["token"]
    client.post(f"/spaces/invites/{invite_token}/accept", headers=auth_header(token_b))

    r = client.get(f"/spaces/{space_id}/members", headers=auth_header(token_b))
    assert r.status_code == 200
    members = r.json()
    assert len(members) == 2
    owner = next(m for m in members if m["is_owner"])
    assert owner["name"] == "에이"
    non_owner = next(m for m in members if not m["is_owner"])
    assert non_owner["name"] == "비"

    # 관리자가 아닌 멤버는 다른 멤버를 제외할 수 없음
    r = client.delete(f"/spaces/{space_id}/members/{owner['user_id']}", headers=auth_header(token_b))
    assert r.status_code == 403

    # 관리자는 관리자 자신을 제외할 수 없음
    r = client.delete(f"/spaces/{space_id}/members/{owner['user_id']}", headers=auth_header(token_a))
    assert r.status_code == 400

    # 관리자는 다른 멤버를 제외할 수 있음
    r = client.delete(f"/spaces/{space_id}/members/{non_owner['user_id']}", headers=auth_header(token_a))
    assert r.status_code == 204

    r = client.get(f"/spaces/{space_id}", headers=auth_header(token_b))
    assert r.status_code == 403


def test_space_transactions_independent_from_personal(client: TestClient):
    token_a = register_and_login(client, "a@test.com")

    r = client.post("/spaces", json={"name": "우리집"}, headers=auth_header(token_a))
    space_id = r.json()["id"]
    r = client.post(f"/spaces/{space_id}/categories", json={"name": "우리집 전용 카테고리"}, headers=auth_header(token_a))
    category_id = r.json()["id"]

    from datetime import date
    today = date.today().isoformat()

    client.post(
        f"/spaces/{space_id}/transactions",
        json={"amount": -30000, "category_id": category_id, "payment_method": "cash", "transaction_date": today},
        headers=auth_header(token_a),
    )

    # 개인 공간 거래 목록에는 영향 없음
    r = client.get("/transactions", headers=auth_header(token_a))
    assert r.status_code == 200
    assert r.json() == []

    # 개인 카테고리 목록에도 space_category가 섞이지 않음
    r = client.get("/categories", headers=auth_header(token_a))
    assert all(c["name"] != "우리집 전용 카테고리" for c in r.json())
