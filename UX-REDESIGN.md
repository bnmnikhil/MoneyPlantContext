# UX mockup redesign checkpoint

## Target and working method

Match `UX mockup/dashboard.png`, `positions.png`, `payoff.png`, and
`strategybuilder.png` as closely as possible in layout, colour, spacing, and
controls. Use real application data and preserve existing calculation semantics.
The owner requested one small change at a time so interrupted work can resume.
Run automated verification for each numbered checkpoint before starting the next.
Browser verification stays explicitly pending when browser access is unavailable;
the owner's instruction to continue permits the next isolated implementation step.

Branch in workspace, frontend, and tradestack: `feat/ux-mockup-redesign`.
Starting branches: workspace `design/ux-view-proposals`; frontend and tradestack
`fix/strategy-builder-quote-source`. Pre-existing untracked mockups, `.claude/`,
backend configuration, crash dumps, and architecture reports must be preserved.
The owner authorised committing, pushing and raising PRs for the completed work.
Frontend checkpoints 1–5 were merged through PR #17 on 13 September 2026.
Checkpoints 6a–6d are the follow-up implementation; checkpoint 6 remains in progress.
Deployment is not part of this handoff. Dated notes below preserve the state at
each checkpoint; this summary and the latest Git handoff supersede them.

Current review links:
- Frontend checkpoints 6a–6d: [PR #18](https://github.com/bnmnikhil/MoneyPlantFrontend/pull/18).
- Mockups, design decisions and current status: [context PR #5](https://github.com/bnmnikhil/MoneyPlantContext/pull/5).
- Frontend baseline: [PR #17](https://github.com/bnmnikhil/MoneyPlantFrontend/pull/17), merged.

## Checkpoints

1. **IMPLEMENTED; BROWSER CHECKED — shared shell.** Replace the desktop sidebar with the mockup's
   top navigation, broker dropdown, session indicator, avatar and overflow menu.
   Apply navy/teal colours within the authenticated app, widen the page frame,
   and retain five primary mobile tabs. Keep Settings and connection actions reachable.
2. **IMPLEMENTED; BROWSER CHECKED — Overview.** Horizontal summary strip, paired broker tables, paired
   positions/holdings previews from `dashboard.png`.
3. **IMPLEMENTED; POPULATED DESKTOP CHECKED — Positions.** Summary strip, table header controls, separate P&L/day
   columns, mockup hierarchy and row styling from `positions.png`.
4. **IMPLEMENTED; BROWSER CHECKED — Live payoff.** Selector toolbar, metrics strip, chart/legs columns
   from `payoff.png`; preserve holdings, ranges, and mixed-expiry handling.
5. **IMPLEMENTED; BROWSER CHECKED — Strategy builder.** Context toolbar and chain/legs/preview workspace
   from `strategybuilder.png`; preserve baseline and quote-source separation.
6. **IN PROGRESS — final consistency.** 6a–6d are implemented and verified:
   phone payoff containment, chart reference labels, Overview spacing and Risk
   table containment. Holdings and Settings phone layouts were checked.
   Broker-session status consistency and full keyboard/empty/error-state checks
   remain pending. Exact pixel matching is not certified by these targeted checks.

## Resume instructions

Read this file, `CLAUDE.md`, and `memory/MEMORY.md`; inspect branch/status in
each repository before editing. Review existing diffs instead of overwriting
unfinished work. Continue with broker-session status consistency, then remaining
keyboard/empty/error-state checks. The next session-status fix may need backend
changes; checkpoints 1–6d contain no backend source changes.

## Verification

Checkpoint 1, 11 September 2026:

- `npm test`: 21 passed, 0 failed on the final code.
- `npm run build`: passed (TypeScript and Vite); Vite reports a bundle over 500 kB.
- `git diff --check`: passed in workspace and frontend.
- Visual/interaction verification: pending. Browser inventory returned no
  browsers or apps, and creating an in-app browser returned "Browser is not
  available: iab". Exact pixel matching, keyboard/menu interaction, and actual
  viewport rendering have not been verified. Recheck when a browser is available.
- Backend source unchanged; no backend tests required for this checkpoint.

## Checkpoint 1 changed files

Frontend:
- `src/components/layout/AppShell.tsx`: full-width frame; sidebar unmounted.
- `src/components/layout/Topbar.tsx`: primary navigation and broker/account menus.
- `src/components/layout/nav.ts`: mockup labels and shared five-item navigation.
- `src/components/layout/MobileTabBar.tsx`: five tabs below 1024px.
- `src/components/Logo.tsx`: separate header leaf/wordmark variant.
- `src/features/session/BrokerStatusChips.tsx`: menu-compatible connect actions.
- `src/index.css`: scoped navy/teal palette and active navigation treatment.

Workspace: this file, the Frontend section of `CLAUDE.md`,
`memory/ux-mockup-redesign.md`, and its link in `memory/MEMORY.md`.

At checkpoint 1 these files remained uncommitted. Source baseline HEADs (for inspecting
the original files without discarding work): workspace
`583ca38cbac6db59ce86c8fbaee04fefa600ae62`, frontend
`42ddfa9eb7bfe1aff982d4f1be2f37111abf8fad`, tradestack
`135493e80197d5d77d0c7259b240bc2eae1f1203`.

## Checkpoint 2 — Overview, 11 September 2026

Implemented the `dashboard.png` arrangement: five-part summary strip; P&L and
capital tables side by side; expandable positions and holdings account groups
below. First account opens initially; other groups can be expanded independently.
Preview headings link to their full pages. Tables stack below 1280px and scroll
within their panels. Refresh remains available below the panels.

Frontend files for this checkpoint:
- `src/pages/DashboardPage.tsx`
- `src/features/dashboard/OverviewBrokerTables.tsx`
- `src/features/dashboard/OverviewFigures.tsx`
- `src/features/dashboard/OverviewPreview.tsx`
- `src/features/dashboard/overview.ts`
- Overview-specific rules appended to `src/index.css`
- `tests/overview.test.mjs`

Existing financial endpoints and aggregation are reused. Missing data uses dashes
or partial markers; accounts stay separate; utilisation uses used divided by
available plus used. A combined-capital caption explains the account boundary.
The mockup's illustrative figures are not copied into application data.

Verification:
- `npm test`: **27 passed, 0 failed** (six new checks cover capital denominators,
  over-utilisation, account grouping, pledged holdings, missing margins and P&L horizons).
- `npm run build`: **passed**; existing Vite >500 kB bundle warning remains.
- `git diff --check`: passed.
- Local `/app` on port 5173: **HTTP 200**.
- API proxy `/api/me` on port 5173: **HTTP 200**; backend port 8080 also responds.
- Browser inventory still has no browsers/apps. No screenshot, pixel comparison,
  or interactive expand/collapse check was possible. These remain pending.

Recovery copies are in `%TEMP%/goldenbook-ux-checkpoint-01` (pre-Overview tracked
diffs and documents) and `%TEMP%/goldenbook-ux-checkpoint-02` (explicit copies of
the task's frontend files and workspace documents). They contain no broker data
or credentials. These are local recovery copies, not git commits.

**Checkpoint 2 handoff:** inspect the working diff and visually check checkpoints 1/2 if
a browser is available. Positions was subsequently implemented in checkpoint 3 below. All repositories
remain on `feat/ux-mockup-redesign`; no commit, push or deployment has been made.

## Checkpoint 3 — Positions, 11 September 2026

Implemented the five-metric summary, table toolbar, nine separate columns,
account/underlying expansion, sticky headers and compact row hierarchy from
`positions.png`. The initial view opens the first account/underlying. Mobile
cards retain separate P&L horizons, prices and type-level premiums. Fold state
is shared between desktop/mobile and persists through successful polling.

Changed files for this checkpoint:
- `frontend/src/pages/PositionsPage.tsx`
- `frontend/src/features/positions/PositionsTable.tsx`
- `frontend/src/features/positions/summary.ts`
- `frontend/src/components/PremiumFigure.tsx`: optional compact rendering.
- `frontend/src/components/MarginFigure.tsx`: accurate estimate/bill tooltips.
- Positions rules appended to `frontend/src/index.css`.
- `frontend/tests/positions-summary.test.mjs`
- `frontend/tests/positions-layout.test.mjs`
- This document, `CLAUDE.md`, and `memory/ux-mockup-redesign.md`.

Financial semantics are preserved: premium excludes non-options and unknown
quotes; signed quantities are already units; account bills remain separate from
underlying estimates. No invented CE/PE margin is rendered. Margin age and
partial/unavailable states remain visible. The estimated-margin headline only
includes matching displayed groups, never unrelated groups from an older report.

Verification:
- `npm test`: **34 passed, 0 failed**. New cases cover headline calculations,
  missing estimates/quotes, account boundaries, and server-rendered table column
  alignment. Server rendering is not a browser interaction or pixel test.
- `npm run build`: passed; existing >500 kB bundle warning remains.
- `git diff --check`: passed.
- `/app/positions` on port 5173 and `/api/me` on 8080: HTTP 200.
- Browser inventory remains empty. Exact visual/viewport matching and interactive
  fold/keyboard checks remain pending; no screenshot verification is claimed.

Recovery: `%TEMP%/goldenbook-ux-checkpoint-03-before` stores the files as they were
before this step. `%TEMP%/goldenbook-ux-checkpoint-03` stores the resulting source
and documents. These local copies are not commits.

**Checkpoint 3 handoff:** Live payoff was subsequently implemented in checkpoint 4 below.
All three repositories remain on `feat/ux-mockup-redesign`. Backend source is
unchanged. No commits, pushes, PRs or deployments are authorised or performed.

## Checkpoint 4 — Live payoff, 11 September 2026

Implemented the `payoff.png` structure: view tabs, searchable account/underlying
selector, five-metric strip, chart with holdings/range controls, and a five-column
legs panel. Chart styling is opt-in for Live payoff so the builder retains its
existing chart layout. Small screens stack the panels and scroll the legs table.

Changed files for this checkpoint:
- `frontend/src/pages/PayoffPage.tsx`
- `frontend/src/features/payoff/CurveSelector.tsx` and `curveSelection.ts`
- `frontend/src/features/payoff/PayoffSummary.tsx` and `HoldingsToggle.tsx`
- `frontend/src/features/payoff/PayoffChart.tsx` and `LegsTable.tsx`
- Payoff rules in `frontend/src/index.css`.
- `frontend/tests/payoff-layout.test.mjs`
- This document, `CLAUDE.md`, and `memory/ux-mockup-redesign.md`.

The selector preserves account identity and refreshes labels; an empty refreshed
list clears the previous selection. Metrics use API results, including all
breakevens, unlimited tails, and all expiry dates. Mixed-expiry scenario wording,
incomplete-data warnings, holdings purchase costs, exact unit quantities and
view-only range semantics remain explicit. Adjust strategy imports the displayed
response including selected holdings; switching tabs preserves the builder draft.
T+0 remains disabled. No endpoint or payoff calculation changes were made.

Verification:
- `npm test`: **42 passed, 0 failed**. Eight new checks cover account selection,
  summary semantics, legs and holdings control states through unit/server rendering.
- `npm run build`: **passed**; existing >500 kB bundle warning remains.
- `git diff --check`: passed in workspace and frontend.
- `/app/payoff` and proxy `/api/me` on port 5173: HTTP 200.
- Backend `/api/me` on port 8080: HTTP 200; backend source unchanged.
- Browser inventory has no browsers/apps. Pixel matching, responsive rendering,
  dropdown keyboard interaction and holdings interactions remain unverified.

Recovery: `%TEMP%/goldenbook-ux-checkpoint-04-before` contains the pre-step files;
`%TEMP%/goldenbook-ux-checkpoint-04` contains cumulative task source and documents.
These local recovery copies contain no broker data and are not commits.

**Checkpoint 4 handoff:** Strategy builder was subsequently implemented in
checkpoint 5 below. All three repositories remain on `feat/ux-mockup-redesign`.
No commits, pushes, PRs or deployments have been made.

## Checkpoint 5 — Strategy builder, 12 September 2026

Implemented the `strategybuilder.png` arrangement: compact context controls above
three panels for option chain, strategy legs and payoff preview. The context bar
keeps the underlying, baseline account, independent quote source, expiry and spot
visible. Add existing / Change opens the baseline loader. Session drafts remain
reachable after New strategy, including when only one previous draft exists.

The chain uses seven columns with separate Buy/Sell cells, ATM and position/draft
quantity markers, refresh and expansion. The middle panel holds quick recipes,
locked baseline rows, draft switches and quantity steppers, editable prices,
per-leg cashflows and a custom-leg chooser based on actual listed chain rows.
Expand an instrument to change its contract or accept its available mark.
The preview has compact range controls, comparison curves, global metrics,
a target-price slider/manual input and the existing heuristic margin values.

Below 1536px the preview moves beneath chain/legs; below 901px all panels stack.
Tables scroll within their panels. These are implemented CSS breakpoints, not
claims of verified rendering at those viewports.

Changed frontend files:
- `src/features/strategy-builder/StrategyBuilderView.tsx`
- `src/features/strategy-builder/OptionChainPicker.tsx`
- `src/features/strategy-builder/StrategyLegEditor.tsx`
- `src/features/strategy-builder/UnderlyingSearch.tsx`
- New `BuilderMetrics.tsx`, `CustomLegForm.tsx`, and `legFigures.ts` in that folder.
- `src/features/payoff/PayoffChart.tsx`: optional compact builder presentation.
- Builder-specific rules in `src/index.css`.
- `tests/builder-layout.test.mjs`.
- Workspace: this document, `CLAUDE.md`, and `memory/ux-mockup-redesign.md`.

Financial behavior: quantities remain exact units, with lots shown only for
complete lots. Baseline P&L is explicitly unrealised at its imported mark because
this response does not contain realised P&L. Unpriced enabled drafts make net
cashflow incomplete; disabled rows are excluded. Shares/futures retain linear
controls. No automatic quote refresh overwrites an assumed entry price. The
preview is associated with its exact inputs and disappears while changed inputs
are recalculated, preventing a prior account/draft result appearing beside new
legs. Cancelled responses cannot restore it. Mixed-expiry scenario labels and
unsupported-holdings margin remain explicit. The mockup's illustrative capital
number is not invented; the available margin estimates are shown with premium
separate. No backend source or API contract changes were needed.

Verification:
- `npm test`: **52 passed, 0 failed**, including 10 new unit/server-render checks
  for financial figures, linear legs, missing quotes, columns and control states.
- `npm run build`: **passed** (TypeScript + Vite); existing >500 kB bundle warning.
- `git diff --check`: passed in workspace and frontend.
- `/app/payoff` and proxy `/api/me` on 5173, and backend `/api/me` on 8080: HTTP 200.
- Browser inventory remains empty. Exact pixels, dropdown/stepper/slider interaction,
  asynchronous races and responsive rendering have not been browser-verified.

Recovery: `%TEMP%/goldenbook-ux-checkpoint-05-before` holds the pre-step files;
`%TEMP%/goldenbook-ux-checkpoint-05` holds cumulative task source and documentation.
These are local recovery copies, not commits, and contain no broker data.

**Resume next:** review current diffs, then checkpoint 6 (consistency and state
checks across pages). Perform screenshot and interaction verification when browser
access becomes available; checkpoints 1–5 are implemented but not pixel-certified.
Workspace, frontend and tradestack remain on `feat/ux-mockup-redesign`. Nothing
was committed, pushed, opened as a PR, or deployed.

## Git handoff — 13 September 2026

The owner requested pushing the work completed so far. Frontend checkpoints 1–5
are committed as `565931a0db5793cbd8c5fb3850e7badc8311804f` and pushed to
`origin/feat/ux-mockup-redesign` in `GoldenBookFrontend`. The matching branch in
`GoldenBook` is pushed at the unchanged backend baseline
`135493e80197d5d77d0c7259b240bc2eae1f1203`; no backend commit was created.
Both remote branch hashes were checked with `git ls-remote`.

This documentation handoff includes all four source PNG mockups, the checkpoint
record and the durable design notes in `GoldenBookContext` on the same branch.
The local checkpoint recovery copies remain available in addition to Git.
Unrelated backend configuration, architecture reports and JVM crash logs are
excluded and remain local.

Pre-push verification on the frontend: `npm test` **52 passed, 0 failed**;
`npm run build` **passed**, with the existing >500 kB Vite bundle warning;
staged `git diff --check` passed. No application code changed during this handoff.
Checkpoint 6 and visual/interaction verification are still pending. No PR,
merge or deployment was performed.

## Checkpoint 6a — payoff responsive containment, 14 September 2026

Browser access is now available in Chrome, and the owner reconnected all three
broker sessions. Populated Overview, Positions, Live payoff and Strategy builder
have been inspected. This starts the visual pass; the earlier pending labels
remain historical, and exact mockup matching is not yet certified.

At a 390px CSS viewport, Live payoff expanded the document to 432px, clipping
the tabs, selector and summary. `frontend/src/index.css` now gives the outer
payoff grids an explicit `minmax(0, 1fr)` track and makes the phone curve controls
occupy their own flex row. This also contains the mounted builder. Table scrolling
stays inside the relevant panels; desktop chart/legs columns remain side by side.

Verification on the final CSS:
- Phone widths 320px and 390px, tablet width 768px, and desktop width 1673px:
  document scroll width equals its client width on Live payoff.
- Populated builder at 320px and 390px: no document horizontal overflow.
- Same-account Holdings added a shares leg at purchase cost; switching it off
  returned to four option legs. A 5% chart view preserved the summary limits.
- Imported a Kite baseline while using Alice Blue quotes. Added a hypothetical
  chain leg, doubled its quantity, verified doubled draft cashflow, then removed
  the test leg. No orders were placed.
- Broker dropdown opens, exposes connection management, and closes with Escape.
- Positions displays its existing stale-risk warning. Browser logs at that check
  contained no errors, only the existing React Router future-version warnings.
- `npm test`: **52 passed, 0 failed**. `npm run build`: **passed**; the existing
  >500 kB bundle warning remains. No calculation or API change was made.

Recovery: `%TEMP%/goldenbook-ux-checkpoint-06a-before` contains pre-edit CSS and
design documentation. The matching `goldenbook-ux-checkpoint-06a` directory holds
the completed checkpoint. Both contain source/docs only, without account data.

**Resume next:** finish visual consistency checks, including chart reference-label
collisions at narrow widths, Overview vertical spacing against the mockup, and
the earlier contradiction between expired-session banners and a Live header.
Holdings, Risk, Settings and the remaining keyboard/error states still need a
complete viewport pass. Checkpoint 6 remains in progress.

All three repositories remain on `feat/ux-mockup-redesign`; this checkpoint changes
only frontend CSS and workspace documentation. No new commit, push, PR or deployment
was made. Existing frontend PR #17 and context PR #5 were opened at the owner's
earlier request; they contain checkpoints 1–5, not this uncommitted checkpoint.

## Checkpoint 6b — chart reference labels, 14 September 2026

`PayoffChart.tsx` now measures the rendered plot width and uses
`referenceLabels.ts` to place spot/breakeven text in non-overlapping rows.
Labels remain centred on their reference line when space permits, are shifted
inside the plot at its edges, and reflow when resized or zoomed. Reference-line
prices and all payoff calculations are unchanged. This applies to Live payoff
and the builder's compact chart.

Verified the previously overlapping HEROMOTOCO labels at 390px (actual DOM text
rectangles do not intersect), zoom/reset, and the populated desktop AUBANK builder.
`tests/reference-labels.test.mjs` covers nearby/coincident labels, separated labels,
plot edges, off-screen filtering and preservation of input data.
`npm test`: **56 passed, 0 failed**. `npm run build`: **passed**, with the existing
bundle-size warning. Recovery copies are `%TEMP%/goldenbook-ux-checkpoint-06b-before`
and `%TEMP%/goldenbook-ux-checkpoint-06b`. No new commit, push or deployment.

Next: Overview vertical spacing, then remaining responsive/error-state checks.

## Checkpoint 6c — Overview spacing, 14 September 2026

Tightened the summary's line heights/padding, panel heading line heights and
inline broker-logo alignment in `src/index.css`; `DashboardPage.tsx` now uses
the explicit summary value class. Account preview buttons no longer enlarge
their desktop rows. Mobile summary type/padding fit the narrow columns, and
broker-table scrollbars use the existing dark palette.

At 1673px the summary measured 104.7px (previously 123.5px; mockup target 104px),
broker rows measured 49px (previously 55.1px), and preview panels measured 384px.
The broker panels start at 213.6px, close to the mockup's 214px. Populated
Overview has no document overflow at 320px, 390px or 768px; the 320px monetary
figures fit inside their columns. Financial values and account groups are unchanged.

`npm test`: **56 passed, 0 failed**. `npm run build`: **passed**, retaining the
existing bundle warning. Pre/post copies: `%TEMP%/goldenbook-ux-checkpoint-06c-before`
and `%TEMP%/goldenbook-ux-checkpoint-06c`. No commit, push or deployment.

Additional read-only phone checks: Holdings cards and Settings fit at 390px.
Risk's grid widened its document to 1030px; fix that next. Risk continues to
show its existing STALE snapshot warnings; no snapshot behavior is being changed.

## Checkpoint 6d — Risk table containment, 14 September 2026

`RiskPage.tsx` gives the small-screen grid an explicit zero-minimum column and
allows its cards to shrink. Its existing table scroll containers now take the
overflow instead of expanding the entire page. At 390px the document shrank from
1030px to its 373px client width, while the instrument table still has its full
965px width inside a 292px scroll area. The document also fits at 320px, 768px
and 1673px. Stale-risk warnings, data and calculations remain unchanged.

`npm test`: **56 passed, 0 failed**. `npm run build`: **passed**, with the existing
bundle warning. Pre/post recovery copies are `%TEMP%/goldenbook-ux-checkpoint-06d-before`
and `%TEMP%/goldenbook-ux-checkpoint-06d`. Backend source remains unchanged.

**Resume next:** broker-session status consistency. Read-only investigation found
`tradestack/.../broker/session/SessionController.java` returns `connected: true`
for every stored session, while `BrokerService.fanOut` reports SESSION_EXPIRED
without changing that status. Merely polling status again cannot fix the header.
Address session validity with per-account regression coverage; do not invalidate
an unrelated account or discard a newly reconnected session because an older
in-flight request failed. No implementation of that behavior is included here.

Further complete keyboard and empty/error-state checks remain pending; checkpoint
6 is still in progress. All three repositories use `feat/ux-mockup-redesign`.
Checkpoints 6a–6d are local and uncommitted; no new push, PR or deployment.

## Git handoff — 14 September 2026

The owner requested updating all task statuses, pushing completed changes and
raising PRs. Checkpoints 6a–6d are committed in the frontend as
`7c783b91ded47e7a777e93280e9706eaaa68eedb` and pushed to
`origin/feat/ux-mockup-redesign`; the remote hash was verified. PR #18 is the new
frontend review because the original redesign PR #17 was already merged on
13 September. The branch was fast-forwarded to that merged baseline before the
follow-up commit; no application files changed during the fast-forward.

Context PR #5 carries this updated tracker, `CLAUDE.md`, `P0-LAUNCH.md` and the
durable design notes. It retains the original mockups and quote-source decision.
The frontend PR links back to this documentation.

Final checks: `npm test` **56 passed, 0 failed**; `npm run typecheck` **passed**;
`npm run build` **passed** (existing >500 kB bundle warning); staged diff check
**passed**. Browser verification is described per checkpoint above.

All repositories remain on `feat/ux-mockup-redesign`. The backend has no new
source changes or commits for these checkpoints and no diff requiring a new PR.
Local backend configuration, architecture report and crash dumps remain excluded.
No merge or deployment was performed in this handoff. Next work remains session
status consistency and the rest of checkpoint 6's keyboard/empty/error-state checks.
