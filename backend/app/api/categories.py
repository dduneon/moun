from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select

from app.core.deps import DbDep, UserDep
from app.models.category import Category

router = APIRouter(prefix="/categories", tags=["categories"])


class CategoryCreate(BaseModel):
    name: str
    icon: str | None = None


class CategoryResponse(BaseModel):
    id: int
    name: str
    icon: str | None
    model_config = {"from_attributes": True}


@router.get("", response_model=list[CategoryResponse])
def list_categories(db: DbDep, user: UserDep):
    return db.scalars(select(Category).where(Category.user_id == user.id)).all()


@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(body: CategoryCreate, db: DbDep, user: UserDep):
    obj = Category(user_id=user.id, **body.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(category_id: int, db: DbDep, user: UserDep):
    obj = db.scalar(
        select(Category).where(Category.id == category_id, Category.user_id == user.id)
    )
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(obj)
    db.commit()
