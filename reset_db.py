import asyncio
from database import engine
from sqlalchemy import text

async def clear_db():
    async with engine.begin() as conn:
        print("Truncating tables...")
        await conn.execute(text("TRUNCATE TABLE users RESTART IDENTITY CASCADE"))
        print("Done!")

if __name__ == "__main__":
    asyncio.run(clear_db())
