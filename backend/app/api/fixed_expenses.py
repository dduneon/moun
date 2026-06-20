from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.deps import DbDep, UserDep
from app.models.fixed_expense import FixedExpense
from app.schemas.common import FixedExpenseCreate, FixedExpensePatch, FixedExpenseResponse

router = APIRouter(prefix="/fixed-expenses", tags=["fixed-expenses"])


def _get_or_404(db, user_id: int, obj_id: int) -> FixedExpense:
    obj = db.scalar(select(FixedExpense).where(FixedExpense.id == obj_id, FixedExpense.user_id == user_id))
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


@router.get("", response_model=list[FixedExpenseResponse])
def list_fixed_expenses(db: DbDep, user: UserDep, active_only: bool = False):
    q = select(FixedExpense).where(FixedExpense.user_id == user.id)
    if active_only:
        q = q.where(FixedExpense.is_active.is_(True))
    return db.scalars(q).all()


@router.post("", response_model=FixedExpenseResponse, status_code=status.HTTP_201_CREATED)
def create_fixed_expense(body: FixedExpenseCreate, db: DbDep, user: UserDep):
    obj = FixedExpense(user_id=user.id, **body.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{obj_id}", response_model=FixedExpenseResponse)
def get_fixed_expense(obj_id: int, db: DbDep, user: UserDep):
    return _get_or_404(db, user.id, obj_id)


@router.patch("/{obj_id}", response_model=FixedExpenseResponse)
def patch_fixed_expense(obj_id: int, body: FixedExpensePatch, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, obj_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_fixed_expense(obj_id: int, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, obj_id)
    db.delete(obj)
    db.commit()
