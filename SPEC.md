# MoneyPlant — Step 4: risk core, packaging and constraints

**Written 7 Aug 2026 from an interview with the owner.** This is a *decision* document: it records what was chosen, what was rejected and why, and what it commits the codebase to. It supersedes nothing in `CLAUDE.md` except where it says so explicitly.

Companion docs: `DEPLOY-STEP3.md` (auth/deploy), `CREDENTIALS-STEP3D.md` (per-user credentials), `tradestack/docs/symbol-model.md` (InstrumentKey).

---

## 0. Situation

Steps 1, 2, 3a–3d and 5 are done. 3d is built and green locally, unmerged, undeployed. The app has two real users, per-user broker credentials, and a working three-broker aggregation over Kite, Alice Blue and Paytm.

The next two to three months build **the actual product**: risk analysis and research over the user's live book. During that window the user base stays at two. After it, the product opens up — invite-only, curated, tens of users, possibly hundreds.

Three problems are being solved together, because they are the same problem:

1. **The core doesn't exist yet.** Risk analysis needs data the current architecture cannot produce — specifically, data that outlives a broker session.
2. **The rules are unenforced.** `CLAUDE.md` states several load-bearing invariants ("gateways are stateless", "broker SDK types never leak past the gateway", "credentials are a parameter, never a field"). Nothing in the build checks any of them. They have held so far because one person wrote everything.
3. **The docs are one 61 KB file** doing five jobs: architecture reference, decision log, changelog, operational runbook and roadmap. It works today and will not at twice the size.

---

## 1. Constraints

These bound every decision below.

| Constraint | Value | Consequence |
|---|---|---|
| **Cost** | Not fixed, but "as low as possible". Default assumption: OCI always-free tier, ₹0/month infra. | No managed services. No Redis unless it fits on the same box. Any paid dependency needs an explicit justification when proposed. |
| **Scale target** | Design for **tens**. Do not foreclose **hundreds**. Thousands is out of scope. | Single JVM is acceptable. Every decision that would break at hundreds must be *written down* (§9), not silently accepted. |
| **Speed** | "Super smooth." Concretely: no user-visible wait on broker latency. | Drives the snapshot-first read model (§4). |
| **Users** | 2 now. Invite-only and curated at "public" — from a DB table, not an env var, so adding a user is not a redeploy. | `MP_ALLOWED_EMAILS` survives this step and dies at the multi-user step. |
| **Deployment** | Exactly one JVM instance. | Recorded as an ADR, not an assumption. See §9. |

---

## 2. Decisions

### D1 — Boundaries are enforced by ArchUnit, in `mvnw test`

Stay a **single Maven module**. Add an ArchUnit suite that fails the normal build.

*Rejected:* Maven multi-module (real compile-time walls, but a pom restructure and a slower build for a 5,800-line codebase); Spring Modulith (a dependency plus its opinions about inter-module communication, when what's wanted is just a check); package-private facades (only works if the package *is* the module, which `broker/` with its three vendor sub-packages is not).

ArchUnit is the cheapest option that turns prose invariants into build failures, and it is reversible — deleting the test file undoes it.

**The initial rule set** (all four chosen; all four fail the build):

| Rule | Statement | Why it matters |
|---|---|---|
| **A1 — SDK containment** | No class outside `..broker.kite..` may depend on `com.zerodhatech..`. Same for each vendor's HTTP/JSON types and its own sub-package. | The anti-corruption rule, stated in `CLAUDE.md` since day one, never checked. |
| **A2 — Risk never touches brokers** | No class in `..risk..` or `..analytics..` may depend on `..broker..`. | The dependency direction chosen in D5. Also keeps `PayoffEngine` honest about being pure domain. |
| **A3 — Gateways are stateless** | No implementation of `BrokerGateway` may declare a field of type `BrokerSession` or `BrokerCredentials`. | This is the invariant that makes multi-user possible at all. A field here means one bean cannot serve two users, and the failure is silent cross-user data leakage, not a crash. |
| **A4 — Controllers depend on services** | No `@RestController` may depend on a `*Repository`, a `BrokerGateway`, or any vendor type. | Keeps the facade rule real as the file count grows. |

Rules live in `src/test/java/com/MoneyPlant/tradestack/arch/`. Each rule carries a comment naming the ADR it enforces — a failing arch test must be able to tell the next person *why*, not just *what*.

**Note on A2 and the `dto/` package.** `risk/` will consume `PositionDto`, which currently lives in `broker/dto/`. A2 as written would forbid that. Resolve it by moving the DTOs the whole app shares — `PositionDto`, `HoldingDto`, `MarginDto`, `BrokerAggregate`, `BrokerWarning`, `Sourced` — out of `broker/dto/` into a neutral package (`portfolio/dto/`, see D6). This is a real refactor with a wide blast radius and it belongs in 4a, before anything depends on the current location.

---

### D2 — ADRs live per repo; CLAUDE.md shrinks to code-truth

**`tradestack/docs/adr/` and `frontend/docs/adr/`**, each with its own numbering, decisions sitting next to the code they bind.

The cross-cutting problem this creates — the API contract binds both repos — is resolved by a rule rather than a third location: **the backend owns the API contract, so contract ADRs live in `tradestack/docs/adr/` and the frontend links to them by path.** The frontend's own ADRs cover only what is genuinely frontend-local.

**An ADR is required when any of these is true:**

- the decision is expensive to reverse;
- it spans both repos;
- it constrains code not yet written;
- it has been argued once already and might be argued again.

Everything else is a `CLAUDE.md` line, or nothing. The threshold is deliberately high: the failure mode being avoided is *volume until nobody reads them*, which is exactly what happened to `CLAUDE.md`.

**Format** — the short Nygard form, one file per decision:

```markdown
# NNNN — Title in the imperative

Status: accepted | superseded by ADR-NNNN | rejected
Date: YYYY-MM-DD

## Context
What forced a decision. Include what was *not* known.

## Decision
What was chosen, stated as a rule that can be checked.

## Consequences
What this makes easy, what it makes hard, and what it forecloses.
Name the ArchUnit rule if one enforces it.
```

**Backfill.** Every "decided on <date>" / "reversed" / "do not relitigate" block in `CLAUDE.md` becomes an ADR. `CLAUDE.md` then becomes what it claims to be: current architecture plus next actions, with pointers. Target ~15 KB.

The initial backfill set, with the sources already written:

| ADR | Subject | Currently recorded in |
|---|---|---|
| 0001 | Multi-broker core: Strategy + Registry + Facade, gateways stateless | `CLAUDE.md` "Backend architecture (locked)" |
| 0002 | `ConnectionService` keyed by `connectionId`, not `brokerId` | same |
| 0003 | No cross-broker merging in the payoff | `CLAUDE.md` "Decided 29 Jul" |
| 0004 | Broker sessions stay in memory | `CLAUDE.md` "Deliberately not built yet" |
| 0005 | `BrokerAggregate` — partial success is 200 | `CLAUDE.md` "API contract" |
| 0006 | P&L semantics: `pnl` is lifetime, `dayChange` is today | `CLAUDE.md` "P&L semantics" |
| 0007 | The application owns its symbols | `CLAUDE.md` "Decided 3 Aug" + `symbol-model.md` |
| 0008 | Per-user broker credentials, AES-256-GCM, key out of the DB | `CREDENTIALS-STEP3D.md` |
| 0009 | Do not use Paytm's official Java SDK | `docs/paytm-api.md` |
| 0010 | Google OAuth + env-var allowlist | `DEPLOY-STEP3.md` |

New ADRs from *this* document start at 0011 and are listed in §10.

**What stays in `CLAUDE.md`:** the operational gotchas. `winget install PostgreSQL.16 --force`, nginx holding `:80`, `spring-boot-flyway` vs `flyway-core`, `setx` only affecting new processes, `curl /api/me` returning 401 as a success signal. These are not decisions and do not fit the ADR form. They are runbook material and stay where they are — or move to `tradestack/deploy/README.md`, which already exists for exactly this.

---

### D3 — Data at rest: snapshots, written on fetch and at EOD

Risk analysis reads **persisted snapshots**, never brokers directly. Two write paths:

1. **On every successful fan-out.** A user opening the app writes a snapshot. Free — the data is already in hand.
2. **A scheduled 15:35 IST capture, Mon–Fri.** For every user with a live broker session at that moment.

**The known weakness, accepted knowingly:** the EOD job needs a live broker token, and tokens die daily with no refresh path. So it captures for whoever connected that day and misses everyone else. The series is therefore uneven in a way users can notice.

This is mitigated, not solved, by **recording the gap explicitly**:

```sql
capture_run(
  user_id, connection_id, trading_day,
  status,        -- CAPTURED | NO_SESSION | FAILED
  broker_id, error, ran_at
)
```

A chart that sees `NO_SESSION` renders a **break in the line**, never a straight segment through it. The alternative — carrying yesterday's snapshot forward — was rejected outright: a position closed on a day the user didn't log in would stay "open" in history permanently, and every decay number computed across that gap would be fiction.

*Rejected:* live-only risk (ships fastest, permanently blocks premium decay, which is one of the four committed features); market-data-only snapshots (no history for anyone who stops using the app).

#### ⚠ D3 has a blocker the current code does not support

`BrokerService` resolves the caller from the Spring Security context:

```java
connections.allFor(currentUser.requireUserId())   // BrokerService.java, in fanOut() and sessions()
```

**A `@Scheduled` job has no security context.** `requireUserId()` will throw. So the EOD capture *cannot* call `allPositions()`, `allHoldings()` or `sessions()` as they stand — the entire fan-out API is caller-scoped by construction.

This is not a bug; it is `ConnectionService.allFor(userId)` doing exactly what it was designed to do (`CLAUDE.md`: "There is deliberately no unscoped `all()`… that is exactly the bug that ends with one user looking at another user's positions"). But it means the capture job needs a **user-explicit** fan-out path that the scheduler can call and a controller cannot reach by accident.

**Required shape:**

- Add `BrokerService.allPositionsFor(String userId)` (and holdings/margins equivalents), with the existing `allPositions()` becoming a one-line delegate passing `currentUser.requireUserId()`.
- `ConnectionService` gains an internal way to enumerate the users who currently have sessions — the scheduler's actual entry point. It must not become a public unscoped `all()` returning sessions; it returns *user ids*, and each is then fanned out individually.
- **ArchUnit rule A5:** no `@RestController` may call any `*For(String userId)` overload. The scoped variant is the only one reachable from HTTP. Without this, the unscoped path becomes the shortest path and D3 reintroduces the exact bug `allFor` was written to prevent.

This is the single largest piece of unplanned work in 4c and should be sized accordingly.

---

### D4 — Snapshot shape: typed columns **plus** raw JSONB

```sql
position_snapshot(
  id, user_id, connection_id, broker_id, trading_day, captured_at,
  -- typed, what risk queries:
  symbol, underlying, instrument_key, expiry, strike, right,
  quantity, avg_price, ltp, pnl, day_change,
  -- fidelity:
  raw jsonb
)
```

`holding_snapshot` mirrors it. `margin_snapshot` is one row per broker per capture.

The `raw` column is the broker's original response for that row. It costs disk and buys the ability to backfill a field discovered in month three — which is not hypothetical: `CLAUDE.md` documents several fields whose meaning is still unverified across brokers (Alice Blue's `t1Quantity`, Paytm's `net_avg` for carry-forwards). Discovering that one of them matters, with no raw archive, means the history is simply gone.

*Rejected:* typed-only (smallest DB, and any unforeseen field is unrecoverable); raw-only (every risk query re-parses three vendor shapes at read time, and mapper bugs become permanent).

---

### D5 — `risk/` reads snapshots and never calls a broker

Enforced by ArchUnit rule A2.

**Consequence that must reach the UI:** "live risk" is really "risk as of the last capture". Every risk surface carries the same as-of stamp the portfolio pages do (§6). Risk that silently claims to be current when it is six hours old is worse than risk that is honestly stale.

**Consequence that is the point:** risk is deterministic and replayable. Given the same snapshot rows it produces the same numbers, offline, with no broker mock in any test. Every risk formula becomes unit-testable against fixtures.

---

### D6 — Package layout

Collapse the three one-controller packages; add three new ones.

```
com.MoneyPlant.tradestack
├── auth/            unchanged
├── broker/          unchanged + user-explicit fan-out (D3)
│   ├── kite/  aliceblue/  paytm/
├── credential/      unchanged
├── common/          unchanged
├── instrument/      + InstrumentKey (D7)
├── portfolio/       NEW — positions/ + holdings/ + account/ merged
│   └── dto/         MOVED from broker/dto/ (see D1 note)
├── analytics/       payoff, unchanged
├── snapshot/        NEW — capture job, store, retention
├── risk/            NEW — exposure, concentration, expiry, decay
└── marketdata/      NEW — spot, and later chains; absorbs SpotPriceService
```

`positions/`, `holdings/` and `account/` are one concept — *what the user holds* — split three ways for no reason beyond the URL path. Merging them is small and safe.

*Rejected:* layered `api/ domain/ infra/` (a deliberate reversal of a rule `CLAUDE.md` marks as locked, and a large diff across every file for no gain at this size); splitting `broker/` into `core/session/vendor-*` (that package is the most-changed code in the project and this is the wrong moment to churn it — revisit if it passes ~40 files).

**`marketdata/` absorbs `SpotPriceService` and `SpotPriceProvider` from `broker/`.** They already sit awkwardly there: `SpotPriceService` asks *any* connected broker for a quote, which is a market-data concern that happens to be served by brokers, not a broker concern. And `BrokerGateway.getLtp` is dead in all three implementations (Kite throws `PermissionException`, Alice Blue is hardcoded 0, Paytm cannot honour its Kite-shaped parameter) — **delete it** as part of D7, as `CLAUDE.md` already recommends. It is also the last remaining broker-shaped-string leak in the gateway interface, so A1 gets cleaner for free.

---

### D7 — `InstrumentKey` lands *before* the risk module

Symbol-model steps 2–4 are a **prerequisite**, not a parallel track.

Risk is the biggest new consumer of symbols in the project — expiry bucketing is literally "group by expiry", which means every leg must have a typed expiry, strike, right and underlying. Building it on `tradingSymbol` strings and a local parser guarantees a second migration through the newest and largest module, and reintroduces exactly the leak the 3 Aug decision was written to prevent.

It also fixes the snapshot schema: `instrument_key`, `expiry`, `strike` and `right` are columns in D4 from day one rather than a later migration over data captured without them.

*Cost, stated plainly:* this delays visible risk features by the length of symbol-model steps 2–4. That is the price of not doing it twice.

---

### D8 — Numerics: `double` internally, rounded at the DTO boundary

Greeks and IV solving need floating point — `BigDecimal` has no `exp`/`log`, so a `BigDecimal` core would convert to `double` and back at every Black-Scholes call, buying nothing.

What changes is that rounding becomes **deliberate and single-sited** rather than incidental:

| Quantity | Precision | Where |
|---|---|---|
| money (P&L, premiums, margins) | 2 dp | DTO serialisation |
| prices | 2 dp | DTO serialisation |
| quantities | integer | already |
| percentages | 2 dp | DTO serialisation |
| greeks *(when they arrive)* | 4 dp | DTO serialisation |
| IV *(when it arrives)* | 2 dp, as a percentage | DTO serialisation |

This closes the `-20339.999999999985` payoff-tooltip issue at its source rather than in a frontend formatter.

*Rejected:* `BigDecimal` for money with a typed boundary into the pricing world (correct, but touches every DTO and all three mappers); a `Money(long paise)` value type (best of the three in the abstract; requires re-agreeing the JSON contract with the frontend, and D11's type generation makes that cheaper later — **revisit at the multi-user step**, not now).

---

### D9 — Risk features: four, all deterministic. No LLM yet.

| Feature | Needs | Ready when |
|---|---|---|
| **Exposure & concentration** | positions only | immediately after D7 |
| **Margin & capital utilisation** | `/api/margins`, already works | immediately |
| **Expiry & time bucketing** | `InstrumentKey` | after D7 |
| **Premium decay tracking** | the snapshot series | after D3 + one week of capture |

Everything is a **plain computed number** with a formula that can be checked by hand. No LLM in this step: the core has to be verifiable before anything narrates it.

**Greeks and IV are explicitly not committed**, and go on the feature list as *"may compute locally later"*. If they are built, the shape is decided: a Spring-free `pricing/` package beside `PayoffEngine` — Black-Scholes plus a Newton/bisection IV solve, taking spot, strike, time-to-expiry, rate and option price. Taking greeks from brokers instead was considered and is worse: three vendors, three definitions of theta, and the numbers vanish the moment a broker disconnects.

Greeks have a hard prerequisite of their own: **per-leg option premiums**, which the stack does not have. `SpotPriceService` covers indices and equities via Paytm; it does not price individual strikes. The open lead remains Alice Blue's `POST /obrest/optionChain/getOptionChain`, still unverified against a live token. That verification is the gate for greeks, and separately for most of Step 8.

**LLM, when it arrives**, has one rule fixed now so it cannot be bolted on badly: **broker credentials, tokens, API keys and secrets never enter a prompt.** Prompt context is built from risk output only — numbers already computed and already shown to the user.

---

### D10 — Read model: snapshot-first, refresh behind it

Every read endpoint serves from Postgres immediately and refreshes in the background.

```
GET /api/positions
  → snapshot rows                    ~20ms
  → freshness: SNAPSHOT, asOf 15:34
  → triggers an async broker fan-out
  ...
next poll (30s)
  → freshness: LIVE, asOf just-now
```

Broker latency stops being a blocking cost and becomes a progress indicator. On a cheap box this is also the cheapest option: a page view costs one indexed query instead of three outbound HTTPS round trips.

*Rejected:* parallel + cached live fan-out (still 1–2s cold, and load scales linearly with users × page views — the thing that breaks first at "hundreds"); per-broker streaming (feels fast, complicates `BrokerAggregate` and every consumer); server-push warm data (smoothest, most expensive in memory, and pointless while sessions die daily).

#### The contract change

`BrokerAggregate<T>` gains three fields:

```java
public record BrokerAggregate<T>(
        List<T> items,
        List<BrokerWarning> warnings,
        Instant asOf,          // null when freshness == NONE
        Freshness freshness,   // LIVE | SNAPSHOT | STALE | NONE
        boolean refreshing     // a background fan-out is in flight
) { ... }
```

| Value | Meaning | UI |
|---|---|---|
| `LIVE` | fetched from brokers within this request cycle | no badge |
| `SNAPSHOT` | today's capture | "as of 15:34" |
| `STALE` | older than today | "as of Tue 5 Aug", muted |
| `NONE` | never captured for this user | skeleton, not an empty state |

One field set on the existing envelope, so every consumer gets it free and there is one place to render it.

*Rejected:* per-item `asOf` (most accurate for mixed-broker books, but a table with three different ages has no coherent header — revisit if it becomes a real complaint); HTTP headers only (TanStack Query hands components the body, not the headers).

**Mixed-age books are a real case** — Kite may have refreshed while Paytm's token is dead. The envelope reports the **oldest** contributing source, so the stamp is never optimistic. Per-broker detail is already available in `warnings`.

**Refresh signalling: keep polling.** Positions already refetch every 30s. A refresh triggered by the first load lands within one poll. Zero new infrastructure, no long-lived connections, no per-user server memory — which matters directly at "hundreds" on a free-tier box. SSE was rejected on exactly that cost.

**Cold start** (`freshness: NONE`): return an empty aggregate with `refreshing: true` and let the UI show its **skeleton**, not its empty state. The app must never say "no positions" when it simply hasn't asked yet.

---

### D11 — Two repos stay; the TS types get generated

The white-screen incident and 3d's "contract pair that must merge together" are the same bug: **types are hand-copied between repos**, so drift is invisible until runtime.

- Backend emits an OpenAPI spec at build time.
- Frontend generates `src/types/api.ts` from it (`npm run gen:api`).
- CI runs the generator and fails on any diff against the checked-in file.

Contract drift becomes a **red build in the repo that caused it**, instead of React minified error #31 on a deployed page.

*Rejected:* monorepo (fixes the class of bug outright and is genuinely tempting; costs a history rewrite plus re-tooling `deploy.sh` and both CIs — not worth it while generation solves the observed failure); convention only (this is what `deploy.sh` already does, and it was bypassed by hand); `/api/v1` versioning (real decoupling, real ongoing cost maintaining two shapes for two users).

**Frontend ADR:** `src/types/api.ts` is generated. Hand-edits are rejected in CI.

---

### D12 — Frontend performance

*The owner deferred this call; here is the reasoning, not just the choice.* All four, because each is small, none constrains anything later, and together they are what "smooth on a cheap box" actually means when the server is doing snapshot reads in 20ms — at which point the remaining latency is all client-side.

| Measure | Why |
|---|---|
| **Route-level code splitting** | `recharts` is the heaviest dependency in the bundle and is used on exactly one route. Lazy-loading payoff, settings and holdings cuts first paint on the landing and dashboard, which is what a new user sees first. Two lines per route. |
| **Persisted query cache** | TanStack Query persisted to `localStorage`, so a returning user sees their last book before any network call. This is the *client-side twin* of D10 — same idea, same as-of honesty, one layer up. It's also what makes a cold JVM invisible after a deploy. |
| **Skeletons everywhere** | `TableSkeleton` already exists; make it a rule that every data surface has a skeleton matching its final layout. Nothing reflows, which is most of what "smooth" means perceptually. D10's `NONE` case depends on this. |
| **Static SPA, no SSR — recorded as a decision** | Caddy serves immutable hashed assets from disk at zero server cost. On a free-tier box with a JVM and Postgres already resident, an SSR runtime is the worst possible place to spend memory. Written down so Next.js doesn't get proposed later on general enthusiasm. |

**Frontend package rules**, adopted as the enforcement half:

- `features/<a>/` may not import from `features/<b>/`. Shared code moves to `lib/` or `components/`. Lint-enforced.
- `pages/*.tsx` compose feature components and hooks only — no fetching, no business logic.
- `lib/api.ts` stays the only place `fetch()` is called.
- `src/types/api.ts` is generated and read-only (D11).

The first three are already true by convention. Making them lint rules is what keeps them true when the codebase doubles.

---

## 3. Deferred, with triggers

Deferring is fine. Deferring without a trigger is how debt becomes permanent.

### Snapshot data posture — **deferred**

Snapshots put other people's actual holdings and P&L in Postgres in plaintext, indefinitely, and `raw` JSONB additionally carries broker client codes and account numbers (Kite's `clientId`, Alice Blue's `clientId`, Paytm's user details). Today the DB holds only encrypted API secrets.

Accepted for two consenting, known users. Fidelity is the whole point of `raw`, and redaction lists would silently miss fields in payloads that are not fully mapped — which describes two of the three brokers.

**Revisit when ANY of these becomes true:**

- a third user is added;
- signup stops being manual;
- the database becomes reachable from outside the VM;
- a backup is stored off-box.

**What "revisit" means:** a stated retention window, a `DELETE`-cascade offboarding path across `broker_credential`, `position_snapshot`, `holding_snapshot` and `capture_run`, and a decision on whether `raw` gets a shorter TTL than the typed rows. Encrypting snapshot rows is *not* the answer — it breaks every aggregate query the risk module exists to run.

### Sessions in memory — deferred to Step 7

`ConnectionService` is a `ConcurrentHashMap`. This is what pins the app to one JVM. Unchanged here, because tokens still die daily and no broker issues a refresh token, so there is nothing durable worth persisting.

**Revisit when:** a second instance is needed (scaling, blue/green, zero-downtime restart), or `FileSessionStore` — which still writes plaintext tokens under `MP_SESSION_STORE` — needs to die.

### Greeks and IV — on the feature list, not committed

See D9. **Gated on** verifying Alice Blue's option chain against a live token.

### `Money` value type — revisit at multi-user

See D8. Cheaper once D11's type generation exists.

---

## 4. What breaks at "hundreds"

Written down now so the wall is visible before it's hit. None of this is work for this step.

| # | Breaks | Why | Fix when it matters |
|---|---|---|---|
| 1 | **Single JVM** | `ConnectionService` is in-memory; `@Scheduled` assumes one instance | Sessions to Postgres, plus ShedLock or a PG advisory lock |
| 2 | **EOD capture burst** | N users × 3 brokers, all at 15:35, sequentially | Stagger the window, bound concurrency, respect per-broker rate limits |
| 3 | **`MP_ALLOWED_EMAILS`** | Every new user is a redeploy | `users` table — already the plan for invite-only |
| 4 | **Sequential fan-out** | `BrokerService.fanOut` is sequential on purpose ("two or three brokers… does not justify an executor") | True per request; false for the capture job across users. Parallelise the *job*, not the request |
| 5 | **Snapshot table growth** | Every user × every position × every day, with a `raw` blob each | Partition by `trading_day`; the retention policy from §3 |
| 6 | **No per-user quota** | One user's refresh loop can exhaust a broker rate limit shared with nobody — but LLM spend, when it arrives, *is* shared | Per-user budget at the LLM boundary |

Items 1 and 2 are the first to bite.

---

## 5. Sequencing

Four sub-steps. Each is independently mergeable, green, and leaves `main` deployable. Branch names identical in both repos, per the existing convention.

### 4a — Foundations *(small–medium)*

**Backend**
- ArchUnit suite: rules A1–A4, plus A5 once D3's user-explicit API exists.
- Move shared DTOs out of `broker/dto/` (D1 note) — do this *first*; A2 depends on it.
- Collapse `positions/` + `holdings/` + `account/` → `portfolio/` (D6).
- `SpotPriceService`/`SpotPriceProvider` → `marketdata/`; delete `BrokerGateway.getLtp` (D6).
- OpenAPI spec emitted at build (D11).
- **Minimal raw capture** — see below.

**Frontend**
- `npm run gen:api`, generated `src/types/api.ts`, CI diff check (D11).
- Lint rules for feature isolation and the `fetch()` restriction (D12).
- Route-level code splitting; persisted query cache (D12).

**Docs**
- `docs/adr/` in both repos; backfill ADRs 0001–0010 (D2).
- ADRs 0011+ from this document (§10).
- `CLAUDE.md` cut down to code-truth plus pointers.

#### Minimal capture ships in 4a, ahead of its schema

Every trading day without capture is a day of series that can never be recovered. So a **deliberately dumb** append-only table and the 15:35 job ship with the hygiene work:

```sql
V3__raw_capture.sql
  raw_capture(id, user_id, connection_id, broker_id,
              trading_day, kind, raw jsonb, captured_at)
  capture_run(...)   -- the gap marker from D3
```

No typed columns, no risk consumer, no contract change. 4c then **migrates over data that already exists** rather than starting from zero — parsing `raw` into the typed schema, backfilled from day one.

This is the one place the strict order is broken, on purpose: it is the only decision in this document whose cost is paid in *elapsed time* rather than effort.

It still needs D3's user-explicit fan-out to exist first. That work moves into 4a with it.

### 4b — InstrumentKey *(medium)*

Symbol-model steps 2–4 (`tradestack/docs/symbol-model.md`): the `InstrumentKey` type, switching consumers, `/api/debug/symbols`. Closes the two known leaks that doc names — **together, not in isolation**, since they change what the UI displays.

Prerequisite for 4c's typed schema and 4d's expiry bucketing (D7).

### 4c — Snapshots and the freshness contract *(large)*

- Typed `position_snapshot` / `holding_snapshot` / `margin_snapshot`, migrated from `raw_capture` (D4).
- Snapshot-first read model (D10).
- `BrokerAggregate` gains `asOf` / `freshness` / `refreshing`; frontend renders the as-of stamp and the `NONE` skeleton.
- Background refresh triggered on read; 30s polling picks it up.

**This is where a contract-pair merge matters most** — and where D11's generated types earn their keep for the first time.

### 4d — Risk module *(large)*

- `risk/` reading snapshots only, A2-enforced.
- Exposure & concentration; margin & capital utilisation; expiry & time bucketing; premium decay (D9).
- `/app/risk` page, plus two or three headline numbers promoted onto the dashboard.
- Risk surfaces carry the same as-of stamp as the portfolio pages (D5).

---

## 6. Acceptance

**4a**
- `mvnw test` fails if a vendor type is imported outside its package, if a gateway declares a session or credential field, if a controller imports a repository, or if `risk`/`analytics` imports `broker`.
- Backend suite green; `npm run typecheck` green.
- A deliberate backend contract change, committed without regenerating, turns the frontend CI red.
- `raw_capture` has rows after one trading day, and a `capture_run` row per user — including `NO_SESSION` for a user who didn't connect.
- `CLAUDE.md` under 20 KB; every backfilled decision reachable from it by pointer.

**4b**
- No `String` symbol crosses a module boundary. `/api/debug/symbols` resolves every symbol appearing in a live position, on all three brokers.

**4c**
- A cold page load renders portfolio data in under 100ms server-side, with an accurate as-of stamp.
- A user with no snapshot sees a skeleton, never "no positions".
- A book with one dead broker token reports the *oldest* contributing source.
- Snapshot rows for a captured day are byte-reconstructible from `raw`.

**4d**
- Every risk number has a unit test against fixture snapshots, with no broker mock anywhere in `risk/`.
- Premium decay renders a visible break across a `NO_SESSION` day, not a straight line.
- Every risk surface shows its as-of stamp.

---

## 7. New ADRs from this document

To be written in 4a, in `tradestack/docs/adr/` unless marked.

| ADR | Subject | Source |
|---|---|---|
| 0011 | Boundaries enforced by ArchUnit in the normal build | D1 |
| 0012 | Risk reads snapshots, never brokers | D5 |
| 0013 | Snapshot store: typed columns plus raw JSONB | D4 |
| 0014 | EOD capture, and gaps recorded rather than interpolated | D3 |
| 0015 | Fan-out is caller-scoped; the user-explicit path is unreachable from HTTP | D3 blocker |
| 0016 | Snapshot-first reads; `asOf`/`freshness` on `BrokerAggregate` | D10 |
| 0017 | Single-instance deployment, and what it blocks | §1, §4 |
| 0018 | `double` internally, rounded at the DTO boundary | D8 |
| 0019 | `InstrumentKey` before the risk module | D7 |
| 0020 | Package layout: `portfolio/`, `snapshot/`, `risk/`, `marketdata/` | D6 |
| 0021 | Two repos, generated TS types | D11 |
| 0022 *(frontend)* | `src/types/api.ts` is generated; hand-edits rejected | D11 |
| 0023 *(frontend)* | Static SPA, no SSR | D12 |
| 0024 *(frontend)* | Feature isolation; `lib/api.ts` is the only fetch layer | D12 |

---

## 8. Risks

**Called out during the interview and accepted by the owner:**

- **EOD capture is uneven.** It only runs for users who connected that day. Mitigated by gap markers (D3), not solved. It cannot be solved while brokers issue no refresh tokens.
- **Snapshot data posture is deferred** with plaintext holdings and un-redacted raw payloads. Triggers are in §3. This one has a real deadline attached to a real event — a third user.

**Identified while writing this spec:**

- **D3's blocker (§D3) is unplanned work.** The entire fan-out API is `SecurityContext`-scoped and a scheduled job cannot use it. Discovered by reading `BrokerService`, not anticipated in the interview. It is a prerequisite for the 4a capture, so it lands earlier than its size suggests.
- **Moving the shared DTOs out of `broker/dto/` has a wide blast radius** and must precede rule A2. Doing it late means rewriting imports across `risk/` too.
- **4c is a contract-pair change** of exactly the kind that produced the white-screen incident. D11's generated types are the mitigation and must be working before 4c starts — which is why they are in 4a.
- **Premium decay cannot be demonstrated until roughly a week after capture starts.** Worth knowing before it looks broken.
