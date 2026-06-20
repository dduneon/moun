from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.deps import DbDep, UserDep
from app.models.income import Income
from app.schemas.common import IncomeCreate, IncomePatch, IncomeResponse

router = APIRouter(prefix="/incomes", tags=["incomes"])


def _get_or_404(db, user_id: int, income_id: int) -> Income:
    obj = db.scalar(select(Income).where(Income.id == income_id, Income.user_id == user_id))
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


@router.get("", response_model=list[IncomeResponse])
def list_incomes(db: DbDep, user: UserDep):
    return db.scalars(
        select(Income).where(Income.user_id == user.id).order_by(Income.id.desc())
    ).all()


@router.post("", response_model=IncomeResponse, status_code=status.HTTP_201_CREATED)
def create_income(body: IncomeCreate, db: DbDep, user: UserDep):
    obj = Income(user_id=user.id, **body.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{income_id}", response_model=IncomeResponse)
def get_income(income_id: int, db: DbDep, user: UserDep):
    return _get_or_404(db, user.id, income_id)


@router.patch("/{income_id}", response_model=IncomeResponse)
def patch_income(income_id: int, body: IncomePatch, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, income_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{income_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_income(income_id: int, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, income_id)
    db.delete(obj)
    db.commit()
