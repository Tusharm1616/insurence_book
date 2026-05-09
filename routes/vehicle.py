from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from database import get_db
from utils.auth import get_current_user
from models.users import User
from datetime import datetime, timedelta
import json
import re

router = APIRouter(prefix="/api/vehicle", tags=["Vehicle Documents"])

def generate_mock_documents(reg_no: str):
    # Use last 4 digits as a seed for consistent mock data
    digits = re.sub(r'\D', '', reg_no)
    seed_str = digits[-4:] if len(digits) >= 4 else "1234"
    seed = int(seed_str) if seed_str else 1234
    
    now = datetime.now()
    
    # Registration Certificate (5 to 15 years validity)
    rc_years = 5 + (seed % 10)
    rc_expiry = now + timedelta(days=365 * rc_years)
    
    # PUC (Between 30 days ago and 180 days from now)
    puc_days = (seed % 210) - 30
    puc_expiry = now + timedelta(days=puc_days)
    
    # Insurance (Between 60 days ago and 365 days from now)
    ins_days = (seed % 425) - 60
    ins_expiry = now + timedelta(days=ins_days)
    
    # Road Tax (5 to 10 years validity)
    tax_years = 5 + (seed % 5)
    tax_expiry = now + timedelta(days=365 * tax_years)
    
    def format_doc(name, expiry):
        days = (expiry - now).days
        if days < 0:
            status = "expired"
        elif days <= 30:
            status = "expiring"
        else:
            status = "valid"
            
        icon = "shield"
        if "PUC" in name: icon = "leaf"
        elif "Tax" in name: icon = "receipt"
        elif "Registration" in name: icon = "credit_card"
            
        return {
            "document_type": name.lower().replace(" ", "_"),
            "document_name": name,
            "expiry_date": expiry.isoformat(),
            "status": status,
            "days_until_expiry": days,
            "icon_name": icon
        }

    return [
        format_doc("Registration Certificate", rc_expiry),
        format_doc("Insurance", ins_expiry),
        format_doc("PUC Certificate", puc_expiry),
        format_doc("Road Tax", tax_expiry)
    ]

@router.get("/document-status")
async def get_document_status(
    reg_no: str = Query(..., description="Vehicle Registration Number"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    reg_no = reg_no.upper().replace(" ", "")
    
    # Check cache
    query = text("""
        SELECT documents 
        FROM vehicle_document_cache 
        WHERE registration_number = :reg_no AND expires_at > NOW()
    """)
    result = await db.execute(query, {"reg_no": reg_no})
    cached = result.scalar_one_or_none()
    
    if cached:
        docs = cached if isinstance(cached, list) else json.loads(cached)
        return {
            "registration_number": reg_no,
            "vehicle_make": "Maruti Suzuki" if len(reg_no) % 2 == 0 else "Honda",
            "vehicle_model": "Swift Dzire" if len(reg_no) % 2 == 0 else "City",
            "owner_name": f"Customer {reg_no[-4:]}",
            "is_mock": True,
            "documents": docs
        }
        
    # Generate mock data
    docs = generate_mock_documents(reg_no)
    
    # Save to cache
    expires_at = datetime.now() + timedelta(hours=24)
    insert_query = text("""
        INSERT INTO vehicle_document_cache (registration_number, documents, expires_at)
        VALUES (:reg_no, :docs, :expires_at)
        ON CONFLICT (registration_number) DO UPDATE 
        SET documents = EXCLUDED.documents, 
            expires_at = EXCLUDED.expires_at, 
            fetched_at = NOW()
    """)
    await db.execute(insert_query, {
        "reg_no": reg_no,
        "docs": json.dumps(docs),
        "expires_at": expires_at
    })
    await db.commit()
    
    return {
        "registration_number": reg_no,
        "vehicle_make": "Maruti Suzuki" if len(reg_no) % 2 == 0 else "Honda",
        "vehicle_model": "Swift Dzire" if len(reg_no) % 2 == 0 else "City",
        "owner_name": f"Customer {reg_no[-4:]}",
        "is_mock": True,
        "documents": docs
    }
