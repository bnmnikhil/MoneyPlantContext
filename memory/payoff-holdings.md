---
name: payoff-holdings
description: "Optional same-account holdings in live payoff curves"
metadata:
  type: decision
  decided: 2026-09-08
---

Live payoff curves accept `includeHoldings` (default false) and optional positive
integer `holdingQty`. Only the selected connection's matching stock is included;
the existing curve selector still comes from positions. HoldingDto carries a
canonical underlying using registry stock normalisation (e.g. M&M -> MM).
Alice Blue's mapper removes its `-EQ` series suffix only for this identity;
the display symbol is preserved. Older DTO constructors remain compatible.

The response carries available quantity, weighted average purchase cost, included
quantity and an availability warning. Quantity defaults to the complete holding,
including pledged shares once, and cannot exceed it. Equity contributes
`quantity * (terminal spot - average cost)`; derivatives retain their entry prices.
Holdings have no expiry and do not add a date to mixed-expiry scenarios.

Any matching nonzero cash position blocks inclusion, because PositionDto and
HoldingDto cannot establish whether broker delivery quantities overlap. Do not
guess by summing or subtracting them. Missing/invalid purchase cost also blocks
inclusion. Holdings-read failure preserves the positions-only response with a
warning; a requested combined curve fails explicitly rather than dropping shares.

The builder imports EQ legs with exact share quantities, uses one-share steps,
and includes them in its target-price inspector. Its margin/capital estimates
are hidden while equity is active: the existing model prices intraday equity,
not delivery holdings. This feature changes payoff, not broker margin estimates
or settlement eligibility. The live page explains that shares are assumed held
through expiry. Existing mixed-expiry scenario limitations still apply.

The live UI takes quantity and average cost from the same combined response as
the graph. Its independently refreshed positions-only response is only the
fallback while no combined result is displayed.

Snapshot identity persistence is deferred (owner decision, 9 Sep 2026). Alice
Blue's live mapper preserves SWIGGY as the identity of SWIGGY-EQ; typed snapshot
storage currently loses that field and reconstructs SWIGGYEQ. Fix and add a
round-trip test when snapshot features resume. Live holdings/payoff reads use
BrokerService and are not routed through that snapshot read path.
