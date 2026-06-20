from __future__ import annotations

import calendar
from datetime import date

from app.models.card import Card
from app.models.fixed_expense import PaymentMethod


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
