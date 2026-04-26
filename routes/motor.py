import os
import uuid
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

router = APIRouter(prefix="/api/motor", tags=["Motor Calculator"])

class MotorCalcRequest(BaseModel):
    vehicle_type: str # 2W, 4W, CV
    cubic_capacity: int
    manufacture_year: int
    idv: float
    ncb_percent: float # 0, 20, 25, 35, 45, 50
    add_ons: List[str] # zero_dep, engine_protect, rti

class MotorCalcResponse(BaseModel):
    base_od: float
    ncb_discount: float
    total_od: float
    total_tp: float
    add_ons_total: float
    net_premium: float
    gst: float
    final_premium: float

def calculate_premium_logic(req: MotorCalcRequest) -> MotorCalcResponse:
    # Simplified mock IRDAI logic
    current_year = datetime.now().year
    age = max(0, current_year - req.manufacture_year)
    
    # 1. Base OD Premium (~1.2% to 3% of IDV depending on age)
    od_rate = 0.03 if age <= 3 else 0.02
    base_od = req.idv * od_rate
    
    # 2. NCB Discount
    ncb_discount = base_od * (req.ncb_percent / 100.0)
    total_od = base_od - ncb_discount
    
    # 3. Third Party Premium (Fixed based on CC & Type)
    total_tp = 0
    if req.vehicle_type == '2W':
        if req.cubic_capacity <= 75: total_tp = 538
        elif req.cubic_capacity <= 150: total_tp = 714
        elif req.cubic_capacity <= 350: total_tp = 1366
        else: total_tp = 2804
    else: # 4W
        if req.cubic_capacity <= 1000: total_tp = 2094
        elif req.cubic_capacity <= 1500: total_tp = 3416
        else: total_tp = 7897
        
    # 4. Add-ons
    add_ons_total = 0
    if "zero_dep" in req.add_ons:
        add_ons_total += req.idv * 0.015 # 1.5% of IDV
    if "engine_protect" in req.add_ons:
        add_ons_total += req.idv * 0.005 # 0.5% of IDV
    if "rti" in req.add_ons:
        add_ons_total += req.idv * 0.01 # 1% of IDV
        
    # 5. Net and Final
    net_premium = total_od + total_tp + add_ons_total
    gst = net_premium * 0.18
    final_premium = net_premium + gst
    
    return MotorCalcResponse(
        base_od=round(base_od, 2),
        ncb_discount=round(ncb_discount, 2),
        total_od=round(total_od, 2),
        total_tp=round(total_tp, 2),
        add_ons_total=round(add_ons_total, 2),
        net_premium=round(net_premium, 2),
        gst=round(gst, 2),
        final_premium=round(final_premium, 2)
    )

@router.post("/calculate-premium", response_model=MotorCalcResponse)
async def calculate_premium(req: MotorCalcRequest):
    return calculate_premium_logic(req)

@router.post("/generate-quote-pdf")
async def generate_quote_pdf(req: MotorCalcRequest):
    data = calculate_premium_logic(req)
    
    filename = f"quote_{uuid.uuid4().hex[:8]}.pdf"
    filepath = f"/tmp/{filename}"
    
    # Ensure /tmp exists on windows? 
    # Better to use a cross-platform temp dir
    import tempfile
    filepath = os.path.join(tempfile.gettempdir(), filename)
    
    doc = SimpleDocTemplate(filepath, pagesize=A4)
    elements = []
    
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle('Title', parent=styles['Heading1'], alignment=1, spaceAfter=20)
    
    elements.append(Paragraph("Motor Insurance Quotation", title_style))
    elements.append(Spacer(1, 12))
    
    # Vehicle Details
    v_details = [
        ["Vehicle Details", ""],
        ["Type", req.vehicle_type],
        ["Cubic Capacity", f"{req.cubic_capacity} CC"],
        ["Manufacture Year", str(req.manufacture_year)],
        ["Declared IDV", f"Rs. {req.idv:,.2f}"],
        ["NCB %", f"{req.ncb_percent}%"]
    ]
    t1 = Table(v_details, colWidths=[200, 200])
    t1.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (1,0), colors.HexColor('#4CAF50')),
        ('TEXTCOLOR', (0,0), (1,0), colors.white),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('FONTNAME', (0,0), (1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (1,0), 10),
        ('BACKGROUND', (0,1), (-1,-1), colors.HexColor('#F5F6FA')),
        ('GRID', (0,0), (-1,-1), 1, colors.white)
    ]))
    elements.append(t1)
    elements.append(Spacer(1, 20))
    
    # Premium Details
    p_details = [
        ["Premium Details", "Amount (Rs.)"],
        ["Base Own Damage (OD) Premium", f"{data.base_od:,.2f}"],
        [f"Less: NCB Discount ({req.ncb_percent}%)", f"- {data.ncb_discount:,.2f}"],
        ["Total OD Premium (A)", f"{data.total_od:,.2f}"],
        ["Total Third Party (TP) Premium (B)", f"{data.total_tp:,.2f}"],
        ["Add-ons Premium (C)", f"{data.add_ons_total:,.2f}"],
        ["Net Premium (A + B + C)", f"{data.net_premium:,.2f}"],
        ["Add: GST @ 18%", f"{data.gst:,.2f}"],
        ["FINAL PREMIUM", f"{data.final_premium:,.2f}"]
    ]
    
    t2 = Table(p_details, colWidths=[300, 100])
    t2.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (1,0), colors.HexColor('#2196F3')),
        ('TEXTCOLOR', (0,0), (1,0), colors.white),
        ('FONTNAME', (0,0), (1,0), 'Helvetica-Bold'),
        ('ALIGN', (1,0), (1,-1), 'RIGHT'),
        ('FONTNAME', (0,-1), (1,-1), 'Helvetica-Bold'),
        ('BACKGROUND', (0,-1), (1,-1), colors.HexColor('#E3F2FD')),
        ('GRID', (0,0), (-1,-1), 0.5, colors.grey)
    ]))
    elements.append(t2)
    
    # Generate PDF
    doc.build(elements)
    
    return FileResponse(
        path=filepath, 
        filename="Motor_Insurance_Quote.pdf",
        media_type="application/pdf"
    )
