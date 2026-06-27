"""
Property-based tests for commission calculation utility.

Feature: add-policy, Property 1: Commission Calculation

Validates: Requirements 1.2, 4.2, 10.2, 14.1, 14.2, 14.3
"""

from decimal import Decimal, ROUND_HALF_UP

from hypothesis import given, settings, assume
from hypothesis import strategies as st

from utils.commission import calculate_commission


# Strategy for valid final_amount values: 0.00 to 99,999,999.99 with 2 decimal places
valid_final_amount = st.decimals(
    min_value=0, max_value=Decimal("99999999.99"), places=2
)

# Strategy for valid commission_percent values: 0.00 to 100.00 with 2 decimal places
valid_commission_percent = st.decimals(
    min_value=0, max_value=Decimal("100"), places=2
)


@settings(max_examples=20)
@given(final_amount=valid_final_amount, commission_percent=valid_commission_percent)
def test_commission_calculation_property(final_amount, commission_percent):
    """
    Property 1: Commission Calculation

    For any valid final_amount in [0, 99999999.99] and commission_percent in [0, 100],
    the computed commission_amount SHALL equal round(final_amount * commission_percent / 100, 2)
    using half-up rounding.

    Validates: Requirements 1.2, 4.2, 10.2, 14.1, 14.2, 14.3
    """
    result = calculate_commission(final_amount, commission_percent)

    if final_amount == 0 or commission_percent == 0:
        assert result == Decimal("0.00"), (
            f"Expected 0.00 for zero input, got {result} "
            f"(final_amount={final_amount}, commission_percent={commission_percent})"
        )
    else:
        expected = (final_amount * commission_percent / Decimal("100")).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
        assert result == expected, (
            f"Expected {expected}, got {result} "
            f"(final_amount={final_amount}, commission_percent={commission_percent})"
        )


@settings(max_examples=20)
@given(commission_percent=valid_commission_percent)
def test_commission_zero_final_amount(commission_percent):
    """
    When final_amount is zero, commission_amount SHALL be 0.00 regardless of
    commission_percent.

    Validates: Requirements 14.3
    """
    result = calculate_commission(Decimal("0"), commission_percent)
    assert result == Decimal("0.00"), (
        f"Expected 0.00 for zero final_amount, got {result} "
        f"(commission_percent={commission_percent})"
    )


@settings(max_examples=20)
@given(final_amount=valid_final_amount)
def test_commission_zero_commission_percent(final_amount):
    """
    When commission_percent is zero, commission_amount SHALL be 0.00 regardless of
    final_amount.

    Validates: Requirements 14.3
    """
    result = calculate_commission(final_amount, Decimal("0"))
    assert result == Decimal("0.00"), (
        f"Expected 0.00 for zero commission_percent, got {result} "
        f"(final_amount={final_amount})"
    )


@settings(max_examples=20)
@given(final_amount=valid_final_amount)
def test_commission_none_commission_percent(final_amount):
    """
    When commission_percent is None, commission_amount SHALL be 0.00.

    Validates: Requirements 14.3
    """
    result = calculate_commission(final_amount, None)
    assert result == Decimal("0.00"), (
        f"Expected 0.00 for None commission_percent, got {result} "
        f"(final_amount={final_amount})"
    )


@settings(max_examples=20)
@given(commission_percent=valid_commission_percent)
def test_commission_none_final_amount(commission_percent):
    """
    When final_amount is None, commission_amount SHALL be 0.00.

    Validates: Requirements 14.3
    """
    result = calculate_commission(None, commission_percent)
    assert result == Decimal("0.00"), (
        f"Expected 0.00 for None final_amount, got {result} "
        f"(commission_percent={commission_percent})"
    )


def test_commission_both_none():
    """
    When both final_amount and commission_percent are None, commission_amount SHALL be 0.00.

    Validates: Requirements 14.3
    """
    result = calculate_commission(None, None)
    assert result == Decimal("0.00"), f"Expected 0.00 for both None, got {result}"
