"""반복 규칙(월/주/격주/매일)에 따른 발생 날짜 계산. 개인/Space 스케줄 생성기가 공유하는 순수 함수."""
from __future__ import annotations

import calendar
from datetime import date, timedelta

from app.models.income import Frequency


def _monthly_dates(day: int, start: date, end: date) -> list[date]:
    """월별 특정일(1~31, 31=말일)이 start~end 범위 안에 있는 날짜 목록."""
    result: list[date] = []
    cur = start.replace(day=1)
    while cur <= end:
        last = calendar.monthrange(cur.year, cur.month)[1]
        actual = min(day, last)
        candidate = cur.replace(day=actual)
        if start <= candidate <= end:
            result.append(candidate)
        next_month = cur.month % 12 + 1
        next_year = cur.year + (1 if cur.month == 12 else 0)
        cur = date(next_year, next_month, 1)
    return result


def _weekly_dates(dow: int, start: date, end: date) -> list[date]:
    """매주 특정 요일(0=월~6=일)이 start~end 범위 안에 있는 날짜 목록."""
    # start부터 해당 요일까지의 offset
    offset = (dow - start.weekday()) % 7
    first = start + timedelta(days=offset)
    result: list[date] = []
    cur = first
    while cur <= end:
        result.append(cur)
        cur += timedelta(weeks=1)
    return result


def _biweekly_dates(dow: int, anchor: date, start: date, end: date) -> list[date]:
    """격주 특정 요일. anchor(effective_from)를 기준으로 2주 간격."""
    # anchor 날짜에서 해당 요일의 첫 번째 날짜 찾기
    offset = (dow - anchor.weekday()) % 7
    first_occurrence = anchor + timedelta(days=offset)

    result: list[date] = []
    cur = first_occurrence
    # start 이전이면 2주씩 전진해서 범위 시작점 찾기
    if cur < start:
        weeks_ahead = ((start - cur).days + 13) // 14
        cur = cur + timedelta(weeks=weeks_ahead * 2)
    while cur <= end:
        if cur >= start:
            result.append(cur)
        cur += timedelta(weeks=2)
    return result


def _daily_dates(start: date, end: date) -> list[date]:
    """매일 — start~end 범위의 모든 날짜."""
    result: list[date] = []
    cur = start
    while cur <= end:
        result.append(cur)
        cur += timedelta(days=1)
    return result


def occurrence_dates(
    frequency: Frequency,
    day: int | None,
    dow: int | None,
    anchor: date,
    start: date,
    end: date,
) -> list[date]:
    """주어진 반복 유형에 따른 start~end 내 발생 날짜 목록."""
    if frequency == Frequency.monthly and day is not None:
        return _monthly_dates(day, start, end)
    if frequency == Frequency.weekly and dow is not None:
        return _weekly_dates(dow, start, end)
    if frequency == Frequency.biweekly and dow is not None:
        return _biweekly_dates(dow, anchor, start, end)
    if frequency == Frequency.daily:
        return _daily_dates(start, end)
    return []
