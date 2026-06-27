"""
Property-based tests for backend CRUD operations on policies_v2.

Feature: add-policy, Properties 2, 3, 5, 6, 7, 8

Validates: Requirements 1.2, 1.3, 1.6, 2.1, 3.1, 4.1, 4.3, 5.1, 5.2, 5.5
"""

import uuid
from decimal import Decimal
from datetime import date, datetime, timezone

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from hypothesis import given, settings, assume, HealthCheck
from hypothesis import strategies as st
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import select, text

from main import app
from utils.auth import get_current_user
from database import get_db


# ─── Test Database Setup ────────────────────────────────────────────────────

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"

engine_test = create_async_engine(
    TEST_DB_URL,
    echo=False,
    connect_args={"check_same_thread": False},
)
TestSessionLocal = async_sessionmaker(
    bind=engine_test, class_=AsyncSession, expire_on_commit=False
)

# Test agent user (simulates authenticated agent)
TEST_AGENT_ID = 1
TEST_AGENT_USERNAME = "testagent"

# Second agent for scoping tests
OTHER_AGENT_ID = 2
OTHER_AGENT_USERNAME = "otheragent"

# Test customer
TEST_CUSTOMER_ID = 1


# ─── Fixtures ───────────────────────────────────────────────────────────────

@pytest_asyncio.fixture(autouse=True)
async def setup_database():
    """Create tables and seed test data before each test, drop after."""
    # Create tables - we need to handle SQLite not understanding 'now()' as a default.
    # Override the problematic server_defaults before creating tables.
    from sqlalchemy import inspect as sa_inspect, text

    async with engine_test.begin() as conn:
        # Create tables using raw SQL for SQLite compatibility
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY,
                username VARCHAR UNIQUE,
                email VARCHAR UNIQUE,
                full_name VARCHAR,
                hashed_password VARCHAR,
                role VARCHAR DEFAULT 'agent',
                phone VARCHAR,
                license_no VARCHAR,
                upi_id VARCHAR,
                bank_name VARCHAR,
                account_number VARCHAR,
                ifsc_code VARCHAR,
                branch_name VARCHAR,
                qr_code_url TEXT
            )
        """))
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS customers (
                id INTEGER PRIMARY KEY,
                agent_id INTEGER REFERENCES users(id),
                full_name VARCHAR(150) NOT NULL,
                phone VARCHAR(15),
                email VARCHAR(100),
                dob DATE,
                anniversary_date DATE,
                address TEXT,
                city VARCHAR(80),
                state VARCHAR(80),
                pincode VARCHAR(10),
                ref_by VARCHAR(150),
                status VARCHAR(20) DEFAULT 'active',
                created_at DATE DEFAULT (date('now')),
                updated_at DATE DEFAULT (date('now'))
            )
        """))
        await conn.execute(text("""
            CREATE TABLE IF NOT EXISTS policies_v2 (
                id VARCHAR(36) PRIMARY KEY,
                customer_id INTEGER REFERENCES customers(id),
                agent_id INTEGER REFERENCES users(id),
                policy_number VARCHAR(60) UNIQUE NOT NULL,
                insurance_company VARCHAR(150),
                insurance_type VARCHAR(50) NOT NULL DEFAULT 'Other',
                start_date DATE,
                end_date DATE,
                total_amount NUMERIC(10, 2),
                discount_amount NUMERIC(10, 2) DEFAULT 0,
                final_amount NUMERIC(10, 2),
                payment_mode VARCHAR(20),
                payment_date DATE,
                inspection_date DATE,
                inspection_status VARCHAR(20) DEFAULT 'NA',
                claim_status VARCHAR(20) DEFAULT 'No Claim',
                claim_amount NUMERIC(10, 2) DEFAULT 0,
                claim_notes TEXT,
                ref_by VARCHAR(150),
                commission_percent NUMERIC(5, 2) DEFAULT 0,
                commission_amount NUMERIC(10, 2) DEFAULT 0,
                policy_pdf_url VARCHAR(500),
                last_year_policy_pdf_url VARCHAR(500),
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))

    # Seed test users and customer
    async with TestSessionLocal() as session:
        await session.execute(text(
            "INSERT INTO users (id, username, email, full_name, hashed_password, role) "
            "VALUES (:id, :username, :email, :full_name, :hashed_password, :role)"
        ), {"id": TEST_AGENT_ID, "username": TEST_AGENT_USERNAME, "email": "agent@test.com",
            "full_name": "Test Agent", "hashed_password": "hashed", "role": "agent"})
        await session.execute(text(
            "INSERT INTO users (id, username, email, full_name, hashed_password, role) "
            "VALUES (:id, :username, :email, :full_name, :hashed_password, :role)"
        ), {"id": OTHER_AGENT_ID, "username": OTHER_AGENT_USERNAME, "email": "other@test.com",
            "full_name": "Other Agent", "hashed_password": "hashed", "role": "agent"})
        await session.execute(text(
            "INSERT INTO customers (id, agent_id, full_name) "
            "VALUES (:id, :agent_id, :full_name)"
        ), {"id": TEST_CUSTOMER_ID, "agent_id": TEST_AGENT_ID, "full_name": "Test Customer"})
        await session.commit()

    yield

    async with engine_test.begin() as conn:
        await conn.execute(text("DROP TABLE IF EXISTS policies_v2"))
        await conn.execute(text("DROP TABLE IF EXISTS customers"))
        await conn.execute(text("DROP TABLE IF EXISTS users"))


async def override_get_db():
    """Provide test database session."""
    async with TestSessionLocal() as session:
        yield session


async def override_get_current_user():
    """Return a mock user object simulating the authenticated test agent."""
    # Create a simple object that mimics the User model
    class MockUser:
        id = TEST_AGENT_ID
        username = TEST_AGENT_USERNAME
        email = "agent@test.com"
        full_name = "Test Agent"
        role = "agent"
    return MockUser()


# Apply dependency overrides
app.dependency_overrides[get_db] = override_get_db
app.dependency_overrides[get_current_user] = override_get_current_user


@pytest_asyncio.fixture
async def client():
    """Async HTTP client for testing endpoints."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


# ─── Hypothesis Strategies ──────────────────────────────────────────────────

INSURANCE_TYPES = ["Life", "Motor", "Health", "Travel", "Other"]
PAYMENT_MODES = ["Cash", "Online", "Cheque", "EMI"]
INSPECTION_STATUSES = ["Pending", "Passed", "Failed", "NA"]
CLAIM_STATUSES = ["No Claim", "Claimed", "Pending"]


def valid_policy_number():
    """Generate unique policy numbers."""
    return st.text(
        alphabet=st.characters(whitelist_categories=("Lu", "Ll", "Nd")),
        min_size=1,
        max_size=50,
    ).filter(lambda x: x.strip() != "")


def valid_decimal(min_val="0.01", max_val="99999999.99"):
    """Generate valid decimal values within range."""
    return st.decimals(
        min_value=Decimal(min_val),
        max_value=Decimal(max_val),
        places=2,
    )


def valid_commission_percent():
    """Generate valid commission percent 0-100."""
    return st.decimals(min_value=Decimal("0"), max_value=Decimal("100"), places=2)


def valid_policy_create_data():
    """Strategy for generating valid policy creation payloads."""
    return st.fixed_dictionaries({
        "customer_id": st.just(TEST_CUSTOMER_ID),
        "policy_number": st.uuids().map(lambda u: str(u)[:20]),
        "insurance_type": st.sampled_from(INSURANCE_TYPES),
        "insurance_company": st.one_of(st.none(), st.text(min_size=1, max_size=50)),
        "total_amount": st.one_of(st.none(), valid_decimal()),
        "discount_amount": st.one_of(st.just(Decimal("0")), valid_decimal("0", "999.99")),
        "final_amount": st.one_of(st.none(), valid_decimal()),
        "commission_percent": valid_commission_percent(),
        "payment_mode": st.one_of(st.none(), st.sampled_from(PAYMENT_MODES)),
        "inspection_status": st.sampled_from(INSPECTION_STATUSES),
        "claim_status": st.sampled_from(CLAIM_STATUSES),
        "ref_by": st.one_of(st.none(), st.text(min_size=0, max_size=50)),
    })


def _serialize_payload(data: dict) -> dict:
    """Convert Decimal/date values to JSON-serializable format."""
    result = {}
    for k, v in data.items():
        if v is None:
            result[k] = v
        elif isinstance(v, Decimal):
            result[k] = float(v)
        elif isinstance(v, date):
            result[k] = v.isoformat()
        else:
            result[k] = v
    return result


# ─── Helper ─────────────────────────────────────────────────────────────────

async def create_policy_via_api(client: AsyncClient, data: dict) -> dict:
    """Helper to create a policy and return the JSON response."""
    payload = _serialize_payload(data)
    resp = await client.post("/api/policies-v2/", json=payload)
    assert resp.status_code == 201, f"Create failed: {resp.status_code} {resp.text}"
    return resp.json()


# ─── Property 2: Agent Scoping on Creation ──────────────────────────────────


@pytest.mark.asyncio
class TestProperty2AgentScoping:
    """
    Property 2: Agent Scoping on Creation

    For any authenticated agent creating a policy, the resulting record's
    agent_id SHALL equal the authenticated user's ID, regardless of the
    policy data provided in the request body.

    Validates: Requirements 1.3
    """

    @settings(max_examples=100, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @given(data=valid_policy_create_data())
    async def test_agent_scoping_on_creation(self, data, client):
        """Created record's agent_id always matches authenticated user."""
        response = await create_policy_via_api(client, data)
        assert response["agent_id"] == TEST_AGENT_ID, (
            f"Expected agent_id={TEST_AGENT_ID}, got {response['agent_id']}"
        )


# ─── Property 3: List Filter Invariant ──────────────────────────────────────


@pytest.mark.asyncio
class TestProperty3ListFilterInvariant:
    """
    Property 3: List Filter Invariant

    For any authenticated agent querying the policy list endpoint, every
    policy in the response SHALL have agent_id equal to the requesting
    agent's ID AND is_active equal to true.

    Validates: Requirements 2.1, 5.5
    """

    @settings(max_examples=30, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @given(num_policies=st.integers(min_value=1, max_value=5))
    async def test_list_filter_invariant(self, num_policies, client):
        """All listed policies belong to current agent and are active."""
        # Create several policies for the current agent
        for i in range(num_policies):
            data = {
                "customer_id": TEST_CUSTOMER_ID,
                "policy_number": f"LIST-{uuid.uuid4().hex[:12]}",
                "insurance_type": "Life",
                "commission_percent": Decimal("0"),
            }
            await create_policy_via_api(client, data)

        # Also insert a policy for another agent directly in DB (should NOT appear)
        async with TestSessionLocal() as session:
            now = datetime.now(timezone.utc).isoformat()
            await session.execute(text(
                "INSERT INTO policies_v2 (id, customer_id, agent_id, policy_number, "
                "insurance_type, is_active, created_at, updated_at) "
                "VALUES (:id, :cid, :aid, :pn, :it, 1, :ca, :ua)"
            ), {"id": str(uuid.uuid4()), "cid": TEST_CUSTOMER_ID,
                "aid": OTHER_AGENT_ID, "pn": f"OTHER-{uuid.uuid4().hex[:12]}",
                "it": "Motor", "ca": now, "ua": now})
            await session.execute(text(
                "INSERT INTO policies_v2 (id, customer_id, agent_id, policy_number, "
                "insurance_type, is_active, created_at, updated_at) "
                "VALUES (:id, :cid, :aid, :pn, :it, 0, :ca, :ua)"
            ), {"id": str(uuid.uuid4()), "cid": TEST_CUSTOMER_ID,
                "aid": TEST_AGENT_ID, "pn": f"INACTIVE-{uuid.uuid4().hex[:12]}",
                "it": "Health", "ca": now, "ua": now})
            await session.commit()

        # Query list endpoint
        resp = await client.get("/api/policies-v2/")
        assert resp.status_code == 200

        body = resp.json()
        policies = body["data"]

        # Verify: we get at least the policies we created
        assert len(policies) >= num_policies

        # Verify invariant: no policy from another agent or inactive
        # (We can't check is_active from list response directly, but
        # the inactive policy should NOT appear in the list)
        for p in policies:
            # The list doesn't include agent_id, but we verify by ensuring
            # none of the "OTHER-" or "INACTIVE-" policy_numbers appear
            assert not p["policy_number"].startswith("OTHER-"), (
                f"Policy from other agent appeared: {p['policy_number']}"
            )
            assert not p["policy_number"].startswith("INACTIVE-"), (
                f"Inactive policy appeared: {p['policy_number']}"
            )


# ─── Property 5: Create-Read Round Trip ─────────────────────────────────────


@pytest.mark.asyncio
class TestProperty5CreateReadRoundTrip:
    """
    Property 5: Create-Read Round Trip

    For any policy created with valid data via POST, a subsequent GET by
    the returned ID SHALL return all fields with values matching what was
    stored.

    Validates: Requirements 3.1
    """

    @settings(max_examples=100, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @given(data=valid_policy_create_data())
    async def test_create_read_round_trip(self, data, client):
        """POST then GET returns matching fields."""
        created = await create_policy_via_api(client, data)
        policy_id = created["id"]

        # GET the policy by ID
        resp = await client.get(f"/api/policies-v2/{policy_id}")
        assert resp.status_code == 200, f"GET failed: {resp.status_code} {resp.text}"

        detail = resp.json()

        # Verify key fields match
        assert detail["id"] == policy_id
        assert detail["policy_number"] == created["policy_number"]
        assert detail["insurance_type"] == created["insurance_type"]
        assert detail["agent_id"] == TEST_AGENT_ID
        assert detail["customer_id"] == TEST_CUSTOMER_ID
        assert detail["is_active"] is True

        # Verify financial fields match creation response
        assert detail["commission_amount"] == created["commission_amount"]
        assert detail["commission_percent"] == created["commission_percent"]
        assert detail["final_amount"] == created["final_amount"]
        assert detail["total_amount"] == created["total_amount"]


# ─── Property 6: Partial Update Correctness ─────────────────────────────────


@pytest.mark.asyncio
class TestProperty6PartialUpdateCorrectness:
    """
    Property 6: Partial Update Correctness

    For any existing policy and any non-empty subset of updatable fields
    with new valid values, a PUT request containing only those fields SHALL
    modify only the specified fields in the persisted record, leaving all
    other fields unchanged (except updated_at and commission_amount if
    financial fields change).

    Validates: Requirements 4.1, 4.3
    """

    @settings(max_examples=50, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @given(
        update_fields=st.fixed_dictionaries(
            {},
            optional={
                "insurance_company": st.text(min_size=1, max_size=50),
                "ref_by": st.text(min_size=1, max_size=50),
                "inspection_status": st.sampled_from(INSPECTION_STATUSES),
                "claim_status": st.sampled_from(CLAIM_STATUSES),
                "payment_mode": st.sampled_from(PAYMENT_MODES),
            },
        )
    )
    async def test_partial_update_correctness(self, update_fields, client):
        """PUT changes only specified fields, others remain unchanged."""
        assume(len(update_fields) > 0)

        # Create a policy first
        create_data = {
            "customer_id": TEST_CUSTOMER_ID,
            "policy_number": f"UPD-{uuid.uuid4().hex[:12]}",
            "insurance_type": "Life",
            "insurance_company": "Original Company",
            "total_amount": Decimal("10000"),
            "final_amount": Decimal("9500"),
            "commission_percent": Decimal("10"),
            "payment_mode": "Cash",
            "inspection_status": "NA",
            "claim_status": "No Claim",
            "ref_by": "Original Ref",
        }
        created = await create_policy_via_api(client, create_data)
        policy_id = created["id"]

        # Build update payload with only selected fields
        update_payload = _serialize_payload(update_fields)

        # Perform PUT
        resp = await client.put(f"/api/policies-v2/{policy_id}", json=update_payload)
        assert resp.status_code == 200, f"PUT failed: {resp.status_code} {resp.text}"

        updated = resp.json()

        # Verify updated fields match the new values
        for field, value in update_fields.items():
            assert updated[field] == value, (
                f"Field '{field}' not updated: expected {value}, got {updated[field]}"
            )

        # Verify non-updated fields remain unchanged
        unchanged_fields = [
            "policy_number", "insurance_type", "customer_id", "agent_id",
        ]
        for field in unchanged_fields:
            assert updated[field] == created[field], (
                f"Field '{field}' changed unexpectedly: "
                f"was {created[field]}, now {updated[field]}"
            )


# ─── Property 7: Soft Delete Preservation ───────────────────────────────────


@pytest.mark.asyncio
class TestProperty7SoftDeletePreservation:
    """
    Property 7: Soft Delete Preservation

    For any active policy, after a DELETE request the record SHALL remain
    in the database with all column values unchanged except is_active
    (set to false) and updated_at (set to deletion time). The policy
    SHALL no longer appear in list queries.

    Validates: Requirements 5.1, 5.2, 5.5
    """

    @settings(max_examples=50, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @given(data=valid_policy_create_data())
    async def test_soft_delete_preservation(self, data, client):
        """DELETE preserves row, only changes is_active and updated_at."""
        # Create a policy
        created = await create_policy_via_api(client, data)
        policy_id = created["id"]

        # Capture state before delete
        pre_delete_resp = await client.get(f"/api/policies-v2/{policy_id}")
        assert pre_delete_resp.status_code == 200
        pre_delete = pre_delete_resp.json()

        # Perform soft delete
        del_resp = await client.delete(f"/api/policies-v2/{policy_id}")
        assert del_resp.status_code == 200
        del_body = del_resp.json()
        assert del_body["id"] == policy_id
        assert "deleted" in del_body["message"].lower()

        # Verify: policy no longer appears in GET by ID (returns 404)
        get_resp = await client.get(f"/api/policies-v2/{policy_id}")
        assert get_resp.status_code == 404

        # Verify: policy no longer appears in list
        list_resp = await client.get("/api/policies-v2/")
        assert list_resp.status_code == 200
        listed_ids = [p["id"] for p in list_resp.json()["data"]]
        assert policy_id not in listed_ids

        # Verify: row still exists in database with is_active=False
        async with TestSessionLocal() as session:
            result = await session.execute(
                text("SELECT id, is_active, policy_number, insurance_type, agent_id "
                     "FROM policies_v2 WHERE id = :pid"),
                {"pid": policy_id}
            )
            db_row = result.first()
            assert db_row is not None, "Row was physically deleted!"
            assert db_row[1] in (False, 0), f"is_active should be False, got {db_row[1]}"
            assert db_row[2] == pre_delete["policy_number"]
            assert db_row[3] == pre_delete["insurance_type"]
            assert int(db_row[4]) == pre_delete["agent_id"]


# ─── Property 8: Required Field Validation ──────────────────────────────────


@pytest.mark.asyncio
class TestProperty8RequiredFieldValidation:
    """
    Property 8: Required Field Validation

    For any create request where at least one required field (customer_id,
    policy_number, insurance_type) is missing, empty, or null, the API SHALL
    return a 422 response and SHALL NOT create a record in the database.

    Validates: Requirements 1.6
    """

    @settings(max_examples=100, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @given(
        missing_field=st.sampled_from(["customer_id", "policy_number", "insurance_type"]),
        valid_data=valid_policy_create_data(),
    )
    async def test_missing_required_fields_return_422(self, missing_field, valid_data, client):
        """Missing required fields return 422, no record created."""
        # Remove the required field from payload
        payload = _serialize_payload(valid_data)

        if missing_field == "customer_id":
            payload.pop("customer_id", None)
        elif missing_field == "policy_number":
            # Test with missing field
            payload.pop("policy_number", None)
        elif missing_field == "insurance_type":
            payload.pop("insurance_type", None)

        # Count policies before
        list_before = await client.get("/api/policies-v2/")
        count_before = list_before.json()["total"]

        # Attempt to create with missing field
        resp = await client.post("/api/policies-v2/", json=payload)
        assert resp.status_code == 422, (
            f"Expected 422 for missing '{missing_field}', got {resp.status_code}: {resp.text}"
        )

        # Verify no record was created
        list_after = await client.get("/api/policies-v2/")
        count_after = list_after.json()["total"]
        assert count_after == count_before, (
            f"Record was created despite missing '{missing_field}': "
            f"count went from {count_before} to {count_after}"
        )

    @settings(max_examples=50, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @given(empty_value=st.sampled_from(["", "   "]))
    async def test_empty_policy_number_returns_422(self, empty_value, client):
        """Empty/whitespace-only policy_number returns 422."""
        payload = {
            "customer_id": TEST_CUSTOMER_ID,
            "policy_number": empty_value,
            "insurance_type": "Life",
        }

        resp = await client.post("/api/policies-v2/", json=payload)
        assert resp.status_code == 422, (
            f"Expected 422 for empty policy_number '{repr(empty_value)}', "
            f"got {resp.status_code}: {resp.text}"
        )

    @settings(max_examples=50, suppress_health_check=[HealthCheck.function_scoped_fixture])
    @given(invalid_type=st.text(min_size=1, max_size=20).filter(
        lambda x: x not in ["Life", "Motor", "Health", "Travel", "Other"]
    ))
    async def test_invalid_insurance_type_returns_422(self, invalid_type, client):
        """Invalid insurance_type returns 422."""
        payload = {
            "customer_id": TEST_CUSTOMER_ID,
            "policy_number": f"INV-{uuid.uuid4().hex[:12]}",
            "insurance_type": invalid_type,
        }

        resp = await client.post("/api/policies-v2/", json=payload)
        assert resp.status_code == 422, (
            f"Expected 422 for invalid insurance_type '{invalid_type}', "
            f"got {resp.status_code}: {resp.text}"
        )
