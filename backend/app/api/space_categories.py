from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.deps import DbDep, SpaceDep
from app.models.space_finance import SpaceCategory
from app.schemas.space_common import SpaceCategoryCreate, SpaceCategoryResponse

router = APIRouter(prefix="/spaces/{space_id}/categories", tags=["space-categories"])


@router.get("", response_model=list[SpaceCategoryResponse])
def list_space_categories(space: SpaceDep, db: DbDep):
    return db.scalars(select(SpaceCategory).where(SpaceCategory.space_id == space.id)).all()


@router.post("", response_model=SpaceCategoryResponse, status_code=status.HTTP_201_CREATED)
def create_space_category(body: SpaceCategoryCreate, space: SpaceDep, db: DbDep):
    obj = SpaceCategory(space_id=space.id, **body.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_space_category(category_id: int, space: SpaceDep, db: DbDep):
    obj = db.scalar(
        select(SpaceCategory).where(SpaceCategory.id == category_id, SpaceCategory.space_id == space.id)
    )
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(obj)
    db.commit()
