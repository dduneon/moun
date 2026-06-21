from datetime import date

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.deps import DbDep, UserDep
from app.models.income import Income
from app.schemas.common import IncomeCreate, IncomeDelete, IncomePatch, IncomeResponse

router = APIRouter(prefix="/incomes", tags=["incomes"])


def _get_or_404(db, user_id: int, income_id: int) -> Income:
    obj = db.scalar(select(Income).where(Income.id == income_id, Income.user_id == user_id))
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


def _latest_per_group(db, user_id: int, for_month: date | None = None):
    today_month = date.today().replace(day=1)
    ref_month = for_month if for_month is not None else today_month

    q = (
        select(Income)
        .where(Income.user_id == user_id)
        .where(Income.effective_from <= ref_month)
        # end_date가 없거나, end_date가 ref_month 이후인 것만
        .where((Income.end_date.is_(None)) | (Income.end_date > ref_month))
    )

    all_rows = db.scalars(q.order_by(Income.group_id, Income.effective_from.desc())).all()

    seen: set[int] = set()
    result = []
    for row in all_rows:
        gid = row.group_id or row.id
        if gid not in seen:
            seen.add(gid)
            result.append(row)
    return result


@router.get("", response_model=list[IncomeResponse])
def list_incomes(db: DbDep, user: UserDep, month: date | None = None):
    return _latest_per_group(db, user.id, for_month=month)


@router.post("", response_model=IncomeResponse, status_code=status.HTTP_201_CREATED)
def create_income(body: IncomeCreate, db: DbDep, user: UserDep):
    obj = Income(
        user_id=user.id,
        effective_from=date.today().replace(day=1),
        **body.model_dump(),
    )
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
    base_scheduled_day = current.scheduled_day
    base_expected_amount = current.expected_amount
    base_actual_amount = current.actual_amount
    base_received_date = current.received_date

    for row in later_rows:
        db.delete(row)
    db.flush()

    new_obj = Income(
        user_id=user.id,
        name=fields.get("name", base_name),
        scheduled_day=fields.get("scheduled_day", base_scheduled_day),
        expected_amount=fields.get("expected_amount", base_expected_amount),
        actual_amount=base_actual_amount,
        received_date=base_received_date,
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
    if body.end_from is None:
        # 전체 삭제
        for row in rows:
            db.delete(row)
    else:
        # 소프트 삭제: 모든 버전에 end_date 설정
        for row in rows:
            row.end_date = body.end_from
    db.commit()
