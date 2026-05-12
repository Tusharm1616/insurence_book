from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.exception_handlers import http_exception_handler
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import uvicorn
import logging
import os
from contextlib import asynccontextmanager
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi.responses import JSONResponse
from fastapi import Request
import time

from database import engine, Base, get_db
from utils.auth import verify_password, get_password_hash, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES, get_current_user
from models.users import User, UserRole

from fastapi.middleware.cors import CORSMiddleware
from routes import auth, customers, policies, dashboard, life_insurance, reminders, motor, two_wheeler, add_policy, vehicle, terms, vehicle_documents, customers_api, policies_api

# Rate limiting configuration
limiter = Limiter(key_func=get_remote_address)

# Create database tables
import asyncio
async def init_db():
    import socket
    max_retries = 5
    for attempt in range(max_retries):
        try:
            # 1. First, create missing tables
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
                "ALTER TABLE customers ADD COLUMN IF NOT EXISTS date_of_birth DATE;",
                "ALTER TABLE customers ADD COLUMN IF NOT EXISTS anniversary_date DATE;",
                "ALTER TABLE customers ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';",
                "ALTER TABLE policies ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';",
                "ALTER TABLE policies ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE;",
                "ALTER TABLE policies ADD COLUMN IF NOT EXISTS end_date DATE DEFAULT CURRENT_DATE + INTERVAL '1 year';",
                # Fix missing columns in policies table
                "ALTER TABLE policies ALTER COLUMN policy_number SET NOT NULL DEFAULT '';",
                "ALTER TABLE policies ALTER COLUMN policy_type SET NOT NULL DEFAULT 'Other';",
                "ALTER TABLE policies ALTER COLUMN status SET NOT NULL DEFAULT 'active';",
                "ALTER TABLE policies ALTER COLUMN issue_date SET NOT NULL DEFAULT CURRENT_DATE;",
                "ALTER TABLE policies ALTER COLUMN expiry_date SET NOT NULL DEFAULT CURRENT_DATE + INTERVAL '1 year';",
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
                    title VARCHAR(255) NOT NULL,
                    reminder_type VARCHAR(50) DEFAULT 'birthday',
                    person_name VARCHAR(255) NOT NULL,
                    phone_number VARCHAR(20),
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
                """
                CREATE TABLE IF NOT EXISTS vehicle_document_cache (
                    id SERIAL PRIMARY KEY,
                    registration_number VARCHAR(20) UNIQUE NOT NULL,
                    documents JSONB NOT NULL,
                    fetched_at TIMESTAMP DEFAULT NOW(),
                    expires_at TIMESTAMP NOT NULL,
                    created_at TIMESTAMP DEFAULT NOW()
                );
                """,
                """
                CREATE TABLE IF NOT EXISTS motor_quote_history (
                    id SERIAL PRIMARY KEY,
                    agent_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                    customer_name VARCHAR(100),
                    vehicle_type VARCHAR(20),
                    vehicle_reg_no VARCHAR(20),
                    year_of_manufacture INTEGER,
                    cc_category VARCHAR(20),
                    fuel_type VARCHAR(20),
                    idv DECIMAL(12,2),
                    ncb_percent DECIMAL(5,2),
                    addons JSONB,
                    od_premium DECIMAL(10,2),
                    tp_premium DECIMAL(10,2),
                    addons_total DECIMAL(10,2),
                    gst DECIMAL(10,2),
                    total_premium DECIMAL(10,2),
                    pdf_url TEXT,
                    created_at TIMESTAMP DEFAULT NOW()
                );
                """,
                """
                CREATE TABLE IF NOT EXISTS terms_conditions (
                    id SERIAL PRIMARY KEY,
                    title VARCHAR(255) DEFAULT 'Terms and Conditions',
                    version VARCHAR(50) DEFAULT '1.0.0',
                    content JSONB NOT NULL,
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
                """
                CREATE TABLE IF NOT EXISTS vehicle_documents (
                    id SERIAL PRIMARY KEY,
                    agent_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
                    vehicle_number VARCHAR(20) NOT NULL,
                    vehicle_type VARCHAR(50) NOT NULL,
                    vehicle_model VARCHAR(100) NOT NULL,
                    manufacturer VARCHAR(100) NOT NULL,
                    fuel_type VARCHAR(30) NOT NULL,
                    registration_year INTEGER,
                    insurance_expiry DATE,
                    puc_expiry DATE,
                    rc_expiry DATE,
                    license_expiry DATE,
                    fitness_expiry DATE,
                    reminder_sent BOOLEAN DEFAULT FALSE,
                    notes TEXT,
                    created_at TIMESTAMP DEFAULT NOW(),
                    updated_at TIMESTAMP DEFAULT NOW()
                );
                """,
                "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_agent_id ON vehicle_documents(agent_id);",
                "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_customer_id ON vehicle_documents(customer_id);",
                "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_vehicle_number ON vehicle_documents(vehicle_number);",
                "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_insurance_expiry ON vehicle_documents(insurance_expiry);",
                "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_puc_expiry ON vehicle_documents(puc_expiry);",
                # Indexes
                "CREATE INDEX IF NOT EXISTS ix_motor_quote_history_agent_id ON motor_quote_history(agent_id);"
            ]
            
            # 2. Execute migrations one by one, each in its own connection
            print(f"DEBUG: Starting migrations execution ({len(migrations)} tasks)...")
            for sql in migrations:
                try:
                    async with engine.begin() as migration_conn:
                        await migration_conn.execute(text(sql))
                except Exception as migration_error:
                    # Log but continue - often these are "column already exists" errors
                    if "already exists" not in str(migration_error).lower():
                        print(f"Migration notice for '{sql[:30]}...': {migration_error}")
            
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

# Middleware for logging requests
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    # Avoid logging docs/openapi for cleaner logs
    if not request.url.path.startswith(("/docs", "/openapi.json")):
        auth_header = request.headers.get("Authorization")
        has_auth = "Yes" if auth_header else "No"
        # Print concise request log
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {request.method} {request.url.path} -> {response.status_code} (Auth: {has_auth})")
    return response

# Global Exception Handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    if isinstance(exc, HTTPException):
        return await http_exception_handler(request, exc)
        
    import traceback
    logging.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "detail": "An internal server error occurred.",
            "error_type": str(type(exc).__name__),
            "traceback": traceback.format_exc(),
            "timestamp": datetime.utcnow().isoformat()
        },
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Diagnostic Ping Endpoint
@app.get("/api/ping")
async def ping(current_user: User = Depends(get_current_user)):
    return {
        "status": "success",
        "message": "Authentication working!",
        "user": current_user.email or current_user.username
    }

app.include_router(auth.router)
app.include_router(auth.api_auth_router)
app.include_router(customers.router)
app.include_router(policies.router)
app.include_router(dashboard.router)
app.include_router(life_insurance.router)
app.include_router(reminders.router)
app.include_router(motor.router)
app.include_router(two_wheeler.router)
app.include_router(add_policy.router)
app.include_router(vehicle.router)
app.include_router(terms.router)
app.include_router(vehicle_documents.router)
app.include_router(customers_api.router)
app.include_router(policies_api.router)

from datetime import datetime

@app.get("/")
@limiter.limit("100/minute")
def read_root(request):
    return {
        "message": "Welcome to InsureBook API",
        "version": "2.1.0",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health")
@limiter.limit("200/minute")
def health_check(request):
    return {
        "status": "healthy",
        "service": "InsureBook API",
        "version": "2.1.0",
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }

@app.get("/api/version")
@limiter.limit("100/minute")
def get_version(request):
    return {
        "api_version": "2.1.0",
        "min_app_version": "1.0.0",
        "build": "2026.05.10",
        "features": {
            "motor_calculator": True,
            "life_insurance_reports": True,
            "whatsapp_reminders": True,
            "terms_conditions": True,
            "change_password": True,
            "dark_mode": True,
            "vehicle_lookup": True,
            "lead_management": True,
        },
        "maintenance_mode": False,
        "contact_support": "support@insurebook.in"
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
