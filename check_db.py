import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

DATABASE_URL = "postgresql+asyncpg://neondb_owner:npg_A3DFoP0rZNwK@ep-purple-bar-aoax9tb8.c-2.ap-southeast-1.aws.neon.tech/neondb?ssl=require"

async def main():
    engine = create_async_engine(DATABASE_URL)
    async with engine.begin() as conn:
        print("--- policies with agent_id ---")
        result = await conn.execute(text("SELECT id, policy_number, agent_id, customer_id, issue_date, premium_amount FROM policies ORDER BY id DESC LIMIT 5;"))
        for row in result.fetchall():
            print(row)
            
        print("--- matching users ---")
        result = await conn.execute(text("SELECT id, full_name, email FROM users ORDER BY id DESC LIMIT 15;"))
        for row in result.fetchall():
            print(row)

asyncio.run(main())
