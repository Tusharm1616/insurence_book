"""Commission calculator utility for policy management."""

from decimal import Decimal, ROUND_HALF_UP


def calculate_commission(
    final_amount: Decimal | None, commission_percent: Decimal | None
) -> Decimal:
    """
    Compute commission_amount = final_amount * commission_percent / 100.

    Returns Decimal("0.00") if either input is None or zero.
    Uses ROUND_HALF_UP rounding to 2 decimal places.

    Args:
        final_amount: The final policy amount (0.00 - 99,999,999.99)
        commission_percent: The commission percentage (0.00 - 100.00)

    Returns:
        Decimal: The computed commission amount rounded to 2 decimal places.
    """
    if final_amount is None or commission_percent is None:
        return Decimal("0.00")

    if final_amount == 0 or commission_percent == 0:
        return Decimal("0.00")

    commission = final_amount * commission_percent / Decimal("100")
    return commission.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
