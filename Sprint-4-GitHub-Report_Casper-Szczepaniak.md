# TrainFUEL — Sprint 4 GitHub Report

**Repository:** https://github.com/szcze006/TrainFuel  
**Sprint:** Sprint 4  
**Contributor:** Casper Szczepaniak (szcze006)  
**Report date:** __________  
**Sprint dates:** __________

## 1. Merged Pull Requests

| Pull request | Author | Reviewers | Merge date | Target branch | Result |
| --- | --- | --- | --- | --- | --- |
| [#27 — Sprint 4: barcode nutrition lookup, meal-count and Firebase helpers](https://github.com/szcze006/TrainFuel/pull/27) | szcze006 | Not recorded | __________ | `dev` | Merged |

**Verified PR metrics:** 8 commits, 6 changed files, 506 lines added, and 0 lines deleted (GitHub PR metadata). These are PR totals, not individual effort-hour estimates.

## 2. Feature Changes Delivered

| Work item | Code and implementation detail | Evidence |
| --- | --- | --- |
| 1. Barcode recognition | Created VisionKit camera barcode scanning view for compatible iPhones | `MyApp/Sprint4Features.swift`, PR #27 |
| 2. External nutrition lookup | Implemented an Open Food Facts API client to request food information from a barcode | `MyApp/Sprint4Features.swift`, PR #27 |
| 3. Nutrient parsing | Added data models and extraction for calories, protein, carbohydrate, and fat per 100 g | `MyApp/Sprint4Features.swift`, PR #27 |
| 4. Portion adjustment | Added editable serving grams and recalculation before logging food | `MyApp/Sprint4Features.swift`, PR #27 |
| 5. Meal-entry integration | Connected scanned values to the existing Add Meal form and its Firebase-backed save action | `MyApp/ContentView.swift`, PR #27 |
| 6. Calendar badges | Added numeric daily meal-count badges and omitted badges for empty dates | `MyApp/Sprint4Features.swift`, `MyApp/PerformanceHubView.swift`, PR #27 |
| 7. Calendar data loading | Implemented month-based Firestore retrieval for earlier meal history | `MyApp/ContentView.swift`, PR #27 |
| 8. Calorie-source breakdown | Added calorie contributions from protein (4 kcal/g), carbohydrates (4 kcal/g), and fats (9 kcal/g) | `MyApp/ContentView.swift`, PR #27 |
| 9. Firestore read helpers | Added reusable one-time profile fetch and scoped listener utilities; full replacement of existing listeners is pending | `Sprint4/Sprint4NutritionHelpers.swift`, PR #27 |
| 10. Scanner state fix | Corrected barcode modal state placement from SignUpView to AddMealView | [Fix commit](https://github.com/szcze006/TrainFuel/commit/e77f2b1561caa3e0de968d6f2b4ed45e7112e626) |
| 11. Simulator testability | Added manual barcode lookup entry when camera scanning is unavailable | [Manual barcode commit](https://github.com/szcze006/TrainFuel/commit/0b8893c898b76258658c92f638c25b28d2479df2) |
| 12. Photo setup workflow | Added a local key setup helper and instructions for existing OpenRouter-based photo estimation; key remains excluded from Git | `setup-photo-scanning.sh`, `PHOTO_SCANNING_SETUP.md` |

The photo-estimation implementation itself existed before this barcode work; Sprint 4 contributions here were configuration assistance and testing support, not authorship of the original photo-analysis code.

## 3. Commit Activity

| Source | Count / description |
| --- | --- |
| Merged Sprint 4 PR #27 | **8 commits** |
| Follow-up commits on `dev` | Scanner state fix, manual barcode entry, simulator camera handling, local OpenRouter setup script, setup documentation |
| First commit | __________ |
| Last commit | __________ |
| Reviewers | Not recorded for #27 |
| Merge date | __________ |

Do not add the follow-up commits to the PR's 8-commit count; they occurred separately. Follow-up activity should be checked against the final Git history before reporting a combined total.

## 4. Individual Contribution — Casper Szczepaniak

My Sprint 4 work focused on reducing manual nutrition entry and responding to feedback on the calendar, macro reporting, and Firebase reads. I added a barcode-based food lookup flow, hooked it into the existing meal form, introduced meal-count badges, and implemented a breakdown of calories contributed by protein, carbohydrates, and fat. I also worked through integration issues after merging and added a way to test barcode lookup without a physical camera.

## 5. Git Workflow and Evidence

- Worked on `feature/sprint-4-casper`, branched from `dev`.
- Committed incremental SwiftUI, API, and Firestore changes.
- Opened PR #27 and merged it into `dev`.
- Applied follow-up fixes to `dev` after Xcode feedback.
- Kept live API credentials out of version control with `.gitignore` and a local setup script.
- Evidence: [merged PR #27](https://github.com/szcze006/TrainFuel/pull/27), [repository](https://github.com/szcze006/TrainFuel), [Jira TFUEL-60–63](https://rangers-team-ik0pzjj8.atlassian.net/browse/TFUEL-60).

## 6. Final Verification Checklist

- [x] Code committed and PR merged
- [x] Barcode UI wired to existing Add Meal view
- [x] Open Food Facts API request implemented
- [x] Calendar meal badges and calorie breakdown implemented
- [x] Local photo API-key setup documented
- [x] Report committed to GitHub
- [ ] Barcode successfully scanned on a physical iPhone
- [ ] Manual barcode lookup confirmed against a known product
- [ ] Calendar meal counts verified against stored Firestore entries
- [ ] All Firebase listener lifecycles audited in the app
- [ ] Full regression/device verification completed

**Summary:** Sprint 4 delivered substantial source-code functionality and addressed the instructor's main design requests. Device and end-to-end validation remain separate from code completion.
