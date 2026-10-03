# Staging and the broker simulator: the plan and tracker

**Created 3 Oct 2026.** This file owns the **staging environment** and the **dummy broker
server** (the simulator) it runs against. Status markers are `P0-LAUNCH.md`'s (`[ ]` `[~]`
`[x]` `[-]`), and the same rule applies: `[x]` only after the verify line has been run.
Branch names carry the id (`staging/st1-broker-endpoints`).

It takes over three items from other trackers rather than duplicating them:
`BROKER-EXPANSION-PLAN.md` SIM-01 to SIM-05 (the simulator) and `NEXT-STEPS.md` SIM-07
and SIM-08 (local and staging packaging). Those entries now point here. TEST-09 (the
browser smoke pack) stays in `NEXT-STEPS.md`; staging is where it runs.

## Why

Production has been open to sign-ups since 3 Oct, and every change so far was proven
either in unit tests or **on production itself**: O4 was checked with planted tokens on
the live Caddy, and V9 first ran against real data. Real brokers make that hard to avoid.
Sessions expire daily, Paytm needs an OTP, markets are only open 09:15–15:30, and failure
modes (an expired token, a 429, a vendor outage) cannot be produced on demand.

Staging is a copy of production that talks to a **dummy broker server** instead of
Zerodha, Alice Blue and Paytm. A branch can be deployed there, signed into, connected to
"brokers", and broken on purpose, at any hour, with no real account, money or personal
data involved.

## What it unlocks

- Every PR is deployed and clicked through before merge: connect, positions, payoff,
  builder, risk and settings.
- **L18 phase 2 (the admin feed)** is tested end to end with a simulated Paytm and Alice
  Blue, including the feed being off, down, or expired.
- **L3 modes and the kill switch** are tested on a real deploy: allowlist, open, closed,
  and a disabled account.
- **D4 rollback** is rehearsed on staging before it is ever needed on production.
- **O-items (alerts)** fire on purpose: a stopped service, an error burst, a missed
  heartbeat.
- **Upstox and later brokers** (`BROKER-EXPANSION-PLAN.md`) get their simulator profile
  and staging soak here, before any production flag.
- Market-hours behaviour is tested at any hour, through the simulator's clock.

## Architecture

```
                     staging.goldenbook.in  (Caddy: basic auth, noindex, STAGING banner)
                                  │
                ┌─────────────────┴──────────────────┐
         SPA (/var/www/gb-staging)         backend :8180 (loopback)
                                             │  GB_ENVIRONMENT=staging
                                             │  broker base URLs → simulator
                                             ▼
                                  broker-sim :8190 (loopback / private)
                                  ├─ /kite/...       Kite Connect shapes
                                  ├─ /aliceblue/...  Alice Blue shapes
                                  ├─ /paytm/...      Paytm Money shapes
                                  ├─ /login/...      fake broker login pages
                                  └─ /_sim/...       scenario + clock control (token)
                                             │
                                  postgres (staging database, own role)
```

The browser goes through the fake broker login page and lands back on
`staging.goldenbook.in/{broker}/callback`. So the **whole connect flow runs**, including
the nonce, the cross-site redirect and the session cookie.

## Findings that shape the work (read from the code, 3 Oct 2026)

| Broker | How the app reaches it | Pointable at a simulator today? |
|---|---|---|
| **Paytm** | Our own `RestClient`, `API_BASE = https://developer.paytmmoney.com`; login `login.paytmmoney.com/merchant-login`; security master CSV URL | **No**: constants. A property override is a small change. |
| **Alice Blue** | Our own `RestClient`, `API_BASE = https://a3.aliceblueonline.com`, `LOGIN_BASE = https://ant.aliceblueonline.com/`; contract master `v2api.aliceblueonline.com/...`; chain `/obrest/optionChain/...` | **No**: constants, and `SESSION_URL` is built from `API_BASE`. Same small change. |
| **Kite** | The Kite Connect **SDK 3.5.0**. `Routes._rootUrl = "https://api.kite.trade"` is a private static with no setter; the login URL `https://kite.trade/connect/login` comes from the SDK too. The only hook is a `java.net.Proxy` in the constructor. | **No, and it is the hard one.** See ST-2. |

The endpoints the app actually calls, which is the whole surface the simulator must
serve:
- **Paytm:** `/accounts/v2/gettoken`, `/accounts/v1/user/details`,
  `/accounts/v1/funds/summary`, `/orders/v1/position`,
  `/holdings/v1/get-user-holdings-data`, `/data/v1/price/live?mode=LTP&pref=…`, and the
  security master CSV.
- **Alice Blue:** `/open-api/od/v1/vendor/getUserDetails`, `/open-api/od/v1/positions`,
  `/open-api/od/v1/holdings/CNC`, `/open-api/od/v1/limits/`,
  `/obrest/optionChain/getUnderlying`, `/getUnderlyingExp`, `/getOptionChain`, and the NFO
  contract master.
- **Kite** (SDK calls): `generateSession`, `getPositions`, `getHoldings`,
  `getMargins("equity")`, `getInstruments("NFO")`.

The VM today: 1 OCPU, 7 GB RAM, aarch64. The always-free allowance is 4 OCPU / 24 GB
(L13), which leaves room for staging.

## Decisions (owner, 3 Oct 2026)

- **D-1 Hosting: the same VM, for now.** A second always-free VM was recommended, for
  full isolation, but the owner chose speed. Staging runs beside production, separated
  by everything except the machine:
  - its own Linux user `gbstaging`, which cannot read `/etc/goldenbook/`;
  - its own env file `/etc/goldenbook-staging/goldenbook.env`, with its own
    `GB_CREDENTIAL_KEY`;
  - **its own Postgres container** (`goldenbook-staging-postgres`, own volume and
    password, loopback `:5442`) rather than a second database in production's
    container, so no production role or password is involved;
  - loopback ports `:8180` (backend) and `:8190` (simulator);
  - capped heaps (staging `-Xmx512m`, simulator `-Xmx256m`), so staging cannot starve
    production on a 1 OCPU / 7 GB box.

  L13's free resize to 4 OCPU / 24 GB becomes more urgent. Revisit a separate VM if
  staging ever affects production.
- **D-2 Access:** `staging.goldenbook.in` behind Caddy **basic auth** plus `noindex`,
  with real Google sign-in in **allowlist** mode for testers. Dev auth is deliberately
  impossible off loopback.
- **D-3 Simulator location:** a separate Maven module, `broker-sim/`, in the `MoneyPlant`
  repo, built and run separately. It is **never** inside the app jar, and a check on the
  app jar enforces that.
- **D-4 Kite:** replace the SDK with our own Kite REST client (ST-2, option 1).

## Items

### `[ ]` ST-1: Configurable broker endpoints, and a guard against confusing them

**Do:**
- Every broker URL becomes a property whose default is today's production value:
  `goldenbook.broker.paytm.api-base`, `.login-url`, `.security-master-url`;
  `goldenbook.broker.aliceblue.api-base`, `.login-url`, `.contract-master-url`;
  `goldenbook.broker.kite.*` (ST-2).
- Add `GB_ENVIRONMENT=production|staging|local`.
- **At startup, production refuses to run unless every broker URL is the vendor's own
  host. Staging refuses to run if any of them is.** That is what makes the simulator
  impossible to confuse with a real broker in either direction.
- Log one line per broker at boot: `broker endpoints: paytm=<host> …`. It sits next to
  C6's auth line and goes into the runbook's verification steps.

**Verify:**
- Unit tests for both directions of the guard.
- Production's boot log shows only vendor hosts.
- A staging boot with one vendor URL fails, and names that URL.

### `[ ]` ST-2: Kite against a simulator

The SDK cannot be repointed. Three ways out:

1. **Own Kite REST client (recommended).** The app uses five calls; Kite Connect's REST
   API is plain JSON over HTTPS, with a SHA-256 checksum at `generateSession`. Replacing
   the SDK:
   - makes the base URL a property, like the other two brokers;
   - removes Gson and the SDK's Jackson clash;
   - makes `raw_capture` hold **Kite's real wire bytes**. Today it holds SDK field names,
     per ADR 0013, because the SDK throws the JSON away.
   - Cost: the gateway, the session service and their tests. `KiteMarginCalibrationTest`
     and `KiteRawCaptureTest` must still pass, the latter rewritten for wire names, with
     any backfill that reads SDK names updated.
2. **Reflection on `Routes._rootUrl`, in staging only.** Quick, but it writes a private
   static that the whole JVM shares, it breaks on any SDK upgrade, and it is exactly the
   kind of hidden switch ST-1 exists to avoid.
3. **DNS and TLS interception.** Point `api.kite.trade` at the simulator inside staging
   and trust a staging CA in the JVM. No code change for the API (the login URL still
   needs one), but it is fragile infrastructure that nobody will remember how to repair.

**Verify:** the gateway's tests pass against simulator responses, and production's
Kite connect still works after the deploy (one real login).

### `[ ]` ST-3: Simulator core (absorbs SIM-01, SIM-03)

**Do:**
- A small Spring Boot service, `broker-sim`, with one profile per broker. Each serves the
  endpoints listed in the findings, with the vendor's paths, status codes, headers and
  JSON shapes.
- **Fake login pages** per broker: pick a simulated account, then redirect to the
  callback with that broker's own parameter (`request_token`; `authCode` + `userId`;
  `requestToken` + `state`).
- **Token exchange and daily expiry** from an injectable clock.
- Credentials: an API key must start `sim_`. Anything else is refused with that broker's
  own error, so a real key typed into staging fails visibly and is never forwarded
  anywhere.

**Verify:**
- From a staging browser, all three brokers connect through their fake login pages.
- Tokens expire at the simulated day boundary.
- A non-`sim_` key is refused.

### `[ ]` ST-4: Synthetic market and portfolios

**Do:**
- **A market engine.** Indices (NIFTY, BANKNIFTY, FINNIFTY, MIDCPNIFTY, SENSEX) and a
  handful of stocks follow a seeded random walk during simulated market hours and freeze
  outside them.
- **Option prices** come from the project's own `BlackScholes` at a fixed volatility
  surface, so the chain, positions, payoff, margin and risk all agree with each other.
- Futures are priced as spot plus carry.
- **Contract masters and security masters** are generated for the simulated expiries,
  in each vendor's format.
- **Named portfolios:** empty; equity-only; NIFTY credit spread; BANKNIFTY iron condor;
  mixed futures and options; T1 and pledged holdings; carried-forward Alice Blue
  positions (to exercise the `netAveragePrice` trap); a Paytm leg with no quote
  (`priceKnown=false`).

**Verify:**
- The payoff page's spot, the chain's `spotLTP` and the futures' LTP agree within the
  carry.
- The risk page's margin estimate is the engine's own number for the same legs.

### `[ ]` ST-5: Scenarios, faults and control (absorbs SIM-04, SIM-05)

**Do:**
- Per simulated account, a scenario can return any of: expired token (Alice Blue's
  plain-text 401; Kite's `TokenException` shape), 403, 429, 500, a timeout, malformed
  JSON, an empty quote, or a missing field.
- `/_sim/...` controls, reachable only on loopback and protected by a token:
  - choose a scenario;
  - set or advance the clock;
  - open or close the market;
  - reset an account.
- The control API does not exist when the simulator runs with a production-like profile.

**Verify:** each fault produces the app's documented outcome. A 409 for a dead session
raises the reconnect banner; a `CALL_FAILED` warning does not; Alice Blue's 401 never
logs the user out of GoldenBook.

### `[ ]` ST-6: Fixture provenance (absorbs SIM-02)

**Do:**
- Every response shape cites its source: the vendor documentation URL with an access
  date, or "shape read from `raw_capture`, values synthetic".
- A test scans fixtures for anything resembling a real PAN, client code, email, token or
  phone number.

**Verify:** the scan runs in `verify.ps1` and fails on a planted real-looking value.

### `[ ]` ST-7: Staging infrastructure

**Do** (per D-1 and D-2):
- Create the VM, or a second service on the existing one.
- Add the DNS record `staging.goldenbook.in`, and a Caddy site with basic auth,
  `X-Robots-Tag: noindex` and the O4 log rules.
- Create a separate Postgres database and role, a separate `GB_CREDENTIAL_KEY`, and a
  separate Google OAuth client (or a second redirect URI on a staging client).
- Add `/etc/goldenbook-staging/goldenbook.env`, plus the `goldenbook-staging` and
  `broker-sim` systemd units.
- **No production data ever goes to staging.** Seed it with simulated users and
  credentials only.

**Verify:**
- Staging serves its pages.
- Sign-in works for an allowlisted tester and refuses others.
- `:8180`, `:8190` and staging's Postgres are unreachable from outside (the runbook's
  step 8).

### `[ ]` ST-8: A visible STAGING marker

**Do:**
- A `VITE_ENVIRONMENT=staging` build shows a fixed banner, "STAGING: simulated brokers,
  no real data", and a different favicon colour.
- The backend's `/api/me` response is unchanged; the banner is build-time only.

**Verify:** a staging screenshot shows the banner, and production's build has no banner
code path enabled.

### `[ ]` ST-9: Deploy path

**Do:**
- `deploy.sh` takes a target (`production` | `staging`), or there is a sibling
  `deploy-staging.sh`.
- Staging deploys **any branch**; production deploys `main` only.
- `deploy-from-local.ps1` gains `-Target staging`.
- The simulator is deployed by the same script.

**Verify:** a feature branch deploys to staging, while production refuses that branch.

### `[ ]` ST-10: Smoke pack against staging (runs NEXT-STEPS TEST-09 here)

**Do:**
- A browser pack (Chrome automation or Playwright) that signs in, connects all three
  simulated brokers, and checks Overview, Positions, Holdings, Payoff, Builder, Risk
  and Settings at desktop and phone widths, plus the expired-session and vendor-error
  states.
- `verify.ps1 -Scope staging` runs it.

**Verify:** the pack passes on `main`, and fails on a branch with a deliberately broken
page.

### `[ ]` ST-11: The simulator on the laptop (absorbs SIM-07)

**Do:**
- One command starts the local Postgres, the backend (dev auth, `GB_ENVIRONMENT=local`,
  broker URLs pointing at the simulator), Vite, and `broker-sim`.
- The documented memory footprint fits beside Chrome on the 8 GB laptop.

**Verify:** a fresh shell gets a working app with three connected simulated brokers and
no real credentials.

## Order and rough size

| Step | Items | Size | Can start |
|---|---|---|---|
| 1 | D-1 to D-4 answered | owner | **done, 3 Oct** |
| 2 | ST-1 endpoints and guard | small | now |
| 3 | ST-2 Kite client (if option 1) | medium | after D-4 |
| 4 | ST-3 + ST-4 simulator, happy paths for all three brokers | large | after ST-1 |
| 5 | ST-7 + ST-8 + ST-9 staging up | medium, mostly ops | after D-1 and D-2; parallel with step 4 |
| 6 | ST-5 + ST-6 faults and provenance | medium | after step 4 |
| 7 | ST-10 smoke pack, ST-11 laptop | medium | after steps 4 and 5 |

The first useful milestone is **steps 2, 4 and 5 for Paytm and Alice Blue alone**. That is
enough to test L18 phase 2 and every PR's UI, while ST-2 settles Kite.

## Not in scope

- Load testing (L13's smoke-load is separate).
- Order placement: the simulator has no order endpoints, matching the read-only product.
- Copying production data into staging, in any form.
