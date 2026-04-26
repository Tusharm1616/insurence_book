from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
import uvicorn

from database import engine, Base, get_db
from utils.auth import verify_password, get_password_hash, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
from models.users import User, UserRole

from fastapi.middleware.cors import CORSMiddleware
from routes import auth, customers, policies, dashboard, life_insurance, reminders, motor

# Create database tables
import asyncio
async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        from sqlalchemy import text
        
        # Safely run migrations
        migrations = [
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR, ADD COLUMN IF NOT EXISTS license_no VARCHAR;",
            "ALTER TABLE policies ADD COLUMN IF NOT EXISTS agent_id INTEGER REFERENCES users(id) ON DELETE CASCADE;",
            "ALTER TABLE policies RENAME COLUMN insurance_type TO policy_type;",
            "ALTER TABLE policies ADD COLUMN IF NOT EXISTS maturity_date DATE;",
            "ALTER TABLE policies RENAME COLUMN renewal_date TO premium_due_date;",
            "ALTER TABLE policies ADD COLUMN IF NOT EXISTS ncb_percent FLOAT DEFAULT 0.0;",
            "ALTER TABLE policies ADD COLUMN IF NOT EXISTS vehicle_reg_no VARCHAR(20);",
            # Indexes
            "CREATE INDEX IF NOT EXISTS ix_customers_agent_id ON customers(agent_id);",
            "CREATE INDEX IF NOT EXISTS ix_customers_agent_dob ON customers(agent_id, dob);",
            "CREATE INDEX IF NOT EXISTS ix_customers_agent_anniversary ON customers(agent_id, anniversary_date);",
            "CREATE INDEX IF NOT EXISTS ix_policies_agent_status ON policies(agent_id, status);",
            "CREATE INDEX IF NOT EXISTS ix_policies_agent_type ON policies(agent_id, policy_type);",
            "CREATE INDEX IF NOT EXISTS ix_policies_agent_expiry_live ON policies(agent_id, expiry_date) WHERE status = 'live';",
            "CREATE INDEX IF NOT EXISTS ix_policies_agent_maturity_live ON policies(agent_id, maturity_date) WHERE status = 'live';"
        ]
        
        for sql in migrations:
            try:
                await conn.execute(text(sql))
            except Exception as e:
                # Ignore errors for existing columns/indexes
                pass

app = FastAPI(title="InsureBook API")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    await init_db()

app.include_router(auth.router)
app.include_router(auth.api_auth_router)
app.include_router(customers.router)
app.include_router(policies.router)
app.include_router(dashboard.router)
app.include_router(life_insurance.router)
app.include_router(reminders.router)
app.include_router(motor.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to InsureBook API"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
