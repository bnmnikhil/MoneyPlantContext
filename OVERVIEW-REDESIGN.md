# Overview redesign — concept A

**Created 7 Oct 2026.** Implements concept A from the mockup the owner chose
(<https://claude.ai/artifact/UxSsjCUWVb8MG2pFuPx6zB>, tab "A · Summary, accounts, attention"):
three bands on `/app` — the summary strip, **one** accounts table, and a **Needs attention** band —
replacing today's two side-by-side broker tables and the positions/holdings previews.

**Status lives here only.** `CLAUDE.md` points at this file and carries no progress.

Legend: `[ ]` not started · `[~]` in progress · `[x]` done and verified · `[-]` dropped

## Scope and constraints

- **Frontend only.** Every input already reaches the browser: positions carry `contract.expiry`,
  `dayChange` and `priceKnown`; `/api/margins` is per connection; `/api/session/status` lists
  brokers with credentials (`brokers`) and live accounts (`connections`). No backend or contract
  change, so the backend gate is untouched.
- **One branch**, `ux/overview-a`, in `frontend/` only. Staging first, then production on the owner's
  word, as with the payoff redesign.
- **The three join rules in `features/dashboard/aggregate.ts` stay exactly as they are** (key on
  `connectionId`; `margin: null` renders a dash, never 0; Day P&L is positions-only and says so).
  The new table is a new rendering of the same `BrokerRow[]`, not a new join.
- **No invented figures.** The mockup's "largest requirement is the short HAL put" line is dropped:
  it needs per-instrument margin, which only the stale risk snapshot has (A1).

## Summary

| Id | Item | Status |
|---|---|---|
| OV-1 | Attention model (pure functions + tests) | `[x]` |
| OV-2 | Capital: tightest account beside the combined figure | `[ ]` |
| OV-3 | One accounts table replaces the two broker tables | `[ ]` |
| OV-4 | Needs attention band, with the all-clear state | `[ ]` |
| OV-5 | Page assembly, freshness at the top, fit-to-screen and phone | `[ ]` |
| OV-6 | Simulator data that exercises every card | `[ ]` |
| OV-7 | Verify on staging, then production | `[ ]` |
| OV-8 | Docs, memory and dead-code removal | `[ ]` |

Decisions, **confirmed by the owner 7 Oct 2026** as the defaults below:

1. **Margin pressure threshold: 75%** used, per account.
2. **Expiring soon window: 7 calendar days** (IST), counting today; shows the nearest later expiry
   as a calm "next" line when nothing is inside the window.
3. **Biggest moves: top 3 legs by |Day P&L|**, ignoring moves under ₹100 so a quiet day shows nothing.
4. **Stale margin estimates** appear under "To fix" only when the risk report is not `LIVE`
   (it never is until A1 lands, so this card will show it every day until then).

---

## `[x]` OV-1 — Attention model

**Done 7 Oct 2026**, frontend `ux/overview-a` `a758690`: `src/features/dashboard/attention.ts`,
`tests/overview-attention.test.mjs` (11 tests; suite 103 passing, `tsc -b` clean). Two decisions made
while building it: `UNSUPPORTED_CAPABILITY` warnings are not "to fix" items (a broker without a
margins call is a fact, not something the user can act on), and **biggest moves do not stop a day
being all clear** (they are information, not a problem), so OV-4 shows the moves card beside the
all-clear line when there are any.

New `src/features/dashboard/attention.ts`, pure, imported by tests with relative imports (Node's
test runner does not resolve `@/`). Inputs: `BrokerRow[]`, `Position[]`, `SessionStatus`, the
aggregate warnings, the risk report's `freshness`/`asOf` (optional), and `now`.

- `marginPressure(rows, threshold)` → accounts at or over the threshold, sorted by utilisation,
  each with `used`, `free`, `pct`. Uses the existing `capitalUtilisation`; a `null` margin is
  skipped, never treated as 0%.
- `expiringSoon(positions, now, days)` → groups of open legs (`qty ≠ 0`) by `(connectionId,
  expiry)` inside the window, each with days left, the legs, and their summed P&L; plus `next`,
  the nearest expiry outside the window. Dates compared as IST calendar days (fixed +05:30, no
  tzdata dependency — the same trap `host-watch.sh` hit). Legs with no `contract` are ignored.
- `biggestMoves(positions, n, minAbs)` → top legs by `|dayChange|`. A leg with
  `priceKnown: false` is excluded: its day change is not a move, it is a missing price.
- `toFix(...)` → items of four kinds: a broker with credentials but no live account
  (`status.brokers` minus connected `brokerId`s); a `SESSION_EXPIRED` warning (reconnect); a
  `CALL_FAILED` warning (could not load — never "reconnect"); legs with no price; and a stale
  risk report.
- `allClear(...)` → true when every list is empty, with the list of checks that passed, for the
  quiet-day line.

**Verify:** `tests/overview-attention.test.mjs` — threshold edges (74.9 / 75.0), null margin
skipped, expiry window edges at IST midnight (a 23:30 UTC `now` is already the next IST day),
unpriced legs excluded from moves, `CALL_FAILED` never labelled as reconnect, all-clear only when
everything is empty.

## `[ ]` OV-2 — Capital: tightest account

The strip's capital cell keeps the combined bar and adds **"Tightest: {account} {pct}% · ₹{free}
free"**, amber when that account is over the threshold, neutral otherwise. Only one account →
no "tightest" line (it would repeat the combined figure). The partial marker (`*`) and its
meaning are unchanged.

**Verify:** a server-rendered component test for the three cases (one account, all calm, one hot).

## `[ ]` OV-3 — One accounts table

New `AccountsTable` replacing `OverviewPnlTable` + `OverviewCapitalTable`
(`features/dashboard/OverviewBrokerTables.tsx`). Columns: Account · Positions · Holdings · Total
P&L · Day | Free · Used · Utilisation, with a divider between the P&L and capital groups and a
total row. Rules carried over: the account label shows when a broker has two accounts
(`needsAccountLabel`); partial totals keep their `*`; a `null` margin is a dash in all three capital
cells.

- An account with no positions and no holdings is **dimmed to one line** ("Nothing open") but keeps
  its capital cells — free capital is still a fact worth seeing.
- Sorted by total P&L magnitude? **No:** sorted by broker then account, as today, so rows do not
  jump between polls.
- Scrolls horizontally inside its panel below ~900px.

**Verify:** component test — two Kite accounts stay two rows; a null margin renders dashes; the idle
account is dimmed; the totals equal the sum of rows.

## `[ ]` OV-4 — Needs attention band

New `AttentionBand` rendering OV-1's output as up to four cards — Margin pressure, Expiring soon,
Biggest moves today, To fix — each **hidden when empty**. When all are empty it collapses to one
line: "Nothing needs attention" plus what was checked.

- Each card has one link: margin → `/app/positions`, expiring and moves → `/app/payoff`, and To fix's
  disconnected broker → a **Connect** button using the existing `useConnectBroker` (the same flow as
  the header's Brokers menu, so nothing new about connecting).
- Long lists are capped (3 legs per expiry group, 2 expiry groups) with "and N more".
- Cards size to content, in a 4-column grid on desktop, 2 on tablet, 1 on phone.

**Verify:** component tests for each card's empty/non-empty state and the all-clear line.

## `[ ]` OV-5 — Page assembly

`src/pages/DashboardPage.tsx`: strip → accounts → attention. Removes the `OverviewPreview` pair and
the bottom "Capital is held separately…" line (it moves into the accounts panel subtitle).
"Updated Ns ago" moves into the capital cell at the top; Refresh stays reachable there.

- **Fit to screen:** the page keeps `page-fit`; with the previews gone nothing needs to stretch, so
  the fill rules for the previews are deleted from `index.css` and the page simply fits.
- **Phone:** strip 2×2, capital on its own line with the tightest account, attention before accounts,
  accounts as one-line rows with a margin bar (mockup tab "A · Phone").
- Empty account list and load/error states keep the current `ConnectBrokerCard`, skeleton and
  `ErrorState` behaviour.

**Verify:** `tsc -b`, `npm test`, `vite build`; and in the browser on staging at 1536×640 (the owner's
window) and at phone width, no page scroll on desktop.

## `[ ]` OV-6 — Simulator data for every card

`broker-sim`'s sample book has every expiry on 27 Oct, so "Expiring soon" can never appear on
staging. Add one Kite leg pair expiring within the next week, computed from the current date so it
never goes stale (broker-sim, own repo and branch). Without this, OV-4's main card is untestable
before production.

**Verify:** staging Overview shows the Expiring soon card with the new legs.

## `[ ]` OV-7 — Staging, then production

Deploy `ux/overview-a` to staging; owner checks it; PR, merge, production deploy with the usual
pre-release copy (`/root/pre-…`), staging stopped during the build, health and log check after.

## `[ ]` OV-8 — Docs, memory, dead code

- Delete `BrokerPnlTable.tsx` and `BrokerFundsTable.tsx` (already unused) and, after OV-5,
  `OverviewBrokerTables.tsx` and `OverviewPreview.tsx` with their CSS.
- `memory/`: one note recording why the previews were replaced by attention, the thresholds chosen,
  and that "tightest account" is shown because capital is held per account.
- `CLAUDE.md` *Frontend → Overview layout* paragraph regenerated to describe the three bands;
  `docs/` page for the dashboard updated per `docs/contributing.md`.
