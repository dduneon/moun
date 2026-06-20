from __future__ import annotations

import calendar
from datetime import date

from app.models.card import Card
from app.models.fixed_expense import PaymentMethod


def calculate_billing_date(transaction_date: date, payment_method: PaymentMethod, card: Card | None = None) -> date:
    """
    결제 방식에 따라 실제 청구일을 계산한다.

    card:
      - 당월 이용분 전체를 익월 statement_day에 청구하는 방식 (국내 일반 카드사 기본)
      - statement_day가 해당 월에 존재하지 않으면(예: 31일인데 2월) 말일로 보정
    cash / account:
      - 청구일 = 거래일
    """
    if payment_method != PaymentMethod.card:
        return transaction_date

    if card is None:
        raise ValueError("payment_method가 card인 경우 card 정보가 필요합니다")

    # 익월 계산
    if transaction_date.month == 12:
        billing_year, billing_month = transaction_date.year + 1, 1
    else:
        billing_year, billing_month = transaction_date.year, transaction_date.month + 1

    # 해당 월의 말일로 statement_day 보정
    last_day = calendar.monthrange(billing_year, billing_month)[1]
    billing_day = min(card.statement_day, last_day)

    return date(billing_year, billing_month, billing_day)
