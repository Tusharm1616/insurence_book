import asyncio
from database import engine
from sqlalchemy import text

async def migrate():
    print("Starting migration...")
    async with engine.begin() as conn:
        try:
            await conn.execute(text("ALTER TABLE users ADD COLUMN phone VARCHAR;"))
            print("Added phone column.")
        except Exception as e:
            print("Phone column might already exist or error:", e)
            
        try:
            await conn.execute(text("ALTER TABLE users ADD COLUMN license_no VARCHAR;"))
            print("Added license_no column.")
        except Exception as e:
            print("License column might already exist or error:", e)
            
    print("Migration finished!")

if __name__ == "__main__":
    asyncio.run(migrate())
