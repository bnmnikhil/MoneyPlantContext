---
name: no-cross-broker-merging
description: "Identical instruments held at two brokers are never netted into one leg; payoff curves group per (connectionId, underlying)"
metadata:
  type: decision
  decided: 2026-07-29
---

The same strike held at two brokers stays **two legs**. Payoff curves group by
`(connectionId, underlying)`, not by underlying alone.

**Why.** Two independent reasons, and the second is the load-bearing one:

1. **Netting would change nothing on the chart.** `PayoffEngine` sums
   `(value − avgPrice) × qty` linearly, so two legs at one strike produce exactly
   the curve of one netted leg at the weighted-average price. The only thing
   netting would improve is the tidiness of the legs table.
2. **Spreads only earn margin benefit inside a single account.** A strategy
   deliberately split across two brokers is financially irrational, so the merged
   curve would rarely have anything real to merge — and a curve whose legs span
   accounts corresponds to no position any broker will actually margin. It would
   be a picture of a book nobody holds.

**Rejected:** merging per underlying across all connections. It reads as the
obvious simplification and is wrong for reason 2.

**If revisited:** the way back in is a *"Combined"* toggle showing cross-broker
net exposure, added only when a real book needs it — not as the default grouping.
Note that the cross-broker aggregation value the product actually promises is
delivered by the positions table, not by the payoff chart.
