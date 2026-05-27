import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
import logging

load_dotenv()

# ❌ REMOVE localhost fallback
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL is not set")

# Fix URL scheme for asyncpg — handles postgresql://, postgres://, and already-fixed URLs
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+asyncpg://", 1)
elif DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
# If already postgresql+asyncpg:// leave it as-is

# Neon requires SSL — add ssl=require if not already present
connect_args = {}
if "neon.tech" in DATABASE_URL or "neondb" in DATABASE_URL.lower():
    connect_args = {"ssl": "require"}
elif "sslmode=require" in DATABASE_URL:
    # Remove sslmode from URL (asyncpg doesn't support it as query param)
    DATABASE_URL = DATABASE_URL.replace("?sslmode=require", "").replace("&sslmode=require", "")
    connect_args = {"ssl": "require"}

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
logger.info(f"Using database: {DATABASE_URL.split('@')[1] if '@' in DATABASE_URL else 'local'}")

# Enhanced engine configuration with connection pooling
engine = create_async_engine(
    DATABASE_URL,
    connect_args=connect_args,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=1800,
    echo=os.getenv("DEBUG", "false").lower() == "true"
)

SessionLocal = async_sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False
)

class Base(DeclarativeBase):
    pass

async def get_db():
    async with SessionLocal() as session:
        try:
            yield session
        except Exception as e:
            logger.error(f"Database session error: {e}")
            await session.rollback()
            raise
        finally:
            await session.close()