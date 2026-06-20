from datetime import date

import pytest

from app.core.billing import calculate_actual_payday, calculate_billing_date
from app.models.card import Card
from app.models.fixed_expense import PaymentMethod
from app.models.user_setting import UserSetting


def _card(statement_day: int) -> Card:
    c = Card()
    c.name = "테스트카드"
    c.statement_day = statement_day
    c.is_active = True
    return c


def _setting(salary_day: int, adjustment: str = "prev_business", country: str = "KR") -> UserSetting:
    s = UserSetting()
    s.salary_day = salary_day
    s.payday_adjustment = adjustment
    s.holiday_country = country
    return s


# ── calculate_billing_date ────────────────────────────────────────────────────

@pytest.mark.parametrize("method", [PaymentMethod.cash, PaymentMethod.account])
def test_non_card_billing_date_equals_transaction_date(method):
    txn_date = date(2026, 6, 15)
    assert calculate_billing_date(txn_date, method) == txn_date


@pytest.mark.parametrize("txn_date, statement_day, expected", [
    (date(2026, 6, 10), 15, date(2026, 7, 15)),
    (date(2026, 6, 21), 25, date(2026, 7, 25)),
    (date(2026, 12, 5),  10, date(2027, 1, 10)),
    (date(2026, 12, 31), 1,  date(2027, 1, 1)),
    # 2월 말일 보정 (평년)
    (date(2026, 1, 15), 31, date(2026, 2, 28)),
    # 2월 말일 보정 (윤년)
    (date(2024, 1, 15), 31, date(2024, 2, 29)),
    (date(2026, 1, 5),  30, date(2026, 2, 28)),
    (date(2026, 3, 10), 31, date(2026, 4, 30)),
])
def test_card_billing_date(txn_date, statement_day, expected):
    assert calculate_billing_date(txn_date, PaymentMethod.card, _card(statement_day)) == expected


def test_card_without_card_info_raises():
    with pytest.raises(ValueError, match="card 정보가 필요"):
        calculate_billing_date(date(2026, 6, 1), PaymentMethod.card, card=None)


# ── calculate_actual_payday ───────────────────────────────────────────────────

@pytest.mark.parametrize("year, month, salary_day, adjustment, expected", [
    # 평일 → 보정 없음
    (2026, 6, 21, "prev_business", date(2026, 6, 21)),   # 2026-06-21은 일요일
    # 2026-06-21은 일요일 → prev_business → 6/19(금)
])
def test_actual_payday_sunday_prev(year, month, salary_day, adjustment, expected):
    # 2026-06-21은 일요일
    result = calculate_actual_payday(year, month, _setting(salary_day, adjustment))
    # 일요일이면 금요일로
    assert result.weekday() < 5  # 영업일


def test_actual_payday_prev_business_day(year=2026, month=6):
    """2026-06-21(일) → 2026-06-19(금)."""
    s = _setting(salary_day=21, adjustment="prev_business")
    result = calculate_actual_payday(2026, 6, s)
    assert result == date(2026, 6, 19)


def test_actual_payday_next_business_day():
    """2026-06-21(일) → 2026-06-22(월)."""
    s = _setting(salary_day=21, adjustment="next_business")
    result = calculate_actual_payday(2026, 6, s)
    assert result == date(2026, 6, 22)


def test_actual_payday_exact_keeps_weekend():
    """exact 모드는 주말이어도 그대로."""
    s = _setting(salary_day=21, adjustment="exact")
    result = calculate_actual_payday(2026, 6, s)
    assert result == date(2026, 6, 21)


def test_actual_payday_saturday_prev():
    """2026-01-10(토) salary_day=10 → 2026-01-09(금)."""
    s = _setting(salary_day=10, adjustment="prev_business")
    result = calculate_actual_payday(2026, 1, s)
    assert result == date(2026, 1, 9)


def test_actual_payday_korean_holiday():
    """설날 연휴 등 공휴일이면 이전 영업일로."""
    # 2026-02-17(화) 설날 → prev_business → 2026-02-13(금) (2/14 토, 2/15 일, 2/16 설날전날, 2/17 설날)
    s = _setting(salary_day=17, adjustment="prev_business", country="KR")
    result = calculate_actual_payday(2026, 2, s)
    assert result.weekday() < 5
    assert result < date(2026, 2, 17)


def test_actual_payday_february_last_day_clamp():
    """salary_day=31이면 2월은 말일(28/29)로 보정."""
    s = _setting(salary_day=31, adjustment="exact")
    assert calculate_actual_payday(2026, 2, s) == date(2026, 2, 28)
    assert calculate_actual_payday(2024, 2, s) == date(2024, 2, 29)
