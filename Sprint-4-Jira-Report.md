# TrainFUEL — Sprint 4 Jira Report

**Project:** Fitness/Nutrition (`TFUEL`)  
**Jira project:** https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/boards  
**Sprint:** Sprint 4  
**Contributor:** Casper Szczepaniak (szcze006)  
**Report date:** __________  
**Sprint dates:** __________

## 1. Sprint Goal

Reduce manual nutrition entry with external food data, improve the daily meal calendar, show calorie contributions from macronutrients, and make Firebase reads more focused. This work responds to instructor feedback on API data sources, daily counts, nutrient breakdown, and efficient streams.

## 2. Commitment vs. Delivery

| Metric | Value | Explanation |
| --- | ---: | --- |
| Jira tasks tracked for Casper's Sprint 4 work | **4** | TFUEL-60, TFUEL-61, TFUEL-62, TFUEL-63 |
| Tasks with source code delivered | **4** | Implementation or supporting code exists for all four areas |
| Tasks in Jira **Done** | **0** | Jira currently lists these four as To Do; no completion claimed |
| Tasks in Jira **In Progress** | **0** | Current recorded status, not a statement that no work happened |
| Tasks in Jira **To Do** | **4** | Status updates are still outstanding |
| Story points committed | **Not recorded** | No verified estimates in these four tickets |
| Story points completed | **Not recorded** | Do not infer points from code or task count |
| Merged PRs directly supporting this scope | **1** | [PR #27](https://github.com/szcze006/TrainFuel/pull/27) |

**Interpretation:** The work is visible in GitHub even though Jira status bookkeeping has not yet caught up. Code delivery is not the same as a verified Done status.

## 3. Issue Breakdown by Type and Status

| Issue type | To Do | In Progress | Done | Total |
| --- | ---: | ---: | ---: | ---: |
| Task | 4 | 0 | 0 | **4** |
| **Total** | **4** | **0** | **0** | **4** |

## 4. Per-Student Allocation

| Student | Tracked issues | Issue keys | Story points |
| --- | ---: | --- | --- |
| Casper Szczepaniak (szcze006) | **4 linked tasks** | TFUEL-60–TFUEL-63 | Not recorded |

These tasks were created with the `casper` and `sprint-4` labels, but Jira currently has **no assignee set** on them. “Linked tasks” here means work authored/tracked for Casper, not formally assigned in Jira. Other team members have separate issues not counted as Casper's tasks.

## 5. Jira Work Items and Detailed Implementation

### [TFUEL-60 — Barcode food scanner and Open Food Facts API](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-60)
- Built a barcode-scanning interface with VisionKit.
- Implemented external product lookup.
- Parsed calorie, protein, carbohydrate, and fat fields.
- Added serving-size adjustment and nutrition preview.
- Connected populated fields to the existing Add Meal form.
- Added a manual barcode test path for the iOS simulator.
- **Status in Jira:** To Do. **Code:** Implemented; physical-device scanning and known-product API validation still need verification.

### [TFUEL-61 — Daily meal counts on calendar](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-61)
- Added numerical meal indicators to days with logged entries.
- Kept zero-entry days free of count badges.
- Added month-focused Firestore meal queries.
- Kept selected-day details available alongside the calendar.
- **Status in Jira:** To Do. **Code:** Implemented; verify against real meal history.

### [TFUEL-62 — Calories from protein, carbohydrates, and fat](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-62)
- Calculated 4 kcal/g for protein and carbohydrate, 9 kcal/g for fat.
- Added a calorie-source breakdown to the Nutrition screen.
- Reused the existing logged daily macro totals.
- Included a note about possible differences from package labels.
- **Status in Jira:** To Do. **Code:** Implemented; visual confirmation against sample entries remains.

### [TFUEL-63 — Optimize Firebase retrieval and stream use](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-63)
- Added on-demand month queries for calendar history.
- Added a one-time static-profile fetch helper.
- Added scoped Firestore snapshot-listener utilities and listener removal.
- Identified the need to keep live data subscriptions limited to active, changing screens.
- **Status in Jira:** To Do. **Code:** Partially integrated; full listener audit and screen-lifecycle integration remain open.

## 6. Story-Point Accuracy

No story-point values were confirmed for TFUEL-60–TFUEL-63. This report intentionally does not invent a velocity, committed-point total, or completed-point total. The evidence of implementation is in the linked GitHub PR and commits.

## 7. Workflow Discipline Checklist

- [x] Sprint 4 tasks created in the TrainFUEL Jira project
- [x] Issues linked to code changes through report and PR description
- [x] Source code merged to `dev`
- [x] Substantial implementation documented by work item
- [ ] Formal assignees added to Jira issues
- [ ] Jira statuses aligned with actual verification
- [ ] Story points estimated in Jira if required by the course
- [ ] Physical iPhone barcode scan tested
- [ ] Calendar and macro breakdown fully regression-tested

## 8. Blockers, Scope Changes, and Spillover

**Camera and simulator:** The iPhone simulator cannot provide normal live VisionKit barcode scanning. Manual barcode entry was added so an API lookup can still be demonstrated.

**Photo scanning:** An existing AI photo analysis feature required a private OpenRouter key. A local setup script and documentation were added; the live key was not committed to GitHub. Its model/service availability remains external to the app.

**Firebase:** Month-scoped reads were added, while broader listener lifecycle changes still require verification.

**Spillover:** Physical barcode scanning, complete Firebase listener audit, and final issue status updates remain follow-up work.

## 9. Evidence Links

- [Jira project / board](https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/boards)
- [TFUEL-60](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-60)
- [TFUEL-61](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-61)
- [TFUEL-62](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-62)
- [TFUEL-63](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-63)
- [Merged GitHub PR #27](https://github.com/szcze006/TrainFuel/pull/27)

**Sprint result:** Four scoped Jira tasks and a merged eight-commit PR cover the requested product improvements. Remaining testing and Jira bookkeeping are disclosed explicitly rather than counted as completed.
