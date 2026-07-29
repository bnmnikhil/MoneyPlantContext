# MoneyPlant — working context

**Generated from the code on 29 Jul 2026.** This file is code-truth, not chat memory. Regenerate it when the architecture shifts.

## What this is

Options trading stack for NSE F&O. The core value is **multi-broker position aggregation** (Kite + Alice Blue + Paytm Money) with payoff graphs, because Alice Blue and Paytm lack decent position visualisation.

**Decided 29 Jul: this is a real product, not just a personal tool.** Target is a limited number of users, run safely, on minimal infrastructure cost. That reverses three earlier deferrals — authentication, persistence and multi-tenancy are now in scope rather than "only when a second user exists". It also means the app cannot be deployed until real auth exists (see Step 3).

Owner is a leveraged call seller. Builds in ~90-minute morning slots. Wants **guided coding, not full dumps** — but will ask for full code on specific methods. Career switch is priority #1; this project is #2, so scope should still be challenged aggressively.

## Repos

```
C:\Projects\Moneyplant\
├── tradestack\   Java 21 + Spring Boot 4.1.0 + Maven   (backend, :8080)
└── frontend\     React 18 + Vite + TS + Tailwind + shadcn/ui (:5173)
```

Two separate git repos, not a monorepo. Remotes: `bnmnikhil/MoneyPlant` (backend) and `bnmnikhil/MoneyPlantFrontend`.

## Branching

Trunk-based, short-lived branches. `dev` deliberately does **not** exist — it earns its keep only once `main` means "what's running on the OCI VM", and nothing is deployed yet.

```
main                    always green, always deployable
step/1d-broker-errors   one branch per roadmap step, per repo
```

- Branch name mirrors the roadmap step and is **identical in both repos** when a step spans them, so the two PRs are obviously a pair. Most steps do span both.
- Squash merge into `main`, delete the branch.
- **Never merge red.** Backend gate is `mvnw test`, frontend gate is `npm run typecheck`. Both are in the PR template.

- `tradestack` HEAD: `5b00f2c Multi brokers support code refactor`
- `frontend` HEAD: `77033be multi broker refactor of backend`

## Backend architecture (locked — do not relitigate)

Package-by-module under `com.MoneyPlant.tradestack`:

| Package | Contents |
|---|---|
| `broker/` | public: `BrokerGateway`, `BrokerRegistry`, `BrokerService`, `ConnectionService`, `BrokerSession`, `BrokerSessionException`, `dto/` |
| `broker/kite/` | private per-broker: `KiteBrokerGateway`, `KiteProperties`, `KiteSessionService`, `KiteSessionController` |
| `instrument/` | `InstrumentService`, `OptionInstrument`, `InstrumentType`, `InstrumentController` |
| `analytics/` | `PayoffEngine`, `PayoffService`, `PayoffController`, `Leg`, `PayoffResult` |
| `positions/`, `holdings/`, `account/` | thin controllers over `BrokerService` |
| `common/` | `ApiExceptionHandler` |

### Patterns in play

- **Strategy** — `BrokerGateway` is the per-broker interface.
- **Adapter / anti-corruption** — each gateway owns private `toDto` methods; broker SDK types never leak past the gateway.
- **Registry** — `BrokerRegistry` auto-discovers gateway beans via constructor `List<BrokerGateway>` → `Map<brokerId, gateway>`. A new broker needs zero changes here.
- **Facade** — `BrokerService` owns resolve-connection-then-call. Controllers only talk to `BrokerService`.

### The two rules that make multi-broker work

1. **Gateways are stateless.** `BrokerSession` is a *parameter*, never a field. `KiteBrokerGateway.client(session)` builds a fresh `KiteConnect` per call. This is what enables multi-user and multi-account-per-broker.
2. **`ConnectionService` is keyed by `connectionId`, not `brokerId`.** That is what allows two accounts on the same broker. Single in-memory `ConcurrentHashMap` chokepoint; becomes Postgres-backed only when OAuth lands.

```java
public record BrokerSession(
    String connectionId,
    String brokerId,
    Map<String, String> tokens,   // kite→{accessToken,publicToken}, aliceblue→{userSession}
    Instant createdAt
) { public String token(String key) { return tokens.get(key); } }
```

The `Map<String,String> tokens` deliberately absorbs per-broker token shapes. Don't replace it with typed fields.

### Deliberately not built yet

`BrokerConnection` entity (userId, brokerId, accountLabel) → Postgres. Now scheduled (Steps 3 and 7), not indefinitely deferred, because the product is going multi-user.

**Sessions still stay in-memory.** Broker tokens die daily under SEBI rules, so there is nothing durable worth persisting and no token encryption problem to solve.

**Likely no credential encryption either.** With app-level (vendor) OAuth — which Kite Connect uses and Alice Blue's a3 vendor flow uses — the *app* holds one api-key/secret pair in the environment and each user simply authorises. Per user you store the linkage, not their secrets. Verify this holds for Paytm before assuming it; if any broker requires per-user API keys, encryption comes back for that broker only.

`connectionId` will need to become user-scoped (something like `{userId}:{brokerId}:{label}`) once users exist. `ConnectionService` is already keyed by `connectionId` rather than `brokerId`, so this is a key-format change, not a redesign.

## API contract

**Read endpoints return `BrokerAggregate<T>`, not bare lists.**

```json
{ "items": [...], "warnings": [{ "brokerId", "connectionId", "code", "message" }] }
```

`code` is `SESSION_EXPIRED` (reconnect required) or `CALL_FAILED` (transient — do not tell the user to reconnect). Partial success is the normal case and returns **200**: if Kite responds and Alice Blue's token is dead, you get Kite's rows plus one warning. A non-200 now means the entire request failed, which is a genuinely different situation.

### Error codes (whole-request failures only)

Only the single-connection endpoints (payoff) can produce these; the aggregate endpoints turn per-broker failure into warnings.

```
BrokerException (abstract: brokerId + code)
├── BrokerSessionException       BROKER_SESSION_EXPIRED   409   "Reconnect"
├── BrokerNotConnectedException  BROKER_NOT_CONNECTED     409   "Connect"
└── BrokerCallException          BROKER_CALL_FAILED       502   retry, say nothing
```

Body is `{error, brokerId, message}`; `brokerId` may be null, which is why the handler builds a `HashMap` rather than `Map.of`. Frontend mirrors this in `BrokerErrorBody` and fires a `moneyplant:broker-session-lost` event carrying `{brokerId, code}`.

**Gateways must classify.** `KiteBrokerGateway.classify()` maps `TokenException` → session expired and *everything else* → call failed. Alice Blue and Paytm gateways must do the same; reporting a 503 as "session expired" sends the user through a pointless OAuth round trip.

**Kite SDK gotcha:** `KiteException` extends `Throwable` directly, not `Exception`. So `catch (KiteException | IOException e)` infers `Throwable` as the least upper bound, and any helper taking the caught variable must accept `Throwable`.

Warning codes are unprefixed (`SESSION_EXPIRED`) because they sit inside a `BrokerWarning` object; error codes are prefixed (`BROKER_SESSION_EXPIRED`) because they sit bare in `{error: ...}`. Deliberate, not an oversight.

| Method | Path | Returns |
|---|---|---|
| GET | `/api/positions` | `BrokerAggregate<PositionDto>` |
| GET | `/api/holdings` | `BrokerAggregate<HoldingDto>` |
| GET | `/api/margins` | `BrokerAggregate<MarginDto>` — one row per broker, **frontend sums** |
| GET | `/api/me` | **STUB** — hardcoded `{email,name,picture}` |
| GET | `/api/session/status` | `{brokers:[{id,connected}]}` |
| GET | `/api/session/login-url` | `{url}` (Kite only) |
| GET | `/api/payoff` | `String[]` underlyings with open positions |
| GET | `/api/payoff/{underlying}` | `PayoffResponse` incl. `spot` |
| GET | `/api/debug/instrument?symbol=` | `OptionInstrument` |
| GET | `/kite/login` | login URL as text/html |
| GET | `/kite/callback` | redirects to `${app.frontend-url}/app` |

Frontend mirrors these exactly in `src/types/api.ts`. **Keep the two in sync — the TS types are the contract.**

## Frontend

- Routing: `/` landing, `/login`, then `AuthGuard` → `AppShell` → `/app`, `/app/positions`, `/app/holdings`, `/app/payoff`.
- Data: TanStack Query. `staleTime` 15s default; positions & payoff refetch every 30s, holdings 60s, session status 60s.
- `lib/api.ts` is the only fetch layer. It maps **401 → redirect to /login** and **409 + `{error:"KITE_SESSION_EXPIRED"}` → `moneyplant:kite-expired` window event** so any query failing surfaces the reconnect banner.
- Query client never retries 401/409.
- Payoff chart: recharts `ComposedChart` + `Area`, gradient split at P&L=0 (green above, red below), dashed breakeven lines, amber spot `ReferenceLine`. "T+0" toggle is a disabled placeholder.
- Vite proxies `/api`, `/oauth2`, `/login/oauth2`, `/kite` → `localhost:8080`.
- **`npm run typecheck`** (= `tsc -b`) is the validation gate for frontend changes. `npm run dev` does **not** typecheck — Vite only transpiles — so this is the only thing that catches a contract drift between the TS types and the backend.

## Payoff engine

Pure computation in `PayoffEngine.compute(List<Leg>)`. 201 samples, ±10% pad beyond strike range, linear interpolation for breakevens, tail-slope heuristic for unbounded flags. Unit-tested via `PayoffEngineTest` (short strangle → 2 breakevens, unbounded loss).

`PayoffService` maps positions → legs by looking up each `tradingSymbol` in `InstrumentService`, groups by underlying, and fetches spot via a hardcoded index-symbol map (`BANKNIFTY → NSE:NIFTY BANK`, etc.).

---

# Known issues — verified against the code

## Blockers for Alice Blue (fix these first)

1. ~~**`ApiExceptionHandler` is Kite-hardcoded.**~~ **Done (1d).** See the error-code section below.
2. **`InstrumentService` cache is single-broker.** `bySymbol` is keyed by trading symbol only and `loadedOn` is one date for the whole app. Once Alice Blue loads its master contract, Kite's map is silently replaced and the second broker's `ensureLoaded` no-ops for the rest of the day. Key by `(brokerId, symbol)` and track `loadedOn` per broker.
3. **`/api/session/status` and `/api/session/login-url` live inside `KiteSessionController`** and hardcode `"kite"`. Move to a broker-neutral controller; `login-url` will need a `brokerId` param.
4. ~~**`CONNECTION_ID` duplicated in 5 files.**~~ **Partly done (1b).** Gone from `PositionsController`, `HoldingsController`, `AccountController` — they use the fan-out and take no connectionId at all. Two legitimate single-connection uses remain: `KiteSessionController` (1f) and `PayoffService` (1g).
5. **`vite.config.ts` doesn't proxy `/aliceblue`** — the callback will 404 in dev.

## Security — verified clean

6. **Credentials are correctly externalised.** `application.properties` holds `kite.api-key=${KITE_API_KEY}` / `kite.api-secret=${KITE_API_SECRET}`; real values live only in the owner's OS environment. Every committed blob of this file was checked (`1403b4e`, `0f9dedb`, `5b00f2c`) — all contain placeholders, never literals. No rotation needed. Repo pushes to `github.com/bnmnikhil/MoneyPlant`.

   Note for future audits: `git log -S"api-secret"` flags commits where the *occurrence count of that string* changed, so it fires when the placeholder line is merely added. It is not evidence of a leaked value — read the blob (`git show <sha>:<path>`) before concluding anything. Keep the same discipline when Alice Blue and Paytm credentials arrive: placeholders in `application.properties`, values in the environment.

## Correctness

7. **`getLtp` swallows the exception and returns 0.** Kite market-data subscription is not active → `PermissionException`. Tolerated as `spot: 0`. This blocks the spot line, option chain, Greeks and T+0. Paid add-on; decision deliberately pending.
8. **`unboundedProfit`/`unboundedLoss` use tail slope, not structure.** Should be derived from `netCallQty` / `netPutQty`. The slope heuristic misreads flat tails and books where legs offset near the edge of the window.
9. **Breakeven detection uses `Math.signum(prev) != Math.signum(cur)`.** `signum(0) == 0`, so a sample landing exactly on zero registers as two crossings and emits a duplicate breakeven.
10. **Payoff window never starts at 0** — `lo = max(0, minStrike - span*0.5 - maxStrike*0.10)`. For long puts the true max profit (at spot=0) is off-screen, so `maxProfit` is understated.
11. **Holdings ignore `t1Quantity`** — settled-but-not-delivered shows qty 0.
12. **`PositionDto.dayChange` is `lastPrice - closePrice`** with a code comment flagging that the SDK field names are unverified. Worth confirming against kiteconnect 3.5.0.
13. **`/api/logout` is called by the frontend but does not exist in the backend.** `api.logout()` will 404/405 and `useLogout` will never redirect.
14. **`AuthGuard` is effectively a no-op** — `/api/me` is a stub that always returns 200, so the app is always "logged in". Expected until Google OAuth, but don't mistake it for working auth.
15. ~~**`PayoffLeg.type` missing `FUT`.**~~ Fixed in 1c.

15b. **`npm run build` was broken from the start** (fixed in 1c). `tsconfig.node.json` set both `composite: true` and `noEmit: true`, which is TS6310, so `tsc -b` always failed — meaning the project had never been type-checked, only transpiled by Vite. Emit now goes to `node_modules/.tmp`, `*.tsbuildinfo` is gitignored. **Run `npm run typecheck` after every frontend change.**

## Hygiene

16. **Line-ending churn** — all 29 backend source files show as fully modified (926 insertions / 926 deletions) with no semantic change. `.gitattributes` only covers `mvnw` and `*.cmd`. Add `* text=auto` and renormalise, otherwise every diff from here on is unreadable.
17. **Dead code** — `PositionsService` is entirely commented out, `BrokerController` is an empty shell, `PositionsController` and `BrokerGateway` carry commented-out old versions. `InstrumentController` imports `KiteSessionService` unused.
18. **`PayoffService.positions(BrokerSession s)`** takes a session parameter it ignores and uses the constant instead.
19. **`spring-boot-starter-thymeleaf` is a dependency but there are no templates.** Drop it. Confirmed by every test run: `WARN ... Cannot find template location: classpath:/templates/`.

22. **Duplicate `org.json.JSONObject` on the test classpath** — `android-json` (via the Spring test starter) and `org.json:json:20230227` (transitively via kiteconnect). Spring warns that runtime behaviour is unpredictable. Exclude one, most likely `android-json`.
20. **`PayoffEngine` is annotated `@Service`** despite being described as pure-domain. Harmless, but it is not Spring-free as claimed.
21. ~~**`DashboardPage` grid/label warts.**~~ Fixed in 1c.

---

# Roadmap

**Order agreed 29 Jul 2026.** Steps are sequential and most span both repos.

| # | Step | Gates |
|---|---|---|
| 0 | Multi-broker core (1a–1f) | ✅ done |
| 1 | Alice Blue integration | — |
| 2 | UI rework — group positions by broker and by instrument; fold in 1g | needs Step 1 |
| 3 | Login / real authentication | **blocks deploy** |
| 4 | Deploy — OCI, Cloudflare TBD | needs Step 3 |
| 5 | Paytm Money integration | — |
| 6 | Strategy builder | wants Step 7, and market data |
| 7 | Persistence — users + broker links | partly pulled into Step 3 |
| 8 | Analysis — technical, fundamental, premium decay, risk/reward, LLM | **blocked on market data** |

## Step 0 — the multi-broker core ✅

No broker code in this step. Alice Blue is only additive once it's done.

- **1a ✅** `.gitattributes` `* text=auto` in both repos. Diffs are readable again.
- **1b ✅** Fan-out + `BrokerAggregate` contract, 3 controllers collapsed, 12 tests. Commits `571e074`, `84ce2df`.
- **1c ✅** Frontend mirrors the contract; `BrokerWarnings`, Broker column, margins summed client-side. Commit `441b9f5`.
- **1d ✅** Broker-neutral error hierarchy + Kite exception classification, both sides.
- **1e** `InstrumentService` cache keyed by `(brokerId, symbol)`, `loadedOn` per broker.
- **1f** Broker-neutral `SessionController`; `/api/session/login-url?brokerId=`.
- **1g — not yet done, folded into Step 2.** `PayoffService` stops using the hardcoded `kite-default` connection and works per connection. **Curves are grouped by `(connectionId, underlying)` — not merged across brokers.** `/api/payoff` returns broker+underlying pairs; the selector reads "BANKNIFTY · Kite". Until this lands, an Alice Blue book appears in the positions table but gets **no payoff curve at all**, which is most of the reason Alice Blue is being integrated.

### Decided 29 Jul: no cross-broker merging in the payoff

Two things were bundled under "merge across brokers"; both are settled.

**Identical instruments are not netted.** The same strike held at two brokers stays two legs. `PayoffEngine` sums `(value − avgPrice) × qty` linearly, so two legs at one strike give exactly the curve of one netted leg at the weighted-average price. Netting would only tidy the legs table.

**Legs are grouped per broker, not per underlying.** Not a cost decision — grouping by `(connectionId, underlying)` versus `underlying` is one extra key either way. The reason is that **spreads only get margin benefit inside a single account**, so a strategy deliberately split across brokers is financially irrational and the merged curve would rarely have anything to merge. A curve whose legs span accounts also corresponds to no real margin position.

This narrows what the payoff feature is for: Alice Blue and Paytm have no decent payoff visualisation at all, so *having a curve per broker* is the win. Cross-broker net exposure is a later "Combined" toggle if a real book ever needs it — the aggregation value lives in the positions table, which already works.

## Step 1 — Alice Blue integration (credentials ready, approved)

Auth is the current **Open API / a3 / v2 redirect flow** — *not* the deprecated v1 SDK:

```
browser → Alice Blue login → callback with userId + authCode
       → backend computes SHA-256(userId + authCode + apiSecret)
       → POST https://a3.aliceblueonline.com/open-api/od/v1/vendor/getUserDetails
       → userSession (valid 24h)
```

Build: `AliceBlueProperties`, `AliceBlueSessionService` (checksum flow → `BrokerSession` with `{userSession}`), `AliceBlueBrokerGateway` (plain REST client, no Java SDK — parse comma-formatted string numbers like `"3,355.10"`; fields `Netqty`, `Tsym`, `Token`, `LTP`, `Opttype`; master-contract loader), `AliceBlueSessionController` at `/aliceblue/callback`. Register as `"aliceblue-default"`. The registry picks it up automatically — **zero changes to existing controllers, `PayoffService` or the frontend**, once the five blockers above are fixed.

## Step 2 — UI rework

Positions grouped **by broker** and **by instrument**, for a cleaner view. Exact design decided at the time.

This is a *display* concern and does not contradict the payoff decision above. The table may collapse two BANKNIFTY 55500 PE rows from different brokers into one line with combined quantity, while `PayoffEngine` still treats them as two legs. The arithmetic is identical either way — keep the layers distinct.

Also fold in **1g** here, so Alice Blue gets a payoff curve.

## Step 3 — Login / real authentication

**This gates deployment.** `/api/me` is a stub that always returns 200, so `AuthGuard` is decorative and the app is permanently "logged in". Harmless on localhost; on a public IP it means anyone with the URL sees live positions, margins and P&L, and can drive the broker connect flow.

Now that the product is multi-user, this is real auth: Google OAuth, a `users` table, and `connectionId` becoming user-scoped. This is where most of Step 7 actually gets built.

## Step 4 — Deploy

OCI VM with a reserved static IP (SEBI requirement). Caddy serves `dist/` and proxies `/api|/oauth2|/kite|/aliceblue` → `:8080`. Single origin. Cloudflare DNS vs OCI-only decided at the time. Minimal infra cost is an explicit constraint — prefer the OCI always-free tier and Postgres on the same VM over managed services.

**Redirect URL gotcha:** brokers allow **one redirect URL per app registration**. Deploying means `localhost:8080/kite/callback` and `<domain>/kite/callback` cannot both be live. Register a second app per broker for dev, and do it when registering Alice Blue so it is handled once for both.

## Step 5 — Paytm Money

REST via `developer.paytmmoney.com`; token auth, not a checksum flow. Confirm whether it supports an app-level vendor flow or requires per-user API keys — that answer decides whether credential encryption is needed.

## Step 6 — Strategy builder

Build a hypothetical strategy and see its payoff before placing it. Note two dependencies: it probably wants Step 7 (saving strategies), and it is only pleasant to use with live option prices, which needs market data.

## Step 7 — Persistence

`users`, `broker_links`. Postgres + jOOQ. Largely pulled forward into Step 3; what remains here is whatever Step 6 needs to save.

## Step 8 — Analysis features

Technical, fundamental, premium decay, risk/reward, LLM analysis. Described by the owner as the core of the product.

**Blocked on market data.** Every item runs through the price/option feed: technical needs history, premium decay needs option prices and IV over time plus stored series, risk/reward needs live premiums, LLM analysis needs something factual underneath. This is not "later work", it is *blocked* work.

## Open decisions

- **Market data source.** Kite's subscription is deferred on cost. Investigate cheaper or free NSE/option-chain APIs before committing. Until then `getLtp` returns 0 and the UI must not display a confident ₹0 — hide the spot card and spot reference line rather than showing zero.
- **Regulatory.** Serving other users changes the picture: broker API terms generally restrict redistribution to third parties without a vendor agreement, and offering analysis or recommendations in India can fall under SEBI Research Analyst / Investment Adviser rules. Worth confirming properly before Step 8 — cheap to check now, expensive to discover late. Not legal advice.

Explicitly out of scope: a Java backtester (stays offline in AlgoTest / Python), and propose-and-confirm order execution (only ever after a risk module exists).
