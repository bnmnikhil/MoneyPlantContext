# P0 Launch — the tracker

**Created 20 Aug 2026.** This file owns *status* for the first production launch: what is
done, what is in flight, what is still untouched. `CLAUDE.md` owns code-truth and points
here; `memory/` owns the reasoning. Do not duplicate status into either of them.

**Item IDs (A1 … F2) are the unit of work.** Take one, do it, run its verification, flip
its marker. One item per branch where the change is non-trivial; the branch name carries
the id (`p0/a2-nifty-lot-size`).

## Status legend

| Marker | Meaning |
|---|---|
| `[ ]` | not started |
| `[~]` | in progress — say who and when in the item's note |
| `[x]` | done **and its verification step has actually been run** |
| `[-]` | dropped — must carry a one-line reason |

An item is never `[x]` on the strength of "the code looks right". The verification line
exists because every wrong claim this project has carried was a claim nobody re-measured.

---

## What P0 means

MoneyPlant is already live and works for its author. P0 is not "make it run" — it is
**make it safe to put in front of someone who is not you, whose money is on the other side
of the numbers it prints.**

Three decisions frame everything below, taken 20 Aug 2026:

1. **Users: a small invited group, not family.** This is the line that creates real
   obligations. India's DPDP Act 2023 makes you a Data Fiduciary. SEBI's algo framework
   still does not bind — but *only* because the app places no orders. Per
   `research/REGULATORY-API-STATIC-IP.md`, order placement for non-family users is
   permanently closed without re-architecture: NSE maps one static IP to exactly one
   client, and placing orders for another person makes MoneyPlant an "algo provider"
   required to run on the broker's servers. **Read-only is now a product constraint, not a
   deferral.**
2. **Scope: dashboard, positions, holdings, payoff, risk, settings.** The Strategy Builder
   ships hidden behind a flag (A6) — its premiums are invented placeholders and its NIFTY
   legs are sized 15% too large.
3. **Numbers bar: label honestly, ship the estimate.** The codebase already does this well
   in two places — `RiskPage.tsx:162` ("mark-to-market value, not exposure") and the margin
   column's "does not total to used". Extend that discipline; do not extend the estimates.

---

## The two findings that outrank the original checklist

Both were found in the code while planning this. Neither was on the list of items P0 was
thought to need, and both are worse than most things that were.

**1. There are no backups of anything.** No `pg_dump`, no schedule, no off-VM copy, no
tested restore. The named Docker volume survives `compose down` but not VM loss. Every
user's encrypted broker credentials, every capture and every snapshot live in exactly one
place. → **D1**

**2. One user's slow broker stalls every other user.**
`InstrumentService.ensureLoaded` is `synchronized` on the singleton and holds that monitor
across a 60-second contract-master download (`instrument/InstrumentService.java:63`), and
`BrokerService.allPositions` calls it **once per position row**
(`broker/BrokerService.java:138`). A failing master never records success, so 20 positions
can mean 20 sequential 60s downloads — pinning a Tomcat thread and blocking every other
user's request on any broker. `catch (RuntimeException)` at `BrokerService.java:148` logs
it at `debug`, so it is invisible. This is a single-user app's assumption breaking the
moment there is a second user. → **B1**

---

## Summary

| ID | Item | Gate | Status |
|---|---|---|---|
| A1 | Risk page computes on nine-day-old positions | A · numbers | `[ ]` |
| A2 | NIFTY lot size hardcoded 75, should be 65 | A · numbers | `[ ]` |
| A3 | Paytm contract master fails silently for a day | A · numbers | `[ ]` |
| A4 | `₹NaN` can reach the screen | A · numbers | `[ ]` |
| A5 | Payoff engine: duplicate breakeven, window floor | A · numbers | `[ ]` |
| A6 | Hide the Strategy Builder behind a flag | A · numbers | `[ ]` |
| A7 | Label the SPAN estimate and the unbounded flags | A · numbers | `[ ]` |
| B1 | `ensureLoaded` stalls every user | B · resilience | `[~]` |
| B2 | No React error boundary → blank white page | B · resilience | `[ ]` |
| B3 | No fetch timeout → infinite skeleton | B · resilience | `[ ]` |
| B4 | Failed queries render confident `₹0` | B · resilience | `[ ]` |
| B5 | Failed simulation looks like an empty one | B · resilience | `[ ]` |
| B6 | No generic exception handler | B · resilience | `[ ]` |
| B7 | Kite builds a new HTTP client per call | B · resilience | `[ ]` |
| C1 | Zero security headers | C · security | `[ ]` |
| C2 | Caddy logs callback query strings | C · security | `[ ]` |
| C3 | Debug endpoints live in production | C · security | `[ ]` |
| C4 | No rate limit, body cap, or validation | C · security | `[ ]` |
| C5 | No disconnect / revoke path | C · security | `[ ]` |
| C6 | Prove `MP_DEV_AUTH` is off in prod | C · security | `[ ]` |
| C7 | Stale "MUST NOT SHIP AS-IS" comment | C · security | `[ ]` |
| D1 | **No backups** | D · operability | `[~]` |
| D2 | No health endpoint, no monitoring | D · operability | `[ ]` |
| D3 | Deploy readiness check is decorative | D · operability | `[ ]` |
| D4 | No rollback path | D · operability | `[ ]` |
| D5 | Stale runbook step on `MP_SESSION_STORE` | D · operability | `[ ]` |
| D6 | `position_snapshot` / `holding_snapshot` backfill | D · operability | `[ ]` |
| E1 | No privacy/terms pages, no app footer | E · legal | `[ ]` |
| E2 | Privacy notice, DPDP-shaped | E · legal | `[ ]` |
| E3 | No data erasure path | E · legal | `[ ]` |
| E4 | No risk disclosure | E · legal | `[ ]` |
| E5 | Broker ToS on cross-broker market data | E · legal | `[ ]` |
| E6 | No support / grievance contact | E · legal | `[ ]` |
| F1 | Allowlist in an env var needs a restart | F · onboarding | `[ ]` |
| F2 | Onboarding note for invited users | F · onboarding | `[ ]` |

**Suggested order: D1, B1, C1 first** — the highest risk-reduction per hour, and the two
that cannot be fixed after they bite. Then Gate A (the numbers), the rest of Gate B, Gate
C, Gate E in parallel with any of them, then D2–D6 and Gate F before the first invite.

---

## Gate A — Numbers you can defend

*A wrong number in a trading app is worse than no number.*

### `[ ]` A1 — The risk page computes on nine-day-old positions

`SnapshotService.getPositions` (`snapshot/SnapshotService.java:47-54`) returns whatever is
in `position_snapshot` regardless of age, and falls back live only when the table is
**empty** — which it never will be again, because the live fallback wrote rows on first
use. So `/api/risk/summary` divides *today's* margin bill across *11 August's* strikes
while `/api/positions` serves live data. It is honest about it (`Freshness.STALE`) but it
will never self-correct.

**Do:** make the freshness contract bite — treat a non-today snapshot exactly as empty at
`SnapshotService.java:49` so it falls through to live. One condition.

**Not now:** the `raw_capture` → `position_snapshot` backfill is the correct long-term fix
and moves to **D6**. When it lands it *must* change `findLatestPositions` to
`distinct on (connection_id) … order by captured_at desc, id desc` — the current
`= max(captured_at)` form returns one broker and silently drops the rest (measured).

**Verify:** with pre-today rows in `position_snapshot`, hit `/api/risk/summary` and assert
`freshness` is `LIVE` and its position count matches `/api/positions`. Today they diverge.

### `[ ]` A2 — NIFTY lot size is wrong by 15%

`PayoffService.getStrategyMetadata` hardcodes `75`; the contract master and the option
chain both say `65`. Every NIFTY leg is sized 15% too large, and margin, max profit, max
loss and capital all inherit it. This is a flat error, not an estimate.

**Do:** read it from `InstrumentService`. Nearly free now — `PositionDto.Contract` already
carries `lotSize` through the lookup `BrokerService.resolveInstrument` was already making.
**Do not edit the literal.** See `memory/nifty-lot-size-is-hardcoded-and-stale.md`.

**Verify:** `GET /api/payoff/metadata` returns `lotSize: 65` for NIFTY, and the value moves
if the contract master does.

### `[ ]` A3 — Paytm's contract master fails silently and caches the failure for a day

`PaytmSecurityMaster.instruments()` (`broker/paytm/PaytmSecurityMaster.java:131-139`)
catches and returns `List.of()`; `InstrumentService.ensureLoaded` (`:77-79`) then stores
empty maps and sets `loadedOn = today`. Paytm rows lose their underlying, type and payoff
curve until IST midnight, evidenced only by `log.info("loaded 0 instruments")`.

**Do:** do not record a successful load for an empty result. Log at `error`.

**Verify:** block the security-master URL; assert no load is recorded, an `error` is
logged, and the next request retries rather than serving empty for the rest of the day.

### `[ ]` A4 — `₹NaN` can reach the screen

`RiskPage.tsx:21` defines a local `inr()` that re-implements `formatINRWhole` without the
`Number.isFinite` guard that `lib/format.ts` has — a `NaN` prints `₹NaN` — and prefixes `₹`
manually, so a negative renders `₹-1,234` instead of `-₹1,234`. Used ~10 times on that page
(`:58`, `:146`, `:154`, `:321`, `:325`).

**Do:** delete it, use the shared module. Same for the unguarded `.toFixed()` calls at
`DashboardPage.tsx:153` (`utilisationPct.toFixed(0)`, NaN when there is no margin data),
`MarginUtilisationCard.tsx:47,73`, `ScenarioLadder.tsx:32`.

**Also:** `StrategyBuilderView.tsx:963` renders `leg.price` into a raw
`<input type="number">`, so float noise like `20339.999999999985` displays in full. Covered
by A6 while the builder is hidden; fix when it un-hides.

**Verify:** load `/app/risk` with a connection whose margin call failed — assert an em
dash, never `₹NaN`.

### `[ ]` A5 — Payoff engine, two real defects

- Breakeven detection uses `Math.signum(prev) != Math.signum(cur)`. `signum(0) == 0`, so a
  sample landing exactly on zero registers as two crossings and emits a duplicate
  breakeven.
- The window never starts at 0 — `lo = max(0, minStrike - span*0.5 - maxStrike*0.10)`. For
  a long put the true max profit (at spot 0) is off-screen, so `maxProfit` is understated.

The tail-slope `unbounded` heuristic is a modelling weakness, not a defect — **label it**
under A7 rather than rewriting it for P0.

**Verify:** unit tests — a curve with a sample exactly at zero yields one breakeven, not
two; a long put's `maxProfit` equals its premium-adjusted value at spot 0.

### `[ ]` A6 — Hide the Strategy Builder

One flag on the tab in `PayoffPage`. Its premiums are invented placeholders and A2's lot
size inherits into every figure it prints. B5 and the A4 input-formatting fix ride with it
when it un-hides.

**Verify:** `/app/payoff` shows no Strategy Builder tab with the flag off; the payoff chart
and legs are unaffected.

### `[ ]` A7 — Extend the honesty treatment

Every derived figure gets a visible estimate treatment and, where one exists, the broker's
own number beside it. Specifically:

- **The SPAN estimate runs ~24% under Zerodha, structurally.** The published scan ranges
  are *minimums* the exchange widens by 6σ, and that σ needs a volatility history this
  stack does not have. Not a bug — say so on the page.
- **The payoff `unbounded` flags** are a tail-slope heuristic, not derived from structure.

**Verify:** walk `/app/risk` and `/app/payoff` and confirm no rupee figure is presented as
a fact when it is an estimate.

---

## Gate B — It stays up, and it fails visibly

### `[~]` B1 — `ensureLoaded` stalls every user

The second of the two headline findings above. Four parts:

- Hoist the call out of the per-row loop in `BrokerService.allPositions` — once per
  session, not once per position row (`broker/BrokerService.java:138`).
- Narrow the lock: `synchronized` per broker rather than on the singleton
  (`instrument/InstrumentService.java:63`), so an Alice Blue download stops blocking Kite
  requests.
- Negative-cache a failed load for a short interval so a broken master cannot be retried in
  a tight loop.
- Raise `BrokerService.java:152` from `debug` to `warn`.

**Verify:** two browser sessions as two users; make Alice Blue's master hang; confirm the
other user's `/api/positions` still returns within its timeout. This is the test that
proves the cross-user fix.

**All four parts done in code, 6 Sep 2026 — branch `p0/b1-instrument-load-lock`, commit
`66ad28c`, unpushed. `mvnw clean test` 380 passing (main is 374).** The browser verification
above has *not* been run, which is why this is `[~]` and not `[x]`.

- The lock is per broker (`loadLocks`, one monitor object each). The fast path reads
  `loadedOn` outside the lock, so **the three publishing writes in `load` must stay in
  order** — `loadedOn` last, after both index maps; a comment says so and reordering them
  reintroduces a visibility bug the tests will not catch.
- The load is hoisted into `BrokerService.warmContractMasters`, deduplicated **by broker**
  so two Kite accounts share one attempt.
- A failed load is negative-cached for 60s (`InstrumentService.FAILURE_BACKOFF`) and then
  throws `InstrumentMasterUnavailableException` rather than returning normally — a caller
  whose `find` came back empty would read it as "the master does not list this symbol",
  which is a far more confident claim than "the master never loaded".
- The failure log is `warn`. (The tracker said `BrokerService.java:152`; line numbers had
  drifted and the line meant is the one in `resolveInstrument`.)

**What the tests do and do not prove.** `aSlowBrokerDoesNotBlockAnotherBrokersLoad` was run
against the old `synchronized` method and **fails there**, timing out after 5s waiting for
Kite — so the headline claim is measured, not assumed. But
`aDeadContractMasterCostsOneAttemptForTheWholeBook` would still pass with the hoist
reverted, because the negative cache alone bounds the attempt count: it pins the outcome,
not the attribution. Neither test exercises **two users**, which is what the browser step
above is for.

### `[ ]` B2 — No React error boundary

Zero matches for `ErrorBoundary`, `componentDidCatch`, `getDerivedStateFromError` or
`react-error-boundary` anywhere in `frontend/`. `main.tsx:9-17` is
`StrictMode > QueryClientProvider > BrowserRouter > App` with no boundary at any level;
`AppShell.tsx:36-58` renders `<Outlet />` bare. Any render-phase throw unmounts the whole
tree to a blank white page — already a documented symptom in `deploy/README.md`.

**Do:** one boundary in `main.tsx` around `<App />`, a second inside `AppShell` around
`<Outlet />` so one broken page does not kill the shell and its nav. Consider a
`QueryCache.onError` sink in `lib/queryClient.ts` while there.

**Verify:** temporarily throw in a page component; confirm a fallback card, not a white
page, and that the shell nav survives.

### `[ ]` B3 — No fetch timeout

No `AbortController`, `AbortSignal.timeout` or `signal:` anywhere in `frontend/src`. A hung
backend leaves queries pinned in `isLoading` forever while the 30s `refetchInterval` on
positions and margins piles up more in-flight requests.

**Do:** `AbortSignal.timeout` in `lib/api.ts` — it is the only fetch layer. Note a raw
network failure currently rejects with a bare `TypeError`, not an `ApiError`
(`api.ts:152`), so `err.status` is `undefined` downstream; wrap it while there.

**Verify:** stop the backend mid-session; confirm the UI reaches an error state rather than
an endless skeleton.

### `[ ]` B4 — Failed queries render confident `₹0`

Two places render zeros that read as a real, flat, riskless book:

- `DashboardPage.tsx:129-158` — the five StatCards have no error branch; `buildBrokerRows`
  gets `[]` on failure (`:65-69`) and the cards render `+₹0.00` / `₹0` as if flat and
  unfunded.
- `PayoffPage.tsx:251-281` — Max profit / Max loss render `₹0` when `p` is undefined
  (`:262`, `:269`). The Legs card falls to `EmptyState "No legs"` on error rather than an
  error state.

The Positions, Holdings, Risk and Settings tables all branch correctly via the shared
`ErrorState` in `components/states.tsx:46` — copy that pattern.

**Verify:** force each query to fail; assert every tile shows an error or a dash, never a
zero.

### `[ ]` B5 — A failed simulation looks like an empty one

`StrategyBuilderView.tsx:568-570` only `console.error`s; there is no error state variable
in the file (only `isSimulating`, `:74`). A failed `/api/payoff/simulate` leaves the
previous value in place and shows "Add or enable legs to visualize…" (`:1129-1131`).

Deferred with A6 while the builder is hidden. Do it when it un-hides.

### `[ ]` B6 — No generic exception handler

`common/ApiExceptionHandler` covers only `BrokerException` and the two credential
exceptions; everything else falls to Spring's default error handling.

**Do:** a catch-all returning a correlation id and no internals, logging the stack trace
server-side against that id.

**Verify:** force an unexpected exception; assert the response carries no class names,
paths or stack frames, and that the id appears in the log.

### `[ ]` B7 — Kite builds a new HTTP client on every call

`KiteBrokerGateway.client()` (`broker/kite/KiteBrokerGateway.java:84-89`) does
`new KiteConnect(apiKey)` per call — and therefore a new `OkHttpClient`, `ConnectionPool`
and `Dispatcher` thread pool — for `getPositions`, `getHoldings`, `getMargins`, `raw`,
`getInstruments` and `basketMargin`. No connection reuse; idle threads and sockets linger.
On a 30s refetch × N users this is steady churn.

The SDK sets **only** a 10s connect timeout and leaves `callTimeout` at `0` (unlimited), so
there is no bound on total call duration. It exposes no setter to fix that.

Alice Blue and Paytm are already correct — 5s connect / 10s read, 60s read on the bulk
clients (`AliceBlueHttpConfig.java:30-31`, `PaytmHttpConfig.java:28-29`).

**Do:** cache the client per session; wrap Kite calls in a deadline the app owns.

**Verify:** thread count stays flat across a sustained refetch cycle; a deliberately
delayed Kite response is cut off by the app's deadline.

---

## Gate C — Security hardening

### `[ ]` C1 — Zero security headers

`deploy/Caddyfile` sets none, and Caddy adds none by default. The best value-per-hour item
in this whole document.

**Do:** add `Strict-Transport-Security`; a `Content-Security-Policy` (the SPA is
self-contained, so a tight policy is achievable); `X-Content-Type-Options: nosniff`;
`X-Frame-Options: DENY` plus `frame-ancestors 'none'`; `Referrer-Policy: no-referrer`;
`Permissions-Policy` denying camera, microphone and geolocation.

**Verify:** `curl -I https://moneyplant.bonamnikhilbabu.in` and check each header, then run
the site through an external headers scanner.

### `[ ]` C2 — Caddy logs callback query strings

The comment at `deploy/Caddyfile:44-47` says query strings on the callback routes are not
written to disk. `format json` does not do that — it logs `request.uri` including the
query, which on those routes carries broker request tokens and the connect nonce. They are
single-use and short-lived, but the file claims a protection it does not provide.

**Do:** make the comment true, or delete the comment. Not both.

**Verify:** complete a broker connect, then grep the Caddy log for the request token.

### `[ ]` C3 — Debug endpoints live in production

`/api/debug/instrument`, `/api/debug/symbols` (`instrument/InstrumentController.java:28,44`)
and `/api/debug/aliceblue/option-chain`
(`broker/aliceblue/AliceBlueDebugController.java:62`) are reachable in prod. They are
authenticated, but they are development scaffolding.

**Do:** put them behind the `@ConditionalOnProperty` shape `auth/DevAuthConfig` already
uses. (The Alice Blue one is deleted outright when the chain graduates into `marketdata/`.)

**Verify:** in a prod-shaped profile all three return 404.

### `[ ]` C4 — No rate limiting, body cap, or validation

None of the three exist. `spring-boot-starter-validation` is **not in the pom**, and there
are zero `@Valid` / `jakarta.validation` hits in `src/` — so any annotation added later
would be inert until the starter is added.

`POST /api/payoff/simulate` and `POST /api/payoff/margin-estimate`
(`analytics/PayoffController.java:36,46`) take a bare `@RequestBody` with no leg-count cap
and no numeric bounds. `NaN`/`Infinity` for `strike` or `price` flow into `PayoffEngine`
and produce a curve of `NaN`s rather than an error. Nothing limits request body size, and
each leg expands into 4–5 derived objects held simultaneously — a plausible OOM on a
free-tier VM from an authenticated but unthrottled caller.

`credential/BrokerCredentialController` is the well-validated counter-example — registry
check on `brokerId` (`:166-171`), a `[A-Za-z0-9 _-]{1,32}` regex on `label` (`:150-157`).
Its one gap: no maximum length on `apiKey` / `apiSecret`.

**Do:** add the validation starter, a request body size limit, a leg-count cap,
`NaN`/`Infinity` rejection, a per-user token bucket on the two POST endpoints, and length
caps on the credential fields.

**Verify:** post an oversized `legs` array and one containing `NaN`; expect 4xx, not a 500
and not an OOM.

### `[ ]` C5 — No disconnect / revoke path

There is no `sessions.remove` anywhere in the codebase, and `SessionController` exposes
only `GET /status` and `GET /login-url`. A user cannot revoke a broker link. Entries stay
in `ConnectionService`'s map for the JVM's lifetime, so a session whose token died hours
ago is re-fanned-out on every request and produces a warning forever.

**Do:** `DELETE /api/session/{connectionId}`, ownership-checked the same way
`session(connectionId)` already checks it, plus the button. This is both a security control
and the fix for the warning spam.

**Verify:** connect a broker, disconnect it, confirm it is gone from `/api/session/status`
**and** from the `broker_session` table, and that no warning recurs.

### `[ ]` C6 — Prove `MP_DEV_AUTH` is off in production

The loopback guard in `auth/DevAuthConfig` (it refuses to start unless `app.frontend-url`
is loopback) is good defence. What is missing is a positive signal.

**Do:** log the active auth mode unambiguously at startup; add reading that line to the
deploy verification list.

**Verify:** the production log names Google OIDC as the active mode on every boot.

### `[ ]` C7 — Stale "MUST NOT SHIP AS-IS" comment

`auth/SecurityConfig.java:118-119` reads *"MUST NOT SHIP AS-IS. On a reachable host an
unauthenticated caller can drive this endpoint."* It describes the pre-3b state. Nonce
attribution landed and `broker/session/PendingConnect` implements it correctly — including
refusing to guess when Alice Blue's callback is ambiguous. The comment is now false and
will stop a future reader, or an auditor, cold.

**Verify:** the comment describes the nonce mechanism that actually exists.

---

## Gate D — Operability

### `[~]` D1 — Backups

The first of the two headline findings. Nothing existed.

**Do:** nightly `pg_dump`, encrypted with `gpg`, pushed to OCI Object Storage (20 GB on the
always-free tier), 30-day retention. Re-verify the off-VM `MP_CREDENTIAL_KEY` backup as
part of this — the dump is worthless without it, and it is the only unrecoverable secret in
the stack.

**Verify — the only proof that matters:** restore last night's dump into a scratch database
and confirm a stored broker credential decrypts with the backed-up key. An untested backup
is not a backup.

**In progress, 20 Aug 2026 — branch `p0/d1-backups`. Code written; the VM setup is not
done.** Six files in `tradestack/deploy/`: `backup.sh`, `restore-verify.sh`,
`CredentialDecryptCheck.java`, the `moneyplant-backup` service and timer, and
`backup.env.example`, plus a "Backups" section in `deploy/README.md` carrying the runbook.

Three design choices worth knowing before touching any of it; reasoning in
`memory/backups-are-write-only-par-and-symmetric-gpg.md`:

- **A write-only pre-authenticated request, not the OCI CLI.** The VM can create backups but
  cannot list, read or delete them, so a compromised host can neither exfiltrate the backup
  history nor destroy it. The costs are real: retention has to be a bucket lifecycle rule,
  and `restore-verify.sh` needs a second read-only PAR kept off the VM.
- **Symmetric gpg, not a public key.** Anything that can read the passphrase off the VM can
  already read `MP_CREDENTIAL_KEY` and the database password out of
  `/etc/moneyplant/moneyplant.env` — strictly more than the backup holds. Asymmetric buys
  nothing against that and costs a second unrecoverable secret to lose.
- **`backup.sh` refuses to upload a dump with no `broker_credential` table data.** The
  failure this item exists to prevent is not a backup that errors; it is one that uploads
  cleanly, keeps the timer green, and is empty.

**Rehearsed end to end against the local Postgres, 20 Aug 2026** — dump, the emptiness
guard, gpg seal and open (byte-identical round trip, wrong passphrase refused), restore into
a scratch database, row counts, Flyway history, and all four real `broker_credential` rows
decrypting under the live `MP_CREDENTIAL_KEY` while a random key failed all four. The
rehearsal found one bug nothing else would have: Postgres's `encode(bytea,'base64')` **wraps
at 76 characters**, so a long ciphertext split across lines, every row after it shifted, and
the check reported three spurious failures out of six. The extraction is hex now.

**Object Storage is set up, 6 Sep 2026.** Bucket `moneyplant-backups`, private, standard
tier, in the **root** compartment (where the A1 VM lives), namespace `axz4vyr5vyas`, region
`ap-hyderabad-1`. Lifecycle rule `delete-moneyplant-backups-after-30-days` is applied and
enabled, prefix `moneyplant/`. **The rule will actually run** — a lifecycle policy is inert
without an IAM grant to the service, and `Allow service objectstorage-ap-hyderabad-1 to
manage object-family in tenancy` was confirmed present rather than assumed. All three were
done with the OCI CLI, not the console; the runbook's console steps are equivalent, not
required.

**What is left:**

1. **The write-only PAR** — the one piece of setup still outstanding, because minting it
   produces the credential itself. Bucket-level, `AnyObjectWrite`, listing **denied**:
   `oci os preauth-request create --namespace axz4vyr5vyas --bucket-name moneyplant-backups
   --name moneyplant-vm-write --access-type AnyObjectWrite --bucket-listing-action Deny
   --time-expires 2027-09-06T00:00:00Z`. Prefix the returned `access-uri` with
   `https://objectstorage.ap-hyderabad-1.oraclecloud.com` to get `MP_BACKUP_PAR_URL`.
   The URL is shown once and is itself the credential; calendar the expiry.
2. Install `backup.env` and the two units, enable the timer, run it once by hand.
3. **Run `restore-verify.sh` against an object downloaded from Object Storage** — not the
   local copy, which tests the dump but not the upload — with the off-VM copy of
   `MP_CREDENTIAL_KEY` pasted from the password manager. This is the step that flips D1 to
   `[x]`. Nothing before it does.
4. Re-confirm both off-VM secrets are current: `MP_CREDENTIAL_KEY` and the new
   `MP_BACKUP_PASSPHRASE`. A restore needs both — one opens the file, the other opens the
   broker secrets inside it.

**It is silent when it stops.** `backup.sh --check` exits non-zero when the last success is
older than 36 hours, and exists to be the command **D2**'s monitor calls;
`moneyplant-backup.service` carries a commented `OnFailure=` line for the same reason. Until
D2 lands, `systemctl list-timers` is the whole story.

### `[ ]` D2 — No health endpoint, no monitoring

`spring-boot-starter-actuator` is not in the pom, so there is no health or metrics endpoint
at all. No uptime check, no alerting, no error tracking. `journalctl` is the whole story —
you will not know the app is down.

**Do:** add actuator, expose `/actuator/health` on loopback only, point a free external
uptime monitor at the public site, set up one alert channel that reaches your phone, and
add `logrotate` for the app log.

**Verify:** stop the service; confirm the alert arrives.

### `[ ]` D3 — Deploy readiness check is decorative

`deploy/deploy.sh:57-63` runs `curl -sf … | grep -q '401\|200'` under `set -o pipefail`.
`curl -f` exits 22 on a 401, so the pipeline's status is non-zero and the `if` is never
true — the loop always burns its full 60 seconds and the script proceeds regardless of
whether the app came up.

**Do:** confirm the behaviour on the VM first (one minute), then drop `-f` or capture the
status code without a pipeline.

**Verify:** deploy a deliberately broken build; the script reports failure instead of
"Done".

### `[ ]` D4 — No rollback path

`deploy.sh` overwrites the jar and `git reset --hard`s both repos; the previous build is
gone.

**Do:** keep `.prev` copies of the jar and `dist/`, add a `rollback.sh` that swaps them
back and restarts. Document the constraint that matters: **Flyway here is forward-only —
there are no down migrations** — so a rollback across V5–V8 has no automatic path and needs
the D1 restore. All four pending migrations are additive (`create table`, `create index`,
`alter table … add column`), so a rollback that does not cross them is safe.

**Verify:** roll back a deliberately broken deploy and confirm service returns.

### `[ ]` D5 — Stale runbook step

`tradestack/deploy/README.md` verification step 9 tells you to confirm `MP_SESSION_STORE`
is **off**. It now defaults **on** in `application.properties`. As written the step has you
"fix" a correct configuration. (`broker/session/SessionStore.java:53`'s javadoc says the
same stale thing.)

**Verify:** step 9 reads correctly against current behaviour.

### `[ ]` D6 — `position_snapshot` / `holding_snapshot` backfill

Deferred out of A1. Copy the `MarginBackfillService` shape for positions — the parsers
already exist — **and change `findLatestPositions` to
`distinct on (connection_id) … order by captured_at desc, id desc`**, because migrated rows
carry per-connection timestamps and the current `= max(captured_at)` form returns one
broker and silently drops the rest (measured). `holding_snapshot` still has zero rows and
no writer; same shape.

Related debt to close with it: `SnapshotService`'s live fallback writes `raw = "{}"`, which
contradicts 4c's "reconstructible from `raw`"; and ArchUnit A2 checks only *direct*
dependencies, so `RiskService → SnapshotService → BrokerService` fires a live broker call
inside a risk request. Widen A2 to transitive reach here.

**Verify:** `position_snapshot` and `holding_snapshot` carry today's rows for every
connected broker, and each matches its `raw_capture` archive payload.

---

## Gate E — Legal, privacy, support

*Required specifically because users are invited non-family. Cheap to build, and the
regulatory research is already done in `research/REGULATORY-API-STATIC-IP.md`.*

### `[ ]` E1 — No privacy/terms pages, no app footer

`LandingPage.tsx:88-91` holds the only footer in the codebase (`© {year} MoneyPlant` and
the literal text `Private system`) — that is where the links go. `AppShell.tsx:43-53` has
no footer element at all and needs one added after `<Outlet />`, accounting for the `pb-24`
mobile tab-bar clearance. Add `/privacy` and `/terms` routes in `App.tsx`.

**Verify:** both routes render and are reachable from signed-out and signed-in states.

### `[ ]` E2 — Privacy notice, DPDP-shaped

As a Data Fiduciary you owe: notice of what is collected and why (Google email, name and
picture; broker API keys and secrets; positions, holdings and margins), the legal basis,
retention, a **named grievance contact**, and a breach-notification commitment. Say plainly
that broker secrets are encrypted at rest with a key held outside the database.

### `[ ]` E3 — No data erasure path

DPDP gives users the right to have their data deleted. There is no `users` table and no
cascade.

**Do (minimum for P0):** a documented, tested manual procedure deleting a user's rows from
`broker_credential`, `broker_session`, `raw_capture`, `capture_run` and the four snapshot
tables by `user_id`, plus removing them from the allowlist. Automate after F1 gives it
somewhere to hang.

**Verify:** run it against a test user and confirm no row anywhere carries that `user_id`.

### `[ ]` E4 — No risk disclosure

Two sentences, on the login page and in the app footer: this is a read-only position
viewer, it places no orders, it is not investment advice; **all figures are estimates and
your broker is the source of truth.** That second clause is what Gate A's labelling is for.

`LoginPage.tsx`'s closing paragraph ("Private system. Access restricted.") is the natural
home for the "by signing in you agree to…" line.

### `[ ]` E5 — Broker ToS on cross-broker market data

Already open in `CLAUDE.md`: **may one broker's feed be used to price another broker's
positions?** Unanswered, and the Alice Blue option chain is about to become load-bearing
for the Strategy Builder. Note the app already does this in one place — spot comes from
Paytm and feeds Kite and Alice Blue curves.

**Do:** read Alice Blue's and Paytm's API terms. If unclear, ask in writing.

**Verify:** a written answer recorded in `research/`, and a memory if the answer changes a
decision.

### `[ ]` E6 — No support / grievance contact

One monitored email address, published in the footer and on the privacy page, doubling as
the DPDP grievance contact.

---

## Gate F — Onboarding an invited user

### `[ ]` F1 — The allowlist is an env var and needs a restart

Adding a user today means SSH to the VM, editing `MP_ALLOWED_EMAILS` in
`/etc/moneyplant/moneyplant.env`, and `systemctl restart moneyplant` — which drops every
other user's HTTP session. Workable for two people, painful for eight.

**Do:** a small `invited_email` table read at sign-in. No restart, and E3's erasure gets
somewhere to hang. `auth/AllowedEmails.java` is a single well-isolated component, so this
is contained. Keep its two good properties: an empty list is a startup failure and never
"allow everyone", and rejection happens during the token exchange so there is no
half-logged-in state.

**Verify:** add and remove a user with no restart; confirm the removed user is refused.

### `[ ]` F2 — Onboarding note for invited users

Each user must register — and pay for — their **own** Kite Connect app before they can
connect anything, and Alice Blue needs its app activated by their admin team or the login
answers `"Invalid vendor id"`. That is a real barrier and it should be stated up front, not
discovered.

---

## Gates that must stay green throughout

- Backend: `mvnw clean test` — **374 on `main`**, 385 on `feat/position-contract-facts`
  (20 Aug 2026). Build from a worktree, not the working tree, when the answer has to be
  about what deploys.
- Frontend: `npm run build` (= `tsc -b && vite build`). `npm run lint` does not work —
  `eslint` is not in `devDependencies`.
- **Only `mvnw clean test`'s own `Tests run:` line under `Results:` is a real test count.**
  `target/surefire-reports/` is not cleaned between runs; summing those XMLs has been wrong
  every time it was tried.
- Before the first invite: run `tradestack/deploy/README.md`'s nine verification steps end
  to end with all three brokers connected, plus one full sign-in as a second allow-listed
  user to confirm data isolation on live data.
