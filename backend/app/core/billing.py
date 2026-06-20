from __future__ import annotations

import calendar
from datetime import date, timedelta

import holidays

from app.models.card import Card
from app.models.fixed_expense import PaymentMethod
from app.models.user_setting import UserSetting


def calculate_billing_date(
    transaction_date: date,
    payment_method: PaymentMethod,
    card: Card | None = None,
) -> date:
    """
    카드: 당월 이용분 → 익월 statement_day 청구 (말일 보정).
    cash/account: 거래일 == 청구일.
    """
    if payment_method != PaymentMethod.card:
        return transaction_date

    if card is None:
        raise ValueError("payment_method가 card인 경우 card 정보가 필요합니다")

    if transaction_date.month == 12:
        billing_year, billing_month = transaction_date.year + 1, 1
    else:
        billing_year, billing_month = transaction_date.year, transaction_date.month + 1

    last_day = calendar.monthrange(billing_year, billing_month)[1]
    billing_day = min(card.statement_day, last_day)

    return date(billing_year, billing_month, billing_day)


def calculate_actual_payday(
    year: int,
    month: int,
    setting: UserSetting,
) -> date:
    """
    명목 월급날(salary_day)이 주말/공휴일이면 UserSetting.payday_adjustment에 따라 보정.

    payday_adjustment:
      'prev_business' — 이전 영업일 (대부분 회사)
      'next_business' — 다음 영업일
      'exact'         — 보정 없음
    """
    # salary_day가 해당 월의 말일을 넘으면 말일로 보정 (예: salary_day=31인데 2월)
    last_day = calendar.monthrange(year, month)[1]
    nominal_day = min(setting.salary_day, last_day)
    payday = date(year, month, nominal_day)

    if setting.payday_adjustment == "exact":
        return payday

    country_holidays = holidays.country_holidays(setting.holiday_country, years=year)

    def is_business_day(d: date) -> bool:
        return d.weekday() < 5 and d not in country_holidays

    if setting.payday_adjustment == "prev_business":
        while not is_business_day(payday):
            payday -= timedelta(days=1)
    elif setting.payday_adjustment == "next_business":
        while not is_business_day(payday):
            payday += timedelta(days=1)

    return payday
