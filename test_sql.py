import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

DATABASE_URL = "postgresql+asyncpg://neondb_owner:npg_A3DFoP0rZNwK@ep-purple-bar-aoax9tb8.c-2.ap-southeast-1.aws.neon.tech/neondb?ssl=require"

async def main():
    engine = create_async_engine(DATABASE_URL)
    async with engine.begin() as conn:
        print("--- Testing SQL Query for agent 6 ---")
        summary_query = text("""
            SELECT
                COALESCE(SUM(premium_amount), 0) as total_business,
                0 as total_income,
                COUNT(*) as policies_sold,
                COUNT(*) FILTER (WHERE LOWER(status) = 'active') as sale_complete,
                COUNT(*) FILTER (WHERE LOWER(status) != 'active') as sale_pending
            FROM policies
            WHERE agent_id = :agent_id
                AND EXTRACT(YEAR FROM COALESCE(issue_date, start_date)) = :year
                AND EXTRACT(MONTH FROM COALESCE(issue_date, start_date)) = :month
        """)
        result = await conn.execute(summary_query, {"agent_id": 6, "year": 2026, "month": 6})
        print("Agent 6:", result.fetchone())

        # Also just query all policies for agent 6
        result = await conn.execute(text("SELECT id, policy_number, customer_id, issue_date, start_date FROM policies WHERE agent_id = 6;"))
        print("Agent 6 policies:", result.fetchall())

asyncio.run(main())
