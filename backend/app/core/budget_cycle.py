from __future__ import annotations

import calendar
from datetime import date, timedelta
from dataclasses import dataclass


@dataclass
class CycleBounds:
    start: date
    end: date
    label: str


def _clamped_day(year: int, month: int, day: int) -> int:
    """해당 연/월의 실제 일수를 넘지 않도록 day를 자른다 (31=말일 등)."""
    last = calendar.monthrange(year, month)[1]
    return min(day, last)


def get_cycle_bounds(ref_date: date, salary_day: int) -> CycleBounds:
    """salary_day 기준으로 ref_date가 속하는 사이클 경계를 계산한다.
    salary_day가 그 달의 실제 일수보다 크면(예: 31=말일) 그 달의 말일로 자동 보정된다."""
    d = salary_day
    if d <= 1:
        last = calendar.monthrange(ref_date.year, ref_date.month)[1]
        return CycleBounds(
            start=ref_date.replace(day=1),
            end=ref_date.replace(day=last),
            label=f"{ref_date.year}년 {ref_date.month}월",
        )

    this_month_start_day = _clamped_day(ref_date.year, ref_date.month, d)

    if ref_date.day >= this_month_start_day:
        start = ref_date.replace(day=this_month_start_day)
        if ref_date.month == 12:
            next_year, next_month = ref_date.year + 1, 1
        else:
            next_year, next_month = ref_date.year, ref_date.month + 1
        next_month_start_day = _clamped_day(next_year, next_month, d)
        end = date(next_year, next_month, next_month_start_day) - timedelta(days=1)
        label = f"{ref_date.year}년 {ref_date.month}월"
    else:
        if ref_date.month == 1:
            prev_year, prev_month = ref_date.year - 1, 12
        else:
            prev_year, prev_month = ref_date.year, ref_date.month - 1
        prev_month_start_day = _clamped_day(prev_year, prev_month, d)
        start = date(prev_year, prev_month, prev_month_start_day)
        end = ref_date.replace(day=this_month_start_day) - timedelta(days=1)
        label = f"{prev_year}년 {prev_month}월"

    return CycleBounds(start=start, end=end, label=label)


def get_current_cycle(salary_day: int) -> CycleBounds:
    return get_cycle_bounds(date.today(), salary_day)


def get_prev_cycle(salary_day: int) -> CycleBounds:
    """현재 사이클의 시작일 하루 전 날짜로 이전 사이클을 계산한다."""
    current = get_current_cycle(salary_day)
    prev_ref = date(current.start.year, current.start.month, current.start.day)
    # 시작일 하루 전
    from datetime import timedelta
    return get_cycle_bounds(current.start - timedelta(days=1), salary_day)


def get_recent_cycles(salary_day: int, count: int = 6, joined_date: date | None = None) -> list[CycleBounds]:
    """최근 최대 count개의 사이클을 오래된 순으로 반환한다.
    joined_date가 주어지면 해당 날짜가 속한 사이클부터 시작한다.
    """
    from datetime import timedelta
    cycles: list[CycleBounds] = []
    current = get_current_cycle(salary_day)
    ref = current.start
    for _ in range(count):
        c = get_cycle_bounds(ref, salary_day)
        cycles.append(c)
        ref = c.start - timedelta(days=1)

    if joined_date is not None:
        joined_cycle_start = get_cycle_bounds(joined_date, salary_day).start
        cycles = [c for c in cycles if c.start >= joined_cycle_start]

    return list(reversed(cycles))
