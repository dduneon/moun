from datetime import date

import pytest
from sqlalchemy.orm import Session

from app.core.budget_cycle import _cycle_bounds, get_cycle_for_date
from app.models.user import User


@pytest.mark.parametrize("ref, exp_start, exp_end, exp_label", [
    (date(2026, 6, 1),  date(2026, 6, 1),  date(2026, 6, 30), "2026년 6월"),
    (date(2026, 6, 15), date(2026, 6, 1),  date(2026, 6, 30), "2026년 6월"),
    (date(2026, 6, 30), date(2026, 6, 1),  date(2026, 6, 30), "2026년 6월"),
    (date(2026, 2, 15), date(2026, 2, 1),  date(2026, 2, 28), "2026년 2월"),
    (date(2024, 2, 29), date(2024, 2, 1),  date(2024, 2, 29), "2024년 2월"),
    (date(2025, 12, 31), date(2025, 12, 1), date(2025, 12, 31), "2025년 12월"),
])
def test_cycle_bounds(ref, exp_start, exp_end, exp_label):
    start, end, label = _cycle_bounds(ref)
    assert start == exp_start
    assert end == exp_end
    assert label == exp_label


def test_creates_cycle(db: Session, user: User):
    cycle = get_cycle_for_date(db, user.id, date(2026, 6, 15))
    assert cycle.user_id == user.id
    assert cycle.start_date == date(2026, 6, 1)
    assert cycle.end_date == date(2026, 6, 30)


def test_returns_existing_cycle(db: Session, user: User):
    c1 = get_cycle_for_date(db, user.id, date(2026, 6, 1))
    db.flush()
    c2 = get_cycle_for_date(db, user.id, date(2026, 6, 25))
    assert c1.id == c2.id


def test_different_users_get_separate_cycles(db: Session, user: User):
    u2_email = "other@example.com"
    from app.models.user import User as U
    u2 = U(email=u2_email, hashed_password="x", name="다른유저")
    db.add(u2)
    db.flush()

    c1 = get_cycle_for_date(db, user.id, date(2026, 6, 15))
    c2 = get_cycle_for_date(db, u2.id, date(2026, 6, 15))
    assert c1.id != c2.id
    assert c1.start_date == c2.start_date


def test_adjacent_months_different_cycles(db: Session, user: User):
    c1 = get_cycle_for_date(db, user.id, date(2026, 6, 30))
    db.flush()
    c2 = get_cycle_for_date(db, user.id, date(2026, 7, 1))
    assert c1.id != c2.id
