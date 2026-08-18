# Decision: Strategy Builder Architecture & Interactive Designer

**Date:** 15 Aug 2026  
**Status:** Shipped in `feat/heuristic-margin-engine`  
**Affects:** `PayoffPage`, `StrategyBuilderView`, `PayoffService`, `PayoffController`, `frontend/src/types/api.ts`

---

## Context

Traders need to design, simulate, and analyze multi-leg options strategies (e.g. Bull Call Spreads, Iron Condors, Straddles) before placing orders, including evaluating expiry payoff curves, breakevens, risk-reward ratios, and capital requirements.

---

## Decision

### 1. Navigation & Page Architecture
- Hosted directly under `/app/payoff` with a clean tab switcher:
  - **`[ Live Positions ]`**: Existing view plotting open F&O positions from connected broker accounts.
  - **`[ Strategy Builder ]`**: Interactive visual designer for custom and template-based multi-leg strategies.
- **What-If Bridge:** Added an **"Open in Strategy Builder"** button on any live position payoff curve to preload open legs directly into the builder for hedging experimentation (e.g., evaluating the impact of adding a protective OTM wing to an existing naked position).

### 2. Pre-Built Strategy Recipes

> ⚠ **Amended 18 Aug 2026 — the recipes are duplicated, and the Java copy is
> dead.** `StrategyTemplate.buildLegs` has **no production caller**: `grep`
> across `src/main/` finds it only from `StrategySimulationTest`. All twelve
> recipes are reimplemented inline in `StrategyBuilderView.tsx`, and that is the
> copy that actually runs. So the two can drift silently and only the *unused*
> one has tests. `getStrategyMetadata` sends the frontend template *names* but
> never their legs, which is how the split happened. Collapse to one
> implementation — keep the Java one, it is tested — before adding a
> thirteenth strategy.

- Automated 1-click generators for 10+ standard strategies, defined in
  [`StrategyTemplate.java`](file:///c:/Projects/Moneyplant/tradestack/src/main/java/com/MoneyPlant/tradestack/analytics/StrategyTemplate.java)
  *and*, separately and actually-executing, in `StrategyBuilderView.tsx`:
  - *Bullish:* Bull Call Spread (Debit), Bull Put Spread (Credit), Long Call.
  - *Bearish:* Bear Put Spread (Debit), Bear Call Spread (Credit), Long Put.
  - *Neutral / Rangebound:* Short Straddle, Short Strangle, Iron Condor, Iron Butterfly.
  - *Volatile:* Long Straddle, Long Strangle.
- Generates strikes dynamically aligned to the underlying's canonical strike step interval (e.g. NIFTY: 50, BANKNIFTY: 100, SENSEX: 100).

### 3. Unified Simulation Endpoint (`POST /api/payoff/simulate`)
- Combines `PayoffEngine` (expiry P&L curve, breakevens, max profit/loss) and `HeuristicMarginEngine` (SEBI SPAN + Exposure bottom-up margin, hedge benefit, and total funds required) in a single synchronous roundtrip.
- Completely offline — requires zero broker token calls and is fully reproducible.

### 4. Interactive UX & Target Inspector
- **Leg Steppers:** $+/-$ buttons for strikes and lots, Buy/Sell pills, CE/PE toggles, and individual leg enable/disable checkboxes.
- **Real-Time Visual Payoff Chart:** Gradient-filled P&L area chart, zero baseline, breakevens, and live spot marker.
- **Target Spot Inspector:** Interactive slider across $\pm 10\%$ of spot showing expected P&L at expiry at any chosen underlying price.

---

## Corrections, 18 Aug 2026

Found by reading the shipped code against this record. Two were fixed; the rest
are open and listed so they are not rediscovered from scratch.

**Fixed — the builder was pricing against a hardcoded spot.** The client sent
`spot: currentConfig.defaultSpot` on every `/simulate` call — the literal
`24500.0` for NIFTY, straight out of `getStrategyMetadata` — and
`simulateStrategy` prefers an explicit spot whenever it is `> 0`. So
`SpotPriceService` was **never consulted**, and every margin, ATM strike,
breakeven and R:R in the builder was precise arithmetic around an invented
number, while the one live feed the project has verified sat unused. The client
now omits the field and the server resolves: live spot, else its own default.
Pinned by three tests in `StrategySimulationTest` — an omitted spot resolves
live, an explicit spot still wins (that is the what-if path, deliberately kept),
and nothing-can-quote falls back rather than returning 0.

A second half of the same bug: the first template must be generated *before* any
simulation has run, so it is necessarily centred on the default spot. A
re-centring effect now rebuilds an **untouched** template once the live spot
arrives, and leaves `CUSTOM` alone — moving a user's own strikes under them is
worse than a stale ATM.

**Fixed — changing expiry or underlying deleted a custom strategy.** Both
handlers called `loadTemplateLegs(activeTemplate, …)`, every manual edit sets
`activeTemplate = "CUSTOM"`, and the recipe switch has no `CUSTOM` case — so it
fell through to an empty array and wrote it. Build a four-leg condor, change
expiry, lose everything, no confirmation. `loadTemplateLegs` now refuses to
write an empty result at all (a template that generates nothing means "I have
nothing to say about these legs", never "clear them"), and custom strategies are
*retargeted* instead: expiry-only changes keep strikes and sizes, while an
underlying change re-expresses each leg by its offset from ATM **in strike
steps** and its size **in lots**, which is what the structure actually was. A
2-step-wide condor stays a 2-step-wide condor.

**Open — leg premiums are invented, and that is the real ceiling.** Nothing in
the stack can quote a single strike, so templates seed a placeholder price.
This is downstream of the same blocker as everything else:
[[analysis-step-is-the-product]] and
[[free-market-data-options-researched]]. Until a chain feed lands, every figure
the builder produces is conditional on a made-up premium — which matters far
more than it looks, because the margin engine is calibrated to 4% and is being
fed guesses. Verifying Alice Blue's chain is the unblock.

**Open — metadata is hardcoded where a contract master already exists.** Lot
sizes, strike steps and default spots are literals in `getStrategyMetadata`,
and `InstrumentService` already loads the real ones. The expiry list is worse:
the next four **Thursdays**, the same list for every underlying, on the system
default zone rather than IST, with no holiday handling — and stock options are
monthly-only, so four weekly expiries for RELIANCE describe contracts that do
not exist.
