# MoneyPlant — working context

**Generated from the code on 29 Jul 2026, last revised 5 Aug 2026 after 3c deployed and 3d was built.** This file is code-truth, not chat memory. Regenerate it when the architecture shifts.

---

## ▶ NEXT SESSION — DO THIS FIRST

**Status end of 5 Aug 2026. Steps 1, 2, 5, 3a, 3b and 3c are done and live. 3d is built and working locally, on a branch, not deployed.**

**`https://moneyplant.bonamnikhilbabu.in` is a working deployment.** DNS (Cloudflare, grey cloud) → OCI static IP → Caddy → `/var/www/moneyplant` for the SPA, `:8080` for the API. Google sign-in works, the backend is up under systemd, and the Kite prod redirect works end to end — all four 3c sub-steps are closed.

**3d — per-user broker credentials — is done and confirmed working on localhost by the owner.** Not on the VM. Full design in `CREDENTIALS-STEP3D.md`; what changed is summarised under Step 3d below.

`main` in both repos is current and in sync with origin (`tradestack 359cff8`, `frontend 6fe156f`). The five branches that were in flight all merged — tradestack PRs #8 and #9, frontend PRs #6 and #7. **No spent branches were deleted**, deliberately; they are still local and on the remote.

**One branch is in flight, in both repos, green, unpushed and unmerged:**

```
tradestack  step/3d-credentials   10f0c2a  credential/ package, Postgres, 3 commits
frontend    step/3d-credentials   611f51f  Settings page, write-only secret
```

They are a **contract pair and must merge together** — the TS types are the contract. Mismatched, the settings screen calls endpoints that do not exist.

**The app is genuinely multi-user.** Google sign-in with an env-var allowlist (two addresses now), `/api/me` real, connections keyed `{userId}:{brokerId}:{label}`, every fan-out scoped to the caller, and broker callbacks attributed by a single-use nonce minted in `/api/session/login-url`. Kite's flow is verified live. Backend suite is **131 green on `main`, 166 on `step/3d-credentials`** — plus a `db`-tagged repository suite excluded by default (`mvnw test -DexcludedGroups=`, Docker required).

### Local development now needs Postgres

Set up 5 Aug and working:

- **PostgreSQL 16 on port 5433** (`winget install PostgreSQL.PostgreSQL.16 --force` — the plain install 403s partway through EDB's CDN). It installs unattended, so the superuser password is the winget default `postgres`, not one you chose.
- A **pre-existing PostgreSQL 17 holds 5432** and is now set to Manual and stopped, to save memory. `Start-Service postgresql-x64-17` if anything ever wants it.
- Role and database: `moneyplant` / `moneyplant`, owner `moneyplant`.
- `MP_DB_URL=jdbc:postgresql://localhost:5433/moneyplant` and `MP_CREDENTIAL_KEY` (32 random bytes, base64) are in the **user** environment.

**Docker is deliberately not used locally.** Docker Desktop on Windows runs a WSL2 VM costing ~2 GB before Postgres starts, which is the wrong trade on an 8 GB laptop already running Chrome, an editor, Vite and a JVM. The VM *does* use Docker (`tradestack/deploy/docker-compose.yml`, `postgres:16-alpine`), so the next service — Redis, most likely — is one more block there rather than a second deployment style. Same real Postgres either side; only `MP_DB_URL` differs.

**`setx` only affects new processes.** An editor or shell started before it was run still has the old environment, and the app then dies at startup naming `MP_CREDENTIAL_KEY`. That is the guard working, not a bug — restart the process.

All three brokers aggregate. Field-level references — including every place each vendor's docs are wrong — are in `tradestack/docs/aliceblue-api.md` and `tradestack/docs/paytm-api.md`. **Read the relevant one before touching a gateway.** The Step 3 plan — identity model, why there is no Postgres, the local/prod split — is in **`DEPLOY-STEP3.md`**, beside this file.

**App-level broker registrations are finished as a concept.** The advice here used to be "only Kite needs a prod registration, do not chase the other two" — 3d made that permanent rather than temporary. There is no app-level registration for any broker any more, and no throwaway strings in the env file either: each user registers their own developer app at each broker they want, and supplies its key and secret in Settings. One useful side effect is that the one-redirect-URL-per-registration limit stops being a shared bottleneck, because each user owns their own.

1. ~~**Finish 3b — account labels and the session-status reshape.**~~ **Done 5 Aug**, both repos. See the 3b remainder note under Step 3 for the two deliberate deviations from the spec. **Unverified live** — the shape is covered by tests, but no broker has been connected against it, and Paytm's label lookup in particular is a guess that wants one real connect to confirm.
2. ~~**Render connect errors on `/app`.**~~ **Done 5 Aug.** `ConnectError` reads `?error=`, strips it so a refresh cannot resurrect it, and offers a per-broker retry; `connect_expired` gets its own message and no retry button, since the backend never learned which broker it was.
3. ~~**Finish 3c — deploy.**~~ **Done 5 Aug.** All four sub-steps closed: Kite's prod app re-pointed at `https://moneyplant.bonamnikhilbabu.in/kite/callback`, `/etc/moneyplant/moneyplant.env` created, the jar deployed under systemd, and the prod redirect URI added in the Google console beside the localhost one. Sign-in and the Kite connect flow both work live. **Runbook: `tradestack/deploy/README.md`.**

   **Three things that cost time and will again.**

   - The VM had **nginx installed holding `:80`**, so Caddy came up serving its own default welcome page rather than `/var/www/moneyplant`. The tell was `Last-Modified: 2023` and a 15 kB body — a packaged file, not a Vite build. The Caddyfile is also keyed to the hostname, so `curl http://localhost` does not match that site block; test with `-H "Host: moneyplant.bonamnikhilbabu.in"`.
   - **A blank white page on `/app` after a successful sign-in** meant the deployed frontend and backend came from different branches. The frontend was built from `step/3b-account-labels` while the jar was built from `main`, which still returned the old broker-keyed `{id, connected}` shape. React then received an object where it expected a string and threw **minified error #31**, killing the whole page. Note this contradicts what this file predicted at the time — it said mismatched halves would make the broker chips "silently disappear rather than error". They do not; it is a hard white screen, because the stale array's elements reach JSX as objects. `deploy.sh` checks out the same branch in both repos precisely to prevent this, and this deploy went around it.
   - `curl .../api/me` returning **401 is success** — it means the app booted and the security chain is wired.
4. ~~**Then 3d — per-user broker credentials.**~~ **Built 5 Aug and working locally**, on `step/3d-credentials` in both repos. Not deployed. Full design in **`CREDENTIALS-STEP3D.md`**; deviations and what actually landed are under Step 3d below.

   **Next action is deploying it**, and it is not a drop-in — the VM will refuse to start until three things exist:

   1. **Postgres on the VM**: `cd deploy && POSTGRES_PASSWORD=... sudo -E docker compose up -d`. The compose file binds to `127.0.0.1:5432`, not `0.0.0.0` — Docker writes its own iptables rules, so the OCI security list would *not* have saved you from the default `5432:5432`.
   2. **`MP_DB_URL`, `MP_DB_USER`, `MP_DB_PASSWORD` and `MP_CREDENTIAL_KEY`** in `/etc/moneyplant/moneyplant.env`. Generate the key with `openssl rand -base64 32` and **back it up somewhere that is not the VM** — losing it strands every stored secret, and the only recovery is every user re-entering their credentials.
   3. The **six broker variables deleted** from that file. They are dead: nothing reads them.

   Then the human cost, which is now the real gate: **each user must register their own Kite Connect app and pay Kite's monthly fee** before they can connect anything. The second allow-listed user cannot use the app until they do.
5. **One cheap experiment while connecting brokers anyway: does Alice Blue forward unknown query parameters?** If it does, `AliceBlueSessionService.loginUrl(state)` becomes a one-line change, it joins Kite and Paytm, and `PendingConnect.consumeSolePendingFor` becomes dead code to delete. Alice Blue is the only broker relying on that fallback.
6. **Then the real prize: verify Alice Blue's option chain** (`POST /obrest/optionChain/getOptionChain`). Still the highest-leverage unknown in the project — per-strike `ltp` and `oi` at no extra cost would unblock Step 6 and most of Step 8, which is the part described as the core of the product.
7. **Symbol-model step 2 (`InstrumentKey`)** remains queued. Decision recorded 3 Aug — see below.

### Decided 3 Aug: the application owns its symbols

> **MoneyPlant speaks its own vocabulary end to end. Broker symbols exist only inside that broker's adapter, and only at the moment a call is made.**

This is the Anti-Corruption Layer already stated below for *types* ("broker SDK types never leak past the gateway"), extended to *names* — which had leaked much further, because a `String` passes through any signature without complaint.

Full model, migration and trade-offs are in **`tradestack/docs/symbol-model.md`**. That doc's own recommendation was the middle path (do step 1, defer the rest); **that was overruled — the full model is the target.**

Status: step 1 (`UnderlyingRegistry` + `underlyings.properties`) is done and shipped. Steps 2–4 (`InstrumentKey`, switch consumers, `/api/debug/symbols`) are next. Two known leaks the next step must close are listed in that doc — do **not** fix them in isolation, because they change what the UI displays.

### ⚠ Before deploying

- ~~**`PaytmDebugController` must be gone.**~~ **Done in 3b.** Deleted along with `mp-pm-raw`, `mp-pm-spot` and the `/kite/login` dev helper.
- **`MP_SESSION_STORE` must be unset.** It writes live broker tokens to `~/.moneyplant/sessions.json` **in plaintext**. It defaults to off and has to be switched on deliberately, so this is a "don't copy your dev env to the server" check rather than a code change. On a reachable host that file is a credential for a real brokerage account. `FileSessionStore` goes away entirely when Step 3/7 puts sessions in Postgres.
- ~~**`KiteProperties` has the silent-placeholder hazard.**~~ **Fixed in 3a.** The guard is now `common/RequiredConfig.requireResolved`, shared by all three brokers and by the Google client credentials, instead of being copy-pasted into two session services and missing from the third.

- ~~**Broker callbacks are `permitAll()` and attribute nothing.**~~ **Closed in 3b.** They are still `permitAll()` and must stay that way — 3a briefly made them authenticated and it broke the connect flow outright, because the session cookie does not survive the broker's cross-site redirect (measured: `present=false`). Attribution is now a single-use nonce minted in `/api/session/login-url`, which *is* authenticated. Kite carries it in `redirect_params`, Paytm in its native `state`; Alice Blue can carry nothing and falls back to "exactly one pending flow for this broker, or refuse".

- **`MP_COOKIE_SECURE` must be `true` on the VM.** The session cookie is `SameSite=Lax` and `Secure` is per-host, defaulting false so plain-HTTP localhost works. Over HTTPS without it the cookie still functions, so nothing will look broken — it will simply be travelling less protected than it should.

- **`MP_CREDENTIAL_KEY` must be backed up off the VM (3d).** It is the only thing standing between a database dump and every user's live broker secrets, which is why it is deliberately not stored in the database. It is also unrecoverable: change or lose it and every stored secret is stranded, surfacing as `BROKER_CREDENTIAL_UNREADABLE` and fixable only by each user entering their credentials again. Rotation is a backfill driven by `broker_credential.key_version`, never an edit to the variable in place.

- **`spring-boot-flyway` must stay in the pom (3d).** Boot 4 split autoconfiguration into per-technology modules, so `flyway-core` is the library and `spring-boot-flyway` is the wiring that runs it at startup. With only the former the app boots perfectly, logs *nothing whatsoever* about Flyway, and the schema silently stays empty until the first query fails on a missing table. The test suite cannot catch this — it disables Flyway on purpose so the default build needs no Postgres — so it is caught only by booting against a real database.

### Carried forward, none blocking

- **Alice Blue holdings quantity is `sellableQty + t1Quantity`.** Every sampled row had `t1Quantity: 0`, so if `sellableQty` already includes T1, freshly-bought stock double-counts. Check on a day with a same-day purchase.
- **Paytm `net_avg` is unverified for carry-forward positions.** It is a genuine weighted average cost in every sampled row, but all had `tot_buy_qty_cf: 0`. If Paytm rebases it to the previous close overnight, it becomes the same trap as Alice Blue's `netAveragePrice`. Check on a position held over a night.
- ~~**`spot` is 0 on all three brokers.**~~ **Fixed 3 Aug** via Paytm's `/data/v1/price/live`, verified live during market hours. `SpotPriceService` asks *any* connected broker, so a Kite or Alice Blue curve gets its spot from Paytm. The UI must still hide the card and reference line on a 0 — that path is now "no broker could quote it", not "always".
- ~~**Paytm has no day-change figure in its positions payload.**~~ ~~**Paytm's live-price response also carries `change_absolute`.**~~ **Both closed 4 Aug**, together with the P&L bug below — one batched quote call fills `ltp`, `pnl` and `dayChange` for every Paytm leg. `mode=LTP` does return `change_absolute`, so no extra call and no second mode were needed.

- ~~**Paytm P&L was 0 on every row.**~~ **Fixed 4 Aug, verified live.** The cause was not the mapper, which was correctly refusing to compute `(0 − 27.69) × 65` from a missing price. It was the *reason* recorded for the missing price: `last_traded_price` in Paytm's positions payload was documented as "0.0 outside market hours", from a payload captured at 11pm. **That was wrong** — at 10:44 IST with the market open and both other brokers quoting live on the same fan-out, every Paytm row was still 0.0. The field is never populated on that endpoint. Positions are now priced from `/data/v1/price/live`, which each row can address itself: it carries `security_id` and `instrument_type`, so no security-master lookup is involved.

  `NSE:<id>:OPTION` is now **verified live** — it was the load-bearing guess, since only INDEX and EQUITY had been confirmed. `FUTURE` follows the same grammar but is still unverified, having no live future to test against. The quote path never throws: a failed or empty quote falls back to realised-only P&L and logs why, so a bad pref costs a log line, not the positions table.
- **`last_update_time` in the live-price payload is not a current epoch second** (`1470196447` = Aug 2016 read as one). Do not surface it as a quote timestamp without working out the real encoding.
- **Payoff points carry float noise** (`-20339.999999999985`). Invisible on a chart, visible in a tooltip. Round at the DTO boundary.
- ~~**CLAUDE.md is not version-controlled.**~~ **Wrong — it always was.** The directory above both repos is itself a git repo, and `CLAUDE.md` is tracked in it. `UX-STEP2.md` and `DEPLOY-STEP3.md` now are too, committed 3 Aug.

---

## What this is

Options trading stack for NSE F&O. The core value is **multi-broker position aggregation** (Kite + Alice Blue + Paytm Money) with payoff graphs, because Alice Blue and Paytm lack decent position visualisation.

**Decided 29 Jul: this is a real product, not just a personal tool.** Target is a limited number of users, run safely, on minimal infrastructure cost. That reverses three earlier deferrals — authentication, persistence and multi-tenancy are now in scope rather than "only when a second user exists". It also means the app cannot be deployed until real auth exists (see Step 3).

 Wants **guided coding, not full dumps** — but will ask for full code on specific methods. Career switch is priority #1;

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

- `tradestack` `origin/main`: `359cff8 Merge pull request #9 from bnmnikhil/fix/paytm-position-pricing`
- `frontend` `origin/main`: `6fe156f Merge pull request #7 from bnmnikhil/step/3b-connect-errors`

Branch names stayed `step/3a-auth` in both repos even though the final commits covered 3b as well. 3a and 3b landed together rather than as the separate pair the plan assumed.

**"Delete the branch" is not being honoured**, by choice as of 5 Aug. Every merged `step/*` branch is still local and on the remote — `step/1-aliceblue`, `step/1e-1f-…`, `step/2-ui-rework`, `step/3a-auth`, `step/3c-deploy`, plus the 3b and Paytm branches — along with the older `origin/V1` and `origin/V2--payoff-graph-one-broker`. Nothing depends on cleaning them up; it is deferred rather than forgotten.

**There is no PR template**, despite the line above saying the gates are in one. The gates are real and both were run on every branch merged so far; the template simply does not exist in either repo.

## Backend architecture (locked — do not relitigate)

Package-by-module under `com.MoneyPlant.tradestack`:

| Package | Contents |
|---|---|
| `broker/` | public: `BrokerGateway`, `BrokerRegistry`, `BrokerService`, `ConnectionService`, `BrokerSession`, `BrokerSessionException`, `dto/` |
| `broker/kite/` | private per-broker: `KiteBrokerGateway`, `KiteProperties`, `KiteSessionService`, `KiteSessionController` |
| `instrument/` | `InstrumentService`, `OptionInstrument`, `InstrumentType`, `InstrumentController` |
| `analytics/` | `PayoffEngine`, `PayoffService`, `PayoffController`, `Leg`, `PayoffResult` |
| `positions/`, `holdings/`, `account/` | thin controllers over `BrokerService` |
| `common/` | `ApiExceptionHandler`, `RequiredConfig` |
| `credential/` | **3d.** `BrokerCredentials`, `CredentialCipher`, `BrokerCredentialRepository`, `BrokerCredentialService`, `BrokerCredentialController`, and the two exceptions |

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

**Sessions stay in-memory, with one opt-in local exception.** Broker tokens die daily under SEBI rules, so there is nothing durable worth persisting and no token encryption problem to solve.

The exception, added 3 Aug: **`SessionStore` behind `ConnectionService`**, off unless `MP_SESSION_STORE=true`. It exists because Paytm's login is a password *and* an OTP every time — their flow issues three access tokens and **no refresh token**, so there is no renewal path — while Kite and Alice Blue re-auth is one button. Paying an OTP per backend restart was the actual cost.

- It sits at `ConnectionService`, not in `broker/paytm`: that service is already the single `connectionId`-keyed chokepoint, and naming a broker there would break "a new broker needs zero changes". **This is the seam Postgres replaces in Step 3/7.**
- Restores only sessions created **today in IST** — stricter than any broker's real expiry, because restoring a dead token produces a confusing 401 while expiring early costs a login the user was making anyway.
- Writes outside the repo (`~/.moneyplant/sessions.json`) so no `.gitignore` mistake can commit a token. `sessions.json` is gitignored anyway as insurance against a custom path.
- Corrupt file, missing file and missing timestamp all fail closed to "no sessions" — a re-login, never a failed startup.

~~**Likely no credential encryption either.**~~ ~~Reversed 5 Aug.~~ **Built 5 Aug, in `credential/`.** The old reasoning was that app-level (vendor) OAuth means the *app* holds one api-key/secret pair in the environment and each user simply authorises, so per user you store the linkage rather than their secrets.

It was rejected on a different ground: it leaves open whether Zerodha's and Paytm's terms *permit* one registration serving several users. **Per-user credentials remove the question instead of answering it** — each user's API access is their own subscription, so there is no redistribution to reason about. Full design in **`CREDENTIALS-STEP3D.md`**.

The cost is real and was accepted knowingly: every user must register a developer app per broker and pay Kite's monthly fee, so onboarding stops being "sign in and press Connect".

### The 3d rule: credentials are a parameter, never a field

The rule above for sessions — *gateways are stateless, `BrokerSession` is a parameter* — extends to credentials, and for the same reason. `BrokerAuthProvider.loginUrl(BrokerCredentials, state)` and each `createSession(BrokerCredentials, …)` take them per call, which is exactly what lets **one set of beans serve two users whose Kite apps are different**. A credential held as a field would have made that impossible without a bean per user.

The two halves are split by sensitivity, deliberately:

| | Sensitivity | Where it lives |
|---|---|---|
| `apiKey` / `appCode` | identifier — already travels in login URLs | resolved at connect time, then **rides in `BrokerSession.tokens`** under `apiKey` |
| `apiSecret` | high — signs the session exchange | read from the encrypted store **only at session creation**; never in a session, never in a response, never logged |

`KiteBrokerGateway` builds `new KiteConnect(apiKey)` on *every* call, so the key has to be reachable per request; putting it in the session — already per-connection, therefore per-user — avoids a database read per gateway call while keeping the secret out of it entirely. `BrokerCredentials.toString()` is overridden so a stray `log.info("{}", creds)` cannot leak the secret.

**AES-256-GCM, key in `MP_CREDENTIAL_KEY`, never in the database.** GCM over CBC because it is authenticated: a tampered ciphertext, a tampered IV or the wrong key all fail loudly instead of yielding plausible garbage that would then be handed to a broker as a secret and come back as "invalid auth code" — the most misleading failure this codebase has already paid for once. A fresh random IV per seal is not optional; reuse under one key voids the guarantee outright. `CredentialCipherTest` spends most of its assertions there.

Schema is one table, `broker_credential`, keyed `(user_id, broker_id)` — **not** by connectionId, because one Kite Connect app can authorise two different Zerodha logins, so credentials belong to the broker relationship while account labels stay a connection concern. Still **no `users` table**: `MP_ALLOWED_EMAILS` governs sign-in and rows key off the Google `sub`.

~~`connectionId` will need to become user-scoped once users exist.~~ **Done in 3b** — `{userId}:{brokerId}:{label}`, as predicted a key-format change rather than a redesign.

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

standalone, from credential/ (3d):
    MissingCredentialsException     BROKER_NOT_CONFIGURED        409   "Go to Settings"
    CredentialDecryptionException   BROKER_CREDENTIAL_UNREADABLE 409   "Enter it again"
```

Body is `{error, brokerId, message}`; `brokerId` may be null, which is why the handler builds a `HashMap` rather than `Map.of`. Frontend mirrors this in `BrokerErrorBody` and fires a `moneyplant:broker-session-lost` event carrying `{brokerId, code}`.

**The two 3d codes deliberately do NOT fire that event and are not part of `isBrokerSessionError`.** That event drives the reconnect banner, and reconnecting fixes neither of them: one needs credentials entered, the other needs them entered again after a key rotation. Offering Connect would send the user through a full broker round trip that fails at the last step. They are 409 rather than 404 for the same reason as the first two — the resource is not missing, the request cannot proceed in the current state.

**Gateways must classify.** `KiteBrokerGateway.classify()` maps `TokenException` → session expired and *everything else* → call failed. Alice Blue and Paytm gateways must do the same; reporting a 503 as "session expired" sends the user through a pointless OAuth round trip.

**Kite SDK gotcha:** `KiteException` extends `Throwable` directly, not `Exception`. So `catch (KiteException | IOException e)` infers `Throwable` as the least upper bound, and any helper taking the caught variable must accept `Throwable`.

**Alice Blue classifies on HTTP status, not on an exception type.** A dead `userSession` is a plain-text `401 Unauthorized` with a non-JSON body, so the gateway checks the status code *before* deserialising — feeding `Unauthorized` to Jackson throws a parse error that would then be misread as transient. The gateway must also never let that 401 escape: `frontend/src/lib/api.ts` maps any 401 to a redirect to `/login`, so one dead broker token would otherwise log the user out of MoneyPlant entirely.

### P&L semantics — decided 30 Jul, applies to every broker

Brokers disagree on what "P&L" means, so `PositionDto` fixes both columns and each gateway fills whichever half its broker withholds.

| Field | Meaning | Kite | Alice Blue |
|---|---|---|---|
| `pnl` | lifetime, since entry, **rupees** | `p.pnl` as given | computed `(ltp − trueEntry) × qty + realizedPnl` |
| `dayChange` | today's move, **rupees** | computed `(lastPrice − closePrice) × qty` | `unrealizedPnl` as given |

**Never use a broker's P&L field without checking which of the two it means.** Alice Blue's `unrealizedPnl` is day mark-to-market; Kite's `pnl` is lifetime. A live example: 650 units bought at 5.20, trading at 7.25 — up ₹1,332 since entry, down ₹1,495 today. Same position, opposite sign.

The corollary for Alice Blue is that **`netAveragePrice` is not the entry price** — it is the M2M basis, and equals the previous close for anything carried overnight. `AliceBlueMapper.trueEntryPrice` reconstructs the real basis from `overnightPrice`/`dayBuyPrice`/`daySellPrice`. Same trap in holdings: use `investedPrice`, never `averageTradedPrice`.

Warning codes are unprefixed (`SESSION_EXPIRED`) because they sit inside a `BrokerWarning` object; error codes are prefixed (`BROKER_SESSION_EXPIRED`) because they sit bare in `{error: ...}`. Deliberate, not an oversight.

| Method | Path | Returns |
|---|---|---|
| GET | `/api/positions` | `BrokerAggregate<PositionDto>` |
| GET | `/api/holdings` | `BrokerAggregate<HoldingDto>` |
| GET | `/api/margins` | `BrokerAggregate<MarginDto>` — one row per broker, **frontend sums** |
| GET | `/api/me` | `{email,name,picture}` from the OIDC principal; 401 when absent |
| POST | `/api/logout` | 204. Served by Spring Security, not a controller |
| GET | `/api/session/status` | `{brokers:[brokerId], connections:[{connectionId,brokerId,accountLabel,connected}]}`, scoped to the caller. As of 3d `brokers` is **the brokers this user has credentials for**, not the registry |
| GET | `/api/broker-credentials` | One row per registered broker: `{brokerId, apiKey, configured}`. **Never returns a secret**, not even masked |
| PUT | `/api/broker-credentials/{brokerId}` | `{apiKey, apiSecret}` → 204. Upsert; both values always required, both trimmed |
| DELETE | `/api/broker-credentials/{brokerId}` | 204, or 404 when nothing was stored |
| GET | `/api/session/login-url` | `{url}` for any registered broker. **Mints the connect nonce** — this is the authenticated moment the callback later depends on |
| GET | `/api/payoff` | `CurveRef[]` — `{connectionId, brokerId, underlying}` per plottable curve |
| GET | `/api/payoff/{underlying}?connectionId=` | `PayoffResponse` incl. `brokerId`, `connectionId`, `spot` |
| GET | `/api/debug/instrument?symbol=` | `OptionInstrument` |
| GET | `/{broker}/callback` | public by necessity; attributed by nonce. Redirects to `${app.frontend-url}/app`, or `/app?error=…` on failure |

Frontend mirrors these exactly in `src/types/api.ts`. **Keep the two in sync — the TS types are the contract.**

## Frontend

- Routing: `/` landing, `/login`, then `AuthGuard` → `AppShell` → `/app`, `/app/positions`, `/app/holdings`, `/app/payoff`, `/app/settings`.
- **`/app/settings` is where broker credentials are entered (3d).** The secret field is write-only: it renders empty with "Stored" beside it rather than a row of dots, because a masked value would imply the real one is retrievable and it deliberately is not. That also settles what a blank secret means on an update — nothing, since both values are always required and there is no "leave unchanged" state to be ambiguous about.
- **`ConnectBrokerCard` has two empty states.** No credentials at all (`brokers` is empty) sends the user to Settings; credentials but no live session offers Connect. A disabled Connect button was rejected for the first case — it reads as busy or broken when the action needed is genuinely different.
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
2. ~~**`InstrumentService` cache is single-broker.**~~ **Done (1e).** Keyed by `(brokerId, symbol)` with `loadedOn` per broker.
3. ~~**`/api/session/status` and `/api/session/login-url` hardcode `"kite"`.**~~ **Done (1f).** Broker-neutral `SessionController` reads the registries; Alice Blue appeared in both with no change to that file.
4. ~~**`CONNECTION_ID` duplicated in 5 files.**~~ **Partly done (1b).** Gone from `PositionsController`, `HoldingsController`, `AccountController` — they use the fan-out and take no connectionId at all. Three legitimate single-connection uses remain: `KiteSessionController`, `AliceBlueSessionController`, and `PayoffService` (1g).
5. ~~**`vite.config.ts` doesn't proxy `/aliceblue`.**~~ **Done (Step 1).**

## Security — verified clean

6. **Credentials are correctly externalised.** `application.properties` holds `kite.api-key=${KITE_API_KEY}` / `kite.api-secret=${KITE_API_SECRET}`; real values live only in the owner's OS environment. Every committed blob of this file was checked (`1403b4e`, `0f9dedb`, `5b00f2c`) — all contain placeholders, never literals. No rotation needed. Repo pushes to `github.com/bnmnikhil/MoneyPlant`.

   Note for future audits: `git log -S"api-secret"` flags commits where the *occurrence count of that string* changed, so it fires when the placeholder line is merely added. It is not evidence of a leaked value — read the blob (`git show <sha>:<path>`) before concluding anything. Keep the same discipline when Alice Blue and Paytm credentials arrive: placeholders in `application.properties`, values in the environment.

## Correctness

7. **`getLtp` swallows the exception and returns 0.** Kite market-data subscription is not active → `PermissionException`. Tolerated as `spot: 0`. This blocks the spot line, option chain, Greeks and T+0. Paid add-on; decision deliberately pending.
8. **`unboundedProfit`/`unboundedLoss` use tail slope, not structure.** Should be derived from `netCallQty` / `netPutQty`. The slope heuristic misreads flat tails and books where legs offset near the edge of the window.
9. **Breakeven detection uses `Math.signum(prev) != Math.signum(cur)`.** `signum(0) == 0`, so a sample landing exactly on zero registers as two crossings and emits a duplicate breakeven.
10. **Payoff window never starts at 0** — `lo = max(0, minStrike - span*0.5 - maxStrike*0.10)`. For long puts the true max profit (at spot=0) is off-screen, so `maxProfit` is understated.
11. **Kite holdings ignore `t1Quantity`** — settled-but-not-delivered shows qty 0. The Alice Blue gateway adds T1 back (`sellableQty + t1Quantity`); Kite still does not, so the two disagree. **Unverified either way:** every sampled Alice Blue row had `t1Quantity: 0`, so if `sellableQty` already includes T1 the Alice Blue side double-counts. Check on a day with a same-day purchase.
12. ~~**`PositionDto.dayChange` is `lastPrice - closePrice`.**~~ **Fixed (Step 1)** — now `× netQuantity`, so it is rupees like `pnl` rather than a per-unit price delta sitting in a column of money. The underlying SDK field names are still unverified against kiteconnect 3.5.0.
13. ~~**`/api/logout` is called by the frontend but does not exist in the backend.**~~ **Done (3a).** Served by Spring Security's logout handler at that path, not a controller, so session and cookie teardown stay in one place.
14. ~~**`AuthGuard` is effectively a no-op.**~~ **Done (3a).** `/api/me` returns the real OIDC principal and 401s without one. Sign-in is Google + an env-var email allowlist; a rejected address is refused during the token exchange, so no session is ever created for it.
15. ~~**`PayoffLeg.type` missing `FUT`.**~~ Fixed in 1c.

15b. **`npm run build` was broken from the start** (fixed in 1c). `tsconfig.node.json` set both `composite: true` and `noEmit: true`, which is TS6310, so `tsc -b` always failed — meaning the project had never been type-checked, only transpiled by Vite. Emit now goes to `node_modules/.tmp`, `*.tsbuildinfo` is gitignored. **Run `npm run typecheck` after every frontend change.**

## Hygiene

16. **Line-ending churn** — all 29 backend source files show as fully modified (926 insertions / 926 deletions) with no semantic change. `.gitattributes` only covers `mvnw` and `*.cmd`. Add `* text=auto` and renormalise, otherwise every diff from here on is unreadable.
17. ~~**Dead code.**~~ **Done.** `PositionsService` and `BrokerController` deleted, `BrokerGateway`'s commented-out version removed. The other two claims were already stale: `PositionsController` carries no commented-out version, and `InstrumentController` no longer imports `KiteSessionService`.
18. ~~**`PayoffService.positions(BrokerSession s)` takes a session it ignores.**~~ **Already stale.** It calls `brokers.positions(connectionId)`; the ignored-parameter version is gone.
19. ~~**`spring-boot-starter-thymeleaf` is a dependency but there are no templates.**~~ **Done.** Both it and `-thymeleaf-test` dropped; the `Cannot find template location` warning is gone from test runs.

22. ~~**Duplicate `org.json.JSONObject` on the test classpath.**~~ **Done.** `android-json` excluded from `spring-boot-starter-webmvc-test`. `org.json:json` stays — it is compile-scoped via kiteconnect and cannot be dropped, so jsonassert now binds to the one that was always going to win at runtime.
20. ~~**`PayoffEngine` is annotated `@Service`** despite being described as pure-domain.~~ **Done.** Neither annotated nor injected — `PayoffService` constructs it directly, which is what `PayoffEngineTest` always did.
21. ~~**`DashboardPage` grid/label warts.**~~ Fixed in 1c.

---

# Roadmap

**Order agreed 29 Jul 2026.** Steps are sequential and most span both repos.

| # | Step | Gates |
|---|---|---|
| 0 | Multi-broker core (1a–1f) | ✅ done |
| 1 | Alice Blue integration | — |
| 2 | UI rework — group positions by broker and by instrument; fold in 1g | needs Step 1 |
| 3 | Login / real authentication | ✅ 3a–3c done and live; 3d built, not deployed |
| 4 | Deploy — OCI + Cloudflare DNS-only | ✅ done 5 Aug, folded into 3c |
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
- **1g ✅ done (30 Jul).** `PayoffService` iterates every live connection instead of the hardcoded `kite-default`. **Curves are grouped by `(connectionId, underlying)` and never merged across brokers**, confirmed by the owner. `/api/payoff` returns `CurveRef[]`; the selector appends the broker name only when more than one broker is connected, matching the positions/holdings tables. A broker that fails is skipped with a log rather than emptying the selector.

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

**Mostly built, 30 Jul.** Full field-level reference — including where the vendor docs are wrong — is in `tradestack/docs/aliceblue-api.md`. Read that before editing the gateway.

| File | State |
|---|---|
| `AliceBlueProperties` | done — `appCode` + `apiSecret` from env |
| `AliceBlueHttpConfig` | done — hand-built `RestClient`, 5s connect / 10s read |
| `AliceBlueSessionService` | done — checksum → `BrokerSession{userSession, clientId}` |
| `AliceBlueSessionController` | done — `/aliceblue/callback`, `"aliceblue-default"` |
| `AliceBlueJson` / `AliceBlueMapper` | done — lenient parsing + DTO mapping, 15 tests |
| `AliceBlueBrokerGateway` | positions, holdings, margins done; **`getInstruments` returns empty** |

The registry picked it up with **zero changes to existing controllers or the frontend**, as predicted.

**Field names came from the v2 REST API, not the old SDK.** The earlier note in this file listing `Netqty`, `Tsym`, `LTP`, `Opttype` and comma-formatted numbers described the **deprecated v1** API. v2 uses `netQuantity`, `tradingSymbol`, `ltp`, and plain (though sometimes string-typed) numbers.

**Remaining: the contract master.** Until `getInstruments` is real, Alice Blue positions appear in the table and margins but `PayoffService` cannot turn their symbols into legs, so they get no payoff curve — which is most of the reason for integrating Alice Blue. V2 JSON endpoint is `https://v2api.aliceblueonline.com/restpy/static/contract_master/V2/NFO`, regenerated daily at 08:00 IST (which matches `InstrumentService`'s per-broker `loadedOn`). Payload shape not yet inspected. V1 was discontinued 30 Nov 2025, so there is no fallback.

Possible shortcut worth weighing: Alice Blue trading symbols are self-describing (`HDFCBANK25AUG26P730` = underlying + DDMMMYY + P/C + strike) and positions also carry `formattedInstrumentName` and `lotsize`, so a symbol parser would avoid downloading ~100k NFO rows onto a small VM. The contract master is authoritative and the strategy builder will need it eventually.

## Step 2 — UI rework

Positions grouped **by broker** and **by instrument**, for a cleaner view. Exact design decided at the time.

This is a *display* concern and does not contradict the payoff decision above. The table may collapse two BANKNIFTY 55500 PE rows from different brokers into one line with combined quantity, while `PayoffEngine` still treats them as two legs. The arithmetic is identical either way — keep the layers distinct.

Also fold in **1g** here, so Alice Blue gets a payoff curve.

## Step 3 — Login / real authentication

**Full plan in `DEPLOY-STEP3.md`.** Split into 3a (auth), 3b (user-scoped connections), 3c (deploy) and 3d (per-user broker credentials, added 5 Aug — its own design doc, `CREDENTIALS-STEP3D.md`).

**3a ✅ done 3 Aug.** Google OAuth, email allowlist, real `/api/me` and `/api/logout`, `AuthGuard` no longer decorative. Verified live on localhost.

**3b ✅ core done 3 Aug, merged 4 Aug.** `connectionId` → `{userId}:{brokerId}:{label}` (userId is Google's `sub`, never the email — connectionId reaches the browser inside `BrokerWarning` and exception messages). `ConnectionService.allFor(userId)` with the unscoped `all()` *removed* rather than kept alongside. Fan-out, `sessions()`, `SpotPriceService` and `session(connectionId)` all scoped; the last also checks ownership, since `/api/payoff` takes a connectionId from the client and reports someone else's as "not connected" rather than "forbidden".

**3b remainder ✅ done 5 Aug.** `accountLabel` on `BrokerSession`, normalised in the canonical constructor so it is never blank, and `/api/session/status` reshaped.

Two deviations from `UX-STEP2.md` §Backend-1, both deliberate:

- **Two arrays, not one.** The spec's single `connections` array cannot express a broker nobody has connected, which is exactly what the Connect buttons are built from. A placeholder row would have made `connectionId` and `accountLabel` nullable for every consumer, so `brokers` stays a separate list of ids.
- **`accountLabel` falls back to the connectionId's *label segment*, not the whole id.** The spec predates user-scoped connectionIds — its example is `kite-default`. The id now leads with Google's `sub`, so falling back to it whole would render `110150585954237860845:kite:default` in a chip.

No broker needs an extra profile call except Paytm: Kite's `generateSession` already returns the client code on the `User` that carries the tokens, and Alice Blue's `clientId` is already in its login response. **Paytm's `/accounts/v1/user/details` response shape is unverified** — the client-code key is guessed from a candidate list, the call cannot throw, and the payload's field names are logged once per connect so the right key can be pinned from a live payload.

**3c ✅ done 5 Aug.** Deployed and working: HTTPS, Google sign-in, and a live Kite connect through `https://moneyplant.bonamnikhilbabu.in`. The three lessons worth keeping are in the numbered list at the top of this file.

**3d ✅ built 5 Aug, working on localhost, not deployed.** Per-user broker credentials in Postgres — see the "credentials are a parameter" section above for the model, `CREDENTIALS-STEP3D.md` for the full design. Backend 166 green.

Two deviations from the design doc, both small and deliberate:

- **`GET /api/broker-credentials` returns a row per registered broker, not per stored row.** The settings screen needs the unconfigured ones too — they are what it offers a form for — so absence is reported as `configured: false` rather than by omission.
- **`login-url` resolves the broker *before* the credentials.** Asking for credentials first would report an unknown brokerId as the far more ordinary "you have not configured this broker", which is true of `ghost` but useless. It also mints the nonce last, so a refused attempt strands no pending flow — which matters for Alice Blue, whose callback attributes by "exactly one pending flow, or refuse".

**Correction to the earlier note here:** this was *not* where most of Step 7 got built, and the claim that there is "no Postgres in Step 3 at all" held right up until 3d, which brought one table and no `users` table. Nothing per-user outlives a login *except credentials* — broker tokens still die daily under SEBI rules, no broker issues a refresh token, and the allowlist is still an environment variable. The rest of persistence stays in Step 7, arriving when saved strategies give it something to hold.

## Step 4 — Deploy

OCI VM with a reserved static IP (SEBI requirement). Caddy serves `dist/` and proxies `/api|/oauth2|/kite|/aliceblue` → `:8080`. Single origin. Cloudflare DNS vs OCI-only decided at the time. Minimal infra cost is an explicit constraint — prefer the OCI always-free tier and Postgres on the same VM over managed services.

**Redirect URL gotcha:** brokers allow **one redirect URL per app registration**. Deploying means `localhost:8080/kite/callback` and `<domain>/kite/callback` cannot both be live. Register a second app per broker for dev, and do it when registering Alice Blue so it is handled once for both.

## Step 5 — Paytm Money ✅ mostly done (31 Jul)

Auth, positions, holdings, margins working. Full reference in `docs/paytm-api.md`.

**Do not use Paytm's official Java SDK.** It is unpublished (system scope only, which `spring-boot-maven-plugin` drops from the fat jar — so it would work locally and fail on the VM), shaded with Spring Web 5.3 inside it, and pulls Jackson 2 into this Jackson 3 app. Reasoning in full in the doc. Reading its source was worth it; linking against it is not.

Remaining:

- ~~**Live market data.**~~ **Done 3 Aug, verified live.** `GET /data/v1/price/live?mode=LTP&pref=<exchange>:<security_id>:<type>`, URL-encoded, comma-separated for batches. Types are `INDEX`, `EQUITY`, `OPTION`, `FUTURE`. Confirmed against a live token during market hours: `NSE:25:INDEX` → BANKNIFTY 57524.9, `NSE:1333:EQUITY` → HDFCBANK. **None of this is in Paytm's docs** — they 404 and the SDK passes `pref` through as an opaque string.
- ~~**Security master.**~~ **Done.** `https://developer.paytmmoney.com/data/v1/scrips/security_master.csv`, no auth token, ~13 MB, ~87k rows, reloaded daily. Columns are located by header name, not position, and the split respects quotes — company names contain commas. `instrument_type` values: `OPTSTK` 62392, `OPTIDX` 16374, `ES` 7726, `FUTSTK` 640, `ETF` 598, `I` 73, `FUTIDX` 27.
- ~~**`getInstruments` returns empty.**~~ **Done** — 79,433 F&O instruments, keyed by the master's `name` column because that is exactly what positions return as `display_name`.
- **Equity spot needs NSE/EQ specifically.** The same ticker appears as `BSE/B`, `BSE/X`, `NSE/SM` and more with *different* security ids. NSE/EQ is 2,080 rows and unique per symbol; quoting any other row prices a different book.
- ~~**Confirm the app-level vendor flow** vs per-user API keys.~~ **Closed 5 Aug by decision rather than by investigation** — the stack moves to per-user credentials for all three brokers, so whether Paytm's vendor flow would have worked no longer matters. See `CREDENTIALS-STEP3D.md`.

## Step 6 — Strategy builder

Build a hypothetical strategy and see its payoff before placing it. Note two dependencies: it probably wants Step 7 (saving strategies), and it is only pleasant to use with live option prices, which needs market data.

## Step 7 — Persistence

`users`, `broker_links`. Postgres + jOOQ. Largely pulled forward into Step 3; what remains here is whatever Step 6 needs to save.

**Postgres arrived in 3d** (`CREDENTIALS-STEP3D.md`), carrying one table — `broker_credential`. Still no `users` table: the allowlist stays an environment variable and rows key off the Google `sub`. 3d uses `JdbcClient` + Flyway rather than jOOQ, because codegen is not worth a build step for a single table; jOOQ remains the right call here, when there are several.

Two things 3d leaves for this step to inherit: `FileSessionStore` still exists and still writes plaintext tokens under `MP_SESSION_STORE` (Postgres is now available to replace it properly), and the `db`-tagged Testcontainers suite is the pattern to follow for any further repository tests.

## Step 8 — Analysis features

Technical, fundamental, premium decay, risk/reward, LLM analysis. Described by the owner as the core of the product.

**Blocked on market data.** Every item runs through the price/option feed: technical needs history, premium decay needs option prices and IV over time plus stored series, risk/reward needs live premiums, LLM analysis needs something factual underneath. This is not "later work", it is *blocked* work.

## Backlog — user-configured brokers

**Priority: very far — but the first half landed in 3d.** `/api/session/status`'s `brokers` array is now "brokers this user has credentials for", which is exactly the shift described below at host-and-user level, and `/app/settings` is where that configuration happens. What stays far off is the scale part: a registry of tens of brokers and a UI for choosing among them.

The broker list *was* a global assumption: `BrokerRegistry` enumerated every broker the build knew about, and the UI offered all three to every user. That is no longer true of the connect flow — though `GET /api/broker-credentials` still enumerates the registry, correctly, because the settings screen has to offer a form for brokers the user has not configured yet. The long-term model is **each user configures which brokers they use, and how many accounts they hold at each**, at a scale sketched as "tens of brokers".

It changes what "disconnected" means. Today that is "a registered broker this user has no session for", which only works while the registry is small and every user plausibly wants all of it. At tens of brokers the answer has to come from that user's own configuration, not from the bean registry.

Let it break ties in present-day design without scheduling work: prefer contracts that can express *this user's* brokers and *per-account* identity over ones that hardcode a global list. It is already why `/api/session/status` returns `brokers` and `connections` as two arrays rather than one array with synthetic rows, and why `accountLabel` falls back to the connectionId's label segment — the segment a user will one day name themselves — rather than to the brokerId.

## Open decisions

- **Market data source. Largely answered 3 Aug: Paytm supplies it, free.** `/data/v1/price/live` covers indices and equities and is verified live. `SpotPriceProvider` + `SpotPriceService` route any broker's curve to whoever can quote it, so one Paytm connection prices Kite and Alice Blue positions too.

  `BrokerGateway.getLtp` is **effectively dead** and should be deleted in the symbol-model work. It returns 0 on all three gateways: Kite throws `PermissionException` (unsubscribed paid add-on), Alice Blue is hardcoded 0, and Paytm cannot honour its Kite-shaped `"NSE:NIFTY BANK"` parameter at all. That signature *was* the symbol leak — which is why the replacement is a separate interface taking a canonical underlying, not a fourth implementation of a broker-shaped string.

  Still missing: option-leg premiums (Step 6/8 need per-strike prices, not just spot) and history.

  **Lead found 30 Jul: Alice Blue's option chain may cover this at no extra cost.** `POST /obrest/optionChain/getOptionChain` returns per-strike `ltp`, `oi` and `pdc` (all as strings), with `getUnderlying` and `getUnderlyingExp` to enumerate underlyings and expiries. No subscription beyond the account, as far as the docs show. That is live premiums and open interest — the inputs Step 8 (premium decay, risk/reward) and Step 6 (strategy builder) are blocked on.

  It does not return the underlying spot directly. Two candidates: put-call parity near ATM (`spot ≈ strike + CE_ltp − PE_ltp`) from the same payload, or the Historical Data endpoint. **Unverified against a live token** — confirm before treating Step 8 as unblocked, and check whether broker API terms permit using one broker's feed to price another broker's positions.
- **Regulatory.** Serving other users changes the picture: broker API terms generally restrict redistribution to third parties without a vendor agreement, and offering analysis or recommendations in India can fall under SEBI Research Analyst / Investment Adviser rules. Worth confirming properly before Step 8 — cheap to check now, expensive to discover late. Not legal advice.

Explicitly out of scope: a Java backtester (stays offline in AlgoTest / Python), and propose-and-confirm order execution (only ever after a risk module exists).
