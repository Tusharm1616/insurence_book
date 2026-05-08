from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
import uvicorn
import logging
import os
from contextlib import asynccontextmanager
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from database import engine, Base, get_db
from utils.auth import verify_password, get_password_hash, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
from models.users import User, UserRole

from fastapi.middleware.cors import CORSMiddleware
from routes import auth, customers, policies, dashboard, life_insurance, reminders, motor, two_wheeler

# Rate limiting configuration
limiter = Limiter(key_func=get_remote_address)

# Create database tables
import asyncio
async def init_db():
    import socket
    max_retries = 5
    for attempt in range(max_retries):
        try:
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
                    # Motor insurance tables creation
                    """
                    CREATE TABLE IF NOT EXISTS motor_insurance_policies (
                        id SERIAL PRIMARY KEY,
                        policy_id INTEGER REFERENCES policies(id) ON DELETE CASCADE,
                        agent_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                        customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
                        insurance_type VARCHAR(50) NOT NULL DEFAULT 'comprehensive',
                        vehicle_type VARCHAR(10) NOT NULL,
                        vehicle_make VARCHAR(100) NOT NULL,
                        vehicle_model VARCHAR(100) NOT NULL,
                        vehicle_variant VARCHAR(100),
                        manufacture_year INTEGER NOT NULL,
                        registration_number VARCHAR(20) UNIQUE NOT NULL,
                        cubic_capacity INTEGER NOT NULL,
                        fuel_type VARCHAR(20),
                        idv FLOAT NOT NULL,
                        ncb_percent FLOAT DEFAULT 0.0,
                        previous_policy_number VARCHAR(100),
                        previous_insurer VARCHAR(100),
                        policy_expiry_date DATE,
                        coverage_details JSON,
                        zero_depreciation BOOLEAN DEFAULT FALSE,
                        engine_protection BOOLEAN DEFAULT FALSE,
                        return_to_invoice BOOLEAN DEFAULT FALSE,
                        roadside_assistance BOOLEAN DEFAULT FALSE,
                        consumable_cover BOOLEAN DEFAULT FALSE,
                        personal_accident_cover BOOLEAN DEFAULT TRUE,
                        passenger_cover BOOLEAN DEFAULT FALSE,
                        driver_cover BOOLEAN DEFAULT FALSE,
                        base_premium FLOAT,
                        third_party_premium FLOAT,
                        own_damage_premium FLOAT,
                        addons_premium FLOAT,
                        net_premium FLOAT,
                        gst_amount FLOAT,
                        final_premium FLOAT,
                        issue_date DATE NOT NULL,
                        expiry_date DATE NOT NULL,
                        cashless_garage_network BOOLEAN DEFAULT TRUE,
                        fast_claim_settlement BOOLEAN DEFAULT TRUE,
                        roadside_assistance_24x7 BOOLEAN DEFAULT TRUE,
                        personal_accident_cover_24x7 BOOLEAN DEFAULT TRUE,
                        hassle_free_process BOOLEAN DEFAULT TRUE,
                        claim_history JSON,
                        claim_free_years INTEGER DEFAULT 0,
                        is_active BOOLEAN DEFAULT TRUE,
                        is_renewed BOOLEAN DEFAULT FALSE,
                        special_conditions TEXT,
                        agent_notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                    """,
                    """
                    CREATE TABLE IF NOT EXISTS motor_insurance_quotes (
                        id SERIAL PRIMARY KEY,
                        agent_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                        customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
                        quote_number VARCHAR(100) UNIQUE NOT NULL,
                        insurance_type VARCHAR(50) NOT NULL,
                        vehicle_type VARCHAR(10) NOT NULL,
                        vehicle_make VARCHAR(100) NOT NULL,
                        vehicle_model VARCHAR(100) NOT NULL,
                        manufacture_year INTEGER NOT NULL,
                        registration_number VARCHAR(20),
                        cubic_capacity INTEGER NOT NULL,
                        fuel_type VARCHAR(20),
                        idv FLOAT NOT NULL,
                        ncb_percent FLOAT DEFAULT 0.0,
                        base_premium FLOAT,
                        third_party_premium FLOAT,
                        own_damage_premium FLOAT,
                        addons_premium FLOAT,
                        net_premium FLOAT,
                        gst_amount FLOAT,
                        final_premium FLOAT,
                        selected_addons JSON,
                        status VARCHAR(20) DEFAULT 'pending',
                        valid_until DATE,
                        created_at DATE DEFAULT CURRENT_DATE,
                        updated_at DATE DEFAULT CURRENT_DATE
                    );
                    """,
                    """
                    CREATE TABLE IF NOT EXISTS reminders (
                        id SERIAL PRIMARY KEY,
                        agent_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                        customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
                        title VARCHAR NOT NULL,
                        reminder_type VARCHAR DEFAULT 'birthday',
                        person_name VARCHAR NOT NULL,
                        phone_number VARCHAR,
                        reminder_date DATE NOT NULL,
                        notes TEXT,
                        is_active BOOLEAN DEFAULT TRUE,
                        notify_whatsapp BOOLEAN DEFAULT TRUE,
                        notify_call BOOLEAN DEFAULT FALSE,
                        days_before INTEGER DEFAULT 0,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                    """,
                    # Indexes
                    "CREATE INDEX IF NOT EXISTS ix_customers_agent_id ON customers(agent_id);",
                    "CREATE INDEX IF NOT EXISTS ix_customers_agent_dob ON customers(agent_id, dob);",
                    "CREATE INDEX IF NOT EXISTS ix_customers_agent_anniversary ON customers(agent_id, anniversary_date);",
                    "CREATE INDEX IF NOT EXISTS ix_policies_agent_status ON policies(agent_id, status);",
                    "CREATE INDEX IF NOT EXISTS ix_policies_agent_type ON policies(agent_id, policy_type);",
                    "CREATE INDEX IF NOT EXISTS ix_policies_agent_expiry_live ON policies(agent_id, expiry_date) WHERE status = 'live';",
                    "CREATE INDEX IF NOT EXISTS ix_policies_agent_maturity_live ON policies(agent_id, maturity_date) WHERE status = 'live';",
                    # Reminder indexes
                    "CREATE INDEX IF NOT EXISTS ix_reminders_agent_id ON reminders(agent_id);",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_date ON reminders(reminder_date);",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_agent_date ON reminders(agent_id, reminder_date);",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_type ON reminders(reminder_type);",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_active ON reminders(is_active);",
                    # Motor insurance indexes
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_agent_id ON motor_insurance_policies(agent_id);",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_customer_id ON motor_insurance_policies(customer_id);",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_reg_no ON motor_insurance_policies(registration_number);",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_type ON motor_insurance_policies(insurance_type);",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_expiry ON motor_insurance_policies(expiry_date);",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quotes_agent_id ON motor_insurance_quotes(agent_id);",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quotes_customer_id ON motor_insurance_quotes(customer_id);",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quotes_number ON motor_insurance_quotes(quote_number);",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quotes_status ON motor_insurance_quotes(status);",
                    "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
                ]
                
                for sql in migrations:
                    try:
                        await conn.execute(text(sql))
                    except Exception:
                        # Ignore errors for existing columns/indexes
                        pass
            print("Database connected and initialized successfully.")
            break
        except Exception as e:
            print(f"Database connection attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                await asyncio.sleep(2)
            else:
                print("Max retries reached. Database initialization failed.")
                raise

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logger.info("Starting InsureBook API...")
    await init_db()
    logger.info("InsureBook API started successfully")
    yield
    # Shutdown
    logger.info("Shutting down InsureBook API...")

app = FastAPI(title="InsureBook API", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS configuration
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",") if os.getenv("ALLOWED_ORIGINS") else ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(auth.api_auth_router)
app.include_router(customers.router)
app.include_router(policies.router)
app.include_router(dashboard.router)
app.include_router(life_insurance.router)
app.include_router(reminders.router)
app.include_router(motor.router)
app.include_router(two_wheeler.router)

@app.get("/")
@limiter.limit("100/minute")
def read_root(request):
    return {"message": "Welcome to InsureBook API", "version": "2.0.0"}

@app.get("/health")
@limiter.limit("200/minute")
def health_check(request):
    return {"status": "healthy", "service": "InsureBook API"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
