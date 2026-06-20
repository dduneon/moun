from datetime import date

import pytest
from sqlalchemy.orm import Session

from app.core.budget_cycle import _cycle_bounds, get_cycle_for_date
from app.models.user import User


# ── _cycle_bounds 단위 테스트 (salary_day 파라미터) ──────────────────────────

@pytest.mark.parametrize("salary_day, ref, exp_start, exp_end, exp_label", [
    # salary_day=21 (기본)
    (21, date(2026, 6, 21), date(2026, 6, 21), date(2026, 7, 20), "2026년 6월"),
    (21, date(2026, 6, 30), date(2026, 6, 21), date(2026, 7, 20), "2026년 6월"),
    (21, date(2026, 7, 1),  date(2026, 6, 21), date(2026, 7, 20), "2026년 6월"),
    (21, date(2026, 7, 20), date(2026, 6, 21), date(2026, 7, 20), "2026년 6월"),
    (21, date(2025, 12, 21), date(2025, 12, 21), date(2026, 1, 20), "2025년 12월"),
    (21, date(2026, 1, 1),   date(2025, 12, 21), date(2026, 1, 20), "2025년 12월"),
    (21, date(2026, 1, 21),  date(2026, 1, 21),  date(2026, 2, 20), "2026년 1월"),
    # 윤년
    (21, date(2024, 2, 20), date(2024, 1, 21), date(2024, 2, 20), "2024년 1월"),
    (21, date(2024, 2, 21), date(2024, 2, 21), date(2024, 3, 20), "2024년 2월"),

    # salary_day=10
    (10, date(2026, 6, 10), date(2026, 6, 10), date(2026, 7, 9), "2026년 6월"),
    (10, date(2026, 6, 15), date(2026, 6, 10), date(2026, 7, 9), "2026년 6월"),
    (10, date(2026, 7, 9),  date(2026, 6, 10), date(2026, 7, 9), "2026년 6월"),
    (10, date(2026, 7, 10), date(2026, 7, 10), date(2026, 8, 9), "2026년 7월"),
    (10, date(2026, 7, 1),  date(2026, 6, 10), date(2026, 7, 9), "2026년 6월"),
    # salary_day=10, 연말 경계
    (10, date(2025, 12, 10), date(2025, 12, 10), date(2026, 1, 9), "2025년 12월"),
    (10, date(2026, 1, 9),   date(2025, 12, 10), date(2026, 1, 9), "2025년 12월"),

    # salary_day=1
    (1, date(2026, 6, 1),  date(2026, 6, 1), date(2026, 6, 30), "2026년 6월"),
    (1, date(2026, 6, 30), date(2026, 6, 1), date(2026, 6, 30), "2026년 6월"),
    # salary_day=1, 2월 말일 보정 (평년)
    (1, date(2026, 2, 28), date(2026, 2, 1), date(2026, 2, 28), "2026년 2월"),
    # salary_day=1, 2월 말일 보정 (윤년)
    (1, date(2024, 2, 29), date(2024, 2, 1), date(2024, 2, 29), "2024년 2월"),
])
def test_cycle_bounds(salary_day, ref, exp_start, exp_end, exp_label):
    start, end, label = _cycle_bounds(ref, salary_day)
    assert start == exp_start
    assert end == exp_end
    assert label == exp_label


# ── get_cycle_for_date 통합 테스트 ────────────────────────────────────────────

def test_creates_cycle_with_user_salary_day(db: Session, user: User):
    cycle = get_cycle_for_date(db, user.id, date(2026, 6, 21))
    assert cycle.user_id == user.id
    assert cycle.start_date == date(2026, 6, 21)
    assert cycle.end_date == date(2026, 7, 20)


def test_salary_day_10_user(db: Session, user_salary10: User):
    cycle = get_cycle_for_date(db, user_salary10.id, date(2026, 6, 15))
    assert cycle.start_date == date(2026, 6, 10)
    assert cycle.end_date == date(2026, 7, 9)


def test_returns_existing_cycle(db: Session, user: User):
    c1 = get_cycle_for_date(db, user.id, date(2026, 6, 21))
    db.flush()
    c2 = get_cycle_for_date(db, user.id, date(2026, 6, 25))
    assert c1.id == c2.id


def test_different_users_get_separate_cycles(db: Session, user: User, user_salary10: User):
    """같은 날짜라도 사용자별로 독립적인 사이클."""
    c1 = get_cycle_for_date(db, user.id, date(2026, 6, 15))
    c2 = get_cycle_for_date(db, user_salary10.id, date(2026, 6, 15))
    assert c1.id != c2.id
    assert c1.start_date == date(2026, 5, 21)   # salary_day=21 → 전달 21일
    assert c2.start_date == date(2026, 6, 10)   # salary_day=10 → 이달 10일


def test_same_cycle_across_month_boundary(db: Session, user: User):
    c1 = get_cycle_for_date(db, user.id, date(2026, 6, 25))
    db.flush()
    c2 = get_cycle_for_date(db, user.id, date(2026, 7, 10))
    assert c1.id == c2.id


def test_adjacent_dates_different_cycles(db: Session, user: User):
    c1 = get_cycle_for_date(db, user.id, date(2026, 7, 20))
    db.flush()
    c2 = get_cycle_for_date(db, user.id, date(2026, 7, 21))
    assert c1.id != c2.id


def test_year_boundary_cycle(db: Session, user: User):
    c1 = get_cycle_for_date(db, user.id, date(2025, 12, 25))
    db.flush()
    c2 = get_cycle_for_date(db, user.id, date(2026, 1, 15))
    assert c1.id == c2.id
