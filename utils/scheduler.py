"""
APScheduler-based background scheduler for InsureBook notifications.

Jobs:
  08:00 — Birthday wishes
  08:30 — Anniversary wishes
  09:00 — Policy expiry reminders (30-day and 60-day)

All jobs use the Railway PostgreSQL database via the async SQLAlchemy engine.
All WhatsApp messages are sent via utils.whatsapp_service.
"""

import logging
from datetime import date, timedelta

from apscheduler.schedulers.asyncio import AsyncIOScheduler  # type: ignore
from apscheduler.triggers.cron import CronTrigger            # type: ignore
from sqlalchemy import text

from database import SessionLocal
from utils.whatsapp_service import whatsapp_service

logger = logging.getLogger(__name__)

# ── Scheduler instance (exported for shutdown in main.py) ────────────────────
scheduler = AsyncIOScheduler(timezone="Asia/Kolkata")


# ── Helper ────────────────────────────────────────────────────────────────────

def _fmt_date(d: date) -> str:
    """Format a date as '15 June 2026'."""
    return d.strftime("%-d %B %Y") if hasattr(d, "strftime") else str(d)


# ── Job 1 — Birthday wishes ───────────────────────────────────────────────────

async def job_birthday_wishes() -> None:
    """
    Send birthday wishes to all customers whose date of birth
    (month + day) matches today's date.
    """
    logger.info("[Scheduler] Birthday job started")
    today = date.today()
    sent = 0
    skipped = 0
    errors = 0

    try:
        async with SessionLocal() as db:
            result = await db.execute(
                text("""
                    SELECT c.id, c.full_name, c.phone
                    FROM customers c
                    WHERE EXTRACT(MONTH FROM c.dob) = :month
                      AND EXTRACT(DAY   FROM c.dob) = :day
                      AND c.dob IS NOT NULL
                      AND c.phone IS NOT NULL
                      AND c.phone != ''
                      AND c.status = 'active'
                """),
                {"month": today.month, "day": today.day},
            )
            rows = result.fetchall()

        logger.info("[Scheduler] Birthday: found %d customer(s) today", len(rows))

        for row in rows:
            cid, full_name, phone = row
            try:
                ok = whatsapp_service.send_birthday_wish(
                    customer_name=full_name or "Valued Customer",
                    phone=phone,
                )
                if ok:
                    sent += 1
                    logger.info(
                        "[Scheduler] Birthday wish sent | customer_id=%s | name=%s",
                        cid, full_name,
                    )
                else:
                    skipped += 1
            except Exception as exc:
                errors += 1
                logger.error(
                    "[Scheduler] Birthday wish failed | customer_id=%s | error=%s",
                    cid, exc,
                )

    except Exception as exc:
        logger.error("[Scheduler] Birthday job DB error: %s", exc)

    logger.info(
        "[Scheduler] Birthday job done | sent=%d skipped=%d errors=%d",
        sent, skipped, errors,
    )


# ── Job 2 — Anniversary wishes ────────────────────────────────────────────────

async def job_anniversary_wishes() -> None:
    """
    Send anniversary wishes to all customers whose anniversary_date
    (month + day) matches today's date.
    """
    logger.info("[Scheduler] Anniversary job started")
    today = date.today()
    sent = 0
    skipped = 0
    errors = 0

    try:
        async with SessionLocal() as db:
            result = await db.execute(
                text("""
                    SELECT c.id, c.full_name, c.phone
                    FROM customers c
                    WHERE EXTRACT(MONTH FROM c.anniversary_date) = :month
                      AND EXTRACT(DAY   FROM c.anniversary_date) = :day
                      AND c.anniversary_date IS NOT NULL
                      AND c.phone IS NOT NULL
                      AND c.phone != ''
                      AND c.status = 'active'
                """),
                {"month": today.month, "day": today.day},
            )
            rows = result.fetchall()

        logger.info(
            "[Scheduler] Anniversary: found %d customer(s) today", len(rows)
        )

        for row in rows:
            cid, full_name, phone = row
            try:
                ok = whatsapp_service.send_anniversary_wish(
                    customer_name=full_name or "Valued Customer",
                    phone=phone,
                )
                if ok:
                    sent += 1
                    logger.info(
                        "[Scheduler] Anniversary wish sent | customer_id=%s | name=%s",
                        cid, full_name,
                    )
                else:
                    skipped += 1
            except Exception as exc:
                errors += 1
                logger.error(
                    "[Scheduler] Anniversary wish failed | customer_id=%s | error=%s",
                    cid, exc,
                )

    except Exception as exc:
        logger.error("[Scheduler] Anniversary job DB error: %s", exc)

    logger.info(
        "[Scheduler] Anniversary job done | sent=%d skipped=%d errors=%d",
        sent, skipped, errors,
    )


# ── Job 3 — Policy expiry reminders ──────────────────────────────────────────

async def job_policy_expiry_reminders() -> None:
    """
    Send policy expiry reminders for policies expiring in exactly 30 or 60 days.
    Uses COALESCE(end_date, expiry_date) so both column variants are covered.
    """
    logger.info("[Scheduler] Policy expiry job started")
    today = date.today()
    target_days = [30, 60]
    sent = 0
    skipped = 0
    errors = 0

    for days_left in target_days:
        target_date = today + timedelta(days=days_left)
        logger.info(
            "[Scheduler] Checking policies expiring on %s (%d days)",
            target_date, days_left,
        )

        try:
            async with SessionLocal() as db:
                result = await db.execute(
                    text("""
                        SELECT
                            p.id,
                            p.policy_type,
                            COALESCE(p.end_date, p.expiry_date) AS eff_expiry,
                            c.full_name,
                            c.phone
                        FROM policies p
                        JOIN customers c ON c.id = p.customer_id
                        WHERE COALESCE(p.end_date, p.expiry_date) = :target_date
                          AND LOWER(p.status) IN ('active', 'live')
                          AND c.phone IS NOT NULL
                          AND c.phone != ''
                    """),
                    {"target_date": target_date},
                )
                rows = result.fetchall()

            logger.info(
                "[Scheduler] Expiry %d-day: found %d policy(ies)", days_left, len(rows)
            )

            for row in rows:
                pid, policy_type, eff_expiry, full_name, phone = row
                try:
                    ok = whatsapp_service.send_policy_expiry_reminder(
                        customer_name=full_name or "Valued Customer",
                        phone=phone,
                        policy_type=policy_type or "Insurance",
                        days_left=days_left,
                        expiry_date=_fmt_date(eff_expiry),
                    )
                    if ok:
                        sent += 1
                        logger.info(
                            "[Scheduler] Expiry reminder sent | policy_id=%s | "
                            "customer=%s | days=%d",
                            pid, full_name, days_left,
                        )
                    else:
                        skipped += 1
                except Exception as exc:
                    errors += 1
                    logger.error(
                        "[Scheduler] Expiry reminder failed | policy_id=%s | error=%s",
                        pid, exc,
                    )

        except Exception as exc:
            logger.error(
                "[Scheduler] Policy expiry DB error (days=%d): %s", days_left, exc
            )

    logger.info(
        "[Scheduler] Policy expiry job done | sent=%d skipped=%d errors=%d",
        sent, skipped, errors,
    )


# ── Register jobs and start ───────────────────────────────────────────────────

def start_scheduler() -> None:
    """
    Register all three cron jobs and start the AsyncIOScheduler.
    Call this once from the FastAPI lifespan startup hook.
    """
    # Birthday wishes — 08:00 IST every day
    scheduler.add_job(
        job_birthday_wishes,
        trigger=CronTrigger(hour=8, minute=0, timezone="Asia/Kolkata"),
        id="birthday_wishes",
        name="Birthday Wishes",
        replace_existing=True,
        misfire_grace_time=3600,  # allow up to 1 hour late
    )

    # Anniversary wishes — 08:30 IST every day
    scheduler.add_job(
        job_anniversary_wishes,
        trigger=CronTrigger(hour=8, minute=30, timezone="Asia/Kolkata"),
        id="anniversary_wishes",
        name="Anniversary Wishes",
        replace_existing=True,
        misfire_grace_time=3600,
    )

    # Policy expiry reminders — 09:00 IST every day
    scheduler.add_job(
        job_policy_expiry_reminders,
        trigger=CronTrigger(hour=9, minute=0, timezone="Asia/Kolkata"),
        id="policy_expiry_reminders",
        name="Policy Expiry Reminders",
        replace_existing=True,
        misfire_grace_time=3600,
    )

    scheduler.start()
    logger.info(
        "[Scheduler] Started with %d job(s): %s",
        len(scheduler.get_jobs()),
        [j.name for j in scheduler.get_jobs()],
    )
