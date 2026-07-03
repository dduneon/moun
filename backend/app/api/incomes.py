import calendar
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import delete as sql_delete, select

from app.core.deps import DbDep, UserDep
from app.models.income import Income
from app.models.transaction import Transaction
from app.schemas.common import IncomeCreate, IncomeDelete, IncomePatch, IncomeResponse

router = APIRouter(prefix="/incomes", tags=["incomes"])


def _get_or_404(db, user_id: int, income_id: int) -> Income:
    obj = db.scalar(select(Income).where(Income.id == income_id, Income.user_id == user_id))
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


def _month_end(month_start: date) -> date:
    last = calendar.monthrange(month_start.year, month_start.month)[1]
    return month_start.replace(day=last)


def _latest_per_group(db, user_id: int, for_month: date | None = None):
    """그룹별로 조회 시점 이전의 가장 최신 버전 반환.
    for_month=None이면 관리 화면용 — 오늘(day 단위) 기준으로 아직 시작 전인 그룹은
    가장 이른 예정 버전을 대신 반환한다.
    for_month이 주어지면 해당 달(캘린더) 조회용 — 그 달이 끝나기 전에 시작한 버전까지 포함한다
    (effective_from이 월 중간의 특정 날짜여도 그 달에는 표시되어야 하므로)."""
    is_management_view = for_month is None
    cutoff = date.today() if is_management_view else _month_end(for_month)
    end_date_ref = date.today() if is_management_view else for_month

    q = (
        select(Income)
        .where(Income.user_id == user_id)
        # end_date가 없거나, end_date_ref 이후인 것만
        .where((Income.end_date.is_(None)) | (Income.end_date > end_date_ref))
    )
    if not is_management_view:
        q = q.where(Income.effective_from <= cutoff)

    all_rows = db.scalars(q.order_by(Income.group_id, Income.effective_from.asc())).all()

    groups: dict[int, list[Income]] = {}
    for row in all_rows:
        gid = row.group_id or row.id
        groups.setdefault(gid, []).append(row)

    result = []
    for rows in groups.values():
        current = [r for r in rows if r.effective_from <= cutoff]
        if current:
            result.append(current[-1])
        elif is_management_view:
            result.append(rows[0])
    return result


@router.get("", response_model=list[IncomeResponse])
def list_incomes(db: DbDep, user: UserDep, month: date | None = None):
    return _latest_per_group(db, user.id, for_month=month)


@router.post("", response_model=IncomeResponse, status_code=status.HTTP_201_CREATED)
def create_income(body: IncomeCreate, db: DbDep, user: UserDep):
    today = date.today()
    fields = body.model_dump(exclude={"include_current_cycle"})

    # 이번 사이클 발생분을 건너뛸 경우 → 다음 발생일(내일 이후)부터 추적.
    # 월별 반복은 다음 달로, 주/격주/매일 반복은 다음 실제 발생일로 자연스럽게 이어진다
    # (실제 발생일 계산은 schedule_generator의 effective_from 기준 필터링에서 처리).
    if not body.include_current_cycle:
        effective_from = today + timedelta(days=1)
    else:
        effective_from = today.replace(day=1)

    obj = Income(user_id=user.id, effective_from=effective_from, **fields)
    db.add(obj)
    db.flush()
    obj.group_id = obj.id
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{income_id}", response_model=IncomeResponse)
def get_income(income_id: int, db: DbDep, user: UserDep):
    return _get_or_404(db, user.id, income_id)


@router.patch("/{income_id}", response_model=IncomeResponse)
def patch_income(income_id: int, body: IncomePatch, db: DbDep, user: UserDep):
    current = _get_or_404(db, user.id, income_id)
    fields = body.model_dump(exclude_unset=True)
    effective_from = fields.pop("effective_from", None)

    if not fields:
        return current

    group_id = current.group_id or current.id

    if effective_from is None:
        # effective_from 미지정 → 단순 인플레이스 수정
        for k, v in fields.items():
            setattr(current, k, v)
        db.commit()
        db.refresh(current)
        return current

    # effective_from 이후 버전들을 모두 제거하고 새 버전 삽입
    # (처음부터 → 전체 삭제 후 단일 버전, 이번달/다음달부터 → 해당 월 이후 버전 교체)
    later_rows = db.scalars(
        select(Income).where(
            Income.user_id == user.id,
            Income.group_id == group_id,
            Income.effective_from >= effective_from,
        ).order_by(Income.effective_from.asc())
    ).all()

    # 삭제 전 기준값 스냅샷 (current 가 later_rows 에 포함될 수 있으므로 미리 저장)
    base_name = current.name
    base_frequency = current.frequency
    base_scheduled_day = current.scheduled_day
    base_day_of_week = current.day_of_week
    base_expected_amount = current.expected_amount
    base_category_id = current.category_id

    for row in later_rows:
        db.delete(row)
    db.flush()

    new_obj = Income(
        user_id=user.id,
        name=fields.get("name", base_name),
        frequency=fields.get("frequency", base_frequency),
        scheduled_day=fields.get("scheduled_day", base_scheduled_day),
        day_of_week=fields.get("day_of_week", base_day_of_week),
        expected_amount=fields.get("expected_amount", base_expected_amount),
        category_id=fields.get("category_id", base_category_id),
        group_id=group_id,
        effective_from=effective_from,
    )
    db.add(new_obj)
    db.commit()
    db.refresh(new_obj)
    return new_obj


@router.delete("/{income_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_income(income_id: int, body: IncomeDelete, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, income_id)
    group_id = obj.group_id or obj.id
    rows = db.scalars(
        select(Income).where(
            Income.user_id == user.id,
            Income.group_id == group_id,
        )
    ).all()
    income_ids = [r.id for r in rows]

    if body.end_from is None:
        # 전체 삭제: 자동 생성된 트랜잭션도 함께 삭제
        db.execute(
            sql_delete(Transaction).where(
                Transaction.source_income_id.in_(income_ids)
            )
        )
        for row in rows:
            db.delete(row)
    else:
        # 소프트 삭제: end_from 이후 자동 생성 트랜잭션 삭제
        db.execute(
            sql_delete(Transaction).where(
                Transaction.source_income_id.in_(income_ids),
                Transaction.transaction_date >= body.end_from,
            )
        )
        for row in rows:
            row.end_date = body.end_from
    db.commit()
