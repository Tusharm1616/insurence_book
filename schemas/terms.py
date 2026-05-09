from pydantic import BaseModel
from typing import List, Any
from datetime import datetime

class TermsUpdate(BaseModel):
    title: str
    version: str
    content: List[Any]

class TermsResponse(TermsUpdate):
    id: int
    updated_at: datetime

    class Config:
        from_attributes = True
