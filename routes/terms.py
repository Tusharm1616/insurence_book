from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from models.terms import TermsConditions
from models.users import User
from schemas.terms import TermsResponse, TermsUpdate
from utils.auth import get_current_user

router = APIRouter(prefix="/terms", tags=["Terms & Conditions"])

@router.get("/", response_model=TermsResponse)
async def get_terms(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(TermsConditions).order_by(TermsConditions.id.desc()).limit(1))
    terms = result.scalars().first()
    if not terms:
        raise HTTPException(status_code=404, detail="Terms not found")
    return terms

@router.put("/", response_model=TermsResponse)
async def update_terms(
    terms_in: TermsUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result = await db.execute(select(TermsConditions).order_by(TermsConditions.id.desc()).limit(1))
    terms = result.scalars().first()
    if terms:
        terms.title = terms_in.title
        terms.version = terms_in.version
        terms.content = terms_in.content
    else:
        terms = TermsConditions(
            title=terms_in.title,
            version=terms_in.version,
            content=terms_in.content
        )
        db.add(terms)
    await db.commit()
    await db.refresh(terms)
    return terms
