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
from routes import notifications as notifications_router

# Rate limiting
limiter = Limiter(key_func=get_remote_address)

# ─────────────────────────────────────────────────────────────────────────────
# Migration helper — every statement runs in its OWN connection+transaction.
# A failure in one statement NEVER poisons subsequent statements.
# ─────────────────────────────────────────────────────────────────────────────
import asyncio
from sqlalchemy import text as _sa_text

async def _run_sql(sql: str, label: str = "") -> None:
    try:
        async with engine.begin() as conn:
            await conn.execute(_sa_text(sql.strip()))
    except Exception as e:
        msg = str(e).lower()
        harmless = any(k in msg for k in (
            "already exists", "does not exist", "duplicate",
            "multiple primary keys", "column already exists",
        ))
        if not harmless:
            print(f"[migration] {label}: {str(e)[:150]}")


async def init_db():
    max_retries = 5
    for attempt in range(max_retries):
        try:
            # 1. Create brand-new tables defined in SQLAlchemy models
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            print("DEBUG: create_all done.")

            # 2. Schema migrations — (label, sql) tuples, each fully isolated
            migrations = [

                # ── CUSTOMERS ────────────────────────────────────────────────
                ("customers mobile_number->phone", """
                    DO $$ BEGIN
                        IF EXISTS (SELECT 1 FROM information_schema.columns
                                   WHERE table_name='customers' AND column_name='mobile_number')
                        AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                                        WHERE table_name='customers' AND column_name='phone')
                        THEN ALTER TABLE customers RENAME COLUMN mobile_number TO phone;
                        END IF;
                    END $$
                """),
                ("customers add phone",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS phone VARCHAR(15)"),
                ("customers date_of_birth->dob", """
                    DO $$ BEGIN
                        IF EXISTS (SELECT 1 FROM information_schema.columns
                                   WHERE table_name='customers' AND column_name='date_of_birth')
                        AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                                        WHERE table_name='customers' AND column_name='dob')
                        THEN ALTER TABLE customers RENAME COLUMN date_of_birth TO dob;
                        END IF;
                    END $$
                """),
                ("customers add dob",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS dob DATE"),
                ("customers add email",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS email VARCHAR(100)"),
                ("customers add address",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS address TEXT"),
                ("customers add city",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS city VARCHAR(80)"),
                ("customers add state",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS state VARCHAR(80)"),
                ("customers add pincode",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS pincode VARCHAR(10)"),
                ("customers add status",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active'"),
                ("customers add anniversary_date",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS anniversary_date DATE"),
                ("customers add created_at",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS created_at DATE DEFAULT CURRENT_DATE"),
                ("customers add updated_at",
                    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS updated_at DATE DEFAULT CURRENT_DATE"),

                # ── USERS ────────────────────────────────────────────────────
                ("users add phone",
                    "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR"),
                ("users add license_no",
                    "ALTER TABLE users ADD COLUMN IF NOT EXISTS license_no VARCHAR"),

                # ── POLICIES ─────────────────────────────────────────────────
                ("policies insurance_type->policy_type", """
                    DO $$ BEGIN
                        IF EXISTS (SELECT 1 FROM information_schema.columns
                                   WHERE table_name='policies' AND column_name='insurance_type')
                        AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                                        WHERE table_name='policies' AND column_name='policy_type')
                        THEN ALTER TABLE policies RENAME COLUMN insurance_type TO policy_type;
                        END IF;
                    END $$
                """),
                ("policies renewal_date->premium_due_date", """
                    DO $$ BEGIN
                        IF EXISTS (SELECT 1 FROM information_schema.columns
                                   WHERE table_name='policies' AND column_name='renewal_date')
                        AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                                        WHERE table_name='policies' AND column_name='premium_due_date')
                        THEN ALTER TABLE policies RENAME COLUMN renewal_date TO premium_due_date;
                        END IF;
                    END $$
                """),
                ("policies sum_insured->sum_assured", """
                    DO $$ BEGIN
                        IF EXISTS (SELECT 1 FROM information_schema.columns
                                   WHERE table_name='policies' AND column_name='sum_insured')
                        AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                                        WHERE table_name='policies' AND column_name='sum_assured')
                        THEN ALTER TABLE policies RENAME COLUMN sum_insured TO sum_assured;
                        END IF;
                    END $$
                """),
                ("policies add sum_assured",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS sum_assured NUMERIC(14,2)"),
                ("policies add agent_id",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS agent_id INTEGER REFERENCES users(id) ON DELETE CASCADE"),
                ("policies add policy_type",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS policy_type VARCHAR(60)"),
                ("policies add status",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active'"),
                ("policies add issue_date",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS issue_date DATE DEFAULT CURRENT_DATE"),
                ("policies add expiry_date",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS expiry_date DATE DEFAULT CURRENT_DATE + INTERVAL '1 year'"),
                ("policies add start_date",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE"),
                ("policies add end_date",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS end_date DATE DEFAULT CURRENT_DATE + INTERVAL '1 year'"),
                ("policies add premium_due_date",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS premium_due_date DATE"),
                ("policies add maturity_date",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS maturity_date DATE"),
                ("policies add ncb_percent",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS ncb_percent FLOAT DEFAULT 0.0"),
                ("policies add vehicle_reg_no",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS vehicle_reg_no VARCHAR(20)"),
                ("policies add payment_mode",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS payment_mode VARCHAR(20)"),
                ("policies add nominee_name",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS nominee_name VARCHAR(120)"),
                ("policies add nominee_relation",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS nominee_relation VARCHAR(60)"),
                ("policies add notes",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS notes TEXT"),
                ("policies add plan_name",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS plan_name VARCHAR(120)"),
                ("policies add insurer_name",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS insurer_name VARCHAR(120)"),
                ("policies add created_at",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS created_at DATE DEFAULT CURRENT_DATE"),
                ("policies add updated_at",
                    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS updated_at DATE DEFAULT CURRENT_DATE"),
                # NOTE: PostgreSQL requires SET NOT NULL and SET DEFAULT as separate statements
                ("policies policy_number not null",
                    "ALTER TABLE policies ALTER COLUMN policy_number SET NOT NULL"),
                ("policies policy_number default",
                    "ALTER TABLE policies ALTER COLUMN policy_number SET DEFAULT ''"),
                ("policies status default",
                    "ALTER TABLE policies ALTER COLUMN status SET DEFAULT 'active'"),

                # ── CREATE TABLES ─────────────────────────────────────────────
                ("create motor_insurance_policies", """
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
                        issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
                        expiry_date DATE NOT NULL DEFAULT CURRENT_DATE + INTERVAL '1 year',
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
                    )
                """),
                ("create motor_insurance_quotes", """
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
                    )
                """),
                ("create reminders", """
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
                    )
                """),
                ("create vehicle_document_cache", """
                    CREATE TABLE IF NOT EXISTS vehicle_document_cache (
                        id SERIAL PRIMARY KEY,
                        registration_number VARCHAR(20) UNIQUE NOT NULL,
                        documents JSONB NOT NULL,
                        fetched_at TIMESTAMP DEFAULT NOW(),
                        expires_at TIMESTAMP NOT NULL,
                        created_at TIMESTAMP DEFAULT NOW()
                    )
                """),
                ("create motor_quote_history", """
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
                    )
                """),
                ("create terms_conditions", """
                    CREATE TABLE IF NOT EXISTS terms_conditions (
                        id SERIAL PRIMARY KEY,
                        title VARCHAR(255) DEFAULT 'Terms and Conditions',
                        version VARCHAR(50) DEFAULT '1.0.0',
                        content JSONB NOT NULL,
                        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                    )
                """),
                ("create vehicle_documents", """
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
                    )
                """),

                # ── INDEXES ───────────────────────────────────────────────────
                ("idx customers agent_id",
                    "CREATE INDEX IF NOT EXISTS ix_customers_agent_id ON customers(agent_id)"),
                ("idx customers dob",
                    "CREATE INDEX IF NOT EXISTS ix_customers_agent_dob ON customers(agent_id, dob)"),
                ("idx customers anniversary",
                    "CREATE INDEX IF NOT EXISTS ix_customers_agent_anniversary ON customers(agent_id, anniversary_date)"),
                ("idx policies agent_status",
                    "CREATE INDEX IF NOT EXISTS ix_policies_agent_status ON policies(agent_id, status)"),
                ("idx policies agent_type",
                    "CREATE INDEX IF NOT EXISTS ix_policies_agent_type ON policies(agent_id, policy_type)"),
                ("idx policies expiry live",
                    "CREATE INDEX IF NOT EXISTS ix_policies_agent_expiry_live ON policies(agent_id, expiry_date) WHERE status = 'live'"),
                ("idx policies maturity live",
                    "CREATE INDEX IF NOT EXISTS ix_policies_agent_maturity_live ON policies(agent_id, maturity_date) WHERE status = 'live'"),
                ("idx reminders agent_id",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_agent_id ON reminders(agent_id)"),
                ("idx reminders date",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_date ON reminders(reminder_date)"),
                ("idx reminders agent_date",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_agent_date ON reminders(agent_id, reminder_date)"),
                ("idx reminders type",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_type ON reminders(reminder_type)"),
                ("idx reminders active",
                    "CREATE INDEX IF NOT EXISTS ix_reminders_active ON reminders(is_active)"),
                ("idx motor policies agent",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_agent_id ON motor_insurance_policies(agent_id)"),
                ("idx motor policies customer",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_customer_id ON motor_insurance_policies(customer_id)"),
                ("idx motor policies reg_no",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_reg_no ON motor_insurance_policies(registration_number)"),
                ("idx motor policies type",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_type ON motor_insurance_policies(insurance_type)"),
                ("idx motor policies expiry",
                    "CREATE INDEX IF NOT EXISTS ix_motor_policies_expiry ON motor_insurance_policies(expiry_date)"),
                ("idx motor quotes agent",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quotes_agent_id ON motor_insurance_quotes(agent_id)"),
                ("idx motor quotes customer",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quotes_customer_id ON motor_insurance_quotes(customer_id)"),
                ("idx motor quotes number",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quotes_number ON motor_insurance_quotes(quote_number)"),
                ("idx motor quotes status",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quotes_status ON motor_insurance_quotes(status)"),
                ("idx vehicle_docs agent",
                    "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_agent_id ON vehicle_documents(agent_id)"),
                ("idx vehicle_docs customer",
                    "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_customer_id ON vehicle_documents(customer_id)"),
                ("idx vehicle_docs number",
                    "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_vehicle_number ON vehicle_documents(vehicle_number)"),
                ("idx vehicle_docs insurance",
                    "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_insurance_expiry ON vehicle_documents(insurance_expiry)"),
                ("idx vehicle_docs puc",
                    "CREATE INDEX IF NOT EXISTS ix_vehicle_docs_puc_expiry ON vehicle_documents(puc_expiry)"),
                ("idx motor_quote_history agent",
                    "CREATE INDEX IF NOT EXISTS ix_motor_quote_history_agent_id ON motor_quote_history(agent_id)"),
            ]

            # 3. Run every migration in its own isolated connection
            print(f"DEBUG: Running {len(migrations)} migrations...")
            for label, sql in migrations:
                await _run_sql(sql, label)
            print("Database initialised successfully.")
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
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logger.info("Starting InsureBook API...")
    await init_db()

    # ── Start background scheduler ────────────────────────────────────────
    try:
        from utils.scheduler import start_scheduler
        start_scheduler()
        logger.info("Background scheduler started.")
    except Exception as sched_err:
        logger.error("Scheduler failed to start: %s", sched_err)

    logger.info("InsureBook API started successfully")
    yield

    # ── Shutdown scheduler ────────────────────────────────────────────────
    try:
        from utils.scheduler import scheduler as _scheduler
        if _scheduler.running:
            _scheduler.shutdown(wait=False)
            logger.info("Background scheduler stopped.")
    except Exception as sched_err:
        logger.error("Scheduler shutdown error: %s", sched_err)

    logger.info("Shutting down InsureBook API...")


app = FastAPI(title="InsureBook API", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",") if os.getenv("ALLOWED_ORIGINS") else ["*"]


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    if not request.url.path.startswith(("/docs", "/openapi.json")):
        has_auth = "Yes" if request.headers.get("Authorization") else "No"
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {request.method} {request.url.path} -> {response.status_code} (Auth: {has_auth})")
    return response


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


@app.get("/api/ping")
async def ping(current_user: User = Depends(get_current_user)):
    return {"status": "success", "message": "Authentication working!", "user": current_user.email or current_user.username}


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


# ── Admin: clear agent's own data ─────────────────────────────────────────────
@app.delete("/api/admin/clear-my-data")
async def clear_agent_data(
    current_user: User = Depends(get_current_user),
    db=Depends(get_db),
):
    """
    Delete ALL customers and policies belonging to the authenticated agent.
    Users/agents are NOT deleted.
    """
    from sqlalchemy import text as _t
    from sqlalchemy.ext.asyncio import AsyncSession

    agent_id = current_user.id

    # Count before
    c_count = (await db.execute(
        _t("SELECT COUNT(*) FROM customers WHERE agent_id = :a"), {"a": agent_id}
    )).scalar() or 0
    p_count = (await db.execute(
        _t("SELECT COUNT(*) FROM policies WHERE agent_id = :a"), {"a": agent_id}
    )).scalar() or 0

    # Delete motor policies linked to this agent's policies
    await db.execute(_t(
        "DELETE FROM motor_insurance_policies WHERE agent_id = :a"
    ), {"a": agent_id})

    # Delete policies
    await db.execute(_t(
        "DELETE FROM policies WHERE agent_id = :a"
    ), {"a": agent_id})

    # Delete customers
    await db.execute(_t(
        "DELETE FROM customers WHERE agent_id = :a"
    ), {"a": agent_id})

    await db.commit()

    return {
        "message": "All your customer and policy data has been deleted.",
        "deleted_customers": c_count,
        "deleted_policies": p_count,
        "agent_id": agent_id,
    }
app.include_router(vehicle_documents.router)
app.include_router(customers_api.router)
app.include_router(policies_api.router)
app.include_router(notifications_router.router)

from datetime import datetime


@app.get("/")
@limiter.limit("100/minute")
def read_root(request):
    return {"message": "Welcome to InsureBook API", "version": "2.3.0", "docs": "/docs", "health": "/health"}


@app.get("/health")
@limiter.limit("200/minute")
async def health_check(request):
    """Enhanced health check — also verifies DB connectivity."""
    from sqlalchemy import text as _t
    db_ok = False
    try:
        async with engine.connect() as conn:
            await conn.execute(_t("SELECT 1"))
        db_ok = True
    except Exception:
        db_ok = False
    return {
        "status": "healthy" if db_ok else "degraded",
        "service": "InsureBook API",
        "version": "2.3.0",
        "db": "ok" if db_ok else "error",
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


@app.get("/api/version")
@limiter.limit("100/minute")
def get_version(request):
    return {
        "api_version": "2.3.0",
        "min_app_version": "1.0.0",
        "build": "2026.05.15.v3",
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
