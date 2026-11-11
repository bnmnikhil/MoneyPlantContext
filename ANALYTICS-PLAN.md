# GoldenBook — Research section plan (financials, screener, insights)

**Created 9 Nov 2026; rewritten 11 Nov 2026 as a step-by-step build plan (owner + Claude).** This file owns the
AN-items and their status. It sits in `NEXT-10.md`'s **Stage D** unless the owner moves it. Status markers are
`P0-LAUNCH.md`'s: `[ ]` not started, `[~]` in progress, `[x]` done and verified, `[-]` dropped. `[x]` means the
step's **Verify** was run, not that code exists.

## Resume here

**Read this block first in any new session.** Then run `git status -sb` and `git branch --show-current` in
`MoneyPlantFrontend`, `MoneyPlant` and `MoneyPlantContext` before trusting it.

| | State on 11 Nov 2026 |
|---|---|
| **Next step** | **AN-13** (storage and ingest service). AN-11 committed (`1e69199`, pushed). AN-12 done 11 Nov: parsers in `fundamentals/parse/` on `MoneyPlant` branch `research/fundamentals`, **uncommitted**. |
| Sample page | Built and verified locally. `MoneyPlantFrontend`, branch `research/stock-page-sample` at `277d01f`, pushed; no PR, not merged. |
| Data | `public/fundamentals/ITC.json` (64 quarter rows, Mar 2018 – Sep 2026) and `BSE.json` (1 row). Files only; **no database tables exist yet**. Raw filings cached (untracked) in `MoneyPlantFrontend/scripts/fundamentals/cache/`. |
| Backend | `main` at `164e7fc` (migrations to `V11`). Branch `research/fundamentals` adds `V12`; local Postgres is at `V12`, staging and production at `V11`. |
| This file, `BUSINESS-PLAN.md` | Committed in `MoneyPlantContext` on `marketing/first-users`, which now contains all of `origin/main` (merged 11 Nov). Pushed; no PR. |
| Local servers | Not running (stopped 11 Nov for low memory). Start only when a step needs them, memory-capped (`memory/laptop-git-and-tooling-gaps`). |
| Open owner decisions | Universe for the first load (AN-20); timing against Stages A–C; the NSE licence question (AN-02). The Java parser port (AN-12) is approved. |

**After every step:** flip its marker in the status table below, update the "Next step" line above, and add one
dated line under the step saying what was verified and what was not.

## Goal

A **Research** section beside positions, holdings, payoff and the Strategy Builder: a stock page with financials,
then a screener, then insights. The edge over generic stock sites is the link to the user's own book (their
positions and holdings in that stock, its option chain, its payoff).

## Decisions

| Decision | Date | Why |
|---|---|---|
| Fundamentals come from the companies' own filings with NSE, extracted and stored by us | 9 Nov (`memory/fundamentals-come-from-filings.md`) | The only free source defensible for showing stored data to users |
| **Production data lives in Postgres behind the signed-in API**, not in files shipped with the frontend | 11 Nov (owner) | Files are public, need a deploy per update, cannot be queried by a screener, and do not scale |
| **One column per figure** in `quarterly_result`, not one row per line item | 11 Nov (owner; replaces this file's earlier narrow design) | Screener filters become plain SQL; the lines are fixed by the statement format. A new line item costs a migration |
| **Banks, NBFCs and insurers get their own result tables**, with a view over the common columns | 11 Nov (owner) | Their statements share almost nothing with a manufacturer's |
| **Prices are stored raw (as traded), corporate actions separately**; adjusted series are computed when read | 11 Nov | Industry practice; history is never rewritten |
| The current price stays live from the user's broker; `price_eod` is history only | 11 Nov | Already works; no intraday storage is planned |
| The parser moves into the backend, in Java | 11 Nov (owner) | One test gate, one place that defines each line item |
| Filing links are collected by hand from NSE's two results tabs; nothing automates NSE's listing pages | 11 Nov | The listing call needs a cookie handshake and was refused as bot-check circumvention. Do not retry it or route around it |
| Facts with sources, never advice: no ranked ideas, no recommendation-like text | 9 Nov | SEBI Research Analyst exposure (`research/BROKER-API-TERMS-MULTI-USER.md`). Not legal advice |

## What was learned on 11 Nov 2026 (probes; AN-05 mostly answered)

- **`nsearchives.nseindia.com` serves plain files** to a self-identifying client from the laptop, no cookies:
  filings, and the daily price file. `www.nseindia.com`'s listing API does not (see the last decision above).
- **Two filing formats, three vintages of the newer one**, all parsed and tested in
  `MoneyPlantFrontend/scripts/fundamentals/parse-filing.mjs`:
  - XBRL `.xml` under `/corporate/xbrl/` for quarters up to Dec 2024. Amounts in full rupees. The quarter's
    facts are in the context `OneD`; `FourD` is year-to-date. No ISIN.
  - "Integrated Filing — IndAS" `.html` under `/corporate/ixbrl/` from the Mar 2025 quarter. Plain HTML
    tables read by row label. The unit is in its own row, or in an "Amount in (Lakhs)" heading, or (Mar and
    Jun 2025) the currency row reads "INR (in Actuals)" with the unit row commented out. Dates are
    `dd-mm-yyyy` or `dd-Mon-yyyy`. A label cell is sometimes left unclosed.
- **NSE's own tables paste straight in.** "Financial Results" lists the XBRL era; "Integrated Filing -
  Financials" lists the rest. Rows from before 2018 have no file (`.../xbrl/-`).
- **ITC as a test of the figures:** Dec 2024 checked against the raw XBRL. Mar 2025 net profit is ₹19,808 cr
  because of the hotels demerger, booked under profit from discontinued operations (₹14,653 cr; corrected at
  AN-12, it is not in "exceptional items"), so the schema needs `exceptional_items` and `profit_discontinued`. The new-format quarters have **not** been checked against the published PDFs.
- **End-of-day prices are free at the same host.** The filings contain no market prices. NSE's daily file
  `https://nsearchives.nseindia.com/products/content/sec_bhavdata_full_DDMMYYYY.csv` downloaded (200, 400 KB,
  3,551 rows): symbol, series, date, previous close, open, high, low, last, close, average price, volume,
  turnover, trades, delivery quantity and percent. **The date inside the file is the authority, not the one in
  its name:** the file named 10 Nov 2026 carried 09-Nov-2026 rows. One file per trading day, so history is one
  download per day wanted (about 250 a year). The same terms question applies as to the filings (AN-02).
- **Not answered:** whether the production VM can reach `nsearchives` (AN-06); bank and NBFC formats.

## Architecture

```
NSE tables pasted by the owner
        │  (filing addresses)
        ▼
POST /api/admin/fundamentals/import        owner only
        │  fetch from nsearchives (or accept an uploaded file), 2 s apart
        ▼
fundamentals/ingest ── raw file, gzip ──▶ disk (GB_FUNDAMENTALS_RAW_DIR)
        │  parse (XBRL or integrated HTML)
        ▼
Postgres: company · filing · quarterly_result
        ▲
GET /api/research/stocks/{symbol}          signed-in users (owner only until AN-02 clears)
        ▲
StockPage (/app/stocks/:symbol): results from the API; price, positions, holdings as today
```

New backend package `com.goldenbook.tradestack.fundamentals` (parse, ingest, repository, controller). It depends
on nothing in `broker/`; ArchUnit should say so.

### Schema (migration `V12`)

```sql
create table company (
    id               bigint generated always as identity primary key,
    nse_symbol       text not null unique,          -- 'ITC', 'M&M'
    underlying       text unique,                   -- GoldenBook's code ('MM'); links to positions and payoff
    isin             text unique,                   -- absent from the older filings
    name             text not null,
    statement_format text not null default 'general',   -- later: 'bank', 'nbfc', 'insurer'
    in_fno           boolean not null default false,
    created_at       timestamptz not null default now()
);

create table filing (
    id             bigint generated always as identity primary key,
    company_id     bigint not null references company(id),
    source_url     text not null unique,
    format         text not null,               -- 'xbrl_xml' | 'integrated_html'
    basis          text not null,               -- 'consolidated' | 'standalone'
    period_start   date not null,
    period_end     date not null,
    approved_on    date,
    audited        boolean not null,
    reported_in    text,                        -- 'lakhs', 'crores', 'actual': as filed
    content_sha256 text not null,
    raw_path       text,
    status         text not null,               -- 'parsed' | 'failed' | 'superseded'
    error          text,
    fetched_at     timestamptz not null,
    parsed_at      timestamptz
);
create index filing_company_period on filing (company_id, period_end desc);

create table quarterly_result (
    company_id          bigint not null references company(id),
    period_end          date   not null,
    basis               text   not null,
    filing_id           bigint not null references filing(id),
    period_start        date   not null,
    audited             boolean not null,
    revenue             numeric(20,0) not null,   -- rupees
    other_income        numeric(20,0),
    total_income        numeric(20,0),
    total_expenses      numeric(20,0),
    finance_costs       numeric(20,0),
    depreciation        numeric(20,0),
    exceptional_items   numeric(20,0),
    profit_before_tax   numeric(20,0),
    tax                 numeric(20,0),
    profit_discontinued numeric(20,0),
    net_profit          numeric(20,0) not null,
    net_profit_owners   numeric(20,0),
    paid_up_equity      numeric(20,0),
    face_value          numeric(12,4),
    eps_basic           numeric(14,4),
    eps_diluted         numeric(14,4),
    primary key (company_id, period_end, basis)
);
```

Rules: a null is "not in the filing", never zero. A later filing for the same quarter and basis overwrites the
result row and marks the earlier filing `superseded`. A filing whose symbol is not the one imported is refused.

### Planned later tables (not in `V12`)

| Table | For | Step |
|---|---|---|
| `bank_quarterly_result` (and NBFC, insurer), plus a view of the common columns | Financial companies | AN-21 |
| `price_eod` (company, trade_date, open, high, low, close, prev_close, volume, source), partitioned by year | 52-week range, charts, returns | AN-22 |
| `corporate_action` (splits, bonuses, dividends, demergers) | Dividend yield; comparable EPS across a split | AN-23 |
| `stock_metric` (trailing EPS, growth, margins; rebuilt at import) | Screener filters | AN-24 |
| `balance_sheet`, `cash_flow`, `segment_result`, `shareholding` | Deeper stock page | Phase 2 |
| `watchlist`, `saved_screen` | First stored user data; covered by erasure | Phase 3 |
| `ingest_run` | What was imported and what failed | with AN-14 if cheap |

Known strains: restated prior quarters inside later filings are ignored (latest filing per quarter wins);
mergers and renames need a symbol-history table; an annual figure summed from quarters breaks where Q4 is only
"year minus nine months"; raw files for all of NSE (~1 GB compressed) belong in object storage, not on the VM.

### API

- `POST /api/admin/fundamentals/import` — owner only. Body: `{ symbol, text }`, where `text` is pasted NSE table
  rows or bare addresses. Fetches only `nsearchives.nseindia.com`. Answers per filing: parsed, skipped (no
  file), failed with the reason.
- `POST /api/admin/fundamentals/upload` — owner only; one raw filing, for when the server cannot reach NSE.
- `GET /api/research/stocks/{symbol}` — `{ symbol, name, isin, quarters: [...] }`, the shape
  `src/features/research/fundamentals.ts` already reads, plus the three new figures. 404 when not loaded.

## Status

| ID | Step | Status |
|---|---|---|
| AN-01 | Data-source dossier (`research/FUNDAMENTALS-DOSSIER.md`) from the findings above | `[~]` findings recorded here; dossier not written |
| AN-02 | Regulatory and terms stance; ask NSE about a data licence; disclaimer copy | `[ ]` **gates showing this to anyone but the owner** |
| AN-03 | Universe decision | `[ ]` owner (see AN-20) |
| AN-04 | Memory: GoldenBook stores market data (not user data) | `[ ]` |
| AN-05 | Filing probe from the laptop | `[x]` 11 Nov, except banks and a PDF reconciliation |
| AN-06 | Can the production VM reach `nsearchives`? | `[ ]` → AN-18 |
| AN-07 | Upstox fundamentals as a cross-check | `[ ]` optional |
| AN-10 | Commit the sample branch and these docs | `[x]` 11 Nov |
| AN-11 | `V12` migration | `[x]` 11 Nov, local only |
| AN-12 | Parser in the backend | `[x]` 11 Nov |
| AN-13 | Storage and ingest service | `[ ]` **next** |
| AN-14 | Owner-only import endpoints | `[ ]` |
| AN-15 | Read API | `[ ]` |
| AN-16 | Stock page reads the API | `[ ]` |
| AN-17 | ITC end to end on the laptop | `[ ]` |
| AN-18 | Server reachability, then staging | `[ ]` |
| AN-19 | Production, owner only | `[ ]` |
| AN-20 | First universe loaded | `[ ]` |
| AN-21 | Bank, NBFC, insurer formats | `[ ]` |
| AN-22 | End-of-day prices | `[ ]` |
| AN-23 | Corporate actions | `[ ]` |
| AN-24 | Metrics table | `[ ]` |

## Steps

Branch for AN-11 to AN-17: **`research/fundamentals`** in `MoneyPlant` and `MoneyPlantFrontend` (same name in
both, as the repo rule says). Gates: backend `mvnw clean test` (read the `Tests run:` line), frontend
`npm run typecheck` and `npm test`. One step at a time; stop after each **Verify**.

### `[ ]` AN-10 — Commit the sample so it is safe

Needs the owner's word (commits are made only when asked).
- `MoneyPlantFrontend` `research/stock-page-sample`: commit `src/features/research/`, `src/pages/StockPage.tsx`,
  the route in `src/App.tsx`, `scripts/fundamentals/` (script, parser, README, `links/`),
  `public/fundamentals/`, `tests/stock-fundamentals.test.mjs`, the `.gitignore` line. Push.
- `MoneyPlantContext`: commit `ANALYTICS-PLAN.md` and `BUSINESS-PLAN.md`. Decide with the owner whether to first
  bring `marketing/first-users` up to `origin/main` (it is 11 behind, so its `NEXT-10.md` is stale).

**Verify:** `git status` clean in both; `git ls-remote` shows the branches.

**Done 11 Nov 2026.** Frontend `research/stock-page-sample` committed (`277d01f`) and pushed. Context: the two docs
committed (`ba21ee3`), then `origin/main` merged into `marketing/first-users` (no conflicts; NEXT-10 is now the
4 Nov version), pushed. Not done: PRs (no `gh` on this laptop; the owner opens them on GitHub if wanted).

### `[ ]` AN-11 — `V12` migration

- `MoneyPlant/src/main/resources/db/migration/V12__fundamentals.sql` with the three tables above, commented in
  the style of the existing migrations.
- Check the additive rule: only `create table` and `create index`.

**Verify:** start the backend locally (dev auth, Postgres 16 on 5433); `flyway_schema_history` shows `12`
`success`; the three tables exist and are empty; `mvnw clean test` green.

**Done 11 Nov 2026.** `MoneyPlant/src/main/resources/db/migration/V12__fundamentals.sql` on branch
`research/fundamentals` (uncommitted). Additive: 3 `create table`, 2 `create index`, 5 `comment on`, nothing else.
Beyond the sketch above: `check` constraints on the enumerated text columns (`statement_format`, `format`,
`basis`, `status`), on non-blank symbol and name, on `period_end >= period_start`, and on a 64-character sha256;
an index on `quarterly_result.filing_id`. Dry-run in a rolled-back transaction, then applied by Flyway when the
jar booted against local Postgres: history `12 | fundamentals | t`; `company`, `filing`, `quarterly_result`
exist with 0 rows; 9 indexes. `mvnw clean test`: **747 passing**, 0 failures (tests disable Flyway, so the boot
is the migration's real check). Not done: staging and production, which run it at AN-18 and AN-19.

### `[ ]` AN-12 — Parser in the backend

Confirm the port with the owner first (the alternative is keeping the Node script as the loader).
- `fundamentals/parse/`: `ParsedFiling` (company, quarter), `XbrlFilingParser`, `IntegratedFilingParser`,
  `FilingParsers.parse(text)` choosing by content, `FilingFormatException`. Amounts as `BigDecimal` rupees.
- Add the three new figures to both parsers: exceptional items, profit from discontinued operations, profit
  attributable to owners.
- Test resources: copy real filings from `MoneyPlantFrontend/scripts/fundamentals/cache/`: ITC Dec 2024 (XBRL),
  ITC Mar 2025 (actuals, month-name dates), ITC Sep 2025 (lakhs), BSE Sep 2025 (unclosed cell). Port every case in
  `tests/stock-fundamentals.test.mjs` that concerns parsing.
- **Golden test:** parse all 64 cached ITC filings and compare each figure with `public/fundamentals/ITC.json`.

**Verify:** `mvnw clean test` green; the golden test passes for all 64; a non-IndAS page and a wrong unit are
refused.

**Done 11 Nov 2026** (uncommitted on `research/fundamentals`). Package `com.goldenbook.tradestack.fundamentals.parse`:
`FilingParsers.parse(text)` (entry point, picks the format from the document's start), `XbrlFilingParser` (JDK StAX,
DTDs and external entities off; facts of context `OneD`), `IntegratedFilingParser` (regex port of
`parse-filing.mjs`, comments stripped, cells split on opening tags, unit from row / heading / "(in Actuals)"),
`ParsedFiling` (`Company`, `Quarter` with `BigDecimal` rupees), `Amounts`, `Basis`, `FilingFormat`,
`FilingFormatException`. The three new figures: XBRL `ExceptionalItemsBeforeTax`,
`ProfitLossFromDiscontinuedOperationsAfterTax`, `ProfitOrLossAttributableToOwnersOfParent`; HTML "Exceptional
items", "Net profit (loss) from discontinued operation after tax", a label ending "profit or loss, attributable to
owners of parent". Standalone filings have no owners' line (null).
- `FilingParsersTest` (14): five real filings in `src/test/resources/fundamentals/` (ITC Dec 2024 consolidated and
  standalone XBRL, ITC Mar 2025 actuals, ITC Sep 2025 lakhs, BSE Sep 2025 with the unclosed cell), every quirk on
  a cut-down page, refusals (not IndAS, empty, no general revenue, unknown unit, external entity).
- `ItcGoldenFilingsTest`: all **64** cached ITC filings give exactly the figures in `ITC.json`. It reads the
  frontend repo's untracked cache, so it **skips** where that is absent (fresh clone, CI); here it ran.
- ArchUnit: `..fundamentals..` must not depend on broker, portfolio, snapshot or credential; `..fundamentals.parse..`
  must not depend on Spring, `java.net` or `java.sql`.
- Gate: `mvnw clean test` **764 passing** (747 + 17).
- **Correction to the 11 Nov findings:** ITC's Mar 2025 ₹19,808 cr is **not** an exceptional item (filed as 0). The
  hotels demerger sits in profit from discontinued operations (₹14,653 cr), so `profit_discontinued` explains it.
  ITC's Dec 2024 standalone does carry ₹528 cr of exceptional items.
- The Node script stays as the loader until AN-16 decides its fate.

### `[ ]` AN-13 — Storage and ingest service

- `FundamentalsRepository` (`JdbcClient`): upsert company, insert filing, upsert result, mark superseded.
- `FilingIngestService`: text → addresses (the paste rules now in `extract-filings.mjs`), fetch, sha256, gzip to
  `${GB_FUNDAMENTALS_RAW_DIR}/<symbol>/<sha>.gz`, parse, store, in one transaction per filing.
- `FilingFetcher`: only host `nsearchives.nseindia.com`, self-identifying user agent, 2 s between requests,
  30 s timeout; a fetch already stored by address is not repeated.
- Tests with a fake fetcher: a revised filing replaces the row; a wrong symbol is refused; a failed filing is
  recorded and does not stop the rest. Repository SQL needs the `db`-tagged suite (Docker), which this laptop
  does not run: say so, and check the SQL by hand against local Postgres.

**Verify:** `mvnw clean test` green; a manual run of the service against local Postgres loads two ITC filings.

### `[ ]` AN-14 — Owner-only import endpoints

- Find how `/app/admin`'s backend endpoint decides "owner" and reuse exactly that guard.
- `FundamentalsAdminController`: the two `POST`s above; CSRF as every other write.
- Never log the pasted text in full; log counts and the failing address.

**Verify:** as a non-owner the endpoints answer 403 (test); as owner a paste of two rows answers two `parsed`.

### `[ ]` AN-15 — Read API

- `ResearchController` `GET /api/research/stocks/{symbol}`; DTO mirrors the JSON's field names. Owner-only for
  now behind one property (`goldenbook.research.audience=owner|all`, default `owner`).
- Update the API table in `CLAUDE.md` and `src/types/api.ts`.

**Verify:** controller tests for found, not loaded (404), not owner (403); `mvnw clean test` green.

### `[ ]` AN-16 — Stock page reads the API

- `src/features/research/hooks.ts` calls `api.stockFundamentals(symbol)` through `lib/api.ts`; a 404 is the
  "No results loaded" state, a 403 hides the page.
- Show exceptional items as a table row when any quarter has one, so ITC's Mar 2025 explains itself.
- Delete `public/fundamentals/`. Keep `scripts/fundamentals/` only if AN-12 kept the Node loader; otherwise
  delete it and its tests, which now live in the backend.

**Verify:** `npm run typecheck`, `npm test`, `npm run build`; no `/fundamentals/` file in `dist`.

### `[ ]` AN-17 — ITC end to end on the laptop

Start backend and Vite. Import ITC by pasting both NSE tables (they are in
`scripts/fundamentals/links/ITC.txt`) into the import endpoint.

**Verify:** 64 rows in `quarterly_result`; the page shows the same figures as the 11 Nov screenshots (Sep 2026:
revenue 30,578, net profit 4,229, EPS 3.32; EPS for four quarters 15.07); desktop and phone width in Chrome;
the Standalone switch; the exposure card with a real ITC position. Reconcile two new-format quarters against
the company's published results PDF.

### `[ ]` AN-18 — Server reachability, then staging

- The owner runs on the VM: `curl -s -o /dev/null -w "%{http_code}\n" -A "GoldenBook-fundamentals/0.1" <one ITC filing address>`.
  `200`: the server fetches. Anything else: imports go through the upload endpoint from the laptop.
- Set `GB_FUNDAMENTALS_RAW_DIR` in staging's environment; deploy the branch to staging; import ITC there.

**Verify:** staging's page shows ITC; the answer to AN-06 is written here.

### `[ ]` AN-19 — Production, owner only

Owner approval per `memory/prod-deploy-authorization`: merge both PRs to `main`, `deploy.sh`, verify. `V12`
runs in production for the first time: confirm with the `flyway_schema_history` query in `CLAUDE.md` (the owner
runs it; Claude does not read the production database). Import ITC through the endpoint.

**Verify:** site 200, `/api/me` 401 from outside, `/api/research/stocks/ITC` 401 unsigned; the owner sees the
ITC page; a second Google account does not.

### `[ ]` AN-20 — First universe loaded

Owner decides the list (suggested: own holdings plus 30–50 liquid F&O names, general format only until AN-21).
For each: paste both NSE tabs, import, spot-check one quarter. Record the list and any failures here.

**Verify:** every listed company has its latest quarter; failures are listed with reasons.

### Later, each its own step

- **AN-21 banks, NBFCs, insurers:** probe one filing of each (HDFC Bank, Bajaj Finance, an insurer), design
  `bank_quarterly_result`, parser, page variant.
- **AN-22 end-of-day prices:** `price_eod`; a loader for `sec_bhavdata_full_DDMMYYYY.csv` (series `EQ`, date
  from inside the file, one request per day, idempotent); backfill one year from the laptop or the server;
  fills the 52-week tile. Raw prices only.
- **AN-23 corporate actions:** source to be found (NSE's corporate-actions list); dividend yield tile; split
  and bonus factors applied to EPS history when read.
- **AN-24 metrics table:** trailing EPS, growth, margins per company, rebuilt at import; price-based ratios
  joined at query time.
- **Phase 2:** balance sheet, cash flow, segments, shareholding; Research in the navigation (a sixth item moves
  the breakpoints `lg` → `xl`).
- **Phase 3:** screener over `stock_metric` with a whitelisted field set; saved screens.
- **Phase 4:** insights, rule-based first, then AI summaries tied to displayed figures.

## Gates that are not code

- **AN-02 before any non-owner sees the page.** NSE's site terms say personal, non-commercial use. Ask NSE (and
  BSE) about a data licence; get a legal view before charging.
- **Link collection does not scale.** Two manual exports per company, and again each quarter for new filings.
  Fine for 30–50 names, not for 2,000. A licence or a vendor is the way past it, not automation of NSE's site.
- **Timing.** Stage A of `NEXT-10.md` is mostly open. Owner to say whether this runs alongside it or after.

## Sources

[Upstox Fundamentals API](https://upstox.com/developer/api-documentation/fundamentals/) ·
[BSE XBRL](https://bseindia.com/static/about/xbrl_info.aspx) ·
[nse-archives (cloud reachability claim)](https://pypi.org/project/nse-archives/) ·
[NSE blocks cloud servers](https://forum.unofficed.com/t/update-nsepython-not-working-in-aws-google-cloud-and-webservers/670) ·
[Screener.in terms](https://www.screener.in/guides/terms) · mockup approved 11 Nov:
https://claude.ai/artifact/8cL2n6LjLWj64HXiC2zJa4 · market and business context: `BUSINESS-PLAN.md`.
