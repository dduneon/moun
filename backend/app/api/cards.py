from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.deps import DbDep, UserDep
from app.models.card import Card
from app.schemas.common import CardCreate, CardPatch, CardResponse

router = APIRouter(prefix="/cards", tags=["cards"])


def _get_or_404(db, user_id: int, card_id: int) -> Card:
    obj = db.scalar(select(Card).where(Card.id == card_id, Card.user_id == user_id))
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


@router.get("", response_model=list[CardResponse])
def list_cards(db: DbDep, user: UserDep):
    return db.scalars(select(Card).where(Card.user_id == user.id)).all()


@router.post("", response_model=CardResponse, status_code=status.HTTP_201_CREATED)
def create_card(body: CardCreate, db: DbDep, user: UserDep):
    obj = Card(user_id=user.id, **body.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/{card_id}", response_model=CardResponse)
def get_card(card_id: int, db: DbDep, user: UserDep):
    return _get_or_404(db, user.id, card_id)


@router.patch("/{card_id}", response_model=CardResponse)
def patch_card(card_id: int, body: CardPatch, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, card_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(obj, field, value)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/{card_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_card(card_id: int, db: DbDep, user: UserDep):
    obj = _get_or_404(db, user.id, card_id)
    db.delete(obj)
    db.commit()
