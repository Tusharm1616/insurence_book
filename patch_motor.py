import os
import re

file_path = 'routes/motor.py'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_endpoints = '''
# --- NEW MOTOR CALCULATOR ENDPOINTS ---
import tempfile
from reportlab.pdfgen import canvas
from reportlab.platypus import Spacer

class MotorCalcPremiumRequest(BaseModel):
    vehicle_type: str
    fuel_type: str
    year_of_manufacture: int
    cc_category: str = ""
    idv: float
    ncb_percent: float
    addons: List[str] = []
    customer_name: str = ""
    vehicle_reg_no: str = ""

@router.post("/calculate-premium")
async def api_calculate_premium(
    req: MotorCalcPremiumRequest,
    current_user: User = Depends(get_current_user)
):
    # IRDAI TP Rates
    tp_premium = 0
    if req.vehicle_type == "Two Wheeler":
        if "Less than 75cc" in req.cc_category: tp_premium = 538
        elif "75cc to 150cc" in req.cc_category: tp_premium = 714
        elif "150cc to 350cc" in req.cc_category: tp_premium = 1366
        else: tp_premium = 2804
    elif req.vehicle_type == "Four Wheeler":
        if "Less than 1000cc" in req.cc_category: tp_premium = 2094
        elif "1000cc to 1500cc" in req.cc_category: tp_premium = 3416
        else: tp_premium = 7897
    else:
        tp_premium = 5000 # Commercial Vehicle
        
    current_year = 2026
    age = max(0, current_year - req.year_of_manufacture)
    
    depreciation_rate = 0.0
    if age == 1: depreciation_rate = 0.05
    elif age == 2: depreciation_rate = 0.10
    elif age == 3: depreciation_rate = 0.15
    elif age == 4: depreciation_rate = 0.25
    elif age == 5: depreciation_rate = 0.35
    elif age == 6: depreciation_rate = 0.40
    elif age == 7: depreciation_rate = 0.45
    elif age >= 8: depreciation_rate = 0.50
    
    base_od_rate = 0.026 if req.vehicle_type == "Two Wheeler" else 0.022
    od_before_ncb = req.idv * base_od_rate * (1 - depreciation_rate)
    ncb_discount = od_before_ncb * (req.ncb_percent / 100)
    od_premium = od_before_ncb - ncb_discount
    
    addons_breakdown = {}
    if "Zero Depreciation" in req.addons: addons_breakdown["Zero Depreciation"] = req.idv * 0.005
    if "Engine Protection Cover" in req.addons: addons_breakdown["Engine Protection Cover"] = 800
    if "Roadside Assistance" in req.addons: addons_breakdown["Roadside Assistance"] = 499
    if "Personal Accident Cover" in req.addons: addons_breakdown["Personal Accident Cover"] = 750
    if "Return to Invoice" in req.addons: addons_breakdown["Return to Invoice"] = req.idv * 0.003
    
    addons_total = sum(addons_breakdown.values())
    subtotal = od_premium + tp_premium + addons_total
    gst = subtotal * 0.18
    total_premium = subtotal + gst
    
    import time
    quote_ref = f"QT{int(time.time() * 1000)}"
    
    return {
        "od_before_ncb": round(od_before_ncb, 2),
        "ncb_discount": round(ncb_discount, 2),
        "od_premium": round(od_premium, 2),
        "tp_premium": round(tp_premium, 2),
        "addon_breakdown": {k: round(v, 2) for k, v in addons_breakdown.items()},
        "addons_total": round(addons_total, 2),
        "subtotal": round(subtotal, 2),
        "gst": round(gst, 2),
        "total_premium": round(total_premium, 2),
        "idv": round(req.idv, 2),
        "vehicle_age": age,
        "ncb_percent": req.ncb_percent,
        "vehicle_type": req.vehicle_type,
        "quote_reference": quote_ref
    }

class QuotePdfRequest(BaseModel):
    vehicle_type: str
    fuel_type: str
    year_of_manufacture: int
    cc_category: str = ""
    idv: float
    ncb_percent: float
    addons: List[str] = []
    customer_name: str = ""
    vehicle_reg_no: str = ""
    # Calculation Results
    od_before_ncb: float
    ncb_discount: float
    od_premium: float
    tp_premium: float
    addon_breakdown: dict
    addons_total: float
    subtotal: float
    gst: float
    total_premium: float
    quote_reference: str

@router.post("/generate-quote-pdf")
async def api_generate_quote_pdf(
    req: QuotePdfRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    import json
    from sqlalchemy import text
    
    # Save to history
    query = text("""
        INSERT INTO motor_quote_history 
        (agent_id, customer_name, vehicle_type, vehicle_reg_no, year_of_manufacture,
         cc_category, fuel_type, idv, ncb_percent, addons, od_premium, tp_premium,
         addons_total, gst, total_premium)
        VALUES 
        (:agent_id, :customer_name, :vehicle_type, :vehicle_reg_no, :year_of_manufacture,
         :cc_category, :fuel_type, :idv, :ncb_percent, :addons, :od_premium, :tp_premium,
         :addons_total, :gst, :total_premium)
    """)
    await db.execute(query, {
        "agent_id": current_user.id,
        "customer_name": req.customer_name,
        "vehicle_type": req.vehicle_type,
        "vehicle_reg_no": req.vehicle_reg_no,
        "year_of_manufacture": req.year_of_manufacture,
        "cc_category": req.cc_category,
        "fuel_type": req.fuel_type,
        "idv": req.idv,
        "ncb_percent": req.ncb_percent,
        "addons": json.dumps(req.addons),
        "od_premium": req.od_premium,
        "tp_premium": req.tp_premium,
        "addons_total": req.addons_total,
        "gst": req.gst,
        "total_premium": req.total_premium
    })
    await db.commit()
    
    # ReportLab PDF Generation
    filename = f"motor_quote_{req.quote_reference}.pdf"
    filepath = os.path.join(tempfile.gettempdir(), filename)
    
    doc = SimpleDocTemplate(filepath, pagesize=A4, rightMargin=30, leftMargin=30, topMargin=30, bottomMargin=30)
    elements = []
    styles = getSampleStyleSheet()
    
    # Header table
    header_data = [
        [Paragraph(f"<font color=white size=18><b>{current_user.full_name} Agency</b></font><br/>"
                   f"<font color=white size=13>{current_user.full_name}</font><br/>"
                   f"<font color=white size=12>Ph: {current_user.phone}</font><br/>"
                   f"<font color=white size=11><i>License: {current_user.license_no}</i></font>"), 
         Paragraph(f"<font color=white size=20><b>MOTOR INSURANCE</b></font><br/>"
                   f"<font color=white size=16><b>PREMIUM QUOTE</b></font><br/>"
                   f"<font color=white size=11>Ref: {req.quote_reference}</font>", styles['Normal'])]
    ]
    t = Table(header_data, colWidths=[300, 230])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#4CAF50')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING', (0,0), (-1,-1), 15),
    ]))
    elements.append(t)
    elements.append(Spacer(1, 20))
    
    # Vehicle Details
    elements.append(Paragraph("<b>Vehicle Details</b>", styles['Heading3']))
    v_data = [
        ["Vehicle Type", req.vehicle_type],
        ["Fuel Type", req.fuel_type],
        ["Year of Manufacture", str(req.year_of_manufacture)],
        ["IDV", f"Rs. {req.idv:,.2f}"],
        ["NCB Percentage", f"{req.ncb_percent}%"],
        ["Registration Number", req.vehicle_reg_no],
        ["Customer Name", req.customer_name],
    ]
    tv = Table(v_data, colWidths=[200, 300])
    tv.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F5F5F5')),
        ('GRID', (0,0), (-1,-1), 1, colors.white),
        ('PADDING', (0,0), (-1,-1), 8),
    ]))
    elements.append(tv)
    elements.append(Spacer(1, 20))
    
    # Premium Breakdown
    elements.append(Paragraph("<b>Premium Breakdown</b>", styles['Heading3']))
    p_data = [
        ["Component", "Amount"],
        ["Own Damage Before NCB", f"Rs. {req.od_before_ncb:,.2f}"],
        ["NCB Discount", f"- Rs. {req.ncb_discount:,.2f}"],
        ["Own Damage Premium", f"Rs. {req.od_premium:,.2f}"],
        ["Third Party Premium", f"Rs. {req.tp_premium:,.2f}"]
    ]
    for k, v in req.addon_breakdown.items():
        p_data.append([k, f"Rs. {v:,.2f}"])
        
    p_data.append(["Subtotal", f"Rs. {req.subtotal:,.2f}"])
    p_data.append(["GST 18%", f"Rs. {req.gst:,.2f}"])
    p_data.append(["Total Premium", f"Rs. {req.total_premium:,.2f}"])
    
    tp = Table(p_data, colWidths=[350, 150])
    tp.setStyle(TableStyle([
        ('GRID', (0,0), (-1,-1), 0.5, colors.lightgrey),
        ('PADDING', (0,0), (-1,-1), 8),
        ('BACKGROUND', (0,-1), (-1,-1), colors.HexColor('#E8F5E9')),
        ('FONTNAME', (0,-1), (-1,-1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (1,2), (1,2), colors.red), # NCB Discount red
    ]))
    elements.append(tp)
    elements.append(Spacer(1, 10))
    elements.append(Paragraph(f"<font color=gray size=12>IDV Covered: Rs. {req.idv:,.2f}</font>", styles['Normal']))
    
    doc.build(elements)
    
    return FileResponse(
        path=filepath, 
        filename=filename,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.get("/quote-history")
async def api_quote_history(
    limit: int = 5,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy import text
    query = text("""
        SELECT * FROM motor_quote_history 
        WHERE agent_id = :agent_id
        ORDER BY created_at DESC
        LIMIT :limit
    """)
    result = await db.execute(query, {"agent_id": current_user.id, "limit": limit})
    rows = result.fetchall()
    
    history = []
    for r in rows:
        history.append({
            "id": r.id,
            "customer_name": r.customer_name,
            "vehicle_type": r.vehicle_type,
            "vehicle_reg_no": r.vehicle_reg_no,
            "total_premium": float(r.total_premium),
            "created_at": r.created_at.isoformat() if r.created_at else None
        })
    return history
'''

content = re.sub(r'# Legacy endpoints for backward compatibility.*', new_endpoints, content, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
