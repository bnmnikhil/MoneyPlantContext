# GoldenBook — Research section plan (financials, screener, insights)

**Created 9 Nov 2026 (owner + Claude).** Status: **planning; nothing built.** This file owns the AN-items and
their status. It sits in `NEXT-10.md`'s **Stage D** (after launch) unless the owner moves it. Status markers are
`P0-LAUNCH.md`'s: `[ ]` not started, `[~]` in progress, `[x]` done and verified, `[-]` dropped.

## Goal

Add a **Research** section beside positions, holdings, payoff and the Strategy Builder: a stock page with
financials, a screener over stocks, and insights. The edge over generic stock sites is the link to the user's own
book (their positions and holdings in that stock, its option chain, its payoff).

## Constraints carried in from earlier decisions

1. **No source of fundamentals exists in the stack.** Brokers return none; NSE's `www` site 403s the OCI VM
   (`memory/free-market-data-options-researched.md`).
2. **SEBI Research Analyst exposure.** Ranked trade ideas or recommendation-like AI text are the exposed end;
   showing facts and running user-defined filters is the defensible end (`research/BROKER-API-TERMS-MULTI-USER.md`).
   Design every surface as facts with sources, never advice. Not legal advice.
3. **Launch scope is live data only** (`memory/launch-scope-is-live-data-only.md`). Market data is not personal
   data, so storing it does not contradict that decision; record the decision (AN-04). Saved screens would be the
   first deliberately stored user data and must be covered by erasure.
4. **The old screener code is lost** (12 Oct); its design is in `memory/index-spread-screener.md`.

## Fundamentals: source and storage (discussed 8–9 Nov 2026)

### Sources surveyed

| Source | Gives | History | Problem | Verdict |
|---|---|---|---|---|
| **NSE/BSE XBRL filings** (primary) | Quarterly results in XBRL, mandatory since Apr 2017 (SEBI LODR Reg 33); the raw material vendors ingest | 2017 onward | Discovery uses unofficial endpoints; NSE site terms say personal/non-commercial; `www.nseindia.com` blocks the VM, `nsearchives.nseindia.com` reportedly does not (unverified); we parse Ind-AS taxonomy ourselves | **Base dataset** |
| **Upstox Fundamentals API** (official, since 11 May 2026) | Income statement, balance sheet, cash flow, shareholding, key ratios, corporate actions, competitors; by ISIN; consolidated/standalone; yearly/quarterly; values in crore | ~4 years annual in the sample; quarterly depth undocumented | Needs a daily Upstox token; display terms for non-Upstox users unpublished; data is probably licensed from a vendor of Upstox's | **Cross-check, or live fetch through a user's own Upstox connection — unless Upstox approves wider use in writing** |
| Yahoo / yfinance | Basic statements | ~4 years | Unofficial; terms forbid commercial use | No |
| Screener.in | Excellent data | 10+ years | No API; terms protect content | No |
| Dhan ScanX | Statements, ratios | ? | Undocumented web backend | No |
| Stoxim, indianapi.in | Statements from XBRL | Stoxim: 3 years, 500 req/day free | Small vendors, unknown licensing | Fallback only |

### Decision (provisional, pending AN-05)

**Download the filings once, store our own extracted numbers, serve users only from our database.**

- Downloading once does not change licensing — showing stored data to others is redistribution, which is why the
  base must be the companies' own statutory filings, not a vendor's compilation (Indian law can protect
  compilations: *Eastern Book Co. v. D.B. Modak*, 2008).
- **Backfill runs from the laptop**, whose residential IP NSE serves, slowly and politely; results load into
  Postgres. ~2,000 companies × ~35 quarters ≈ 70,000 files, a few GB raw; a few million extracted rows.
- **Quarterly incremental**: from the VM if `nsearchives` is reachable from it, otherwise a laptop job four times a
  year that pushes new filings up.
- **Every figure shows "From the company's filing of <date>" with a link to the original.**

### Storage (new `fundamentals/` module; same for every user, no DPDP burden)

- `company` — ISIN (key), NSE symbol, BSE code, name, sector, industry, F&O flag; linked to `UnderlyingRegistry`.
- `financial_line` — narrow: one row per (isin, statement, basis, period type, period end, line item). **Line items
  use GoldenBook's own vocabulary**, mapped in the adapter; values in rupees (converted from crore); period labels
  parsed to dates; source, filing reference and fetched-at on every row; upsert captures restatements.
- **A separate line-item format for banks, NBFCs and insurers** from the start — their statements have no
  revenue/operating-profit in the usual sense.
- `shareholding`, `corporate_action` — per quarter / per event (separate filings with their own discovery).
- **Ratios are computed by us** from statements plus price, so a screener filter means one fixed thing; vendor
  ratios only as a cross-check.
- Raw filings archived compressed outside the database (or discarded) for reprocessing.
- Limits: balance sheet and cash flow are half-yearly only; depth starts in 2017.

## Items

### Phase 0 — decisions and probes (no product code)

| ID | Item | Output | Status |
|---|---|---|---|
| AN-01 | Data-source dossier: the table above, finished with the probe results | `research/FUNDAMENTALS-DOSSIER.md` | `[~]` survey done 8 Nov |
| AN-02 | Regulatory stance: facts and user-defined filters, never recommendations; disclaimer copy; legal opinion if budget allows | memory + copy rules | `[ ]` |
| AN-03 | Universe: F&O stocks (~200) first, all NSE (~2,000) later | decision | `[ ]` |
| AN-04 | Decision: GoldenBook stores market data (not user data) | memory | `[ ]` |
| AN-05 | **XBRL probe (laptop, half a day):** `curl` an `nsearchives` iXBRL page and the NSE listing page (status codes); fetch ~5 XBRL `.xml` files (a normal company, a bank, others); parse revenue, profit, EPS and match against the PDF; count files and size for one quarter | probe notes in the dossier | `[~]` owner testing links locally, 9 Nov |
| AN-06 | From the VM: `curl` one `nsearchives` file — can the quarterly update run on the server? | yes/no in the dossier | `[ ]` |
| AN-07 | Upstox: call all 8 fundamentals endpoints for 3 ISINs with one live token (history depth, coverage, rate limits); email support asking whether fundamentals may be shown to non-Upstox users | payloads in `research/`, written answer | `[ ]` |

### Phase 1 — data foundation (backend, M–L)

`fundamentals/` module and the tables above; XBRL parser with the general and financial-company formats; laptop
backfill; quarterly incremental; EOD price history (`price_eod`, partitioned by year) for ratios and technicals;
every run records freshness and alerts on failure (O-items). **Done when** the backfill reconciles against the
filings' PDFs for ~10 companies, figure by figure.

### Phase 2 — stock page `/app/stocks/:symbol` (M)

Price chart, ratios, statements, results/dividend calendar, each figure linked to its filing. The edge: option
panel from the Alice Blue chain (PCR, OI by strike) and **"Your exposure"** (the user's positions and holdings in
this stock, link to its payoff). Navigation: one **Research** item with tabs Stocks / Screener / Insights (a sixth
nav item moves breakpoints `lg` → `xl`).

### Phase 3 — screener (M–L)

User-built filters over financials, technicals and option metrics; server-side queries from a whitelisted field
set. Saved screens (first stored user data; covered by erasure). Presets labelled as filters, not ideas. The
options-structure screener (credit spreads) stays hidden until AN-02 clears it.

### Phase 4 — insights

- **4a, rule-based:** from the user's book — concentration, expiry clustering, margin pressure, results dates for
  holdings, 52-week extremes; every insight shows its numbers; extends `features/dashboard/attention.ts`.
- **4b, AI layer:** Claude summarises already-computed facts, each claim tied to a displayed figure; no targets or
  buy/sell language; cached per stock per day; book commentary on request only; needs a cost budget and an eval
  set before switch-on.

### Phase 5 — history-dependent (later)

EOD option-chain capture → IV percentile and premium decay (closes risk's decay stub). Back-testing stays offline.

## Order

AN-05 → AN-01 → AN-02/03/04 → Phase 1 → 2 → 3 → 4a → 4b → 5. AN-05 (does the filing route work?) gates the
source decision; the source decision gates everything after it.

## Open (owner)

1. Does this jump ahead of Stages A–C, or start after the announcement (Stage D)?
2. Acceptable monthly spend if a paid vendor is needed after all.
3. Universe: F&O only first, or all NSE?

## Links for AN-05

- NSE results listing: https://www.nseindia.com/companies-listing/corporate-filings-financial-results
- BSE results listing: https://www.bseindia.com/corporates/Comp_Resultsnew.aspx
- Sample iXBRL filings:
  - https://nsearchives.nseindia.com/corporate/ixbrl/INTEGRATED_FILING_INDAS_126130_11112025183926_iXBRL_WEB.html
  - https://nsearchives.nseindia.com/corporate/ixbrl/INTEGRATED_FILING_INDAS_141367_09022026192205_iXBRL_WEB.html
  - https://nsearchives.nseindia.com/corporate/ixbrl/INTEGRATED_FILING_INDAS_89487_06052025195705_iXBRL_WEB.html
- Laptop checks:
  ```powershell
  curl.exe -s -o test.html -w "%{http_code} %{size_download}`n" -A "Mozilla/5.0" "https://nsearchives.nseindia.com/corporate/ixbrl/INTEGRATED_FILING_INDAS_126130_11112025183926_iXBRL_WEB.html"
  curl.exe -s -o list.html -w "%{http_code}`n" -A "Mozilla/5.0" "https://www.nseindia.com/companies-listing/corporate-filings-financial-results"
  ```
  `200` = plain downloader works; `403` = needs the homepage cookie handshake.

## Sources

[Upstox Fundamentals API](https://upstox.com/developer/api-documentation/fundamentals/) ·
[launch notice](https://upstox.com/developer/api-documentation/announcements/company-fundamentals-api) ·
[income statement endpoint](https://upstox.com/developer/api-documentation/get-income-statement) ·
[BSE XBRL](https://bseindia.com/static/about/xbrl_info.aspx) (helpdesk bse.xbrl@bseindia.com) ·
[BSE XBRL mandate](https://moneylife.in/article/bse-mandates-filing-of-financial-results-through-xbrl-format/50259.html) ·
[nse-archives (cloud reachability claim)](https://pypi.org/project/nse-archives/) ·
[NSE blocks cloud servers](https://forum.unofficed.com/t/update-nsepython-not-working-in-aws-google-cloud-and-webservers/670) ·
[Screener.in terms](https://www.screener.in/guides/terms) · [Stoxim](https://www.stoxim.com/)
