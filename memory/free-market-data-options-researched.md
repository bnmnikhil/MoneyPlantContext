---
name: free-market-data-options-researched
description: "Survey of free live-price and option-chain APIs, 15 Aug 2026: Upstox is free with per-strike IV and greeks; NSE direct is unusable from the OCI VM and its terms do not cover a product"
metadata:
  type: reference
---

Researched 15 Aug 2026, because Step 8 is [[analysis-step-is-the-product]] and
[[analysis-step-is-the-product]] is blocked on per-strike option data.

**Do not build on NSE direct.** `nseindia.com/api/option-chain-indices` is real
and free, and it is the wrong choice here for four reasons in ascending order of
seriousness:

1. Unofficial — no contract, no SLA, the shape changes without notice.
2. Needs a cookie handshake (homepage, then the option-chain page, carrying
   cookies with browser-like headers) and is throttled to roughly 3 req/s.
3. **NSE's WAF blocks hosting-provider ASNs.** Decisive: it works from the
   laptop and 403s from the OCI VM, so it tests green locally and fails only in
   production.
4. NSE's site terms permit "personal, non-commercial use only", and its Data
   Usage & Data Sharing Policy requires an agreement and fees for commercial
   use, with redistribution needing a separate agreement. MoneyPlant is
   [[real-product-not-personal-tool]], so that carve-out is not ours.

**Upstox is the find, and the best free option located.** All trading and
market-data APIs are ₹0 with no subscription, 50 req/s on quotes and OHLC. Its
Put/Call Option Chain returns, per strike: LTP, close, volume, OI, previous OI,
bid/ask, **delta, gamma, vega, theta, IV, probability of profit** — plus the
underlying spot — in one call per (underlying, expiry). NSE and BSE; not MCX,
which does not matter here. Costs a fourth OAuth integration with the same
daily-login shape the other three have.

That is bigger than spot. It would make the Black-Scholes IV solve in
[[per-instrument-risk-model]] a fallback rather than the foundation, and turn
greeks — which SPEC.md D9 explicitly declined to commit to — into fetched data.

**The rest.** Dhan's chain is comparable but the Data API is ₹499+GST/month per
user. Kite's ₹500/month tier stays declined. ICICI Breeze is free including
history but is another full broker OAuth. The Yahoo-Finance-backed "free NSE
API" wrappers on GitHub are equities-only and delayed — useless for F&O.

**Sequencing: verify Alice Blue's chain first.** It costs one live token and
*zero* new integration, since that connection already exists. Treat Upstox as
the designed fallback. Build on neither until one is confirmed against a live
token — the standing rule in [[analysis-step-is-the-product]].
