from sqlalchemy import Column, Integer, String, Date, ForeignKey, Boolean, Text
from sqlalchemy.orm import relationship
from database import Base
import enum

class ReminderType(str, enum.Enum):
    BIRTHDAY = "birthday"
    ANNIVERSARY = "anniversary"
    CUSTOM = "custom"

class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(Integer, primary_key=True, index=True)
    agent_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)  # Optional link to customer
    
    # Reminder Details
    title = Column(String, nullable=False)  # e.g., "Birthday", "Anniversary"
    reminder_type = Column(String, default=ReminderType.BIRTHDAY)
    person_name = Column(String, nullable=False)  # Name of the person
    phone_number = Column(String, nullable=True)  # Contact number
    reminder_date = Column(Date, nullable=False)  # The date of the event
    notes = Column(Text, nullable=True)  # Additional notes
    
    # Notification Settings
    is_active = Column(Boolean, default=True)
    notify_whatsapp = Column(Boolean, default=True)
    notify_call = Column(Boolean, default=False)
    days_before = Column(Integer, default=0)  # Days before to notify
    
    # Relationships
    agent = relationship("User", foreign_keys=[agent_id])
    customer = relationship("Customer", foreign_keys=[customer_id])
    
    def __repr__(self):
        return f"<Reminder(id={self.id}, title='{self.title}', date='{self.reminder_date}')>"
