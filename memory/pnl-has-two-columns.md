---
name: pnl-has-two-columns
description: "Brokers disagree on what \"P&L\" means, so PositionDto carries both lifetime and day figures and each gateway computes whichever half its broker withholds"
metadata:
  type: decision
  decided: 2026-07-30
---

`PositionDto` fixes **two** columns and every gateway fills both:

- `pnl` — lifetime, since entry, in rupees
- `dayChange` — today's move, in rupees

Kite gives `pnl` directly and `dayChange` is computed as
`(lastPrice − closePrice) × qty`. Alice Blue is the mirror image: its
`unrealizedPnl` **is** the day figure, and lifetime is reconstructed as
`(ltp − trueEntry) × qty + realizedPnl`.

**Why.** The two numbers can carry opposite signs on the same position, so
picking "the" P&L field silently produces a wrong number rather than a missing
one. The live case that settled it: 650 units bought at 5.20, trading at 7.25 —
**up ₹1,332 since entry, down ₹1,495 today.**

**The trap this exists to prevent:** never use a broker's P&L field without
first establishing which of the two meanings it carries. The naming is actively
misleading — Alice Blue's `unrealizedPnl` sounds lifetime and is not.

**Corollary, same root cause:** Alice Blue's `netAveragePrice` is *not* an entry
price. It is the mark-to-market basis and equals the previous close for anything
carried overnight, so `AliceBlueMapper.trueEntryPrice` rebuilds the real basis
from `overnightPrice` / `dayBuyPrice` / `daySellPrice`. Holdings repeat it: use
`investedPrice`, never `averageTradedPrice`.
