from datetime import date

import pytest

from app.core.budget_cycle import get_cycle_bounds, get_current_cycle, get_recent_cycles


@pytest.mark.parametrize("ref, salary_day, exp_start, exp_end, exp_label", [
    (date(2026, 6, 1),  1,  date(2026, 6, 1),  date(2026, 6, 30), "2026년 6월"),
    (date(2026, 6, 15), 1,  date(2026, 6, 1),  date(2026, 6, 30), "2026년 6월"),
    (date(2026, 2, 15), 1,  date(2026, 2, 1),  date(2026, 2, 28), "2026년 2월"),
    (date(2024, 2, 29), 1,  date(2024, 2, 1),  date(2024, 2, 29), "2024년 2월"),
    # salary_day=25: 오늘이 25일 이상
    (date(2026, 6, 25), 25, date(2026, 6, 25), date(2026, 7, 24), "2026년 6월"),
    # salary_day=25: 오늘이 25일 미만 → 전월 25일부터
    (date(2026, 6, 10), 25, date(2026, 5, 25), date(2026, 6, 24), "2026년 5월"),
    # 월말 경계: salary_day=21, 12월
    (date(2025, 12, 31), 21, date(2025, 12, 21), date(2026, 1, 20), "2025년 12월"),
    # salary_day=31(말일): 2월엔 28일로 보정, 사이클은 다음 달 말일 전날까지
    (date(2026, 1, 15), 31, date(2025, 12, 31), date(2026, 1, 30), "2025년 12월"),
    (date(2026, 2, 1),  31, date(2026, 1, 31),  date(2026, 2, 27), "2026년 1월"),
    (date(2026, 2, 2),  31, date(2026, 1, 31),  date(2026, 2, 27), "2026년 1월"),
    (date(2026, 3, 1),  31, date(2026, 2, 28),  date(2026, 3, 30), "2026년 2월"),
    (date(2026, 3, 5),  31, date(2026, 2, 28),  date(2026, 3, 30), "2026년 2월"),
    # salary_day=30: 2월엔 28일로 보정
    (date(2026, 3, 1),  30, date(2026, 2, 28),  date(2026, 3, 29), "2026년 2월"),
])
def test_cycle_bounds(ref, salary_day, exp_start, exp_end, exp_label):
    c = get_cycle_bounds(ref, salary_day)
    assert c.start == exp_start
    assert c.end == exp_end
    assert c.label == exp_label


def test_recent_cycles_count():
    cycles = get_recent_cycles(salary_day=1, count=6)
    assert len(cycles) == 6


def test_recent_cycles_ordered():
    cycles = get_recent_cycles(salary_day=1, count=3)
    assert cycles[0].start < cycles[1].start < cycles[2].start


def test_recent_cycles_contiguous():
    from datetime import timedelta
    cycles = get_recent_cycles(salary_day=10, count=4)
    for i in range(len(cycles) - 1):
        assert cycles[i].end + timedelta(days=1) == cycles[i + 1].start
