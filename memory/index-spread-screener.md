---
name: index-spread-screener
description: "First screener scans owned Alice Blue chains for bounded index credit spreads, with auditable filters and no order placement"
metadata:
  type: decision
---

**25 Sep 2026.** The first Screener is a read-only discovery surface, not an
execution engine. On opening `/app/screener`, the authenticated backend uses
the caller's first available Alice Blue option-chain source, scans NIFTY,
BANKNIFTY and FINNIFTY, and reports up to 20 single-expiry, one-lot credit
verticals. It reruns while the page is open every five minutes or on demand.

**Why this small universe and defined-risk structure?** The only production
option feed here is Alice Blue's per-strike last price and open interest. There
is no bid/ask, volume history, greeks, volatility surface, or demonstrated
execution price. Screening naked short options or claiming to find the "best"
entry would convert that missing information into false confidence. A same-
expiry credit vertical at least has calculable terminal max loss under a
last-trade assumption. The server reports the formula and the UI states what
the last prices cannot prove.

Filter: nearest expiry 2–35 calendar days from today in IST; short strike at
least 1% out of the money, hedge 1–3 listed strikes farther out; both prices
known, positive and currently retrieved, both OI >= 100, verified symbols and
matching lot sizes from the contract master. Credit must be between zero and
strike width, with credit/(width-credit) >= 10%. Rank descending by that
return-on-maximum-expiry-loss ratio, breaking ties on minimum leg OI. Prices
are last traded, **not** bids and asks, and exchange fees, slippage, assignment
and required margin are excluded. A high ratio is a sorting criterion, not a
probability of profit or a recommendation.

Data is fetched via `OptionChainService`, which checks ownership of the user's
source connection and caches chain reads briefly. Stale cached responses are
not scanned; an expired session propagates the reconnect error. Transient
per-underlying failures are reported alongside whatever else was scanned.
No background job, saved recommendations, or broker order endpoint is added.
