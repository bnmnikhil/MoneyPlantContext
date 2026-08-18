---
name: nse-span-margin-parameters
description: "Where NSE Clearing's and Zerodha's published SPAN + exposure margin parameters live, and the exact values as of 17 Aug 2026"
metadata:
  type: reference
---

Looked up 17 Aug 2026, when the owner compared [[heuristic-margin-engine]]'s
AUBANK figure against Zerodha's own margin calculator and found it 37% high.

**Margin = SPAN + Exposure**, stated by Zerodha as
`SPAN + Exposure − spread benefit (if any)`, collected as NRML overnight margin.
Intraday MIS is a fraction of it (~40%), which this stack does not model.

| Parameter | Index derivatives | Stock derivatives |
|---|---|---|
| Price scan range | 6σ scaled by √2, **min 9.3%** | 6σ scaled by √2, **min 14.2%** |
| Exposure margin | **2%** of contract value (spot × lot) | **3.5%**, or 1.5σ of six-month log returns if higher |
| Volatility scan range | 25% of annualised EWMA volatility, floored at 3 points | same |
| Short option minimum | set by NSE Clearing, per short option | same |

**SPAN itself:** sixteen scenarios per contract. Fourteen pair each of seven
price moves — 0, ±1/3, ±2/3, ±3/3 of the price scan range — with volatility up
and down; the last two are extreme moves at twice the range, weighted 35%
because they are correspondingly less likely. The worst portfolio-level loss
across the sixteen is the SPAN charge. Exchanges publish the daily inputs in a
**SPAN Risk Parameter file**, which is the authoritative source and is *not*
currently consumed by this stack.

**What this stack cannot compute**, and therefore where its estimate is
knowingly light: the 6σ that widens the scan range past its floor, and the 1.5σ
that can raise stock exposure past 3.5%. Both need a volatility history. Loading
the SPAN parameter file directly would remove both gaps at once and is the
obvious next step if the estimate ever needs to be exact.

Sources:
- https://support.zerodha.com/category/trading-and-markets/general-kite/funds/articles/what-is-span-and-exposure-margin
- https://zerodha.com/margin-calculator/SPAN/
- https://www.nseclearing.in/risk-management/equity-derivatives/nsccl-span
- https://zerodha.com/varsity/chapter/margin-calculator-part-1/
