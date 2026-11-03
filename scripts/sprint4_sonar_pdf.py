#!/usr/bin/env python3
"""Render a dashboard-derived SonarQube Sprint 4 PDF, with explicit source disclosure.\n\nInputs are the November 3 dashboard screenshots supplied by the project owner.\n"""
from datetime import datetime, timezone
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
import os

out = "docs/Sprint-4-Static-Analysis/SonarQube-Report.pdf"
os.makedirs(os.path.dirname(out), exist_ok=True)
styles = getSampleStyleSheet()
story=[]
def line(s, style="BodyText"):
    story.append(Paragraph(s,styles[style]));story.append(Spacer(1,10))
def tab(rows):
    t=Table(rows,colWidths=[225,115,115])
    t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),colors.HexColor("#e8edf6")),("GRID",(0,0),(-1,-1),0.4,colors.grey),("FONTNAME",(0,0),(-1,0),"Helvetica-Bold"),("TOPPADDING",(0,0),(-1,-1),9),("BOTTOMPADDING",(0,0),(-1,-1),9)]))
    story.append(t);story.append(Spacer(1,15))
line("TrainFuel - Sprint 4 SonarQube Static Analysis", "Title")
line("Dashboard-derived report | SonarQube Cloud | November 3, 2026")
line("<b>Evidence/source:</b> SonarQube Cloud TrainFuel project summary and security measures screenshots provided during Sprint 4. This is a PDF summary of observed dashboard results, <b>not a native SonarQube PDF export</b>. Values are not newly rescanned by this PDF generator.")
line("<b>Tool:</b> SonarQube Cloud, cloud-hosted analysis; Free plan identified in prior Sprint 3 report (current plan not independently confirmed).")
line("<b>Languages:</b> Swift / SwiftUI, Python, GitHub Actions YAML. <b>Branch:</b> main. <b>Displayed analysis commit:</b> e10fa807. <b>Execution:</b> SonarQube Cloud (cloud), not local.")
line("SonarQube results and trend", "Heading2")
tab([["Metric","Sprint 3","Sprint 4"],["Bugs / Reliability issues","0","0"],["Vulnerabilities / Security issues","0","3"],["Code smells / Maintainability","0","0"],["Security hotspots","0","0"],["Quality Gate","Not computed","Not computed"]])
line("<b>Additional dashboard details:</b> Security rating C; reliability rating A; maintainability rating A; duplication 0.0%; accepted issues 0; 3.3k lines of code displayed.")
line("Scope and exclusions", "Heading2")
line("The SonarQube Cloud dashboard showed 8 analyzed files. Security measures displayed issues in the GitHub Actions Trivy workflow and in scripts/sprint4_trivy_pdf.py; other six displayed components had security rating A. The project contains Swift/SwiftUI application sources and related automation files.")
line("<b>Exclusions:</b> No manual exclusions are documented in the supplied dashboard evidence. The precise source-file inclusion and exclusion settings have not been independently verified. Code coverage was not configured in the dashboard.")
line("Findings and reflection", "Heading2")
line("Security issues rose from zero in Sprint 3 to three in Sprint 4. The most problematic area identified in the dashboard is new security-scan automation code, rather than a Swift app security rating issue. Next sprint we should examine the three SonarQube findings individually, correct any unsafe configuration or Python patterns, and rerun both tools to verify the fixes.")
line("<b>Interpretation:</b> The three open issues are labeled Security on the SonarQube dashboard; their individual rules and actual vulnerability severity have not been inspected. 'Quality Gate: Not computed' is not equivalent to Pass.")
line("This static analysis was generated using automated tools during this sprint.")
doc=SimpleDocTemplate(out,pagesize=(612,792),rightMargin=48,leftMargin=48,topMargin=42,bottomMargin=42)
doc.build(story)
print(out)
