"""
테스트 데이터 시드 스크립트
usage: cd backend && python scripts/seed_test_data.py
"""
from __future__ import annotations

import sys
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select, delete
from app.db.base import SessionLocal
from app.models.budget_cycle import BudgetCycle
from app.models.card import Card
from app.models.category import Category
from app.models.fixed_expense import FixedExpense, PaymentMethod
from app.models.income import Income, IncomeStatus, IncomeType
from app.models.transaction import Transaction
from app.models.user import User
from app.models.user_setting import UserSetting

TARGET_EMAIL = "test@test.com"

# 카테고리 정의 (이름 기준으로 프론트와 매핑)
EXPENSE_CATEGORIES = [
    "식비", "교통", "쇼핑", "문화", "의료", "통신", "카페", "여행", "구독", "기타",
]
INCOME_CATEGORIES = [
    "급여", "부업", "투자", "기타수입",
]


def seed():
    db = SessionLocal()
    try:
        user = db.scalar(select(User).where(User.email == TARGET_EMAIL))
        if not user:
            print(f"[ERROR] {TARGET_EMAIL} 유저를 찾을 수 없습니다. 먼저 가입해주세요.")
            return

        print(f"[OK] 유저 발견: {user.name} (id={user.id})")

        # ── UserSetting ──────────────────────────────────────────
        setting = db.scalar(select(UserSetting).where(UserSetting.user_id == user.id))
        if not setting:
            setting = UserSetting(user_id=user.id, salary_day=21, payday_adjustment="prev_business")
            db.add(setting)
            print("[OK] UserSetting 생성 (salary_day=21)")
        else:
            setting.salary_day = 21
            print("[OK] UserSetting 업데이트")

        # 의존 순서대로 먼저 삭제
        db.execute(delete(Transaction).where(Transaction.user_id == user.id))
        db.execute(delete(Income).where(Income.user_id == user.id))
        db.execute(delete(BudgetCycle).where(BudgetCycle.user_id == user.id))
        db.execute(delete(FixedExpense).where(FixedExpense.user_id == user.id))
        db.execute(delete(Card).where(Card.user_id == user.id))
        db.execute(delete(Category).where(Category.user_id == user.id))
        db.flush()

        # ── Categories ───────────────────────────────────────────
        categories: dict[str, Category] = {}
        for name in EXPENSE_CATEGORIES + INCOME_CATEGORIES:
            cat = Category(user_id=user.id, name=name)
            db.add(cat)
            categories[name] = cat
        db.flush()
        print(f"[OK] 카테고리 {len(categories)}개 생성")

        cat = lambda name: categories[name]  # noqa: E731

        # ── Card ─────────────────────────────────────────────────
        shinhan = Card(user_id=user.id, name="신한카드", statement_day=15)
        kb = Card(user_id=user.id, name="국민카드", statement_day=20)
        db.add_all([shinhan, kb])
        db.flush()
        print(f"[OK] 카드 2개 생성: 신한카드(id={shinhan.id}), 국민카드(id={kb.id})")

        # ── Fixed Expenses ────────────────────────────────────────
        fixed_expenses = [
            FixedExpense(user_id=user.id, name="월세", amount=Decimal("500000"),
                         payment_method=PaymentMethod.account, billing_day=25),
            FixedExpense(user_id=user.id, name="넷플릭스", amount=Decimal("17000"),
                         payment_method=PaymentMethod.card, billing_day=14),
            FixedExpense(user_id=user.id, name="스포츠센터", amount=Decimal("80000"),
                         payment_method=PaymentMethod.card, billing_day=3),
            FixedExpense(user_id=user.id, name="핸드폰 요금", amount=Decimal("55000"),
                         payment_method=PaymentMethod.account, billing_day=18),
            FixedExpense(user_id=user.id, name="유튜브 프리미엄", amount=Decimal("14900"),
                         payment_method=PaymentMethod.card, billing_day=7),
        ]
        db.add_all(fixed_expenses)
        db.flush()
        total_fixed = sum(f.amount for f in fixed_expenses)
        print(f"[OK] 고정지출 {len(fixed_expenses)}개 생성 (합계: {total_fixed:,}원)")

        # ── BudgetCycle (현재: 2026-05-21 ~ 2026-06-20) ──────────
        cycle = BudgetCycle(
            user_id=user.id,
            start_date=date(2026, 5, 21),
            end_date=date(2026, 6, 20),
            label="2026년 5월",
            salary_expected=Decimal("4200000"),
            salary_actual=Decimal("4200000"),
        )
        prev_cycle = BudgetCycle(
            user_id=user.id,
            start_date=date(2026, 4, 21),
            end_date=date(2026, 5, 20),
            label="2026년 4월",
            salary_expected=Decimal("4200000"),
            salary_actual=Decimal("4200000"),
        )
        db.add_all([prev_cycle, cycle])
        db.flush()
        print(f"[OK] BudgetCycle 생성: {cycle.start_date} ~ {cycle.end_date} (id={cycle.id})")

        # ── Income ────────────────────────────────────────────────
        incomes = [
            Income(
                user_id=user.id,
                type=IncomeType.salary,
                name="5월 급여",
                expected_amount=Decimal("4200000"),
                actual_amount=Decimal("4200000"),
                scheduled_day=21,
                received_date=date(2026, 5, 21),
                status=IncomeStatus.confirmed,
                budget_cycle_id=cycle.id,
            ),
            Income(
                user_id=user.id,
                type=IncomeType.extra,
                name="프리랜서 수입",
                expected_amount=Decimal("150000"),
                actual_amount=Decimal("150000"),
                received_date=date(2026, 6, 14),
                status=IncomeStatus.confirmed,
                budget_cycle_id=cycle.id,
            ),
            # 이전 사이클 급여
            Income(
                user_id=user.id,
                type=IncomeType.salary,
                name="4월 급여",
                expected_amount=Decimal("4200000"),
                actual_amount=Decimal("4200000"),
                scheduled_day=21,
                received_date=date(2026, 4, 21),
                status=IncomeStatus.confirmed,
                budget_cycle_id=prev_cycle.id,
            ),
        ]
        db.add_all(incomes)
        db.flush()
        print(f"[OK] 수입 {len(incomes)}개 생성")

        # ── Transactions ─────────────────────────────────────────
        def tx(name, amount, cat_name, tx_date, card=None, memo=None,  # noqa: ANN001
               method=PaymentMethod.card):
            t_date = tx_date if isinstance(tx_date, date) else date(*tx_date)
            # billing_date: 카드면 카드 결제일 기준, 현금/계좌는 거래일
            if method == PaymentMethod.card and card:
                billing_day = card.statement_day
                if t_date.day <= billing_day:
                    billing_date = t_date.replace(day=billing_day)
                else:
                    m = t_date.month + 1 if t_date.month < 12 else 1
                    y = t_date.year if t_date.month < 12 else t_date.year + 1
                    billing_date = date(y, m, billing_day)
            else:
                billing_date = t_date
                method = PaymentMethod.account

            # spend_cycle_id: 거래일 기준
            spend_cycle = cycle if t_date >= date(2026, 5, 21) else prev_cycle
            # billing_cycle_id: 청구일 기준
            billing_cycle = cycle if billing_date >= date(2026, 5, 21) else prev_cycle

            return Transaction(
                user_id=user.id,
                name=name,
                amount=Decimal(str(amount)),
                category_id=cat(cat_name).id,
                payment_method=method,
                card_id=card.id if card else None,
                transaction_date=t_date,
                billing_date=billing_date,
                spend_cycle_id=spend_cycle.id,
                billing_cycle_id=billing_cycle.id,
                memo=memo,
            )

        transactions_data = [
            # 5월 21일 ~
            tx("스타벅스 강남점", -6500, "카페", date(2026, 5, 21), shinhan, "아메리카노"),
            tx("대중교통", -1450, "교통", date(2026, 5, 21), method=PaymentMethod.account),
            tx("이마트", -78000, "식비", date(2026, 5, 22), shinhan),
            tx("올리브영", -71000, "쇼핑", date(2026, 5, 23), kb),
            tx("CU 편의점", -4200, "식비", date(2026, 5, 24), shinhan),
            tx("대중교통", -1450, "교통", date(2026, 5, 25), method=PaymentMethod.account),
            tx("CGV", -15000, "문화", date(2026, 5, 26), kb),
            tx("점심 식사", -12000, "식비", date(2026, 5, 27), shinhan, "삼겹살"),
            tx("스타벅스", -6000, "카페", date(2026, 5, 28), shinhan),
            tx("쿠팡", -34500, "쇼핑", date(2026, 5, 29), kb),
            tx("대중교통", -1450, "교통", date(2026, 5, 30), method=PaymentMethod.account),
            tx("한식당", -9000, "식비", date(2026, 5, 31), shinhan),
            # 6월
            tx("배달의민족", -28000, "식비", date(2026, 6, 1), kb),
            tx("대중교통", -1450, "교통", date(2026, 6, 2), method=PaymentMethod.account),
            tx("스타벅스", -5500, "카페", date(2026, 6, 3), shinhan, "라떼"),
            tx("대중교통", -1450, "교통", date(2026, 6, 4), method=PaymentMethod.account),
            tx("교보문고", -18000, "문화", date(2026, 6, 5), kb),
            tx("편의점", -3200, "식비", date(2026, 6, 6), shinhan),
            tx("이마트", -65000, "식비", date(2026, 6, 7), shinhan),
            tx("대중교통", -1450, "교통", date(2026, 6, 9), method=PaymentMethod.account),
            tx("점심 식사", -11000, "식비", date(2026, 6, 10), shinhan),
            tx("약국", -15000, "의료", date(2026, 6, 11), method=PaymentMethod.account),
            tx("스타벅스", -6500, "카페", date(2026, 6, 12), shinhan, "아메리카노"),
            tx("대중교통", -1450, "교통", date(2026, 6, 13), method=PaymentMethod.account),
            tx("프리랜서 수입", 150000, "부업", date(2026, 6, 14),
               method=PaymentMethod.account),
            tx("올리브영", -42000, "쇼핑", date(2026, 6, 15), kb),
            tx("이마트", -52000, "식비", date(2026, 6, 16), shinhan),
            tx("대중교통", -1450, "교통", date(2026, 6, 17), method=PaymentMethod.account),
            tx("족발집", -35000, "식비", date(2026, 6, 18), shinhan),
            tx("스타벅스", -7000, "카페", date(2026, 6, 19), shinhan, "프라푸치노"),
            tx("대중교통", -1450, "교통", date(2026, 6, 20), method=PaymentMethod.account),
        ]
        db.add_all(transactions_data)

        total_expense = sum(abs(int(t.amount)) for t in transactions_data if t.amount < 0)
        total_income_tx = sum(int(t.amount) for t in transactions_data if t.amount > 0)
        print(f"[OK] 거래내역 {len(transactions_data)}개 생성")
        print(f"     지출 합계: {total_expense:,}원 / 수입 거래: {total_income_tx:,}원")

        db.commit()
        print("\n✅ 시드 완료!")
        print(f"   사이클: {cycle.start_date} ~ {cycle.end_date}")
        print(f"   급여: 4,200,000원 / 고정지출: {total_fixed:,}원")

    except Exception as e:
        db.rollback()
        print(f"[ERROR] {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
