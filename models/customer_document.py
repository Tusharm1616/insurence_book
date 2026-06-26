import uuid
from sqlalchemy import Column, String, Integer, ForeignKey, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class CustomerDocument(Base):
    __tablename__ = "customer_documents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"))
    agent_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))

    document_type = Column(String(50), nullable=False, default="Other")
    # Values: Aadhaar, PAN, Driving Licence, RC Book, New Policy, Renewal Policy, Claim Document, Other
    document_name = Column(String(255), nullable=False)
    file_url = Column(String(500), nullable=False)
    file_size = Column(Integer, nullable=True)  # bytes
    notes = Column(String(500), nullable=True, default="")

    uploaded_at = Column(TIMESTAMP, server_default=func.now())

    # Relationships
    customer = relationship("Customer", backref="documents")
    agent = relationship("User", foreign_keys=[agent_id])
