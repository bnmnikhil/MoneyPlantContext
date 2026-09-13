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
The owner authorised committing and pushing checkpoints 1–5 on 13 September
2026. This authorisation covers the task branches and supporting mockups/docs;
merging, PR creation and deployment remain unrequested. Earlier handoff notes
below describe their historical uncommitted state.

## Checkpoints

1. **IMPLEMENTED; VISUAL CHECK PENDING — shared shell.** Replace the desktop sidebar with the mockup's
   top navigation, broker dropdown, session indicator, avatar and overflow menu.
   Apply navy/teal colours within the authenticated app, widen the page frame,
   and retain five primary mobile tabs. Keep Settings and connection actions reachable.
2. **IMPLEMENTED; VISUAL CHECK PENDING — Overview.** Horizontal summary strip, paired broker tables, paired
   positions/holdings previews from `dashboard.png`.
3. **IMPLEMENTED; VISUAL CHECK PENDING — Positions.** Summary strip, table header controls, separate P&L/day
   columns, mockup hierarchy and row styling from `positions.png`.
4. **IMPLEMENTED; VISUAL CHECK PENDING — Live payoff.** Selector toolbar, metrics strip, chart/legs columns
   from `payoff.png`; preserve holdings, ranges, and mixed-expiry handling.
5. **IMPLEMENTED; VISUAL CHECK PENDING — Strategy builder.** Context toolbar and chain/legs/preview workspace
   from `strategybuilder.png`; preserve baseline and quote-source separation.
6. **TODO — final consistency.** Responsive and state checks across all pages;
   Holdings, Risk and Settings inherit the shared visual system.

## Resume instructions

Read this file, `CLAUDE.md`, and `memory/MEMORY.md`; inspect branch/status in
each repository before editing. Review existing diffs instead of overwriting
unfinished work. Continue the first incomplete checkpoint. No backend source
change is expected for checkpoint 1.

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

Recovery copies are in `%TEMP%/moneyplant-ux-checkpoint-01` (pre-Overview tracked
diffs and documents) and `%TEMP%/moneyplant-ux-checkpoint-02` (explicit copies of
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

Recovery: `%TEMP%/moneyplant-ux-checkpoint-03-before` stores the files as they were
before this step. `%TEMP%/moneyplant-ux-checkpoint-03` stores the resulting source
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

Recovery: `%TEMP%/moneyplant-ux-checkpoint-04-before` contains the pre-step files;
`%TEMP%/moneyplant-ux-checkpoint-04` contains cumulative task source and documents.
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

Recovery: `%TEMP%/moneyplant-ux-checkpoint-05-before` holds the pre-step files;
`%TEMP%/moneyplant-ux-checkpoint-05` holds cumulative task source and documentation.
These are local recovery copies, not commits, and contain no broker data.

**Resume next:** review current diffs, then checkpoint 6 (consistency and state
checks across pages). Perform screenshot and interaction verification when browser
access becomes available; checkpoints 1–5 are implemented but not pixel-certified.
Workspace, frontend and tradestack remain on `feat/ux-mockup-redesign`. Nothing
was committed, pushed, opened as a PR, or deployed.

## Git handoff — 13 September 2026

The owner requested pushing the work completed so far. Frontend checkpoints 1–5
are committed as `565931a0db5793cbd8c5fb3850e7badc8311804f` and pushed to
`origin/feat/ux-mockup-redesign` in `MoneyPlantFrontend`. The matching branch in
`MoneyPlant` is pushed at the unchanged backend baseline
`135493e80197d5d77d0c7259b240bc2eae1f1203`; no backend commit was created.
Both remote branch hashes were checked with `git ls-remote`.

This documentation handoff includes all four source PNG mockups, the checkpoint
record and the durable design notes in `MoneyPlantContext` on the same branch.
The local checkpoint recovery copies remain available in addition to Git.
Unrelated backend configuration, architecture reports and JVM crash logs are
excluded and remain local.

Pre-push verification on the frontend: `npm test` **52 passed, 0 failed**;
`npm run build` **passed**, with the existing >500 kB Vite bundle warning;
staged `git diff --check` passed. No application code changed during this handoff.
Checkpoint 6 and visual/interaction verification are still pending. No PR,
merge or deployment was performed.
