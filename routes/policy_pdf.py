"""
Policy PDF Generation — Generate a formatted PDF summary of a policy.
"""
import io
from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Spacer, Paragraph
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_RIGHT

from database import get_db
from models.users import User
from models.customers import Customer
from models.policies import Policy
from utils.auth import get_current_user

router = APIRouter(prefix="/api/policies", tags=["Policy PDF"])

# Colors
PRIMARY = HexColor("#22C55E")
DARK = HexColor("#1C1C1C")
GRAY = HexColor("#6B7280")
LIGHT_BG = HexColor("#F9FAFB")
WHITE = HexColor("#FFFFFF")


def _format_date(d) -> str:
    if not d:
        return "N/A"
    if isinstance(d, date):
        return d.strftime("%d %b %Y")
    return str(d)


def _format_currency(amount) -> str:
    if not amount:
        return "₹0"
    try:
        val = float(amount)
        if val == int(val):
            return f"₹{int(val):,}"
        return f"₹{val:,.2f}"
    except (ValueError, TypeError):
        return "₹0"


def _build_pdf(policy, customer: Customer, agent: User) -> io.BytesIO:
    """Build a professional PDF summary of the policy."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=20 * mm,
        rightMargin=20 * mm,
        topMargin=15 * mm,
        bottomMargin=15 * mm,
    )

    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        "TitleStyle",
        parent=styles["Heading1"],
        fontSize=20,
        textColor=PRIMARY,
        spaceAfter=4,
    )
    subtitle_style = ParagraphStyle(
        "SubtitleStyle",
        parent=styles["Normal"],
        fontSize=10,
        textColor=GRAY,
    )
    section_title_style = ParagraphStyle(
        "SectionTitle",
        parent=styles["Heading2"],
        fontSize=13,
        textColor=DARK,
        spaceBefore=14,
        spaceAfter=6,
        borderPadding=(0, 0, 4, 0),
    )
    normal_style = ParagraphStyle(
        "NormalCustom",
        parent=styles["Normal"],
        fontSize=10,
        textColor=DARK,
        leading=14,
    )
    footer_style = ParagraphStyle(
        "FooterStyle",
        parent=styles["Normal"],
        fontSize=8,
        textColor=GRAY,
        alignment=TA_CENTER,
    )

    elements = []

    # ── Header ────────────────────────────────────────────────────────────
    agent_name = agent.full_name if hasattr(agent, "full_name") and agent.full_name else (agent.username if hasattr(agent, "username") else "Insurance Agent")
    header_data = [
        [
            Paragraph("InsureBook", title_style),
            Paragraph(f"Generated: {_format_date(date.today())}", subtitle_style),
        ],
        [
            Paragraph(f"Agent: {agent_name}", subtitle_style),
            Paragraph(f"Policy #{policy.policy_number}", subtitle_style),
        ],
    ]
    header_table = Table(header_data, colWidths=[100 * mm, 70 * mm])
    header_table.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("ALIGN", (1, 0), (1, -1), "RIGHT"),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
    ]))
    elements.append(header_table)
    elements.append(Spacer(1, 6 * mm))

    # ── Divider line via table ────────────────────────────────────────────
    divider = Table([[""]], colWidths=[170 * mm], rowHeights=[1])
    divider.setStyle(TableStyle([
        ("LINEBELOW", (0, 0), (-1, 0), 1, PRIMARY),
    ]))
    elements.append(divider)
    elements.append(Spacer(1, 4 * mm))

    # ── Customer Section ──────────────────────────────────────────────────
    elements.append(Paragraph("Customer Details", section_title_style))
    cust_data = [
        ["Name", customer.full_name or "N/A"],
        ["Phone", customer.phone or "N/A"],
        ["Email", customer.email or "N/A"],
        ["Address", f"{customer.address or ''}, {customer.city or ''}, {customer.state or ''} {customer.pincode or ''}".strip(", ")],
    ]
    cust_table = Table(cust_data, colWidths=[40 * mm, 130 * mm])
    cust_table.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("TEXTCOLOR", (0, 0), (0, -1), GRAY),
        ("TEXTCOLOR", (1, 0), (1, -1), DARK),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BACKGROUND", (0, 0), (-1, -1), LIGHT_BG),
        ("BOX", (0, 0), (-1, -1), 0.5, GRAY),
        ("INNERGRID", (0, 0), (-1, -1), 0.25, HexColor("#E5E7EB")),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
    ]))
    elements.append(cust_table)
    elements.append(Spacer(1, 4 * mm))

    # ── Policy Section ────────────────────────────────────────────────────
    elements.append(Paragraph("Policy Details", section_title_style))
    
    policy_type = getattr(policy, "policy_type", None) or getattr(policy, "insurance_type", "N/A")
    insurer_name = getattr(policy, "insurer_name", None) or getattr(policy, "insurance_company", "N/A")
    
    policy_data = [
        ["Policy Number", policy.policy_number or "N/A"],
        ["Insurance Type", policy_type],
        ["Company", insurer_name],
        ["Plan Name", getattr(policy, "plan_name", "N/A") or "N/A"],
        ["Start Date", _format_date(getattr(policy, "issue_date", None) or getattr(policy, "start_date", None))],
        ["End Date", _format_date(getattr(policy, "expiry_date", None) or getattr(policy, "end_date", None))],
        ["Status", (getattr(policy, "status", None) or ("active" if getattr(policy, "is_active", True) else "inactive")).capitalize()],
    ]
    
    nominee_name = getattr(policy, "nominee_name", None)
    nominee_relation = getattr(policy, "nominee_relation", "N/A")
    if nominee_name:
        policy_data.append(["Nominee", f"{nominee_name} ({nominee_relation})"])
        
    vehicle_reg_no = getattr(policy, "vehicle_reg_no", None)
    if vehicle_reg_no:
        policy_data.append(["Vehicle Reg No", vehicle_reg_no])

    pol_table = Table(policy_data, colWidths=[40 * mm, 130 * mm])
    pol_table.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("TEXTCOLOR", (0, 0), (0, -1), GRAY),
        ("TEXTCOLOR", (1, 0), (1, -1), DARK),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BACKGROUND", (0, 0), (-1, -1), WHITE),
        ("BOX", (0, 0), (-1, -1), 0.5, GRAY),
        ("INNERGRID", (0, 0), (-1, -1), 0.25, HexColor("#E5E7EB")),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
    ]))
    elements.append(pol_table)
    elements.append(Spacer(1, 4 * mm))

    # ── Financial Section ─────────────────────────────────────────────────
    elements.append(Paragraph("Financial Details", section_title_style))
    
    sum_assured = getattr(policy, "sum_assured", None) or getattr(policy, "total_amount", 0)
    premium_amount = getattr(policy, "premium_amount", None) or getattr(policy, "final_amount", 0)
    
    fin_data = [
        ["Sum Assured", _format_currency(sum_assured)],
        ["Premium Amount", _format_currency(premium_amount)],
        ["NCB", f"{getattr(policy, 'ncb_percent', 0) or 0}%"],
    ]
    
    premium_due_date = getattr(policy, "premium_due_date", None)
    if premium_due_date:
        fin_data.append(["Premium Due Date", _format_date(premium_due_date)])
        
    maturity_date = getattr(policy, "maturity_date", None)
    if maturity_date:
        fin_data.append(["Maturity Date", _format_date(maturity_date)])

    fin_table = Table(fin_data, colWidths=[40 * mm, 130 * mm])
    fin_table.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("TEXTCOLOR", (0, 0), (0, -1), GRAY),
        ("TEXTCOLOR", (1, 0), (1, -1), DARK),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BACKGROUND", (0, 0), (-1, -1), LIGHT_BG),
        ("BOX", (0, 0), (-1, -1), 0.5, GRAY),
        ("INNERGRID", (0, 0), (-1, -1), 0.25, HexColor("#E5E7EB")),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
    ]))
    elements.append(fin_table)
    elements.append(Spacer(1, 8 * mm))

    # ── Footer ────────────────────────────────────────────────────────────
    elements.append(divider)
    elements.append(Spacer(1, 3 * mm))
    elements.append(Paragraph("Generated by InsureBook — Your Smart Insurance Partner", footer_style))

    doc.build(elements)
    buffer.seek(0)
    return buffer


@router.get("/{policy_id}/generate-pdf")
async def generate_policy_pdf(
    policy_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate a formatted PDF summary of a policy and return as file download."""
    is_uuid = False
    try:
        import uuid
        uuid.UUID(policy_id)
        is_uuid = True
    except ValueError:
        pass

    policy = None
    if is_uuid:
        from models.policy_v2 import PolicyV2
        result = await db.execute(
            select(PolicyV2).where(
                PolicyV2.id == policy_id,
                PolicyV2.agent_id == current_user.id,
            )
        )
        policy = result.scalars().first()
    else:
        try:
            p_id_int = int(policy_id)
            result = await db.execute(
                select(Policy).where(
                    Policy.id == p_id_int,
                    Policy.agent_id == current_user.id,
                )
            )
            policy = result.scalars().first()
        except ValueError:
            pass

    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")

    # Fetch customer
    cust_result = await db.execute(
        select(Customer).where(Customer.id == policy.customer_id)
    )
    customer = cust_result.scalars().first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    # Build PDF
    pdf_buffer = _build_pdf(policy, customer, current_user)

    filename = f"Policy_{policy.policy_number.replace(' ', '_')}.pdf"

    return StreamingResponse(
        pdf_buffer,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
        },
    )

