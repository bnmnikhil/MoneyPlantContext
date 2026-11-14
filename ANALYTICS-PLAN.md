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
| **Next step** | **AN-20, more stocks**: production has 46 companies (ITC, the non-financial Nifty 50 and 8 more F&O names, 12-13 Nov; list and failures under AN-20) and a year of prices. Open: the renamed-symbol decision (TMPV/TATAMOTORS, TATACONSUM/TATAGLOBAL), then the rest of the F&O list, read from NSE's listing pages in Chrome. Still with the owner: AN-21 (bank filing links), AN-23 (corporate-actions source; lead under AN-22), the two display decisions under AN-24, and optionally `GB_FUNDAMENTALS_RAW_DIR` on production. **Laptop formatted 12-13 Nov 2026:** restore per `LAPTOP-SETUP.md` ("Format of 12-13 Nov 2026"); this repo's working branch is `marketing/first-users`. |
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
| AN-06 | Can the production VM reach `nsearchives`? | `[x]` 11 Nov: **yes** |
| AN-07 | Upstox fundamentals as a cross-check | `[ ]` optional |
| AN-10 | Commit the sample branch and these docs | `[x]` 11 Nov |
| AN-11 | `V12` migration | `[x]` 11 Nov, local only |
| AN-12 | Parser in the backend | `[x]` 11 Nov |
| AN-13 | Storage and ingest service | `[x]` 11 Nov |
| AN-14 | Owner-only import endpoints | `[x]` 11 Nov |
| AN-15 | Read API | `[x]` 11 Nov |
| AN-16 | Stock page reads the API | `[x]` 11 Nov |
| AN-17 | ITC end to end on the laptop | `[x]` 11 Nov |
| AN-18 | Server reachability, then staging | `[x]` 11 Nov |
| AN-19 | Production, owner only | `[x]` 11 Nov |
| AN-20 | First universe loaded | `[~]` 46 companies on production 12-13 Nov (non-financial Nifty 50 + 8 F&O); renamed-symbol decision open |
| AN-21 | Bank, NBFC, insurer formats | `[ ]` |
| AN-22 | End-of-day prices | `[x]` 11 Nov (backend `9f56112`, frontend `1753513`) |
| AN-23 | Corporate actions | `[ ]` |
| AN-24 | Metrics table | `[x]` 11 Nov (`2b4f9fc`) |
| AN-25 | Owner import page (file upload instead of console) | `[x]` 11 Nov (`594520e`) |
| AN-26 | Price chart with volume and delivery % | `[~]` 1Y done 14 Nov; daily job in prod 14 Nov (AN-26c); 3Y/5Y/Max pending (AN-26b) |
| AN-27 | Results-day moves | `[ ]` |
| AN-28 | Annual profit and loss | `[x]` 14 Nov (`7ce1edb`); growth-span fix `ca60c77` deployed 14 Nov; AN-28b (years from March filings) later |
| AN-29 | Shareholding pattern | `[ ]` |
| AN-30 | Balance sheet and cash flow | `[ ]` |
| AN-31 | Peers and upcoming events | `[ ]` |

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

**Done 11 Nov 2026** (uncommitted on `research/fundamentals`).
- `fundamentals/store/`: `FilingStore` (interface, so the rules test without a database) and `PostgresFilingStore`
  (`JdbcClient`; company upsert keyed by NSE symbol keeps an ISIN once known; result upsert on the primary key).
- `fundamentals/ingest/`: `FilingSources` (paste → addresses: first address per line ending `.xml`/`.html`,
  repeats dropped, `.../xbrl/-` counted as "without file", address-less lines counted as ignored),
  `NseArchivesFetcher` (https on `nsearchives.nseindia.com` only, no redirects, self-identifying, 2 s apart,
  10 s connect / 30 s read, 5 MB cap), `RawFilingArchive` (`goldenbook.fundamentals.raw-dir` =
  `GB_FUNDAMENTALS_RAW_DIR`; `<SYMBOL>/<sha256>.gz`; blank = not kept), `FilingIngestService`
  (`importFilings(symbol, pastedText)` and `importDocument(symbol, source, bytes)` for AN-14's upload).
- Rules: an address stored before is not fetched again (`ALREADY_STORED`); a filing of another company is refused;
  the filing **approved latest** wins its quarter and basis, a same-day one imported later wins, an unknown date
  counts as oldest; the loser is stored as `superseded` (`OLDER_THAN_STORED` when it arrives late). One transaction
  per filing; one failure is reported and the rest carry on. Logs counts and failing addresses, never the paste.
- **Deviation from the schema's intent:** a filing that fails to fetch or parse is **not** stored (its company,
  period and basis are unknown, and those columns are required), so `filing.status = 'failed'` is unused. Failures
  are in the import report and the log; an `ingest_run` table can keep them later.
- Tests: `FilingSourcesTest` (5), `FilingIngestServiceTest` (11, in-memory store, fetcher serving the fixtures),
  `FundamentalsStoreDbTest` (2, tagged `db`). The db test runs on Testcontainers, **or** with
  `-Dfundamentals.db.url=jdbc:postgresql://localhost:5433/goldenbook` in a throwaway schema it drops afterwards:
  run that way here, both passed, no schema left behind, the real tables untouched.
- Gate: `mvnw clean package` **780 passing**. Boot: context starts; logs "GB_FUNDAMENTALS_RAW_DIR unset".

### `[ ]` AN-14 — Owner-only import endpoints

- Find how `/app/admin`'s backend endpoint decides "owner" and reuse exactly that guard.
- `FundamentalsAdminController`: the two `POST`s above; CSRF as every other write.
- Never log the pasted text in full; log counts and the failing address.

**Verify:** as a non-owner the endpoints answer 403 (test); as owner a paste of two rows answers two `parsed`.

**Done 11 Nov 2026** (uncommitted on `research/fundamentals`).
- `fundamentals/api/FundamentalsAdminController`, guarded by `ops/AdminGuard` (`GB_ADMIN_EMAILS`, verified address):
  - `POST /api/admin/fundamentals/import` `{symbol, text}` → `ImportReport` (`symbol`, `filings[]` of
    `{source, outcome, periodEnd, basis, detail}`, `withoutFile`, `ignored`). Symbol `[A-Z0-9&-]{1,20}` after
    upper-casing; at most 200 addresses; 400 `INVALID_IMPORT` with a message otherwise. **Synchronous**: about 2 s
    per new filing (ITC's 64 ≈ 2 min the first time); a frontend calling it must allow for that.
  - `POST /api/admin/fundamentals/upload?symbol=&source=` with the file as the body (`application/octet-stream`) →
    one `FilingResult`. `source` must pass the fetcher's host rule.
- **Deviation:** a non-owner gets **404, not 403**, following `StatusController`'s rule that a signed-in user must
  not learn the endpoint exists. AN-15's read API should do the same while it is owner-only.
- `common/RequestBodyLimitFilter`: the 64 KB body cap (C4) is raised to **2 MB for the exact path
  `/api/admin/fundamentals/upload` only** (a filing is 50–150 KB); the paste import stays under 64 KB (ITC's two
  NSE tables ≈ 25 KB). Tested, including look-alike paths.
- Tests: `FundamentalsAdminControllerTest` (5): 404 for a stranger, an unverified owner and no login, with nothing
  imported; the report passed through `no-store`; every 400 reason; `M&M`; upload checks. `RequestLimitsTest` +1.
- **Over HTTP, local backend, dev auth as owner** (`GB_ADMIN_EMAILS=dev@localhost` for that process only): no CSRF
  header → 403; bad symbol → 400; two pasted ITC rows → two `PARSED` in 2.6 s (two real NSE downloads), `withoutFile
  1`, `ignored 1`; the same again → two `ALREADY_STORED` in 0.08 s; a 94 KB upload (Mar 2025) → `PARSED`, and it
  filled ITC's ISIN `INE154A01025`; a 2.2 MB upload → 413. Database: 3 rows with the expected figures; originals
  gzipped under `GB_FUNDAMENTALS_RAW_DIR`; the log shows counts only.
- Gate: `mvnw clean test` **786 passing**.

### `[ ]` AN-15 — Read API

- `ResearchController` `GET /api/research/stocks/{symbol}`; DTO mirrors the JSON's field names. Owner-only for
  now behind one property (`goldenbook.research.audience=owner|all`, default `owner`).
- Update the API table in `CLAUDE.md` and `src/types/api.ts`.

**Verify:** controller tests for found, not loaded (404), not owner (404, per AN-14's rule); `mvnw clean test` green.

**Done 11 Nov 2026** (uncommitted on `research/fundamentals`).
- `fundamentals/store/FundamentalsReader` (interface; `StockResults`, `QuarterView`) and `PostgresFundamentalsReader`:
  every stored quarter of a company, both bases, ordered by period then basis, each with its filing's NSE address,
  approval date and unit; `generatedAt` = the newest `parsed_at`. Amounts as `Long` rupees (`longValueExact`),
  per-share as `Double`. A company with no result rows reads as not loaded.
- `fundamentals/api/ResearchController` `GET /api/research/stocks/{symbol}`: symbol trimmed and upper-cased;
  `Cache-Control: max-age=60, private`. Audience `goldenbook.research.audience` = `GB_RESEARCH_AUDIENCE`, `owner`
  (default, `AdminGuard`) or `all` (any signed-in user); anything else fails at startup. **Two 404s:** outside the
  audience a bare 404; inside it, a stock with nothing loaded (or an invalid symbol) is 404
  `{"error":"STOCK_NOT_LOADED","message":...}`, which AN-16 shows as "No results loaded". The reader is held by the
  controller directly: the controller-repository rule (ADR 0011) is about per-user rows, and these are not.
- JSON field names are the stock page's (`features/research/fundamentals.ts`) plus `exceptionalItems`,
  `profitDiscontinued`, `netProfitOwners`. **`src/types/api.ts` is updated in AN-16** with the rest of the frontend.
- CLAUDE.md's API table lists the three endpoints, marked as on the branch.
- Tests: `ResearchControllerTest` (5: found and its JSON shape, not loaded, outside the audience reads nothing,
  `all`, the setting); `FundamentalsStoreDbTest` +1 for the reader (3 in all, run against local Postgres in a
  throwaway schema). Gate: `mvnw clean package` **791 passing**.
- Over HTTP (local, dev auth as owner): `itc` → 200, 3 quarters, ISO dates, plain numbers, Mar 2025's
  `profitDiscontinued` 146526100000; `TCS` → 404 `STOCK_NOT_LOADED`; `M%26M` → decoded to `M&M`, 404 the same.

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

**AN-16 done 11 Nov 2026** (frontend `research/fundamentals` `fc611f1`): page reads `/api/research/stocks/{symbol}`; 404 `STOCK_NOT_LOADED` → "No results loaded", bare 404 → "Research is not available yet" (none of the user's book shown); rows "Exceptional items" and "Profit from discontinued operations" only when a shown quarter has one; types in `types/api.ts`; `public/fundamentals` and `scripts/fundamentals` removed (cache kept untracked for the golden test, whose expected JSON moved to backend `itc-node-script.json`, `65ec2f2`); links files moved to `research/fundamentals-links/`. Gates: typecheck, `npm test` 177, build; nothing under `dist/fundamentals`.

**AN-17 so far, 11 Nov 2026.** First full import: 31 parsed, **30 refused** — XBRL filings up to Dec 2022 state no company name (only the symbol), and the company upsert failed NOT NULL. Fixed in `58e7fbf` (named by symbol until a filing states the name; a nameless filing never blanks name or ISIN; db test added). Re-import: 30 parsed + 34 already stored; third run all 64 already stored in 0.1 s. DB: 64 quarters, Mar 2018–Sep 2026 (30 consolidated, 34 standalone), `ITC Limited`, `INE154A01025`. API vs the sample's 64 quarters: **0 differences**. Reconciled with ITC's published results: Sep 2026 consolidated net profit ₹4,229.33 cr, standalone ₹4,137.12 cr, exceptional −₹25.66 cr, Jun 2026 consolidated ₹4,508.79 cr — all exact. **Revenue caveat:** revenue from operations includes cigarette taxes (Sep 2026 ₹30,578 cr; ITC's net revenue ₹20,454 cr), so from Jun 2026 revenue jumps and operating margin falls to 18%: to discuss (show net revenue, or a note). **Left:** the Chrome check (extension not connected).

**AN-17 done 11 Nov 2026** (browser check, frontend `86122be`). In Chrome on the laptop: desktop (tiles incl. the 52-week
range from stored prices, the chart, both one-off rows); the Standalone switch (table and tiles follow the basis); the
exposure card with a real ITC position (lines add up to the total). **Found and fixed at 390 px:** the page scrolled sideways
(960 px) because each filing link's screen-reader text is absolutely positioned and escaped the table's scroll box; both
scroll boxes are now `relative`. On phones the pinned label column wraps at 9rem so two quarters fit; thin dark scrollbar.
Checked after: page 372 px wide in a 372 px view, table scrolls to the latest quarter. Personal position figures are kept out
of commits and this file.

### `[ ]` AN-18 — Server reachability, then staging

- The owner runs on the VM: `curl -s -o /dev/null -w "%{http_code}\n" -A "GoldenBook-fundamentals/0.1" <one ITC filing address>`.
  `200`: the server fetches. Anything else: imports go through the upload endpoint from the laptop.
- Set `GB_FUNDAMENTALS_RAW_DIR` in staging's environment; deploy the branch to staging; import ITC there.

**Verify:** staging's page shows ITC; the answer to AN-06 is written here.

**AN-06 answered 11 Nov 2026:** from the production VM, a filing and a daily price file both answered **200**, at the same
sizes as from the laptop (58,623 and 400,839 bytes), with the self-identifying user agent and no cookies. The server fetches
filings and prices itself; the upload endpoint is only a fallback. Staging next (done, below): check `GB_ADMIN_EMAILS` is set for staging;
set `GB_FUNDAMENTALS_RAW_DIR` under `/opt/goldenbook-staging` (the only place the staging service may write); run
`deploy-staging.sh research/fundamentals`; confirm the boot and Flyway `12`-`14`.

**AN-18 done 11 Nov 2026.** The owner deployed `research/fundamentals` to staging (both repos at `d25a226` / `86122be`), with
`GB_ADMIN_EMAILS` set and `GB_FUNDAMENTALS_RAW_DIR` under `/opt/goldenbook-staging`. Boot clean in 19 s; Flyway `12`, `13`,
`14` applied on staging's database. Imported through the owner's signed-in browser session (no import screen yet, so from
the console): ITC **64 of 64 parsed**, all fetched by the staging server from NSE, 64 originals archived; quarters and metrics
identical to the laptop (trailing EPS 15.07 consolidated, 14.30 standalone). Prices 10 Nov 2025-11 Nov 2026 in six loads:
314 files loaded, 53 not published, 0 failed, about 12 minutes. Staging's ITC page renders with the 52-week range to the close
of 11 Nov 2026. Market cap and P/E show a dash there because staging's simulated brokers do not quote ITC; a fallback to the
last stored close would fill them (not built; a small follow-up for the owner to decide).

### `[ ]` AN-19 — Production, owner only

Owner approval per `memory/prod-deploy-authorization`: merge both PRs to `main`, `deploy.sh`, verify. `V12`
runs in production for the first time: confirm with the `flyway_schema_history` query in `CLAUDE.md` (the owner
runs it; Claude does not read the production database). Import ITC through the endpoint.

**Verify:** site 200, `/api/me` 401 from outside, `/api/research/stocks/ITC` 401 unsigned; the owner sees the
ITC page; a second Google account does not.

**AN-19 done 11 Nov 2026**, on the owner's word ("AN-25 then AN-19"). `research/fundamentals` merged `--no-ff` into `main` in
both repos (backend `c1111c0`, frontend `8c1ad4e`; both branches were 0 behind `main`, so the merge is the gated code) and
deployed with `deploy.sh`: 800 tests on the VM (1 skipped: the golden test, which needs the laptop's filing cache), frontend
built. Live boot: Google OIDC, open sign-up as before, no dev auth; Flyway applied `12`, `13`, `14` (0.2 s); started in 13.7 s;
`GB_FUNDAMENTALS_RAW_DIR` unset, so originals are not kept (optional to set; the production service's writable paths must
allow it). From outside: `/`, `/app/positions`, `/app/stocks/ITC`, `/app/admin/research` 200; `/api/me` and
`/api/research/stocks/ITC` 401; an import POST without a session is redirected, not served. Production holds **no
fundamentals data yet**: AN-20.

### `[ ]` AN-20 — First universe loaded

Owner decides the list (suggested: own holdings plus 30–50 liquid F&O names, general format only until AN-21).
For each: paste both NSE tabs, import, spot-check one quarter. Record the list and any failures here.

**Verify:** every listed company has its latest quarter; failures are listed with reasons.

**AN-20 started 12 Nov 2026.** On production through `/app/admin/research`: the owner imported ITC (64 quarters, March 2018 to
September 2026); a year of prices was loaded from the owner's signed-in tab (10 Nov 2025 to 11 Nov 2026: 315 days loaded,
52 not published, 0 failed, about 12 minutes). Production's ITC page shows the live price, P/E and market cap, and the
52-week range ₹252.80-₹412.00 over 248 trading days to 11 Nov 2026.

**AN-20, three more batches, 12-13 Nov 2026 (46 companies on production).** Filing links read from NSE's two listing pages
in the owner's Chrome (no file downloads, no listing API), imported one company at a time through
`/api/admin/fundamentals/import` from the owner's signed-in tab (about 2 s per filing). Non-financial Nifty 50 names only;
banks, NBFCs and insurers wait for AN-21. Checked afterwards through `GET /api/research/stocks/{symbol}` (rows = quarters
across both bases):

| Batch | Companies (rows, first to last quarter) |
|---|---|
| 1 | RELIANCE 67, TCS 66, INFY 66, HCLTECH 67, WIPRO 64, LT 70, BHARTIARTL 66, HINDUNILVR 65, MARUTI 61, SUNPHARMA 69, ASIANPAINT 69, ULTRACEMCO 64, TITAN 68, M&M 62; all Mar/Jun/Sep 2018 to Sep 2026 |
| 2 | TECHM 66, ONGC 63, NTPC 63, POWERGRID 65, COALINDIA 70, TATASTEEL 69, JSWSTEEL 67, HINDALCO 65, ADANIENT 67, ADANIPORTS 65, CIPLA 68, DRREDDY 70, BRITANNIA 68, HEROMOTOCO 66, BAJAJ-AUTO 66, APOLLOHOSP 62, BEL 64, TRENT 65 to Sep 2026; GRASIM 68 and EICHERMOT 68 to Jun 2026 (Sep results not filed yet) |
| 3 (13 Nov) | DIVISLAB 67, TATAPOWER 66, PIDILITIND 70, SIEMENS 63, DLF 63, HAVELLS 65, GODREJCP 66, DABUR 70 filings, every one parsed, none failed; all to Sep 2026. Slower tonight: about 6 minutes a company |
| Partial | NESTLEIND 22 (Sep 2023 on: NSE's results list has nothing for it between 2010 and Sep 2023, around its change of financial year); TATACONSUM 54 (Mar 2020 on); TMPV 8 (Sep 2025 to Jun 2026) |

Failures, all understood:
- **Renamed symbols are refused, by design.** Every pre-rename filing names the old symbol, and the importer refuses a filing
  whose symbol differs from the one being loaded: TMPV's 58 filings as TATAMOTORS, TATACONSUM's pre-2020 ones as
  TATAGLOBAL. **Owner decision:** accept a company's former symbols (small backend change and deploy; recommended), load
  the old filings as a separate TATAMOTORS stock, or keep TMPV from the rename on (the old company also held the
  commercial-vehicle business, now TMCV, which is not loaded).
- HCLTECH: NSE lists a second copy (`_WEB_2`) of the Mar 2019 filing that the archive does not serve (404); the main copy
  imported. LT: the two Mar 2025 integrated filings of 9 May 2025 could not be read ("Revenue or net profit could not
  be read"); the quarter is filled by L&T's refiling of 3 Jul 2025. Why the first ones fail is not yet looked at.
- LT's standalone Sep 2025 quarter is a net loss of ₹3,591 crore: as filed (exceptional item −₹5,413 crore, EPS −26.11),
  a live example for the one-off decision under AN-24.

Seen on the way: after midnight IST the stock page shows "No live price", so P/E and market cap are blank until a broker
session is live again; the last-close fallback suggested under AN-24 would cover this. Not loaded: TMCV (new listing, no
history), the rest of the F&O list. BAJAJ-AUTO lacks its consolidated Mar 2026 quarter, so its trailing figures show dashes on the
search page; re-import that filing. Also shipped 13 Nov: the Research search page and header tab (backend `dd2bc2c`,
frontend `2c87678`), the chart tooltip (`d9269a8`), loss bars below the zero line and no Filing row (`0b184c1`).

**AN-22 done 11 Nov 2026.** `V13`: `price_eod` (raw prices as traded, EQ only, keyed by **NSE symbol** and date, because the
file covers every listed stock, not only loaded companies; **not partitioned**, as about 700k rows a year does not need it yet)
and `price_eod_file` (one row per daily file). `fundamentals/prices/`: `Bhavcopy` (columns by name, trading date from inside
the file, refuses mixed dates or high below low), `PriceLoadService` (weekdays, the same fetcher; 404 = not published, not
recorded), `PostgresPriceStore` (batched upsert; `summary` = latest close and 52-week high and low, with the days loaded).
`POST /api/admin/prices/load {from, to}`: owner only, at most 62 days, not in the future. The stock API gains `price`; the
page's 52-week tile shows the range, and "From N trading days since ..." until the window holds about a year.
**Real run:** 22 files for 12 Oct-10 Nov 2026 in 51 s: 54,221 rows, 20 trading days, 2,819 stocks; the same range again was
all already loaded. **Finding:** a holiday's file (20 Oct, 10 Nov) carries the previous trading day; dating rows from inside
the file handles it. ITC's stored days chain exactly (each prev_close equals the previous close). A year of prices is about
six calls of 62 days, a minute and a half each.

**AN-22 year backfill, 11 Nov 2026** (`d25a226`). Six 62-day loads from the laptop: 249 trading days, 615,307 rows, no
failures; ITC's 52-week range ₹252.80-₹412.00 over 249 days (the high is Nov 2025, before the Jan 2026 fall).
**Finding, fixed:** NSE trades on some Sundays (Union Budget, Sun 1 Feb 2026; Diwali Muhurat, Sun 8 Nov 2026); the loader
tried weekdays only, so those sessions were missing and the next day's previous close pointed at nothing. It now tries every
calendar date. NSE also publishes a Sunday-named file each week that repeats Friday (harmless: rows are dated from inside the
file); Saturdays have none. After the fix ITC's price chain has 0 breaks. **Lead for AN-23:** 475 breaks remain across 427 of
~2,800 stocks, days where NSE's stated previous close differs from the stored close. That is the signature of an ex-date
adjustment (dividend, split, bonus), so the price files may themselves reveal corporate actions. Not verified yet.

**AN-24 done 11 Nov 2026.** `V14`: `stock_metric` per company and basis (trailing four-quarter revenue, net profit and EPS;
growth over the four before; latest quarter against a year earlier; operating margin). `StockMetrics` is pure: four or eight
**consecutive** quarters or null, and no growth from a loss or zero. `StockMetricsService` rebuilds after **every** import
(which also backfills) and after a stored upload; its failure is logged, never the import's. Checked on ITC: latest-quarter
net profit -18.46% consolidated and -20.13% standalone (ITC reported -18.5% and -20.1%); trailing EPS 15.07, as on the page;
margins checked by hand in the db test. **Two owner decisions** before a screener uses these: (1) ITC's revenue includes
cigarette taxes from Jun 2026, so revenue growth (+24%) and margin (18%) are distorted: show net revenue, or a note;
(2) trailing profit growth (-45.6%) compares with a year holding the hotels demerger gain: exclude discontinued operations
and exceptional items from growth, or show it as filed.

### `[ ]` AN-25 — Owner import page (proposed 11 Nov 2026)

Requested by the owner after AN-18, where the import ran from the browser console: a simple file upload instead. Frontend only;
uses the existing owner-only endpoints, no backend change. Assumed meaning, to confirm: upload NSE's exported list file(s)
rather than paste text; uploading filing documents themselves is box 3.
- Page `/app/admin/research`, linked from `/app/admin`; owner only (a non-owner gets the same 404 the endpoints give).
- **Import results:** symbol field; choose or drop NSE's exported file(s) (both tabs, `.csv`/`.txt`, at most 1 MB, read in the
  browser); a preview line ("64 filings found, 57 rows without a file"); Import; progress text ("about 2 minutes for new
  filings"); then a table of each filing's outcome with the reason for any failure.
- **Load prices:** from/to dates, defaulting to the day after the last stored day through today; the page splits the range into
  62-day calls itself and shows progress per call.
- **Upload one filing (fallback):** an `.xml`/`.html` file plus its NSE address, to `/api/admin/fundamentals/upload`.
- Pure helpers with tests: reading the file into addresses (count, rows without file), and splitting a date range.

**Verify:** typecheck, `npm test`, build; in Chrome on the laptop, import a second stock from its two exported files and load a
week of prices from the page; a non-owner session sees a 404.

**AN-25 done 11 Nov 2026** (frontend `594520e`). `/app/admin/research`, linked from `/app/admin`: Import results (symbol +
NSE's exported list files, read in the browser, at most 1 MB, preview of filings found, outcome table with failures first and a
link to the stock page); Load prices (date range, default the last 7 days because no endpoint gives the last stored day; the
page cuts it into 62-day calls and shows each outcome); Upload one filing (fallback). Owner only through the status endpoint's
guard. `lib/api.ts` gains a raw-body option for the upload. Helpers in `features/research/importTools.ts` with tests. Checked in
Chrome on the laptop: a one-filing list imported (1 parsed), a week of prices (5 already loaded, 1 not published, 1 loaded),
and with no owner configured the page reads "Not available" and the import 404s. Gates: typecheck, `npm test` 183, build.

### Stock page sections beyond quarterly results (agreed 14 Nov 2026)

Discussed with the owner on 14 Nov 2026, ranked by value against how hard the data is. The owner said to start with AN-26.
Order: AN-26, AN-27 (no new data; they make the page useful to F&O traders), then AN-28 from the quarters already stored,
then AN-29 and AN-30 (new data and parsers), and AN-31 once more companies are loaded. Corporate actions stay AN-23.
Open with the owner: one long page or tabs (Overview, Results, Ownership, Price) once the page has more than four sections.

- **AN-26 Price chart with volume and delivery %.** From `price_eod` (a year is stored; the daily file also carries delivery
  quantity and %, which most screeners do not show). A read endpoint for one stock's daily rows; close-price chart with
  1M/3M/6M/1Y ranges; volume bars split into delivered and not delivered; delivery % against its own average. Prices are as
  traded, not adjusted for splits or bonuses until AN-23, and the page says so.

  **AN-26 1Y done 14 Nov 2026** (branch `research/price-chart` in both repos; production deploy on the owner's word, "A,
  take 1Y to prod first"). `GET /api/research/stocks/{symbol}/prices` → `{symbol, adjusted: false, days[]}`, the stored days
  in the 365 up to the latest (`PriceStore.lastYear`), same audience and bare 404 as the stock endpoint, 200 with no days
  when none are stored. Frontend `features/research/PriceSection.tsx` + pure `prices.ts`: 1M/3M/6M/1Y; close as an area
  line, **green when up over the shown range and red when down** (owner's choice over neutral grey, gold or blue); volume
  bars split delivered / traded-not-delivered on the same date axis (two panels, never two scales); a readout above that
  follows the crosshair and rests on the latest day; delivery % latest vs 20-day vs range average; heading shows change
  over the range and the **intraday** low and high (they can sit outside the closes the line draws: ITC's 1M low ₹252.80
  on 28 Oct closed at ₹259.50). Month labels once per month for 6M/1Y. Checked on the laptop in Chrome (ITC, desktop and
  390 px); gates: backend 804, frontend 200, typecheck, build.

  **AN-26b pending — 3Y, 5Y and Max (agreed 14 Nov 2026, next after the 1Y deploy).**
  - **How far back:** probed 14 Nov from the laptop with a self-identifying user agent: `sec_bhavdata_full_DDMMYYYY.csv`
    answers 200 for 15 Oct 2019, 1 Nov 2019, 13 Nov 2020, 12 Nov 2021, 14 Nov 2023, and 404 for every date tried from
    Jan to 16 Sep 2019 and in 2016 and 2018. So about seven years: 3Y, 5Y and **Max (from Oct 2019)**. The first exact
    day between 16 Sep and 15 Oct 2019 is not pinned yet.
  - **10Y is not in this file.** Before Oct 2019 only NSE's older bhavcopy exists (different format, zipped, no delivery
    columns): a separate loader, later, if wanted.
  - **Backfill:** about 1,550 trading days, Oct 2019 to Nov 2025, through `POST /api/admin/prices/load` from the owner's
    signed-in tab (62 days per call, about 30 calls, about an hour at the last load's pace; stop before midnight IST, when
    the session ends). Adds roughly 4-5 million `price_eod` rows (every EQ symbol); **check the VM's free disk first**
    (ask the owner to run `df -h` on the VM, or get approval to run it). Not partitioned; revisit if it grows past that.
  - **Split and bonus adjustment without AN-23:** on an ex-date NSE's file prints an *adjusted* `PREV_CLOSE`. The factor
    for each day is `stored close of the previous trading day / that day's prev_close`; where it differs from 1 beyond
    rounding (say more than 0.5%), multiply every earlier price (and divide earlier volumes) by it. Computed when read,
    prices stay stored as traded. Dividends are not adjusted this way (NSE does not adjust prev close for them); say so.
    Flip `adjusted` to true on the response when applied. Test with a known split or bonus in the window.
  - **Chart:** add 3Y, 5Y, Max; above one year send or draw **weekly** points (last close of the week, summed volume and
    delivered quantity), so about 350 points rather than 1,700; the endpoint takes a range or a `from` date.

  **AN-26c daily prices, in production 14 Nov 2026** (branch `research/daily-prices` in both repos, backend
  `23b817d`, frontend `8da7656`; merged `c6fbaa3` / `9f34e42`). `PriceDailyJob` runs at 19:30, 21:30 and 08:00 IST every
  day (weekends too: NSE's special sessions) and loads every date from the day after the newest stored file
  (`PriceStore.lastFileDate`, the max `price_eod_file.file_date`) to today through `PriceLoadService`, so a missed run, a
  restart or a late file is caught up and a repeat does nothing; a holiday stays "not published". A gap over 62 days loads
  the latest 62 and says so (older days are an owner load). On unless `GB_PRICES_DAILY=false`; to keep it off on the laptop
  set that in the user environment; **staging runs it too** once deployed there. `GET /api/admin/prices/status` (owner only)
  → newest file, on/off, last run; one line on `/app/admin/research` above Load prices, red when off, failed or gapped.
  Verified: unit tests for catch-up, not published, up to date, empty store, gap, failure; DB test for `lastFileDate`;
  the local backend boots with the job wired and the status endpoint answering. Gates: backend 810, frontend 210, build.
  Production prices were loaded by hand to 13 Nov on 14 Nov.
- **AN-27 Results-day moves.** For each of the last eight results: the approval date (`filing.approved_on`), the close
  before and the next trading day's close, the move in % and against the stock's typical daily move. The section closest to
  GoldenBook's purpose: does this stock move a lot on results? One query over data already stored.
- **AN-28 Annual profit and loss.** Ten years of revenue, profit and margins; 3-, 5- and 7-year growth. First as the sum of a
  financial year's four stored quarters (only when all four are there); later, the March filing's own full-year column,
  which needs the filings fetched again (production does not keep the originals).

  **AN-28 done 14 Nov 2026, in production** (frontend `7ce1edb`). `features/research/annual.ts`: a year is the sum of its
  four stored quarters, only when all four are there and consecutive; the year end is the company's own (commonest month of
  its audited quarters, March by default; Siemens September); at most ten years plus TTM when the latest quarter is not a
  year end; the quarterly table's rows reused, so lines a quarter did not state are a dash. EPS is the sum of quarterly EPS.
  Growth: revenue and net profit compounded over 3, 5 and 7 full years; a dash with a loss at either end. ITC consolidated
  shows FY20-FY26 + TTM (FY19 is incomplete: quarterly consolidated results were mandatory only from April 2019).
  **Fix merged, not deployed** (frontend `ca60c77` on `main`; the deploy was held for the owner's go-ahead): growth must start
  at the year exactly N years back, found by date. Counting back along the list stretched BAJAJ-AUTO's "3 years" across its
  missing FY23 (FY22 to FY26). Until deployed, production's growth is wrong for stocks with a missing year.
  **BAJAJ-AUTO, 14 Nov:** its Mar 2026 filing names the company BAJAJAUTO; the importer now compares symbols on letters and
  digits only and stores under the symbol being loaded (backend `c7fb6ca`, `f515cbe`, in production). The Mar 2026 quarter
  imported; P/E 23.1. Its FY23 gap is NSE's, not ours: NSE's results list has no row at all for the 30 Jun 2022 quarter
  (checked 14 Nov under Quarterly, Half Yearly, Annual and Others), so FY23 and 3-year growth stay dashes. **Owner: leave
  it for now (14 Nov).**

  **AN-28b, later (agreed 14 Nov 2026): yearly figures from the March filing itself.** Each March-quarter filing carries the
  full financial year beside the quarter (XBRL context `FourD`, 12 months; the integrated HTML has a "year ended" column),
  as the Sep filing carries the half year (`FourD`, 6 months: Bajaj's Sep 2022 file has Apr-Sep and Jul-Sep). Read the
  12-month column and store it as a yearly row (new table or a `period_months` on the result), and show those years in
  place of summed quarters. Fixes years with a quarter NSE never published (BAJAJ-AUTO FY23, June 2022 missing) and gives
  the company's own annual EPS instead of the sum of quarterly EPS. Cost: parser change and a re-import of each company's
  March filings (about 8 per company) because production does not keep originals. Fallbacks considered and not chosen:
  June = half year − Sep quarter from the Sep filing; or fetch the missing filing from BSE (needs BSE addresses allowed).
  **Deployed 14 Nov 13:10 IST:** the growth fix and AN-26c (backend `c6fbaa3`, frontend `9f34e42`); BAJAJ-AUTO now shows
  3-year growth as a dash, 5-year 17.8% revenue / 16.8% profit; the price status reads daily load on, latest file 13 Nov.
- **AN-29 Shareholding pattern.** Promoter, foreign institutions, domestic institutions, public, and promoter pledges, each
  quarter. A new NSE filing type: new tables, a parser, IDs read from NSE's listing page in Chrome as for results.
- **AN-30 Balance sheet and cash flow.** Half-yearly, filed with the September and March results. Enables debt, cash, ROE,
  ROCE and free cash flow. The largest parser job.
- **AN-31 Peers and upcoming events.** Peers needs NSE's industry classification; the next results date comes from board-
  meeting notices, so a trader can see whether results fall before expiry.

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
