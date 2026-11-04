# Sprint 4 – Jira Report

## Jira Project

- **Project Name:** Fitness/Nutrition (TrainFUEL)
- **Project Link:** [https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/summary](https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/summary)
- **Sprint:** Sprint 4
- **Sprint Dates:** October 20 - November 4, 2026

### Sprint Goal

Reduce manual nutrition entry with external food data and meal photo scanning, improve the daily meal calendar, show calorie contributions from macronutrients, save hydration and recovery data, and make Firebase reads more focused.

---

## Sprint Commitment vs Delivery

| Metric | Count |
|---|---:|
| Issues committed at sprint start | 0 |
| Issues completed | 8 |
| Issues not completed | 0 |
| Issues added mid-sprint | 8 |

Sprint 4 was started on October 20 with no issues in it. All 8 issues were added to the sprint on November 2, 2026, when the Sprint 4 feature work was planned and developed. TFUEL-52 had been created during Sprint 3 and was moved from the backlog into Sprint 4; the other 7 issues were created on November 2.

---

## Issue Breakdown by Type

| Type | To Do | In Progress | Done |
|---|---:|---:|---:|
| Story | 0 | 0 | 0 |
| Task | 0 | 0 | 8 |
| Bug | 0 | 0 | 0 |

All 8 Sprint 4 issues were Tasks, and all 8 were moved to Done. TFUEL-64 is a bug fix but was logged as a Task.

---

## Sprint 4 Issues

| Issue | Description | Assignee | Story Points | Status |
|---|---|---|---:|---|
| TFUEL-52 | Persist Hydration and Recovery Data | Kacper Miczek | 3 | Done |
| TFUEL-58 | Load recent data on launch instead of full user history | Kacper Miczek | 2 | Done |
| TFUEL-59 | Scan a meal photo to estimate calories and macros | Kacper Miczek | 5 | Done |
| TFUEL-60 | Add barcode food scanner with Open Food Facts API | Casper Szczepaniak | 3 | Done |
| TFUEL-61 | Display daily meal counts on nutrition calendar | Casper Szczepaniak | 3 | Done |
| TFUEL-62 | Show calories by protein carbs and fat | Casper Szczepaniak | 3 | Done |
| TFUEL-63 | Optimize Firestore reads and snapshot listeners | Casper Szczepaniak | 3 | Done |
| TFUEL-64 | Today's meals hidden and macro calorie card shows code instead of numbers | Kacper Miczek | 1 | Done |

---

## Jira Work Items and Implementation

### [TFUEL-52 - Persist Hydration and Recovery Data](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-52)
- Saved daily water intake, sleep hours and soreness to Firestore under each user's daily logs.
- Loaded saved values back when the app opens, so data is no longer lost on restart.
- Connected the Performance Hub and Sports Coach recovery check-in to the saved data.
- **PR:** [#25](https://github.com/szcze006/TrainFuel/pull/25)

### [TFUEL-58 - Load recent data on launch instead of full user history](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-58)
- Changed the startup query to load only the last 30 days of meals instead of the full history.
- Added on-demand loading of older days when they are opened in the calendar.
- Kept already opened older days in memory so they are not fetched again.
- **PR:** [#24](https://github.com/szcze006/TrainFuel/pull/24)

### [TFUEL-59 - Scan a meal photo to estimate calories and macros](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-59)
- Added a photo option to the Add Meal screen to take or choose a meal photo.
- Sent the photo to an AI vision model (OpenRouter) to estimate the meal name, calories, protein, carbs and fat.
- Filled the Add Meal form with the estimate so the user can review and edit it before saving.
- Kept the API key in a local, Git-ignored file so it is never committed.
- **PR:** [#26](https://github.com/szcze006/TrainFuel/pull/26)

### [TFUEL-60 - Add barcode food scanner with Open Food Facts API](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-60)
- Built a barcode-scanning interface with VisionKit.
- Implemented external product lookup with the Open Food Facts API.
- Parsed calorie, protein, carbohydrate, and fat fields.
- Added serving-size adjustment and nutrition preview.
- Connected populated fields to the existing Add Meal form.
- Added a manual barcode test path for the iOS Simulator.
- **PR:** [#27](https://github.com/szcze006/TrainFuel/pull/27)

### [TFUEL-61 - Display daily meal counts on nutrition calendar](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-61)
- Added numerical meal indicators to days with logged entries.
- Kept zero-entry days free of count badges.
- Added month-focused Firestore meal queries.
- Kept selected-day details available alongside the calendar.
- **PR:** [#27](https://github.com/szcze006/TrainFuel/pull/27)

### [TFUEL-62 - Show calories by protein carbs and fat](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-62)
- Calculated 4 kcal/g for protein and carbohydrate, 9 kcal/g for fat.
- Added a calorie-source breakdown to the Nutrition screen.
- Reused the existing logged daily macro totals.
- Included a note about possible differences from package labels.
- **PR:** [#27](https://github.com/szcze006/TrainFuel/pull/27)

### [TFUEL-63 - Optimize Firestore reads and snapshot listeners](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-63)
- Added on-demand month queries for calendar history.
- Added a one-time static-profile fetch helper.
- Added scoped Firestore snapshot-listener utilities and listener removal.
- Identified the need to keep live data subscriptions limited to active, changing screens.
- **PR:** [#27](https://github.com/szcze006/TrainFuel/pull/27)

### [TFUEL-64 - Today's meals hidden and macro calorie card shows code instead of numbers](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-64)
- Made the whole Nutrition screen one scrolling list so today's meals are visible again and can be swiped to delete.
- Fixed the string interpolation so the calorie card shows protein, carbs and fat in kcal instead of raw code.
- **PR:** [#28](https://github.com/szcze006/TrainFuel/pull/28)

---

## Per-Student Work Allocation

| Student | Issues Assigned | Issues Completed |
|---|---:|---:|
| Casper Szczepaniak | 4 | 4 |
| Kacper Miczek | 4 | 4 |

### Kacper Miczek's Assigned Issues

- TFUEL-52 - Persist Hydration and Recovery Data
- TFUEL-58 - Load recent data on launch instead of full user history
- TFUEL-59 - Scan a meal photo to estimate calories and macros
- TFUEL-64 - Today's meals hidden and macro calorie card shows code instead of numbers

Kacper completed all 4 assigned Sprint 4 issues (11 story points).

---

## Estimation & Accuracy

| Metric | Value |
|---|---:|
| Total story points committed at sprint start | 0 |
| Story points added during sprint | 23 |
| Final sprint story points | 23 |
| Total story points completed | 23 |
| Completion % | 100% |

No story points were committed at sprint start. Issues worth 23 story points were added during the sprint (Kacper Miczek 11, Casper Szczepaniak 12), and all 23 were completed.

**Completion Percentage:**

23 completed story points / 23 final story points × 100 = **100%**

---

## Workflow Discipline

- ☑ Issues moved through workflow states (To Do → In Progress → Done)
- ☑ Issues closed only after acceptance criteria were met
- ☐ Sprint completed/closed in Jira

7 of 8 issues moved To Do → In Progress → Done. TFUEL-64 was a small bug fix that went from To Do directly to Done. The sprint was still active at the time of this report and will be closed in Jira after the sprint end date.

---

## Blockers & Scope Changes

### Major Blockers

- **Camera and simulator:** The iOS Simulator cannot provide live camera input, so the barcode scanner and meal photo scan cannot be fully tested there. A manual barcode entry path was added so the API lookup can still be demonstrated.
- **Photo scanning:** The meal photo scan needs a private OpenRouter API key. A local setup script and documentation were added, and the key was not committed to GitHub. The availability of the AI model is outside the app's control.
- **Firebase:** Month-scoped and 30-day reads were added, while broader snapshot-listener lifecycle changes still need verification.
- **Planning:** Sprint 4 started with no issues planned, so the board did not show progress until the work was added on November 2.

### Scope Changes

- All 8 issues (23 story points) were added during Sprint 4.
- TFUEL-52 (Persist Hydration and Recovery Data) was carried over from the Sprint 3 backlog into Sprint 4.
- TFUEL-64 was added after a layout bug was found once the macro calorie card (TFUEL-62) was merged.

### Work Spilled Over

- No Sprint 4 issues spilled over. All 8 issues in the sprint were completed.
- Follow-up testing for the next sprint: barcode and photo scanning on a physical iPhone, and a complete Firebase listener audit.

---

## Jira Evidence Links

- **Sprint Report:** [https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/boards/1/reports/sprint-retrospective?sprint=5](https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/boards/1/reports/sprint-retrospective?sprint=5)
- **Backlog:** [https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/boards/1/backlog](https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/boards/1/backlog)
- **Sprint Board:** [https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/boards/1](https://rangers-team-ik0pzjj8.atlassian.net/jira/software/projects/TFUEL/boards/1)
