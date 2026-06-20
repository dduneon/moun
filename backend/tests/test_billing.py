from datetime import date

import pytest

from app.core.billing import calculate_billing_date
from app.models.card import Card
from app.models.fixed_expense import PaymentMethod


def _card(statement_day: int) -> Card:
    c = Card()
    c.name = "테스트카드"
    c.statement_day = statement_day
    c.is_active = True
    return c


# ── cash / account ────────────────────────────────────────────────────────────

@pytest.mark.parametrize("method", [PaymentMethod.cash, PaymentMethod.account])
def test_non_card_billing_date_equals_transaction_date(method):
    txn_date = date(2026, 6, 15)
    assert calculate_billing_date(txn_date, method) == txn_date


# ── card 익월 청구 ─────────────────────────────────────────────────────────────

@pytest.mark.parametrize("txn_date, statement_day, expected_billing", [
    # 일반 케이스: 6월 거래 → 7월 statement_day 청구
    (date(2026, 6, 10), 15, date(2026, 7, 15)),
    (date(2026, 6, 21), 25, date(2026, 7, 25)),
    # 연말 경계: 12월 거래 → 1월 청구
    (date(2026, 12, 5),  10, date(2027, 1, 10)),
    (date(2026, 12, 31), 1,  date(2027, 1, 1)),
    # statement_day 말일 보정: 2월에 31일 없음
    (date(2026, 1, 15), 31, date(2026, 2, 28)),
    # 윤년 2월: 29일까지 있음
    (date(2024, 1, 15), 31, date(2024, 2, 29)),
    # statement_day 30인데 2월
    (date(2026, 1, 5),  30, date(2026, 2, 28)),
    # statement_day가 딱 말일과 일치
    (date(2026, 3, 10), 31, date(2026, 4, 30)),
])
def test_card_billing_date(txn_date, statement_day, expected_billing):
    card = _card(statement_day)
    result = calculate_billing_date(txn_date, PaymentMethod.card, card)
    assert result == expected_billing


def test_card_without_card_info_raises():
    with pytest.raises(ValueError, match="card 정보가 필요"):
        calculate_billing_date(date(2026, 6, 1), PaymentMethod.card, card=None)
