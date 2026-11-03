#!/usr/bin/env python3
"""Build a Sprint 4 Trivy PDF from the JSON emitted by the Trivy scanner."""
import json
import os
import sys
from collections import Counter
from datetime import datetime, timezone
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether

source, destination = sys.argv[1:3]
with open(source, encoding="utf-8") as fh:
    data = json.load(fh)
counts = Counter({k: 0 for k in ("CRITICAL", "HIGH", "MEDIUM", "LOW")})
findings = []
for result in data.get("Results", []):
    target = result.get("Target", "Unknown target")
    for vuln in result.get("Vulnerabilities") or []:
        severity = (vuln.get("Severity") or "UNKNOWN").upper()
        counts[severity] += 1
        findings.append((target, vuln.get("VulnerabilityID", ""), severity, vuln.get("PkgName", "")))
scan_date = datetime.now(timezone.utc).strftime("%B %d, %Y, %H:%M UTC")
sha = os.environ.get("SCAN_COMMIT", "unknown")
trivy_version = os.environ.get("TRIVY_VERSION", "not recorded")
styles = getSampleStyleSheet()
doc = SimpleDocTemplate(destination, pagesize=(612,792), topMargin=40,bottomMargin=40)
story = []
def p(text, style="BodyText"):
    story.append(Paragraph(text, styles[style]))
    story.append(Spacer(1,9))
p("TrainFuel - Sprint 4 Trivy Security Scan", "Title")
p("Generated from actual automated Trivy JSON scan output on "+escape(scan_date))
p("<b>Project:</b> TrainFuel (Swift / SwiftUI iOS app)")
p("<b>Tool:</b> Trivy "+escape(trivy_version)+" | <b>Scan type:</b> filesystem (fs)")
p("<b>Execution:</b> GitHub Actions (CI) on Ubuntu | <b>Commit:</b> "+escape(sha))
p("<b>Scope:</b> Checked-out repository at this commit, including available Swift Package Manager dependency manifests. Source code of downloaded third-party packages is not in the repository.")
p("<b>Exclusions:</b> No explicit Trivy exclusions configured. Findings depend on Trivy's supported analyzers and available databases.")
p("Vulnerability counts", "Heading2")
rows=[["Severity", "Sprint 3", "Sprint 4"]]+[[key,"0",str(counts[key])] for key in ("CRITICAL","HIGH","MEDIUM","LOW")]
table=Table(rows,colWidths=[210,130,130]);table.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),colors.HexColor("#e9eef5")),("GRID",(0,0),(-1,-1),0.4,colors.grey),("FONTNAME",(0,0),(-1,0),"Helvetica-Bold"),("BOTTOMPADDING",(0,0),(-1,-1),8),("TOPPADDING",(0,0),(-1,-1),8)]))
story.append(table);story.append(Spacer(1,16))
p("<b>Trend:</b> Sprint 3 reported zero vulnerabilities in all four severity levels. Sprint 4 figures above are the newly scanned counts.")
p("<b>Reflection:</b> "+("The dependency/security scan identified vulnerabilities in packages listed below. We will review the affected dependencies and update or replace vulnerable versions before the next sprint." if sum(counts.values()) else "No vulnerabilities were detected by this scan. The main outstanding risk is limited coverage of application-specific Swift code, so next sprint we will add tests and review the code using SonarQube alongside Trivy."))
p("This static analysis was generated using automated tools during this sprint.")
p("Scan findings (first 40)", "Heading2")
if findings:
    for target, vid, severity, package in findings[:40]:
        p(escape(severity+" | "+vid+" | "+package+" | "+target))
else:
    p("No vulnerability records found in Trivy's JSON Results.")
p("<b>Note:</b> This report covers Trivy only; SonarQube metrics and its Quality Gate must come from a separate SonarQube analysis export.")
doc.build(story)
print("Wrote", destination, dict(counts))
