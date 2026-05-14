"""
Clear all customer and policy data for the current agent from the live Railway DB.

Usage:
  railway run python clear_data.py

This script:
  - Deletes ALL policies (all agents)
  - Deletes ALL customers (all agents)
  - Keeps users/agents intact
  - Resets sequences so IDs start from 1 again
"""
import asyncio
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    raise SystemExit("ERROR: DATABASE_URL not set in environment")

DATABASE_URL = (
    DATABASE_URL
    .replace("postgresql://", "postgresql+asyncpg://", 1)
    .replace("postgres://", "postgresql+asyncpg://", 1)
)

from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

engine = create_async_engine(DATABASE_URL, echo=False)


async def clear():
    async with engine.begin() as conn:
        # Count before
        c_count = (await conn.execute(text("SELECT COUNT(*) FROM customers"))).scalar()
        p_count = (await conn.execute(text("SELECT COUNT(*) FROM policies"))).scalar()
        print(f"\nBefore: {c_count} customers, {p_count} policies")

        confirm = input("\n⚠️  This will DELETE all customers and policies. Type YES to confirm: ")
        if confirm.strip() != "YES":
            print("Aborted.")
            return

        # Delete in correct order (policies reference customers)
        await conn.execute(text("DELETE FROM motor_insurance_policies"))
        await conn.execute(text("DELETE FROM motor_insurance_quotes"))
        await conn.execute(text("DELETE FROM policies"))
        await conn.execute(text("DELETE FROM customers"))

        # Reset sequences
        await conn.execute(text("ALTER SEQUENCE IF EXISTS policies_id_seq RESTART WITH 1"))
        await conn.execute(text("ALTER SEQUENCE IF EXISTS customers_id_seq RESTART WITH 1"))

        # Count after
        c_after = (await conn.execute(text("SELECT COUNT(*) FROM customers"))).scalar()
        p_after = (await conn.execute(text("SELECT COUNT(*) FROM policies"))).scalar()
        print(f"\n✅ Done! After: {c_after} customers, {p_after} policies")
        print("Users/agents are untouched.")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(clear())
