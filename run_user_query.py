import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

DATABASE_URL = "postgresql+asyncpg://neondb_owner:npg_A3DFoP0rZNwK@ep-purple-bar-aoax9tb8.c-2.ap-southeast-1.aws.neon.tech/neondb?ssl=require"

async def main():
    engine = create_async_engine(DATABASE_URL)
    async with engine.begin() as conn:
        print("--- USER QUERY RESULT ---")
        try:
            # Replaced c.name with c.full_name, and p.insurance_type with p.policy_type
            result = await conn.execute(text("SELECT p.id, p.customer_id, c.full_name, p.policy_type, p.created_at FROM policies p LEFT JOIN customers c ON c.id = p.customer_id ORDER BY p.created_at DESC LIMIT 20;"))
            for row in result.fetchall():
                print(row)
        except Exception as e:
            print("Error:", e)

asyncio.run(main())
