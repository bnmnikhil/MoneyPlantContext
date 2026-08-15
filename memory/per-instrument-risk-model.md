---
name: per-instrument-risk-model
description: "Risk nets per account, names market value / max loss / loss bound separately, and uses a scenario ladder instead of greeks; max loss is standalone and must never be summed"
metadata:
  type: decision
---

Decided 15 Aug 2026, building the per-instrument risk layer. Full record in
`tradestack/docs/adr/0026-per-instrument-risk-model.md`; this is the part worth
remembering without opening it.

**Netting is per account** — one row per `(connectionId, InstrumentKey)`, summing
Kite's NRML and MIS buckets but never crossing connections. Delta *does* net
across accounts and margin does not, and margin is the one that binds. Same
reasoning as [[no-cross-broker-merging]], which settled the payoff-curve half of
the same question.

**The single word "exposure" was the bug.** `qty × ltp` is one number pretending
to be three. A short call and a long put with identical `qty × ltp` differ
enormously — the put's figure is exactly its maximum loss, the call's is
unbounded. Now three named things: `marketValue`, an exact structural `maxLoss`,
and a three-valued `lossBound`. `UNKNOWN` is deliberately distinct from
`UNBOUNDED`: "can lose without limit" is a finding, "no contract master resolved
this" is a gap, and one blank cell for both lets an unresolved Alice Blue row
read as safe.

**The thing most likely to be got wrong later: `maxLoss` is per contract,
standalone, and must never be summed.** Found on the first real book in
`raw_capture` — a bear put spread on HAL where the short 4600 put reads ₹685,717
alone against a true structure worst case of ₹34,462, because the long 4350 put
caps it. Twenty times over, and a spread is most of what an options book holds.
`InstrumentRiskCalculatorTest` pins both figures against each other so the gap
cannot quietly disappear.

**The scenario ladder is the honest substitute for greeks**, and works today
because terminal payoff needs no market data beyond a spot. Grouped by expiry as
well as underlying — terminal payoff means legs with different expiries cannot
share a curve. `PayoffService` still has that flaw (`Set<String> expiries` on one
curve) and is worth fixing when it is next touched.

**σ's volatility is solved from the book's own prices** — Black-Scholes plus
Newton in `pricing/`, using the nearest-the-money leg and refusing anything past
10% moneyness. The smile means an OTM leg's vol is a real number about the wrong
strike, and vega collapses there so the solve is ill-conditioned anyway. Which
strike answered is published as `ivSource` and must stay on screen.

**This solve is a bridge, not a foundation.** See
[[free-market-data-options-researched]] — a chain that publishes IV directly
replaces it behind the same interface without touching a calculator.
