from datetime import date

import pytest
from sqlalchemy.orm import Session

from app.core.budget_cycle import _cycle_bounds, get_cycle_for_date


# ── _cycle_bounds 단위 테스트 (DB 불필요) ─────────────────────────────────────

@pytest.mark.parametrize("ref, exp_start, exp_end, exp_label", [
    # 21일 당일 → 이달 21일 ~ 익월 20일
    (date(2026, 6, 21), date(2026, 6, 21), date(2026, 7, 20), "2026년 6월"),
    # 21일 이후
    (date(2026, 6, 30), date(2026, 6, 21), date(2026, 7, 20), "2026년 6월"),
    # 1일 (월초) → 전달 21일 ~ 이달 20일
    (date(2026, 7, 1),  date(2026, 6, 21), date(2026, 7, 20), "2026년 6월"),
    # 20일 (사이클 마지막 날)
    (date(2026, 7, 20), date(2026, 6, 21), date(2026, 7, 20), "2026년 6월"),
    # 12월 21일 → 연말 경계
    (date(2025, 12, 21), date(2025, 12, 21), date(2026, 1, 20), "2025년 12월"),
    # 1월 1일 → 전년 12월 사이클
    (date(2026, 1, 1),  date(2025, 12, 21), date(2026, 1, 20), "2025년 12월"),
    # 1월 20일 → 전년 12월 사이클
    (date(2026, 1, 20), date(2025, 12, 21), date(2026, 1, 20), "2025년 12월"),
    # 1월 21일 → 새 사이클
    (date(2026, 1, 21), date(2026, 1, 21), date(2026, 2, 20), "2026년 1월"),
    # 2월 20일 (윤년 2024)
    (date(2024, 2, 20), date(2024, 1, 21), date(2024, 2, 20), "2024년 1월"),
    # 2월 21일 윤년
    (date(2024, 2, 21), date(2024, 2, 21), date(2024, 3, 20), "2024년 2월"),
    # 3월 1일 (윤년 이후 월초)
    (date(2024, 3, 1),  date(2024, 2, 21), date(2024, 3, 20), "2024년 2월"),
])
def test_cycle_bounds(ref, exp_start, exp_end, exp_label):
    start, end, label = _cycle_bounds(ref)
    assert start == exp_start
    assert end == exp_end
    assert label == exp_label


# ── get_cycle_for_date 통합 테스트 ────────────────────────────────────────────

def test_get_cycle_for_date_creates_new(db: Session):
    cycle = get_cycle_for_date(db, date(2026, 6, 21))
    assert cycle.id is not None
    assert cycle.start_date == date(2026, 6, 21)
    assert cycle.end_date == date(2026, 7, 20)
    assert cycle.label == "2026년 6월"


def test_get_cycle_for_date_returns_existing(db: Session):
    c1 = get_cycle_for_date(db, date(2026, 6, 21))
    db.flush()
    c2 = get_cycle_for_date(db, date(2026, 6, 25))
    assert c1.id == c2.id


def test_same_cycle_across_month_boundary(db: Session):
    """6월 25일과 7월 10일은 같은 사이클."""
    c1 = get_cycle_for_date(db, date(2026, 6, 25))
    db.flush()
    c2 = get_cycle_for_date(db, date(2026, 7, 10))
    assert c1.id == c2.id


def test_adjacent_dates_different_cycles(db: Session):
    """7월 20일과 7월 21일은 다른 사이클."""
    c1 = get_cycle_for_date(db, date(2026, 7, 20))
    db.flush()
    c2 = get_cycle_for_date(db, date(2026, 7, 21))
    assert c1.id != c2.id


def test_year_boundary_cycle(db: Session):
    """12월 25일과 1월 15일은 같은 사이클."""
    c1 = get_cycle_for_date(db, date(2025, 12, 25))
    db.flush()
    c2 = get_cycle_for_date(db, date(2026, 1, 15))
    assert c1.id == c2.id
