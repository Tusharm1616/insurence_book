"""Unit tests for the PUT /api/policies-v2/{id} update endpoint logic."""

import pytest
from decimal import Decimal
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

from schemas.policies_v2 import PolicyV2Update
from utils.commission import calculate_commission


class TestPolicyV2UpdateSchema:
    """Test the PolicyV2Update schema validation."""

    def test_empty_body_all_none(self):
        """Empty update body (no fields set) should result in empty exclude_unset dict."""
        update = PolicyV2Update()
        data = update.model_dump(exclude_unset=True)
        assert data == {}

    def test_partial_update_single_field(self):
        """Single field provided should only include that field."""
        update = PolicyV2Update(insurance_company="New Company")
        data = update.model_dump(exclude_unset=True)
        assert data == {"insurance_company": "New Company"}

    def test_partial_update_multiple_fields(self):
        """Multiple fields provided should be included."""
        update = PolicyV2Update(
            insurance_company="New Company",
            final_amount=Decimal("5000.00"),
        )
        data = update.model_dump(exclude_unset=True)
        assert "insurance_company" in data
        assert "final_amount" in data
        assert data["insurance_company"] == "New Company"
        assert data["final_amount"] == Decimal("5000.00")

    def test_commission_percent_validation_too_high(self):
        """commission_percent > 100 should fail validation."""
        with pytest.raises(Exception):
            PolicyV2Update(commission_percent=Decimal("101"))

    def test_commission_percent_validation_negative(self):
        """commission_percent < 0 should fail validation."""
        with pytest.raises(Exception):
            PolicyV2Update(commission_percent=Decimal("-1"))

    def test_final_amount_validation_negative(self):
        """final_amount < 0 should fail validation."""
        with pytest.raises(Exception):
            PolicyV2Update(final_amount=Decimal("-100"))

    def test_final_amount_validation_too_large(self):
        """final_amount > 99999999.99 should fail validation."""
        with pytest.raises(Exception):
            PolicyV2Update(final_amount=Decimal("100000000.00"))

    def test_valid_commission_percent(self):
        """Valid commission_percent between 0 and 100 should pass."""
        update = PolicyV2Update(commission_percent=Decimal("15.50"))
        data = update.model_dump(exclude_unset=True)
        assert data["commission_percent"] == Decimal("15.50")

    def test_valid_final_amount(self):
        """Valid final_amount within range should pass."""
        update = PolicyV2Update(final_amount=Decimal("99999999.99"))
        data = update.model_dump(exclude_unset=True)
        assert data["final_amount"] == Decimal("99999999.99")


class TestCommissionRecalculation:
    """Test commission recalculation logic for update scenarios."""

    def test_recalculate_when_final_amount_changes(self):
        """When final_amount changes, commission should be recalculated."""
        # Simulating: stored commission_percent = 10, new final_amount = 5000
        new_commission = calculate_commission(Decimal("5000"), Decimal("10"))
        assert new_commission == Decimal("500.00")

    def test_recalculate_when_commission_percent_changes(self):
        """When commission_percent changes, commission should be recalculated."""
        # Simulating: stored final_amount = 10000, new commission_percent = 15
        new_commission = calculate_commission(Decimal("10000"), Decimal("15"))
        assert new_commission == Decimal("1500.00")

    def test_recalculate_when_both_change(self):
        """When both fields change, commission uses both new values."""
        new_commission = calculate_commission(Decimal("8000"), Decimal("12.5"))
        assert new_commission == Decimal("1000.00")

    def test_no_recalculation_with_zero_final_amount(self):
        """If final_amount is set to 0, commission should be 0."""
        new_commission = calculate_commission(Decimal("0"), Decimal("10"))
        assert new_commission == Decimal("0.00")

    def test_no_recalculation_with_zero_percent(self):
        """If commission_percent is set to 0, commission should be 0."""
        new_commission = calculate_commission(Decimal("5000"), Decimal("0"))
        assert new_commission == Decimal("0.00")

    def test_uses_stored_value_when_field_not_in_request(self):
        """Verify logic: use stored value for field not in the update request."""
        # The endpoint logic: if only final_amount is in update_data,
        # commission_percent comes from the stored policy record.
        stored_commission_percent = Decimal("20")
        new_final_amount = Decimal("7500")
        result = calculate_commission(new_final_amount, stored_commission_percent)
        assert result == Decimal("1500.00")
