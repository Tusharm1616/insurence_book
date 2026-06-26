import qrcode
import io
import base64
from typing import Optional


def generate_upi_qr(upi_id: Optional[str]) -> Optional[str]:
    """Generate a base64 data URL for a UPI QR code.

    Returns None for empty/whitespace/null input.
    Returns a data:image/png;base64,... string for valid UPI IDs.
    """
    if not upi_id or not upi_id.strip():
        return None

    upi_uri = f"upi://pay?pa={upi_id.strip()}&pn=Agent"

    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(upi_uri)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)

    b64_data = base64.b64encode(buffer.getvalue()).decode("utf-8")
    return f"data:image/png;base64,{b64_data}"
