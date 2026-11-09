---
name: fundamentals-come-from-filings
description: "Provisional, 9 Nov 2026: company financials are built once from NSE/BSE XBRL filings into our own store and served from it; Upstox's fundamentals API is a cross-check, not the base"
metadata:
  type: decision
  decided: 2026-11-09
  status: provisional — confirm after AN-05 (XBRL probe)
---

**Decided provisionally 9 Nov 2026 (owner + Claude)** while planning the Research section (`ANALYTICS-PLAN.md`).

GoldenBook will **download companies' XBRL financial-result filings once (backfill from the laptop), extract the
numbers into its own `fundamentals/` tables, and serve users only from that store**, with a quarterly incremental
and every figure linked to its source filing.

**Why filings and not Upstox.** Upstox's official Fundamentals API (since 11 May 2026) is the cleanest free feed,
but storing it and showing it to people without Upstox accounts is redistribution of what is probably a licensed
vendor's compilation — the use its unpublished terms are most likely to forbid, and a revocation could also demand
deletion of the store. Downloading "once" does not change that: licensing governs use, not the fetch. The filings
are the companies' own statutory disclosures, so extracting facts from them is the defensible base (Indian law can
protect compilations — *Eastern Book Co. v. Modak*, 2008 — so copying Screener's or a vendor's tables is not).
Remaining risk: the exchange site's access terms, minimised by a single slow backfill. Not legal advice.

**Why the laptop.** `www.nseindia.com` 403s the OCI VM ([[free-market-data-options-researched]]) but serves a
residential IP. Whether `nsearchives.nseindia.com` serves the VM decides where the quarterly update runs.

**How to apply.** Line items use GoldenBook's own vocabulary ([[app-owns-its-symbols]]), with a separate format for
banks/NBFCs/insurers; ratios are computed by us, not taken from a vendor; market data is not user data, so this does
not breach [[launch-scope-is-live-data-only]]. Use Upstox only as a cross-check or through a user's own connection
unless Upstox approves wider display in writing. Revisit if the AN-05 probe shows the filings cannot be fetched or
parsed reliably.
