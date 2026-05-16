"""
WhatsApp notification service using Twilio Sandbox.

IMPORTANT — Twilio FREE Sandbox requirement:
  Every customer must first send the message:
      join <your-sandbox-keyword>
  to the Twilio sandbox number: +14155238886
  before they can receive any messages from the sandbox.
  This is a Twilio sandbox limitation — it does NOT apply to paid Twilio numbers.

All credentials are loaded from environment variables only.
Never hardcode TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, or TWILIO_WHATSAPP_FROM.
"""

import os
import logging
from typing import Optional

logger = logging.getLogger(__name__)


class WhatsAppService:
    """
    Sends WhatsApp messages via Twilio REST API.

    Reads credentials from environment variables:
      TWILIO_ACCOUNT_SID   — Twilio Account SID (starts with AC)
      TWILIO_AUTH_TOKEN    — Twilio Auth Token
      TWILIO_WHATSAPP_FROM — Sender number, e.g. whatsapp:+14155238886
    """

    def __init__(self) -> None:
        self.account_sid: Optional[str] = os.getenv("TWILIO_ACCOUNT_SID")
        self.auth_token: Optional[str] = os.getenv("TWILIO_AUTH_TOKEN")
        self.from_number: str = os.getenv(
            "TWILIO_WHATSAPP_FROM", "whatsapp:+14155238886"
        )
        self._client = None  # lazy-loaded

    # ── Internal helpers ──────────────────────────────────────────────────────

    def _get_client(self):
        """Lazy-load the Twilio client so import errors surface at call time."""
        if self._client is None:
            try:
                from twilio.rest import Client  # type: ignore
                if not self.account_sid or not self.auth_token:
                    raise EnvironmentError(
                        "TWILIO_ACCOUNT_SID or TWILIO_AUTH_TOKEN is not set. "
                        "Add them in the Railway dashboard under Variables."
                    )
                self._client = Client(self.account_sid, self.auth_token)
            except ImportError:
                raise ImportError(
                    "twilio package is not installed. "
                    "Add twilio==8.10.0 to requirements.txt."
                )
        return self._client

    @staticmethod
    def _normalise_phone(phone: str) -> str:
        """
        Ensure the phone number is in E.164 WhatsApp format.
        Input examples: '9876543210', '+919876543210', '919876543210'
        Output: 'whatsapp:+919876543210'
        """
        digits = phone.strip().replace(" ", "").replace("-", "")
        # Already fully formatted
        if digits.startswith("whatsapp:"):
            return digits
        # Strip whatsapp: prefix if present in a different form
        if "whatsapp:" in digits:
            digits = digits.split("whatsapp:")[-1]
        # Already has + prefix
        if digits.startswith("+"):
            return f"whatsapp:{digits}"
        # 12-digit with country code 91 (India)
        if digits.startswith("91") and len(digits) == 12:
            return f"whatsapp:+{digits}"
        # 10-digit Indian mobile number
        if len(digits) == 10 and digits[0] in "6789":
            return f"whatsapp:+91{digits}"
        # Fallback — prepend + and wrap
        return f"whatsapp:+{digits}"

    @staticmethod
    def _normalise_from(from_number: str) -> str:
        """Ensure the from number has the whatsapp: prefix."""
        s = from_number.strip()
        if s.startswith("whatsapp:"):
            return s
        return f"whatsapp:{s}"

    # ── Public API ────────────────────────────────────────────────────────────

    def send_message(self, to_phone: str, message: str) -> bool:
        """
        Send a plain-text WhatsApp message to a single phone number.

        Args:
            to_phone: Customer phone number (any reasonable format).
            message:  Plain text message (no markdown, max 1600 chars).

        Returns:
            True if Twilio accepted the message, False on any error.
        """
        if not to_phone or not to_phone.strip():
            logger.debug("send_message: skipped — empty phone number")
            return False

        try:
            client = self._get_client()
            to_formatted  = self._normalise_phone(to_phone)
            from_formatted = self._normalise_from(self.from_number)

            logger.info(
                "WhatsApp sending | from=%s | to=%s",
                from_formatted, to_formatted,
            )

            msg = client.messages.create(
                from_=from_formatted,
                to=to_formatted,
                body=message[:1600],
            )
            logger.info(
                "WhatsApp sent | SID=%s | to=%s | status=%s",
                msg.sid, to_formatted, msg.status,
            )
            return True
        except Exception as exc:
            logger.error(
                "WhatsApp send failed | to=%s | from=%s | error=%s",
                to_phone, self.from_number, exc,
            )
            return False

    def send_policy_expiry_reminder(
        self,
        customer_name: str,
        phone: str,
        policy_type: str,
        days_left: int,
        expiry_date: str,
    ) -> bool:
        """
        Send a policy expiry reminder to a customer.

        Args:
            customer_name: Full name of the customer.
            phone:         Customer WhatsApp number.
            policy_type:   E.g. "Health Insurance", "Motor Insurance".
            days_left:     Number of days until expiry (30 or 60).
            expiry_date:   Human-readable date string, e.g. "15 June 2026".

        Returns:
            True if message was accepted by Twilio.
        """
        message = (
            f"Dear {customer_name},\n\n"
            f"This is a reminder from InsureBook.\n\n"
            f"Your {policy_type} policy is expiring in {days_left} days "
            f"on {expiry_date}.\n\n"
            f"Please renew your policy at the earliest to avoid a lapse in coverage.\n\n"
            f"Contact your insurance agent for renewal assistance.\n\n"
            f"Thank you,\nInsureBook Team"
        )
        return self.send_message(phone, message)

    def send_birthday_wish(self, customer_name: str, phone: str) -> bool:
        """
        Send a birthday greeting to a customer.

        Args:
            customer_name: Full name of the customer.
            phone:         Customer WhatsApp number.

        Returns:
            True if message was accepted by Twilio.
        """
        message = (
            f"Dear {customer_name},\n\n"
            f"Wishing you a very Happy Birthday!\n\n"
            f"May this special day bring you joy, good health, and happiness. "
            f"We are grateful to have you as our valued customer.\n\n"
            f"Warm regards,\nInsureBook Team"
        )
        return self.send_message(phone, message)

    def send_anniversary_wish(self, customer_name: str, phone: str) -> bool:
        """
        Send a wedding anniversary greeting to a customer.

        Args:
            customer_name: Full name of the customer.
            phone:         Customer WhatsApp number.

        Returns:
            True if message was accepted by Twilio.
        """
        message = (
            f"Dear {customer_name},\n\n"
            f"Wishing you and your family a very Happy Anniversary!\n\n"
            f"May your bond grow stronger with each passing year. "
            f"Thank you for being a valued customer of InsureBook.\n\n"
            f"Warm regards,\nInsureBook Team"
        )
        return self.send_message(phone, message)


# ── Singleton instance ────────────────────────────────────────────────────────
whatsapp_service = WhatsAppService()
