"""
Emergency migration script — run this directly on Railway via:
  railway run python run_migrations.py

Or paste the SQL into Railway's Postgres > Database > Query tab.
"""
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    raise SystemExit("ERROR: DATABASE_URL not set")

DATABASE_URL = (
    DATABASE_URL
    .replace("postgresql://", "postgresql+asyncpg://", 1)
    .replace("postgres://", "postgresql+asyncpg://", 1)
)

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

engine = create_async_engine(DATABASE_URL, echo=True)

MIGRATIONS = [
    # ── customers ────────────────────────────────────────────────────────
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS phone VARCHAR(15)",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS dob DATE",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS anniversary_date DATE",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS email VARCHAR(100)",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS address TEXT",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS city VARCHAR(80)",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS state VARCHAR(80)",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS pincode VARCHAR(10)",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active'",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS created_at DATE DEFAULT CURRENT_DATE",
    "ALTER TABLE customers ADD COLUMN IF NOT EXISTS updated_at DATE DEFAULT CURRENT_DATE",
    # rename mobile_number -> phone if needed
    """
    DO $$ BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='customers' AND column_name='mobile_number')
        AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                        WHERE table_name='customers' AND column_name='phone')
        THEN ALTER TABLE customers RENAME COLUMN mobile_number TO phone; END IF;
    END $$
    """,

    # ── policies ─────────────────────────────────────────────────────────
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS payment_mode VARCHAR(20)",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS nominee_name VARCHAR(120)",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS nominee_relation VARCHAR(60)",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS notes TEXT",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS plan_name VARCHAR(120)",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS insurer_name VARCHAR(120)",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS sum_assured NUMERIC(14,2)",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS issue_date DATE DEFAULT CURRENT_DATE",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS expiry_date DATE DEFAULT CURRENT_DATE + INTERVAL '1 year'",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS end_date DATE DEFAULT CURRENT_DATE + INTERVAL '1 year'",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS premium_due_date DATE",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS maturity_date DATE",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS ncb_percent FLOAT DEFAULT 0.0",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS vehicle_reg_no VARCHAR(20)",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active'",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS agent_id INTEGER",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS created_at DATE DEFAULT CURRENT_DATE",
    "ALTER TABLE policies ADD COLUMN IF NOT EXISTS updated_at DATE DEFAULT CURRENT_DATE",
    # rename sum_insured -> sum_assured if needed
    """
    DO $$ BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name='policies' AND column_name='sum_insured')
        AND NOT EXISTS (SELECT 1 FROM information_schema.columns
                        WHERE table_name='policies' AND column_name='sum_assured')
        THEN ALTER TABLE policies RENAME COLUMN sum_insured TO sum_assured; END IF;
    END $$
    """,
]

async def run():
    ok = 0
    fail = 0
    async with engine.begin() as conn:
        for sql in MIGRATIONS:
            try:
                await conn.execute(text(sql.strip()))
                ok += 1
            except Exception as e:
                msg = str(e).lower()
                if "already exists" in msg or "does not exist" in msg:
                    ok += 1  # harmless
                else:
                    print(f"WARN: {str(e)[:100]}")
                    fail += 1

    print(f"\n✅ Done: {ok} OK, {fail} warnings")

    # Show current columns
    async with engine.connect() as conn:
        r = await conn.execute(text(
            "SELECT column_name FROM information_schema.columns "
            "WHERE table_name='customers' ORDER BY ordinal_position"
        ))
        print("\ncustomers columns:", [row[0] for row in r.fetchall()])

        r2 = await conn.execute(text(
            "SELECT column_name FROM information_schema.columns "
            "WHERE table_name='policies' ORDER BY ordinal_position"
        ))
        print("policies columns:", [row[0] for row in r2.fetchall()])

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(run())
