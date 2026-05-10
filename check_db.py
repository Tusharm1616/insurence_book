import asyncio
from database import SessionLocal
from models.policies import Policy
from sqlalchemy.future import select

async def main():
    async with SessionLocal() as db:
        result = await db.execute(select(Policy.id, Policy.policy_type, Policy.status, Policy.agent_id))
        policies = result.all()
        for p in policies:
            print(f"ID: {p.id}, Type: '{p.policy_type}', Status: '{p.status}', Agent: {p.agent_id}")

if __name__ == "__main__":
    asyncio.run(main())
