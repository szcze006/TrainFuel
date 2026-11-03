# Sprint 4 — Static Analysis

This folder is reserved for the **Sprint 4 automated static-analysis PDF exports**.

## PDF files to add

- `SonarQube-Report.pdf` — export from a new SonarQube Cloud analysis of the Sprint 4 code. Include bugs/reliability, vulnerabilities/security, code smells/maintainability, security hotspots, and Quality Gate status.
- `Trivy-Report.pdf` — PDF export or converted summary of a **new** Trivy repository/filesystem scan, including CRITICAL/HIGH/MEDIUM/LOW counts.

## Analysis information to include in each report or a combined report

- Language: Swift (SwiftUI) and dependency manifests
- SonarQube Cloud edition/version and analysis branch/commit
- Trivy version and scan type (filesystem or repository)
- Where each scan ran (cloud/local/CI)
- Scanned paths, exclusions, and reason for any exclusions
- Previous Sprint 3 counts versus actual new Sprint 4 counts
- A 2–3 sentence reflection about the highest-risk area and planned improvements

Exact required statement:

> This static analysis was generated using automated tools during this sprint.

## Sprint 3 baseline

The Sprint 3 report recorded SonarQube bugs 0, vulnerabilities 0, code smells 0, hotspots 0, Quality Gate *Not computed*; Trivy CRITICAL 0, HIGH 0, MEDIUM 0, LOW 0.

**Important:** These are only baseline numbers. Do not present them as Sprint 4 results. Upload actual generated PDF reports here before submitting this folder URL.

Sprint 3 reference: [previous analysis](../Sprint-3-Static-Analysis/).
