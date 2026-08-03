# Step 2 — Positions & Dashboard UX spec

**Decided 31 Jul 2026.** Design spec only — no code written yet. Sits beside `CLAUDE.md`,
above both repos, because it spans them.

Supersedes the one-line roadmap entry "Step 2 — UI rework: positions grouped by broker
and by instrument". That description is still true but too small: the real change is that
Dashboard and Positions stop being the same page.

---

## The problem being solved

Two problems, one of which is a correctness issue rather than a cosmetic one.

**1. Summed margin is misleading.** `useMargins().totals` adds Kite's available margin to
Alice Blue's and shows one figure. Margin does not pool across brokers. ₹48,900 free at
Alice Blue will not prevent a square-off at Kite. For a leveraged call seller this is the
single number that must never be misread, and it is currently presented in the one form
that cannot be acted on.

**2. Dashboard duplicates Positions.** Both render the same `PositionsTable` over the same
rows. Dashboard adds five stat cards; that is its entire contribution.

## The split

| Page | Question it answers | Scope |
|---|---|---|
| Dashboard | Can I get hurt today? | Per connection, always |
| Positions | What do I hold, and how is it doing? | One connection at a time, switchable |

Cross-broker aggregation appears in exactly one place — the Dashboard exposure table —
and is labelled as awareness only. This is consistent with the payoff decision already
recorded in `CLAUDE.md`: legs are never merged across brokers, because a spread only earns
margin benefit inside one account.

---

## Positions page

### Layout

```
PageHeader ......................... title + RefreshBar (unchanged)
BrokerWarnings ..................... only for CALL_FAILED (see below)
Account cards ...................... [All] [Kite · ZR4821] [Alice Blue · AB1190]
PositionsTable ..................... scoped to the selected card
```

### Account cards

The cards are both the summary and the filter. One card per connection, plus an "All" card
when more than one connection exists.

Each card shows:

| Element | Source | Notes |
|---|---|---|
| Status dot + broker name | session status | green connected, red expired |
| Account label | new — see backend | `ZR4821`. Falls back to `connectionId` |
| Day P&L | sum of `dayChange` for that connection | large, coloured |
| Lifetime P&L | sum of `pnl` for that connection | small, coloured, suffixed "total" |
| Utilisation bar | margins | threshold-coloured, see below |
| `NN% used · ₹X free` | margins | absolute free margin always visible |

Rules:

- **One connection only → no card row.** A single card plus an identical "All" card is
  noise. Render a plain stat strip instead. Same rule the payoff selector and the broker
  column already use.
- **The "All" card shows summed P&L but never a single margin figure.** P&L sums honestly
  across accounts; margin does not. The All card's bar region shows `2 accounts · ₹1,91,280
  free across both` in muted text, not a blended percentage.
- **An expired connection is still a card**, greyed, not clickable to scope, with a
  Reconnect action on the card itself.

### Scope behaviour

- Scope is React state in `PositionsPage`, not a route param and not persisted. It resets
  on reload, which is correct — a stale scope after an overnight token refresh would be
  worse than a fresh one.
- **Default scope is the riskiest connection**, computed **once**, on the first render where
  margins have resolved. It is never recomputed. Positions and margins refetch every 30s;
  a default that re-evaluated would silently re-scope the page mid-session, which is
  unacceptable on a page you act from.
- Riskiest is defined as **highest utilisation**, tie-broken by **lowest absolute free
  margin**. Utilisation is the comparable measure across accounts of different sizes;
  absolute free margin is what actually runs out.
- When the default fires, the selected card carries a small muted chip: `least headroom`.
  A default the user did not choose must explain itself, otherwise it reads as a bug.
- Before margins resolve, render skeleton cards and scope to All. Do not flicker.

### Table changes

`PositionsTable` and `grouping.ts` are already written for this and need one adjustment:

- **Broker-level group headers appear only when scope is All.** When scoped to one
  connection, the broker header is a heading over the entire table — the same argument
  that hides the Broker column today. `groupPositions` already returns `BrokerGroup[]`;
  the page passes a `showBrokerLevel` decision down rather than the table deriving it from
  `brokers.length > 1`.
- Underlying groups, collapse state, subtotals and the stacked P&L column stay exactly as
  currently written in the working tree. That part of Step 2 is good and does not change.

### Warnings

`BrokerWarnings` currently renders both codes identically. Split them:

- `SESSION_EXPIRED` → **not** a banner. It becomes the card's own state. A banner plus a
  red card is the same information twice.
- `CALL_FAILED` → stays a banner. It is transient, has no card state, and must not tell
  the user to reconnect.

---

## Dashboard — risk console

Order is deliberate: it descends from "act now" to "be aware".

### 1. Margin headroom

One horizontal bar per connection. Label left, `NN% used · ₹X free` right. No summing, no
"All" row — this section exists specifically because summing is wrong.

### 2. Risk banner

Rendered only when a connection breaches a threshold. Names the account, states the number,
and says what it means. Not a generic "margin is low".

> Alice Blue below ₹50,000 free margin. 86% utilised.

Wording rule: state the fact, not a prediction. The mockup's "a 2% adverse move takes it
negative" is out of scope — that needs live premiums and Greeks, which `getLtp` returning 0
makes impossible today. Do not ship a sentence the data cannot support.

### 3. Expiring

Rows grouped by expiry date, nearest first: date, days remaining, underlyings, leg count,
combined P&L. For a seller this is the highest-signal block on the page — it is the
difference between a position that needs attention this week and one that does not.

**Requires a new backend field.** See below.

### 4. Exposure by underlying

Across accounts, with the broker named on each row, labelled `across accounts, awareness
only`. Columns: underlying, broker, legs, lifetime P&L, day P&L.

### 5. Holdings + book total

Holdings value and total P&L, one line. Low priority, low frequency — it belongs at the
bottom.

### Removed from Dashboard

- The five `StatCard`s. Replaced by the per-connection bars and the book total line.
- `PositionsTable`. This is the duplication being removed. The path to positions is the nav
  item, not an embedded copy of the table.

---

## Thresholds

| Utilisation | Colour | Meaning |
|---|---|---|
| ≤ 70% | `--fill-accent` | normal |
| 70–85% | `--fill-warning` | tight |
| > 85% | `--fill-danger` | banner fires |

Banner also fires on **free margin < ₹50,000** regardless of percentage, because a small
account at 60% utilisation can still be one gap away from trouble.

Both numbers are guesses calibrated to the current book. Put them in one exported constant
so they can be tuned in one place, and revisit after a month of live use.

**Utilisation formula needs verifying before it is trusted.** `Margins` carries
`available`, `used`, `total`, `cash`, `collateral`. Whether `total == used + available`
holds for both Kite and Alice Blue is unverified. Check against live payloads from both
brokers before shipping a threshold that turns a bar red. If they disagree, prefer
`used / (used + available)` and document why.

---

## Backend work required

Three items. The first two block the Dashboard; none block the Positions page.

### 1. Account labels — needed by both pages

`/api/session/status` returns `{brokers:[{id, connected}]}`, keyed by **brokerId**. Every
other contract in the system is keyed by **connectionId**. That endpoint therefore cannot
represent two accounts at the same broker, which is the exact case `ConnectionService` was
designed to support.

Proposed shape:

```json
{ "connections": [
  { "connectionId": "kite-default", "brokerId": "kite",
    "accountLabel": "ZR4821", "connected": true }
]}
```

`accountLabel` comes from the broker's own profile call at connect time and is stored on
`BrokerSession`. Falls back to `connectionId` when absent — never blank.

This is a breaking change to `SessionStatus`, so the TS type and every consumer
(`useBrokerStatus`, `BrokerStatusChips`, `ConnectBrokerCard`) move together.

### 2. Expiry on positions — needed by the Dashboard expiry ladder

`PositionDto` gains `expiry` (nullable `LocalDate`), resolved in `BrokerService`
alongside `underlying`, from the same `OptionInstrument` lookup. Same best-effort
contract: unresolvable means null, and a null must never remove the row.

This is a one-field extension of enrichment code already written in the working tree.

### 3. Nothing else

Everything else on both pages comes from `/api/positions` and `/api/margins` as they exist
today. No market data, no spot, no Greeks, no IV. This spec is deliberately buildable while
`getLtp` still returns 0.

---

## Frontend work

| File | Change |
|---|---|
| `features/positions/AccountCards.tsx` | new — cards, states, click-to-scope |
| `features/positions/scope.ts` | new — scope state, riskiest-account default, once-only |
| `features/risk/thresholds.ts` | new — utilisation, threshold constants, banner predicate |
| `features/positions/grouping.ts` | scope-aware filtering; keep grouping logic as-is |
| `features/positions/PositionsTable.tsx` | accept `showBrokerLevel` as a prop |
| `pages/PositionsPage.tsx` | cards + scope wiring |
| `pages/DashboardPage.tsx` | rewrite |
| `features/session/BrokerWarnings.tsx` | filter to `CALL_FAILED` only |
| `types/api.ts` | `SessionStatus` reshape, `Position.expiry` |
| `lib/format.ts` | percentage helper |

`npm run typecheck` after every change — `npm run dev` will not catch the `SessionStatus`
reshape.

---

## Build order

The step is bigger than one 90-minute slot. Split it, and keep each half independently
mergeable — this is exactly the pairing that went wrong once before.

- **2a — Positions.** Cards, scope, riskiest default, thresholds, warning split, table
  prop. Frontend-only apart from account labels. Ships value on its own.
- **2b — Dashboard.** Expiry enrichment on the backend, then the risk console. Depends on
  2a's threshold module.

Branch names identical in both repos, as always. Merge both PRs of a pair together.

---

## Open questions

1. **Is `total == used + available` on both brokers?** Blocks the threshold. Cheap to check
   against a live token.
2. **Does Alice Blue's profile call return an account label?** Kite's does. If Alice Blue
   does not, the label falls back to `connectionId`, which is ugly but honest.
3. **Should the expiry ladder count calendar days or trading days?** Calendar is simpler;
   trading days is what actually matters near a holiday. Start with calendar, note the gap.

## Explicitly not in this step

Greeks, IV, spot price, option chain, T+0 curve, premium decay, alerts. All blocked on
market data. Nothing in this spec depends on any of them.
