"""상품권(Voucher) 회계 모델 테스트.

핵심: 충전은 예산에서 차감하되 소비 통계엔 넣지 않고(=saving), 사용은 소비 통계에만
반영하고 예산에선 다시 차감하지 않는다(=이중 차감 방지). 잔액은 voucher_delta 합.
"""
from datetime import date
from decimal import Decimal

from sqlalchemy.orm import Session

from app.core.budget_calculator import get_available_budget, get_saving_summary, get_spend_summary
from app.models.category import Category
from app.models.transaction import Transaction, TransactionType
from app.models.fixed_expense import PaymentMethod
from app.models.user import User
from app.models.voucher import Voucher

START = date(2026, 6, 1)
END = date(2026, 6, 30)


def _cat(db, user, name="식비"):
    c = Category(user_id=user.id, name=name, icon="🍚")
    db.add(c)
    db.flush()
    return c


def _voucher(db, user, name="온누리상품권"):
    v = Voucher(user_id=user.id, name=name)
    db.add(v)
    db.flush()
    return v


# ── 유닛 레벨: 두 축 분리 ────────────────────────────────────────────────────

def test_charge_reduces_budget_not_spend(db: Session, user: User):
    cat = _cat(db, user, "상품권")
    v = _voucher(db, user)
    # 온누리 10% 할인: 90,000 지불 → 100,000 충전
    db.add(Transaction(
        user_id=user.id, amount=Decimal(-90000), type=TransactionType.saving,
        category_id=cat.id, payment_method=PaymentMethod.account,
        voucher_id=v.id, voucher_delta=Decimal(100000),
        transaction_date=date(2026, 6, 5), billing_date=date(2026, 6, 5),
    ))
    db.flush()

    # 소비 통계엔 안 잡히고, 저축 통계엔 잡힘
    assert get_spend_summary(db, user.id, START, END).total_spend == Decimal(0)
    assert get_saving_summary(db, user.id, START, END).total_saving == Decimal(-90000)

    # 가용 예산은 실지불액(90,000)만큼만 줄어듦
    ab = get_available_budget(db, user.id, START, END)
    assert ab.confirmed_saving == Decimal(-90000)


def test_usage_hits_spend_not_budget(db: Session, user: User):
    cat = _cat(db, user, "식비")
    v = _voucher(db, user)
    # 충전
    db.add(Transaction(
        user_id=user.id, amount=Decimal(-90000), type=TransactionType.saving,
        category_id=_cat(db, user, "상품권").id, payment_method=PaymentMethod.account,
        voucher_id=v.id, voucher_delta=Decimal(100000),
        transaction_date=date(2026, 6, 5), billing_date=date(2026, 6, 5),
    ))
    # 사용: 상품권으로 식비 30,000
    db.add(Transaction(
        user_id=user.id, amount=Decimal(-30000), type=TransactionType.expense,
        category_id=cat.id, payment_method=PaymentMethod.voucher,
        voucher_id=v.id, voucher_delta=Decimal(-30000),
        transaction_date=date(2026, 6, 10), billing_date=date(2026, 6, 10),
    ))
    db.flush()

    # 사용은 소비 통계(카테고리별)에 잡힘
    s = get_spend_summary(db, user.id, START, END)
    assert s.total_spend == Decimal(-30000)
    assert {r.category_name for r in s.by_category} == {"식비"}

    # 하지만 가용 예산은 충전분(90,000)만 차감, 사용분(30,000)은 이중 차감 안 됨
    ab = get_available_budget(db, user.id, START, END)
    # billed_transactions(=spend_summary)엔 사용분이 보이지만, available 계산엔 미반영
    assert ab.billed_transactions == Decimal(-30000)
    # available = 0(수입) - 0(고정) + budget_spend(0, voucher 제외) + confirmed_saving(-90000)
    assert ab.available == Decimal(-90000)


# ── API 레벨: 충전 → 사용 → 잔액 ────────────────────────────────────────────

def _register(client, email="v@test.com"):
    client.post("/auth/register", json={"email": email, "password": "pass1234", "name": "유저"})
    r = client.post("/auth/login", json={"email": email, "password": "pass1234", "device_id": "d1"})
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def test_voucher_charge_and_use_flow(client):
    h = _register(client)
    cat_id = client.post("/categories", json={"name": "식비"}, headers=h).json()["id"]

    # 상품권 생성
    v = client.post("/vouchers", json={"name": "온누리상품권"}, headers=h).json()
    assert v["balance"] == "0.00" or Decimal(v["balance"]) == 0

    # 충전: 90,000 지불 → 100,000 충전 (분류 미지정 → 시스템 카테고리 자동 지정)
    r = client.post(
        f"/vouchers/{v['id']}/charge",
        json={"paid_amount": 90000, "face_amount": 100000,
              "transaction_date": "2026-06-05"},
        headers=h,
    )
    assert r.status_code == 201
    assert Decimal(r.json()["balance"]) == Decimal(100000)

    # 충전 거래는 "상품권 충전" 카테고리로 자동 분류됨
    cats = {c["name"] for c in client.get("/categories", headers=h).json()}
    assert "상품권 충전" in cats

    # 사용: 상품권으로 식비 30,000
    r = client.post(
        "/transactions",
        json={"amount": -30000, "category_id": cat_id, "payment_method": "voucher",
              "voucher_id": v["id"], "transaction_date": "2026-06-10", "name": "점심"},
        headers=h,
    )
    assert r.status_code == 201
    assert r.json()["voucher_id"] == v["id"]

    # 잔액 = 100,000 - 30,000 = 70,000
    bal = client.get(f"/vouchers/{v['id']}", headers=h).json()["balance"]
    assert Decimal(bal) == Decimal(70000)


def test_voucher_payment_requires_voucher_id(client):
    h = _register(client, "v2@test.com")
    cat_id = client.post("/categories", json={"name": "식비"}, headers=h).json()["id"]
    r = client.post(
        "/transactions",
        json={"amount": -1000, "category_id": cat_id, "payment_method": "voucher",
              "transaction_date": "2026-06-10"},
        headers=h,
    )
    assert r.status_code == 422


def test_deleting_usage_restores_balance(client):
    h = _register(client, "v3@test.com")
    cat_id = client.post("/categories", json={"name": "식비"}, headers=h).json()["id"]
    v = client.post("/vouchers", json={"name": "지역화폐"}, headers=h).json()
    client.post(f"/vouchers/{v['id']}/charge",
                json={"paid_amount": 50000, "transaction_date": "2026-06-05"},
                headers=h)
    use = client.post("/transactions",
                      json={"amount": -20000, "category_id": cat_id, "payment_method": "voucher",
                            "voucher_id": v["id"], "transaction_date": "2026-06-10"},
                      headers=h).json()
    assert Decimal(client.get(f"/vouchers/{v['id']}", headers=h).json()["balance"]) == Decimal(30000)

    # 사용 삭제 → 잔액 복구
    client.delete(f"/transactions/{use['id']}", headers=h)
    assert Decimal(client.get(f"/vouchers/{v['id']}", headers=h).json()["balance"]) == Decimal(50000)
