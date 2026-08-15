# MoneyPlant — working context

**Regenerated from the code on 11 Aug 2026.** This file is code-truth and current state, not chat history. Closed items and the reasoning behind decisions have been cut: they live in git, in `tradestack/docs/adr/` (0011–0021, 0025), in `SPEC.md`, and in `memory/`. Regenerate this file when the architecture shifts; do not let it accumulate a changelog again.

**`memory/` — read `memory/MEMORY.md` at the start of any non-trivial task.** It is the project memory: one file per durable decision or piece of project state, carrying the *reasoning* this file deliberately cuts. This file answers "what is true of the code now?"; `memory/` answers "why did we choose this, and when?". Keep the two from overlapping, and add a memory whenever a decision is made that a future reader would otherwise have to reverse-engineer from a diff.

**Companion docs.** `SPEC.md` — the Step 4 plan, and the authority for it. `CREDENTIALS-STEP3D.md` — per-user broker credentials. `UX-STEP2.md` — UI rework. `tradestack/docs/symbol-model.md`, `aliceblue-api.md`, `paytm-api.md`. `tradestack/deploy/README.md` — deploy runbook. `research/` — regulatory and IP findings. **`DEPLOY-STEP3.md` was deleted in `84bd89b`;** `SPEC.md`, `CREDENTIALS-STEP3D.md` and `research/REGULATORY-API-STATIC-IP.md` still cite it and those references now dangle.

---

## Where things stand

**Live at `https://moneyplant.bonamnikhilbabu.in`.** Cloudflare DNS (grey cloud) → OCI static IP → Caddy → `/var/www/moneyplant` for the SPA, `:8080` for the API. Google sign-in, Postgres on the VM via `deploy/docker-compose.yml`, and the Kite prod redirect all work end to end. Steps 1, 2, 3 (a–d) and 5 are done and deployed.

**Both working trees are clean and everything is pushed.** `main` has not moved in either repo since 7 Aug:

```
tradestack  main 84780c2 = origin/main
  └ 6 commits on feat/db-sessions → 5580c89   pushed
frontend    main 9d9a331 = origin/main
  └ 3 commits on fix/pledged-holdings → 11ad149   pushed
```

`fix/pledged-holdings` has no tracking config in either repo, so `%(upstream:track)` prints blank for it — that reads as unpushed but is not. Answer "is anything unpushed?" with `git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/`, then confirm untracked branches with `git ls-remote`.

**Gates green:** backend `mvnw test` 364 passing; frontend `npm run typecheck` clean; frontend `npm run build` passing.

### Latest additions (15 Aug 2026 — `feat/heuristic-margin-engine`)

- **Bottom-Up Heuristic Margin Engine:** Pure-domain calculator (`com.MoneyPlant.tradestack.risk.HeuristicMarginEngine`) implementing SEBI/NSE exchange-level SPAN + Exposure margin formulas and vertical spread/strangle offsets offline.
- **Dual-Mode Margin Allocation:** `MarginAllocator` dynamically uses the top-down broker bill when available (`MarginBasis.EXACT`), and falls back to bottom-up heuristic calculation when missing (`MarginBasis.ESTIMATED`).
- **Visual Options Strategy Designer (Step 6):** Complete interactive strategy builder at `/app/payoff` (Strategy Builder tab) featuring:
  - 10+ standard NSE option strategy recipes (Bull/Bear Call/Put Spreads, Straddles, Strangles, Iron Condor, Iron Butterfly) generated around ATM spot with canonical strike intervals.
  - Interactive multi-leg editor with strike/lot stepper controls, Buy/Sell pills, and individual leg disable/enable toggles.
  - Real-time simulation API (`POST /api/payoff/simulate` and `GET /api/payoff/metadata`).
  - Target Spot Inspector (interactive slider across $\pm 10\%$ of spot with real-time expiry P&L probe).
  - Bottom-up SEBI margin & total capital breakdown with hedge benefit badges.
  - "Open in Strategy Builder" bridge to import live held positions into the builder for what-if hedging experimentation.

### Step 4 — what is actually built

`SPEC.md` plans four sub-steps: **4a foundations → 4b InstrumentKey → 4c snapshots and the freshness contract → 4d risk module**, each meant to be independently mergeable. **4a landed as three commits. 4b, 4c, 4d and the dashboard rework then landed together as one commit, `risk analysis`,** in both repos — 39 files backend, 12 frontend. That is the un-splittable commit the plan was written to avoid. It is still on an unmerged branch, so a rebase-split before merging remains possible, but it is no longer free.

**Four shortfalls against the sub-steps' own acceptance criteria, all verified in the code:**

- **Snapshot-first reads are not wired.** `PositionsController:23` still calls `brokers.allPositions()`; `SnapshotService`'s only consumer is `RiskService`. The portfolio endpoints always report `Freshness.LIVE`. D10 and ADR 0016 are unmet.
- **Nothing migrates `raw_capture` into the typed tables** — the entire justification for shipping dumb capture early. `SnapshotService`'s live fallback is the only writer to `position_snapshot` and it writes `raw = "{}"`, contradicting 4c's "reconstructible from `raw`". `holding_snapshot` and `margin_snapshot` have **zero rows and no write path**.
- **ADR 0012 leaks.** ArchUnit A2 checks only *direct* dependencies of `..risk..`, so it passes — but `RiskService` → `SnapshotService` → `BrokerService` fires a live broker call inside a risk request. **Widening A2 to transitive reach belongs with whatever lands 4c.**
- **Two of D9's four risk features are stubs.** `RiskService:42` returns `List.of()` for decay; margin & capital utilisation is absent from `RiskSummaryReport` entirely. Exposure and expiry bucketing are real and unit-tested.

4b is shallower than its acceptance says: `InstrumentKey` exists with tests but is referenced only inside `instrument/`, and the DTOs still carry symbol strings.

**Deferred, knowingly:** D11 (generated TS types, CI) entirely — neither repo has any CI, and there is no PR template despite the branching rules below citing one. ADR 0021 and frontend 0022 are *accepted but unimplemented*, both waiting on that CI. `step/4a-frontend` (code splitting, persisted query cache, lint rules) was never done.

### Next

**Verified against live data 15 Aug 2026, app connected to all three brokers.** What works end to end: `raw_capture` fresh for all three (`capture_run` all `CAPTURED`), `margin_snapshot` migrating exactly — every row matches its archive payload to the paisa — and `spot_snapshot` filling across 8 underlyings. Kite's `span + exposure + optionPremium = debits` holds to 0.0000 on live data; Alice Blue's is out by 1.6 paise, which is the documented float32 artefact, not a discrepancy.

1. **`position_snapshot` is frozen at 11 Aug while the archive is current — fix first.** `raw_capture` positions are fresh (17:34 today, Kite 16 net legs) but the typed table still holds 11 Aug rows, so **`/api/risk/summary` computes everything on four-day-old positions** while `/api/positions` serves live. It is honest about it (`Freshness.STALE`) but will never self-correct: `SnapshotService.getPositions` only falls back live when the table is *empty*, and nothing migrates positions. Worse than uniformly stale — the page now mixes *today's* margins and spot with 11 Aug legs, so the margin allocation divides a current bill across old strikes. The fix is `MarginBackfillService` copied for positions (the parsers already exist), **and it must change `findLatestPositions` to `distinct on (connection_id) … order by captured_at desc, id desc`** — migrated rows carry per-connection timestamps, and the current `= max(captured_at)` form returns one broker and silently drops the rest (measured).
2. **Verify Kite's basket margin against a live token.** `getCombinedMarginCalculation` is implemented in the gateway but deliberately unwired, with no schema, until one real response is seen. It logs `initial/final/benefit` on every call. Confirm `considerPositions=false` is the right reading and that `final.total` lands near the account's real `used`, then wire it and add the migration.
3. **Merge the stack into `main`** — now thirteen commits across two repos, overdue.
4. **Finish 4d:** the decay series. Margin & capital utilisation is **done** (D9 stub closed).
5. `holding_snapshot` still has zero rows and no writer — the same backfill shape as positions.
4. **Opportunistic, next time a broker is connected:** does Alice Blue forward unknown query parameters? If so `AliceBlueSessionService.loginUrl(state)` becomes a one-liner and `PendingConnect.consumeSolePendingFor` becomes dead code — Alice Blue is its only user.
5. **The real prize, still unclaimed: verify Alice Blue's option chain** (`POST /obrest/optionChain/getOptionChain`). Per-strike `ltp` and `oi` at no extra cost would unblock Step 6 and most of Step 8; `SPEC.md` D9 makes it the gate for greeks.

### The risk page — three things to settle before designing it

1. **D9 contradicts ADR 0012 on margin data.** D9 calls margin utilisation ready *"immediately — `/api/margins`"*; 0012 forbids `risk/` from touching `broker/`. Under 0012 risk must read `margin_snapshot`, which has zero rows. Not ready; blocked behind a writer that does not exist. (`margin_snapshot` also drops `total` deliberately, as derivable.)
2. **No formula is defined anywhere for capital utilisation** — the only one of the four features with no stated arithmetic. The dashboard uses `used / (available + used)`, which at least gives the risk page something to agree with.
3. **`ExposureCalculator` computes option exposure as `qty × ltp`** — premium value, not notional, not delta-weighted. For a short option that understates risk enormously. It also buckets `concentrationByType` on `product` (NRML/MIS), not CE/PE/FUT. Both are modelling decisions, not bugs to fix silently.

---

## What this is

Options trading stack for NSE F&O. The core value is **multi-broker position aggregation** (Kite + Alice Blue + Paytm Money) with payoff graphs, because Alice Blue and Paytm lack decent position visualisation.

**A real product, not a personal tool** (decided 29 Jul 2026): a limited number of users, run safely, on minimal infrastructure cost. Prefer the OCI always-free tier and Postgres on the same VM over managed services.

The owner wants **guided coding, not full dumps** — but will ask for full code on specific methods. Career switch is priority #1.

## Repos, branching, gates

```
C:\Projects\Moneyplant\
├── tradestack\   Java 21 + Spring Boot 4.1.0 + Maven   (backend, :8080)
└── frontend\     React 18 + Vite + TS + Tailwind + shadcn/ui (:5173)
```

Two separate git repos (`bnmnikhil/MoneyPlant`, `bnmnikhil/MoneyPlantFrontend`), plus the directory above them, which is itself a repo holding this file and the design docs.

Trunk-based, short-lived branches; **the branch name is identical in both repos** when a step spans them, so the two PRs are obviously a pair. Squash merge into `main`. **Never merge red:** backend gate `mvnw test`, frontend gate `npm run typecheck`. `dev` deliberately does not exist.

- **`npm run lint` does not work** — the script is in `package.json` but `eslint` is not in `devDependencies`. `typecheck` (= `tsc -b`) is genuinely the only frontend gate. `npm run dev` does not typecheck, so it is the only thing that catches contract drift against the backend.
- The backend has a **`db`-tagged Testcontainers suite excluded by default** (`mvnw test -DexcludedGroups=`, Docker required). It is the pattern for repository tests and **is not being followed** — `TypedSnapshotRepository` shipped with no repository test, and `CaptureRepositoryTest` has never run as a suite.
- **"Delete the branch" is not being honoured, by choice.** Every merged branch is still local and on the remote (12 in `tradestack`, 12 in `frontend`), plus `origin/V1` and `origin/V2--payoff-graph-one-broker`.

## Local development

- **PostgreSQL 16 on port 5433** (`winget install PostgreSQL.PostgreSQL.16 --force`; the plain install 403s partway through EDB's CDN). Installed unattended, so the superuser password is winget's default `postgres`. Role/database `moneyplant`/`moneyplant`, owner `moneyplant`.
- A pre-existing **PostgreSQL 17 holds 5432**, set to Manual and stopped to save memory. `Start-Service postgresql-x64-17` if anything wants it.
- `MP_DB_URL=jdbc:postgresql://localhost:5433/moneyplant` and `MP_CREDENTIAL_KEY` (32 random bytes, base64) are in the **user** environment. **`setx` only affects new processes** — a shell or editor started before it was run still dies at startup naming `MP_CREDENTIAL_KEY`. That is the guard working.
- **Docker is deliberately not used locally.** Docker Desktop's WSL2 VM costs ~2 GB before Postgres starts, which is the wrong trade on an 8 GB laptop already running Chrome, an editor, Vite and a JVM. The VM *does* use Docker, so the next service (Redis, probably) is one more block there rather than a second deployment style. Same real Postgres either side; only `MP_DB_URL` differs.
- Local Flyway history: **V1–V7 all applied and `success`.** `V5`–`V7` have run **only** here — a fresh VM runs the three in sequence for the first time at deploy. `V6` exists only because `V5` had already been applied and could not be edited.

**`raw_capture` is the best source of vendor payload truth in the project** — better than either vendor doc. Read it before guessing at any payload:

```
"/c/Program Files/PostgreSQL/16/bin/psql.exe" -h localhost -p 5433 -U moneyplant -d moneyplant \
  -c "select broker_id, jsonb_pretty(raw) from raw_capture where kind='margins' order by captured_at desc"
```

All three brokers were connected on 11 Aug and every kind captured cleanly (~7 rows each per kind, all `capture_run` rows `CAPTURED`).

**Kite's archive is not Kite's bytes.** Alice Blue and Paytm hold their parsed responses. The Kite SDK parses with Gson and discards the JSON, so `raw()` re-serialises the SDK's models with Jackson — **SDK field names, not wire names** (`tradingSymbol`, never `trading_symbol`), and anything the SDK does not model is already gone. ADR 0013 states this; `KiteRawCaptureTest` asserts it. A backfill must expect SDK names.

---

## Backend architecture (locked — do not relitigate)

Package-by-module under `com.MoneyPlant.tradestack`:

| Package | Contents |
|---|---|
| `broker/` | `BrokerGateway`, `BrokerAuthProvider`, `BrokerRegistry`, `BrokerAuthRegistry`, `BrokerService`, `ConnectionService`, `ConnectionIds`, `BrokerSession`, `SessionStore`/`PostgresSessionStore`, `PendingConnect`, `SessionController`, `RawPortfolioSource`, `PortfolioKind`, `PortfolioFetchedEvent`, the exceptions |
| `broker/kite/`, `/aliceblue/`, `/paytm/` | private per-broker gateway, session service, session controller, mapper, http config |
| `portfolio/` | thin controllers (`Positions`, `Holdings`, `Account`) + `dto/` — `BrokerAggregate`, `BrokerWarning`, `PositionDto`, `HoldingDto`, `MarginDto`, `Freshness`, `Sourced` |
| `instrument/` | `InstrumentService`, `InstrumentKey`, `BrokerInstrument`, `OptionInstrument`, `InstrumentType`, `UnderlyingRegistry`, `InstrumentController` |
| `analytics/` | `PayoffEngine`, `PayoffService`, `PayoffController`, `Leg`, `PayoffResult` |
| `marketdata/` | `SpotPriceService`, `SpotPriceProvider` |
| `snapshot/` | `CaptureService`, `CaptureRepository`, `EodCaptureJob`, `OnFetchCapture`, `SnapshotService`, `TypedSnapshotRepository`, `SnapshotConfig` |
| `risk/` | `RiskService`, `RiskController`, `ExposureCalculator`, `ExpiryBucketer` + four report records. Reads `SnapshotService`, never `broker/` — but see the transitive leak above |
| `credential/` | `BrokerCredentials`, `CredentialCipher`, repository, service, controller, two exceptions |
| `auth/` | `SecurityConfig`, `AllowedEmails`, `AuthController`, `CurrentUser` |
| `common/` | `ApiExceptionHandler`, `RequiredConfig`, `BrokerJson` |
| `arch/` *(test)* | ArchUnit A1–A5: `SdkContainmentTest`, `DependencyDirectionTest`, `ControllerBoundaryTest`, `FanOutScopingTest`, `StatelessGatewayTest`. All in the normal build |

`snapshot/` depends on `broker/`; `broker/` does not depend on `snapshot/`. `BrokerService` publishes `PortfolioFetchedEvent` and knows nothing about capture, so no gateway call acquires a database side effect.

### Patterns and the rules that make multi-broker work

- **Strategy** — `BrokerGateway` is the per-broker interface. **Adapter / anti-corruption** — each gateway owns private `toDto` methods; broker SDK types never leak past it. **Registry** — `BrokerRegistry` auto-discovers gateway beans via constructor `List<BrokerGateway>`, so a new broker needs zero changes there. **Facade** — `BrokerService` owns resolve-connection-then-call; controllers only talk to `BrokerService`.
- **`RawPortfolioSource` is a second interface, not a wider `BrokerGateway`.** All three gateways implement both. A raw-payload method on `BrokerGateway` would put a vendor-shaped leak in the one place the anti-corruption rule exists to keep clean.
- **Gateways are stateless.** `BrokerSession` is a *parameter*, never a field; `KiteBrokerGateway` builds a fresh `KiteConnect` per call. This is what enables multi-user and multi-account-per-broker.
- **Credentials are a parameter too**, for the same reason: `BrokerAuthProvider.loginUrl(BrokerCredentials, state)`. That is what lets one set of beans serve two users whose Kite apps differ.
- **`ConnectionService` is keyed by `connectionId`**, formatted `{userId}:{brokerId}:{label}` where userId is Google's `sub` (never the email — connectionId reaches the browser inside warnings and exception messages). `allFor(userId)`; the unscoped `all()` was removed rather than kept alongside. `session(connectionId)` also checks ownership.

```java
public record BrokerSession(
    String connectionId, String brokerId,
    Map<String, String> tokens,   // kite→{accessToken,publicToken}, aliceblue→{userSession}
    Instant createdAt
) { public String token(String key) { return tokens.get(key); } }
```

The `Map<String,String> tokens` deliberately absorbs per-broker token shapes. **Do not replace it with typed fields.** It also carries `apiKey`, and `BrokerSession` additionally carries `accountLabel` (the account the broker authenticated) and `credentialLabel` (which registration authorised the login).

### Sessions and credentials in Postgres

**Sessions persist, encrypted** (ADR 0025). `PostgresSessionStore` replaced `FileSessionStore` and its plaintext `~/.moneyplant/sessions.json`, both **deleted**. The seam sits at `ConnectionService`, not in `broker/paytm`, because that service is already the single `connectionId`-keyed chokepoint and naming a broker there would break "a new broker needs zero changes". Why it exists at all: Paytm's login is a password *and* an OTP every time, issuing three access tokens and **no refresh token**, so there is no renewal path — while Kite and Alice Blue re-auth is one button.

- Only sessions created **today in IST** are restored — stricter than any broker's real expiry, because restoring a dead token gives a confusing 401 while expiring early costs a login the user was making anyway. A restart across an IST date boundary costs a login, by design.
- Unreadable rows fail closed to "no sessions" — a re-login, never a failed startup.
- The token map is sealed with the same key as credentials, so **`MP_CREDENTIAL_KEY` now protects live logins**, not just the ability to start one. A Paytm access token can place orders.

**Credentials are per user, per broker, per registration.** `broker_credential` keyed `(user_id, broker_id, label)` — not by connectionId, because one Kite Connect app can authorise two different Zerodha logins. Still **no `users` table**: `MP_ALLOWED_EMAILS` governs sign-in and rows key off the Google `sub`. `JdbcClient` + Flyway, not jOOQ — codegen is not worth a build step for two tables.

The two halves are split by sensitivity: `apiKey`/`appCode` is an identifier that already travels in login URLs, so it is resolved at connect time and rides in `BrokerSession.tokens`; `apiSecret` is read from the encrypted store **only at session creation** — never in a session, never in a response, never logged. `BrokerCredentials.toString()` is overridden so a stray `log.info("{}", creds)` cannot leak it.

**AES-256-GCM, key in `MP_CREDENTIAL_KEY`, never in the database.** GCM over CBC because it is authenticated: a tampered ciphertext, tampered IV or wrong key fail loudly instead of yielding plausible garbage that would be handed to a broker as a secret and come back as "invalid auth code". **A fresh random IV per seal is not optional**; reuse under one key voids the guarantee. `CredentialCipherTest` spends most of its assertions there.

**Each user registers their own developer app at each broker.** There is no app-level registration for any broker any more, which removes the question of whether one registration may serve several users, and removes the one-redirect-URL-per-registration bottleneck. The cost is onboarding effort, **not money** — Kite Connect's **Personal tier is ₹0** and covers every endpoint this app calls; the ₹500/month Connect tier only adds WebSocket and historical candles, which the app does not use (spot comes from Paytm).

### Deliberately not built yet

`BrokerConnection` entity → Postgres (Step 7). Saved strategies (Step 6) are what will give the rest of persistence something to hold.

---

## API contract

**Read endpoints return `BrokerAggregate<T>`, not bare lists.**

```json
{ "items": [...], "warnings": [{ "brokerId", "connectionId", "code", "message" }] }
```

`code` is `SESSION_EXPIRED` (reconnect required) or `CALL_FAILED` (transient — do not tell the user to reconnect). **Partial success is the normal case and returns 200:** if Kite responds and Alice Blue's token is dead, you get Kite's rows plus a warning. A non-200 means the whole request failed, which is genuinely different.

| Method | Path | Returns |
|---|---|---|
| GET | `/api/positions`, `/api/holdings` | `BrokerAggregate<PositionDto|HoldingDto>` |
| GET | `/api/margins` | `BrokerAggregate<MarginDto>` — **one row per connection**, frontend sums |
| GET | `/api/risk/summary` | `RiskSummaryReport`; decay series is `[]` server-side |
| GET | `/api/me` | `{email,name,picture}` from the OIDC principal; 401 when absent |
| POST | `/api/logout` | 204. Served by Spring Security, not a controller |
| GET | `/api/session/status` | `{brokers:[brokerId], connections:[{connectionId,brokerId,accountLabel,credentialLabel,connected}]}`, caller-scoped. `brokers` is **the brokers this user has credentials for**, not the registry |
| GET | `/api/session/login-url` | `?brokerId=` + optional `?label=`. `{url}`. **Mints the connect nonce** — the authenticated moment the callback depends on — and parks the resolved label with it. Resolves the broker *before* the credentials, and mints the nonce last, so a refused attempt strands no pending flow |
| GET | `/api/broker-credentials` | One row per **registration**: `{brokerId, label, apiKey, configured}`. Unconfigured brokers appear with `configured: false` — the settings screen needs the empty form. **Never returns a secret, not even masked** |
| PUT/DELETE | `/api/broker-credentials/{brokerId}[/{label}]` | Upsert / delete → 204. Both values always required, both trimmed. Omitted label means `default` |
| GET | `/api/payoff` | `CurveRef[]` — `{connectionId, brokerId, underlying}` per plottable curve |
| GET | `/api/payoff/{underlying}?connectionId=` | `PayoffResponse` incl. `brokerId`, `connectionId`, `spot` |
| GET | `/api/debug/instrument?symbol=`, `/api/debug/symbols` | `OptionInstrument`, symbol-model debug |
| GET | `/{kite|aliceblue|paytm}/callback` | public by necessity; attributed by nonce. Redirects to `${app.frontend-url}/app`, or `/app?error=…` |

**Frontend mirrors these exactly in `src/types/api.ts`. The TS types are the contract — keep the two in sync.**

**Broker callbacks are `permitAll()` and must stay that way.** 3a briefly made them authenticated and it broke the connect flow outright: the session cookie does not survive the broker's cross-site redirect (measured: `present=false`). Attribution is a single-use nonce minted in the authenticated `login-url` — Kite carries it in `redirect_params`, Paytm in its native `state`; **Alice Blue can carry nothing** and falls back to "exactly one pending flow for this broker, or refuse".

### Error codes (whole-request failures only)

Only single-connection endpoints (payoff) produce these; aggregate endpoints turn per-broker failure into warnings.

```
BrokerException (abstract: brokerId + code)
├── BrokerSessionException       BROKER_SESSION_EXPIRED   409   "Reconnect"
├── BrokerNotConnectedException  BROKER_NOT_CONNECTED     409   "Connect"
└── BrokerCallException          BROKER_CALL_FAILED       502   retry, say nothing

standalone, from credential/:
    MissingCredentialsException     BROKER_NOT_CONFIGURED        409   "Go to Settings"
    CredentialDecryptionException   BROKER_CREDENTIAL_UNREADABLE 409   "Enter it again"
```

Body is `{error, brokerId, message}`; `brokerId` may be null, which is why the handler builds a `HashMap` rather than `Map.of`. Frontend mirrors this in `BrokerErrorBody` and fires `moneyplant:broker-session-lost` carrying `{brokerId, code}`.

**The two credential codes deliberately do NOT fire that event** and are not part of `isBrokerSessionError`. That event drives the reconnect banner, and reconnecting fixes neither: one needs credentials entered, the other needs them entered again after a key rotation. Offering Connect would send the user through a full broker round trip that fails at the last step. All four are 409 rather than 404 because the resource is not missing — the request cannot proceed in the current state.

**Warning codes are unprefixed** (`SESSION_EXPIRED`) because they sit inside a `BrokerWarning` object; **error codes are prefixed** (`BROKER_SESSION_EXPIRED`) because they sit bare in `{error: ...}`. Deliberate.

**Gateways must classify.** `KiteBrokerGateway.classify()` maps `TokenException` → session expired and everything else → call failed. Reporting a 503 as "session expired" sends the user through a pointless OAuth round trip.

---

## Broker semantics — the traps

### P&L — decided 30 Jul, applies to every broker

Brokers disagree on what "P&L" means, so `PositionDto` fixes both columns and each gateway fills whichever half its broker withholds.

| Field | Meaning | Kite | Alice Blue |
|---|---|---|---|
| `pnl` | lifetime, since entry, **rupees** | `p.pnl` as given | computed `(ltp − trueEntry) × qty + realizedPnl` |
| `dayChange` | today's move, **rupees** | computed `(lastPrice − closePrice) × qty` | `unrealizedPnl` as given |

**Never use a broker's P&L field without checking which of the two it means.** Alice Blue's `unrealizedPnl` is day mark-to-market; Kite's `pnl` is lifetime. Live example: 650 units bought at 5.20, trading at 7.25 — up ₹1,332 since entry, down ₹1,495 today. Same position, opposite sign.

Corollary: **Alice Blue's `netAveragePrice` is not the entry price** — it is the M2M basis, and equals the previous close for anything carried overnight. `AliceBlueMapper.trueEntryPrice` reconstructs the real basis from `overnightPrice`/`dayBuyPrice`/`daySellPrice`. Same trap in holdings: use `investedPrice`, never `averageTradedPrice`.

### Margins — the same trap, one field lower

Read off live payloads 11 Aug. All three gateways populate all five `MarginDto` fields, so **margins need no backend work** — but three of the five mean different things per broker.

| `MarginDto` | Kite | Alice Blue | Paytm |
|---|---|---|---|
| `available` | `net` | `tradingLimit` | `trade_balance` |
| `used` | `utilised.debits` | `utilizedMargin` | `utilised_amount` |
| `cash` | `available.liveBalance` | `openingCashLimit` | `available_cash` |
| `collateral` | `available.collateral` | `collateralMargin` | `collaterals` |
| `total` | *derived* `available + used` | *derived* | *derived* |

- **`cash` cannot be summed.** Alice Blue's is an **opening** balance; Kite's and Paytm's are live, and both were negative on 11 Aug (−45,586 and −50,837) because the books are funded against collateral rather than cash. A total would mix a morning figure with two current ones — hence cash per broker and a dash in the total cell. `PaytmMapper` documents the negative as real and refuses to clamp it.
- **`total` is a MoneyPlant invention** — no vendor supplies it. **`used` is the only field meaning the same thing everywhere.**
- Kite fetches **only the `"equity"` segment**; commodity margins are silently absent. It exposes both `available.cash` and `available.liveBalance`, and the gateway deliberately maps the latter.
- Span/exposure detail exists on Kite (`utilised.span`, `exposure`, `optionPremium`) and Alice Blue (`utilizedSpanMargin`, `utilizedExposureMargin`) but **not Paytm**, so any per-component breakdown would be broker-asymmetric. Recoverable from `margin_snapshot.raw` later.

### Per-broker gotchas

**Kite.** `KiteException` extends `Throwable` directly, not `Exception` — so `catch (KiteException | IOException e)` infers `Throwable`, and any helper taking the caught variable must accept `Throwable`. Kite holdings **ignore `t1Quantity`**, so settled-but-not-delivered shows qty 0; the Alice Blue gateway adds it back, so the two disagree.

**Alice Blue.** `getInstruments` **works** — it downloads the NFO contract master and parses it. Measured 15 Aug 2026 against a live token: all 11 Alice Blue positions resolved an `InstrumentKey`, and `/api/payoff` offered 3 Alice Blue curves. The long-standing note that it "returns empty, so Alice Blue gets no payoff curve" is dead and has been removed from the roadmap row too; `SnapshotPositionSource`'s javadoc still repeated it and has been corrected. Classifies on **HTTP status, not an exception type** — a dead `userSession` is a plain-text `401 Unauthorized` with a non-JSON body, so the gateway checks the status *before* deserialising; feeding `Unauthorized` to Jackson throws a parse error that would be misread as transient. **The gateway must never let that 401 escape:** `frontend/src/lib/api.ts` maps any 401 to a redirect to `/login`, so one dead broker token would log the user out of MoneyPlant entirely. Field names come from the **v2** REST API (`netQuantity`, `tradingSymbol`, `ltp`) — not the deprecated v1 (`Netqty`, `Tsym`, `LTP`). Holdings quantity is `sellableQty + t1Quantity`; every sampled row had `t1Quantity: 0`, so **if `sellableQty` already includes T1 this double-counts** — check on a day with a same-day purchase. `getInstruments` still returns empty, so Alice Blue positions appear in tables and margins but get **no payoff curve**. Contract master: `https://v2api.aliceblueonline.com/restpy/static/contract_master/V2/NFO`, regenerated 08:00 IST; shape not yet inspected. Symbols are self-describing (`HDFCBANK25AUG26P730`), so a parser may beat downloading ~100k rows onto a small VM.

**Paytm.** **Do not use Paytm's official Java SDK** — unpublished (system scope, which `spring-boot-maven-plugin` drops from the fat jar, so it would work locally and fail on the VM), shaded with Spring Web 5.3, and pulls Jackson 2 into this Jackson 3 app. Positions are priced from `/data/v1/price/live?mode=LTP&pref=<exchange>:<security_id>:<type>` (comma-separated for batches; types `INDEX`, `EQUITY`, `OPTION`, `FUTURE`) — **none of this is in Paytm's docs.** **Never percent-encode `pref`.** Colons and commas are legal in a query, and `RestClient.uri(String)` encodes the template again, so a hand-rolled `%3A` reaches Paytm as `%253A`, matches nothing, and returns empty `data` — which both callers treat as "no quote" and degrade silently (realised-only P&L; spot 0). That was a real bug, fixed 11 Aug; `PaytmQuoteUrlTest` pins the URL. `mode=LTP` also returns `change_absolute`, so one batched call fills `ltp`, `pnl` and `dayChange`. `last_traded_price` in the positions payload is **never populated** — not "0.0 outside market hours" as once recorded. The quote path never throws: a failed quote falls back to realised-only P&L and logs why. `FUTURE` is still unverified, having no live future to test against.

- Security master: `https://developer.paytmmoney.com/data/v1/scrips/security_master.csv`, no token, ~13 MB, ~87k rows, reloaded daily. Columns located by header name, and the split respects quotes — company names contain commas. Keyed by the master's `name` column, which is exactly what positions return as `display_name`.
- **Equity spot needs NSE/EQ specifically.** The same ticker appears as `BSE/B`, `BSE/X`, `NSE/SM` with *different* security ids; NSE/EQ is 2,080 rows and unique per symbol. Quoting any other row prices a different book.
- **`last_update_time` is not a current epoch second** (`1470196447` = Aug 2016 read as one). Do not surface it as a quote timestamp without working out the encoding.
- **`net_avg` for carry-forward positions looks safe**, on one row: `tot_buy_qty_cf: 65`, `tot_buy_val_cf: 1799.85`, `net_avg: 27.69`, and `1799.85 / 65 = 27.69` exactly — so it is the true cost basis, **not** rebased to the previous close, pointing away from Alice Blue's trap. Confirm across several rows before closing it.
- Paytm is the only broker needing an extra profile call for the client code, and **`/accounts/v1/user/details`' shape is unverified** — the key is guessed from a candidate list, the call cannot throw, and field names are logged once per connect so the right key can be pinned.

**Spot** comes from `marketdata/SpotPriceService` via Paytm's free live-price endpoint, so a Kite or Alice Blue curve gets its spot from Paytm. `BrokerGateway.getLtp` is **deleted**; `SpotPriceProvider` takes a canonical underlying rather than a broker-shaped string. The UI must still hide the spot card and reference line on a 0 — that path now means "no broker could quote it".

### The application owns its symbols (decided 3 Aug)

> **MoneyPlant speaks its own vocabulary end to end. Broker symbols exist only inside that broker's adapter, and only at the moment a call is made.**

The anti-corruption rule for *types*, extended to *names* — which had leaked much further, because a `String` passes through any signature without complaint. Full model in `tradestack/docs/symbol-model.md`; **that doc recommends the middle path and was overruled — the full model is the target.** Step 1 (`UnderlyingRegistry` + `underlyings.properties`) is shipped. Step 2 (`InstrumentKey`, `BrokerInstrument`) exists but no consumer outside `instrument/` uses it. Steps 3–4 (switch consumers, close the two leaks) are the real work and are untouched; the two leaks must be closed **together**, because they change what the UI displays. ADR 0019 makes this a hard prerequisite for the risk module.

---

## Frontend

Routing: `/` landing, `/login`, then `AuthGuard` → `AppShell` → `/app`, `/app/positions`, `/app/holdings`, `/app/payoff`, `/app/risk`, `/app/settings`.

- **`/app` is the capital-and-P&L dashboard, not a positions table.** It used to render the *same* `PositionsTable` as `/app/positions`, untruncated, behind a "View all" link to an identical table. Now: `features/dashboard/aggregate.ts` outer-joins positions, holdings and margins into one row per connection; `BrokerPnlTable` and `BrokerFundsTable`; five tiles (Total P&L, Day P&L, Margin available, Margin used, Collateral) with total margin and utilisation % riding as a hint on the used tile.

  **Three rules live in that join, each from a real trap.** (1) **Key on `connectionId`, never `brokerId`** — `/api/margins` returns one row per connection despite its javadoc, so two Kite accounts are two rows both labelled `kite`, and folding on the broker id sums them into one. (2) **Outer join, and `margin: null` rather than `0`** — a dead margin call must leave the P&L row intact and show a dash, not a zero that reads as an empty account. (3) **Day P&L is positions-only and says so** — `HoldingDto` has no `dayChange` field at all (the snapshot repository writes a hardcoded `0.0`). The old "P&L today" tile was mislabelled from the day it was written: it summed lifetime `Position.pnl`.

  **The dashboard's tile hints were sized blind** and still have not been seen rendered. `aggregate.ts` was instead compiled standalone (its imports are type-only) and exercised under `node` against real `raw_capture` margins, 27 checks passing. **`frontend` has no test runner**, so that is the available technique for pure logic.

  **The Chrome extension *can* screenshot `localhost` now** — it could not before ("Frame with ID 0 is showing error page"), and that outdated note is why later UI shipped unseen. `/app/positions` was verified live on 15 Aug 2026 against all three brokers. Two things only a rendered page caught: a sticky `<th>` clipping the first broker band (shadcn's `Table` wraps in `overflow-auto`, which becomes the sticky containing block), and a freshness caption that named the reassuring date instead of the load-bearing one.
- **`/app/settings` is where broker credentials are entered.** The secret field is **write-only**: it renders empty with "Stored" beside it rather than dots, because a masked value would imply the real one is retrievable and it deliberately is not. That also settles what a blank secret means on update — nothing, since both values are always required.
- **Registrations and accounts are different axes, and `features/session/brokerConnectState.ts` is the only place they are joined.** A registration is a developer app; an account is a login it authorised, and one app can authorise several. Both `BrokerStatusChips` and `ConnectBrokerCard` read that hook, so they cannot disagree. Two rules: a registration with a live account is **not** offered for connecting (this is what makes the chips go quiet once everything is linked), and the registration label is **always sent** to `login-url` while only being *shown* when there is more than one — a lone registration named anything but `default` would otherwise start a flow the backend cannot resolve. Fixed 7 Aug after two Kite accounts and two Kite registrations produced four chips reading as duplicates; "add another account" now lives on the registration's own card in Settings, beside the accounts it has already authorised.
- **`ConnectBrokerCard` has two empty states.** No credentials at all sends the user to Settings; credentials but no live session offers Connect. A disabled Connect button was rejected for the first case — it reads as busy or broken when the action needed is genuinely different.
- Data: TanStack Query, `staleTime` 15s; positions & payoff refetch 30s, holdings 60s, session status 60s. Never retries 401/409.
- `lib/api.ts` is the only fetch layer: **401 → redirect to `/login`**, 409 + a broker error body → the window event that surfaces the reconnect banner.
- Payoff chart: recharts `ComposedChart` + `Area`, gradient split at P&L=0, dashed breakeven lines, amber spot `ReferenceLine`. "T+0" toggle is a disabled placeholder.
- Vite proxies `/api`, `/oauth2`, `/login/oauth2`, `/kite` → `localhost:8080`.

---

## Payoff engine

Pure computation in `PayoffEngine.compute(List<Leg>)`: 201 samples, ±10% pad beyond strike range, linear interpolation for breakevens, tail-slope heuristic for unbounded flags. `PayoffService` maps positions → legs via `InstrumentService` and groups by `(connectionId, underlying)`.

### No cross-broker merging (decided 29 Jul)

**Identical instruments are not netted** — the same strike at two brokers stays two legs. The engine sums `(value − avgPrice) × qty` linearly, so two legs at one strike give exactly the curve of one netted leg at the weighted-average price; netting would only tidy the legs table.

**Legs are grouped per broker, not per underlying** — because **spreads only get margin benefit inside a single account**, so a strategy deliberately split across brokers is financially irrational and the merged curve would rarely have anything to merge. A curve whose legs span accounts corresponds to no real margin position. Cross-broker net exposure is a later "Combined" toggle if a real book needs it; the aggregation value lives in the positions table.

### Open correctness bugs

- **`unboundedProfit`/`unboundedLoss` use tail slope, not structure.** Should derive from `netCallQty`/`netPutQty`. The heuristic misreads flat tails and books where legs offset near the window edge.
- **Breakeven detection uses `Math.signum(prev) != Math.signum(cur)`.** `signum(0) == 0`, so a sample landing exactly on zero registers as two crossings and emits a duplicate breakeven.
- **The window never starts at 0** — `lo = max(0, minStrike - span*0.5 - maxStrike*0.10)`. For long puts the true max profit (at spot=0) is off-screen, so `maxProfit` is understated.
- **Payoff points carry float noise** (`-20339.999999999985`) — invisible on a chart, visible in a tooltip. Round at the DTO boundary (ADR 0018).

---

## Before deploying

- **`MP_CREDENTIAL_KEY` must stay backed up off the VM.** Done 7 Aug; keep it true through every rebuild. It is the only unrecoverable secret in the stack and is deliberately not in the database — it is what stands between a database dump and every user's live broker secrets *and* their live sessions. Lose it and every stored secret is stranded, surfacing as `BROKER_CREDENTIAL_UNREADABLE`, fixable only by every user re-entering credentials. **Rotation is a backfill driven by `broker_credential.key_version`, never an edit to the variable in place.**
- **`MP_COOKIE_SECURE` must be `true` on the VM.** The cookie is `SameSite=Lax` and `Secure` defaults false so plain-HTTP localhost works. Over HTTPS without it nothing looks broken — it simply travels less protected.
- **`MP_SESSION_STORE` defaults ON and should stay on.** Postgres-backed, encrypted; the old warning about a plaintext session file describes code that no longer exists.
- **`spring-boot-flyway` must stay in the pom.** Boot 4 split autoconfiguration per technology: `flyway-core` is the library, `spring-boot-flyway` is the wiring that runs it at startup. With only the former the app boots perfectly, logs *nothing* about Flyway, and the schema silently stays empty until the first query fails. The test suite cannot catch this — it disables Flyway on purpose — so only booting against a real database does.
- **`deploy.sh` checks out the same branch in both repos.** Do not go around it. A frontend and backend built from different branches gives **a blank white page**, not a graceful degradation: React receives an object where it expects a string and throws minified error #31, killing the page.
- **Brokers allow one redirect URL per app registration**, so `localhost` and the domain cannot both be live for one app. Register a second app per broker for dev.
- Postgres on the VM is bound to `127.0.0.1:5432`. **Docker writes its own iptables rules**, so the OCI security list would *not* have saved you from the default `5432:5432`.

Host-level gotchas (Caddy hostname matching, nginx squatting on `:80`, `401` from `/api/me` meaning success) are in **`tradestack/deploy/README.md`** — the runbook, not here.

---

## Roadmap

| # | Step | State |
|---|---|---|
| 0 | Multi-broker core (1a–1g) | ✅ done |
| 1 | Alice Blue integration | ✅ done — contract master loads, positions resolve, payoff curves render |
| 2 | UI rework — group positions by broker and instrument | partly; grouping helpers exist |
| 3 | Login / real authentication (3a–3d) | ✅ done, deployed, live |
| 4 | Deploy — OCI + Cloudflare DNS-only | ✅ done, folded into 3c |
| 5 | Paytm Money integration | ✅ mostly done |
| 6 | Strategy builder | ✅ interactive visual designer shipped (`feat/heuristic-margin-engine`) |
| 7 | Persistence — users + broker links | partly pulled into Step 3 |
| 8 | Analysis — technical, fundamental, decay, risk/reward, LLM | **blocked on market data** |

⚠ **"Step 4" means two things.** This table's Step 4 is the deploy. `SPEC.md` calls itself *"Step 4: risk core, packaging and constraints"*, and **every 4a/4b/4c/4d reference in this file and in branch names means that document**, not this row.

Step 8 is described by the owner as the core of the product, and is **blocked** rather than merely later: technical needs history, premium decay needs option prices and IV over time, risk/reward needs live premiums, LLM analysis needs something factual underneath.

**Backlog — user-configured brokers.** Priority very far, but the first half landed in 3d: `/api/session/status`'s `brokers` is now this user's, and `/app/settings` is where configuration happens. What stays far off is scale — a registry of tens of brokers and a UI for choosing among them. It changes what "disconnected" means: today that is "a registered broker this user has no session for", which only works while the registry is small. Let it break ties without scheduling work: prefer contracts that can express *this user's* brokers and *per-account* identity over ones hardcoding a global list.

---

## Open decisions

- **Market data.** Largely answered: Paytm supplies spot, free and verified live. **Still missing: option-leg premiums** (Step 6/8 need per-strike prices) and history. The lead is Alice Blue's option chain — per-strike `ltp`, `oi`, `pdc` (all as strings), with `getUnderlying`/`getUnderlyingExp`, apparently at no cost beyond the account. It does not return spot directly; candidates are put-call parity near ATM (`spot ≈ strike + CE_ltp − PE_ltp`) from the same payload, or the Historical Data endpoint. **Unverified against a live token** — confirm before treating Step 8 as unblocked, and check whether broker terms permit using one broker's feed to price another's positions.
- **Regulatory** — full findings in `research/REGULATORY-API-STATIC-IP.md`. **Nothing binds MoneyPlant while it stays read-only**, and the reserved static IP is needed for DNS, TLS and redirect URIs, *not* by SEBI (whose static-IP mandate binds order placement only). Two findings price the addition of order placement: **NSE maps one static IP to exactly one client** (family excepted), which one shared VM egress IP cannot satisfy for two unrelated users; and **placing orders for another person makes MoneyPlant an "algo provider"** — the broker's agent, requiring exchange empanelment, per-algo registration and hosting on the broker's servers. The lane that stays open is self-and-family. Offering analysis or recommendations may separately fall under SEBI RA/IA rules — confirm before Step 8. Not legal advice.
- **Credentials are correctly externalised** and no rotation is needed: every committed blob of `application.properties` holds placeholders. For future audits, `git log -S"api-secret"` flags commits where that string's *occurrence count* changed, so it fires when a placeholder line is merely added — read the blob (`git show <sha>:<path>`) before concluding anything.

**Explicitly out of scope:** a Java backtester (stays offline in AlgoTest / Python), and propose-and-confirm order execution (only ever after a risk module exists).
