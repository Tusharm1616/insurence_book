"""
Notification management routes.

Endpoints:
  POST /notifications/test-whatsapp          — send a test message
  POST /notifications/trigger-policy-check   — manually run expiry job
  POST /notifications/trigger-birthday-check — manually run birthday job
  POST /notifications/trigger-anniversary-check — manually run anniversary job
  GET  /notifications/scheduler-status       — list jobs + next run times

All routes require a valid Bearer JWT token.
"""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from utils.auth import get_current_user
from utils.whatsapp_service import whatsapp_service
from utils.scheduler import (
    scheduler,
    job_birthday_wishes,
    job_anniversary_wishes,
    job_policy_expiry_reminders,
)
from models.users import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notifications", tags=["Notifications"])


# ── Request / Response schemas ────────────────────────────────────────────────

class TestWhatsAppRequest(BaseModel):
    phone: str
    message: str


class TestWhatsAppResponse(BaseModel):
    success: bool
    phone: str
    message: str


class TriggerResponse(BaseModel):
    triggered: bool
    job: str
    detail: str


class JobInfo(BaseModel):
    id: str
    name: str
    next_run_time: Optional[str]
    trigger: str


class SchedulerStatusResponse(BaseModel):
    running: bool
    job_count: int
    jobs: list[JobInfo]


# ── Routes ────────────────────────────────────────────────────────────────────

@router.post("/test-whatsapp", response_model=TestWhatsAppResponse)
async def test_whatsapp(
    req: TestWhatsAppRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Send a test WhatsApp message to any phone number.
    Useful for verifying Twilio sandbox credentials and phone opt-in.
    """
    if not req.phone.strip():
        raise HTTPException(status_code=400, detail="phone must not be empty")
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="message must not be empty")

    ok = whatsapp_service.send_message(
        to_phone=req.phone.strip(),
        message=req.message.strip(),
    )
    logger.info(
        "[Notifications] Test WhatsApp | agent=%s | phone=%s | success=%s",
        current_user.email or current_user.username,
        req.phone,
        ok,
    )
    return TestWhatsAppResponse(
        success=ok,
        phone=req.phone,
        message=req.message,
    )


@router.post("/trigger-policy-check", response_model=TriggerResponse)
async def trigger_policy_check(
    current_user: User = Depends(get_current_user),
):
    """
    Manually trigger the policy expiry reminder job right now.
    Checks for policies expiring in exactly 30 and 60 days.
    """
    try:
        await job_policy_expiry_reminders()
        return TriggerResponse(
            triggered=True,
            job="policy_expiry_reminders",
            detail="Policy expiry check completed. Check server logs for details.",
        )
    except Exception as exc:
        logger.error("[Notifications] Manual policy check failed: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))


@router.post("/trigger-birthday-check", response_model=TriggerResponse)
async def trigger_birthday_check(
    current_user: User = Depends(get_current_user),
):
    """
    Manually trigger the birthday wishes job right now.
    Sends wishes to all customers whose birthday is today.
    """
    try:
        await job_birthday_wishes()
        return TriggerResponse(
            triggered=True,
            job="birthday_wishes",
            detail="Birthday check completed. Check server logs for details.",
        )
    except Exception as exc:
        logger.error("[Notifications] Manual birthday check failed: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))


@router.post("/trigger-anniversary-check", response_model=TriggerResponse)
async def trigger_anniversary_check(
    current_user: User = Depends(get_current_user),
):
    """
    Manually trigger the anniversary wishes job right now.
    Sends wishes to all customers whose anniversary is today.
    """
    try:
        await job_anniversary_wishes()
        return TriggerResponse(
            triggered=True,
            job="anniversary_wishes",
            detail="Anniversary check completed. Check server logs for details.",
        )
    except Exception as exc:
        logger.error("[Notifications] Manual anniversary check failed: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))


@router.get("/scheduler-status", response_model=SchedulerStatusResponse)
async def scheduler_status(
    current_user: User = Depends(get_current_user),
):
    """
    Return the current state of the APScheduler and all registered jobs
    with their next scheduled run times.
    """
    jobs_info: list[JobInfo] = []
    for job in scheduler.get_jobs():
        next_run = (
            job.next_run_time.isoformat() if job.next_run_time else "paused"
        )
        jobs_info.append(
            JobInfo(
                id=job.id,
                name=job.name,
                next_run_time=next_run,
                trigger=str(job.trigger),
            )
        )

    return SchedulerStatusResponse(
        running=scheduler.running,
        job_count=len(jobs_info),
        jobs=jobs_info,
    )
