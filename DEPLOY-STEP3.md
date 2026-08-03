# Step 3 — Multi-user auth, and the road to deploy

**Decided 3 Aug 2026.** Design spec. Sits beside `CLAUDE.md` and `UX-STEP2.md`, above both
repos, because it spans them.

Expands the one-line roadmap entry "Step 3 — Login / real authentication". The scope is
larger than the entry implies and smaller than the entry's dependencies imply: it is real
multi-tenancy, but it does **not** need Postgres.

---

## The decision

> **Full multi-tenancy. A second user logs in with their own Google account and links their
> own broker account. Local development continues unchanged throughout.**

The alternative considered and rejected was auth + an allowlist + seeded demo data — faster
to ship, but a correctly-isolated second user sees an *empty* app, which is useless for the
thing the second user is actually for: arguing about Step 8 analysis against a real book.

Purpose is feedback, not scale. Target is a handful of users on the OCI always-free tier.

---

## Two findings that shrink the step

### 1. No Postgres — not even for this

The only per-user data multi-tenancy creates is the broker link. Broker tokens die daily
under SEBI rules and **no broker in the stack issues a refresh token**, so nothing survives
the night that is worth a table. Google supplies identity on every login. The allowlist is
an environment variable.

`users` and `broker_links` stay in Step 7, where they belong, and arrive when something
finally needs to outlive a day — saved strategies (Step 6) being the likely trigger.

This reverses the CLAUDE.md line "this is where most of Step 7 actually gets built". It is
not. Step 3 is auth and key-scoping only.

### 2. No Spring profiles

Only three things differ between laptop and VM, and all three are already environment
variables:

| Variable | Local | Prod |
|---|---|---|
| `KITE_API_KEY` / `_SECRET` (and Alice Blue, Paytm) | dev app registration | **prod app registration** |
| `app.frontend-url` | `http://localhost:5173` | `https://<domain>` |
| callback base URL | `http://localhost:8080` | `https://<domain>` |

Same names, different values per host. A `local` profile would be more machinery for the
same result, and profiles drift — a property set in one and forgotten in the other is a
class of bug that cannot happen if the file has exactly one version.

**Fix `KiteProperties` as part of this step.** An unset env var currently binds as the
literal `${KITE_API_KEY}` rather than failing at startup. Alice Blue and Paytm both guard
this; Kite does not. With one environment that hazard is theoretical. With two it is a
matter of time.

---

## Local stays alive: register new apps, never repoint old ones

Brokers allow **one redirect URL per app registration**. The instinct is to edit the
existing registration to point at the domain. Do not.

- Existing registrations keep pointing at `localhost:8080/{broker}/callback`. Untouched.
- A **second, separate** registration per broker points at `https://<domain>/{broker}/callback`.
- Prod key/secret live only in the VM's environment. Dev key/secret live only on the laptop.

Repointing the existing app means the dev loop dies the moment you deploy, and prod debugging
then happens against a live brokerage account with no way back.

**Register only the broker the second user actually trades on, first.** Three approvals in
flight is three times the waiting for no additional feedback. Kite is the assumed first.

Kite Connect charges a monthly fee per app, so a second registration is a recurring cost.
Confirm the current figure before registering all three.

---

## Identity model

### userId

`userId` is the Google **`sub`** claim, not the email address.

Email is more readable, and with nothing persisted the usual "stable key for stored rows"
argument does not apply. `sub` wins on a different ground: `connectionId` is embedded in
`BrokerWarning.connectionId` and in `BrokerNotConnectedException` messages, both of which
travel to the frontend. An email-derived connectionId puts a personal identifier into API
response bodies for no benefit.

Email is kept on the principal, for the allowlist and for display.

### Allowlist

```
MP_ALLOWED_EMAILS=bnmtheja@gmail.com,brother@example.com
```

Matched case-insensitively against the verified Google email. An address not on the list
gets a clean "not invited" page, **not** a 403 blob and not a redirect loop.

Google OAuth needs no verification review at this scale — an unverified app supports up to
100 test users. Add each address as a test user on the consent screen.

### connectionId

```
{userId}:{brokerId}:{label}        e.g.  10847...219:kite:default
```

`ConnectionService` is already keyed by `connectionId` rather than `brokerId`, so this is a
key-format change, not a redesign — as predicted in CLAUDE.md. Production blast radius is
four files:

```
KiteSessionController.java:26       "kite-default"       // TEMP: until per-user connections
AliceBlueSessionController.java:26  "aliceblue-default"  // TEMP: until per-user connections
PaytmSessionController.java:25      "paytm-default"      // TEMP: until per-user connections
PaytmDebugController.java:35        — deleted in this step regardless
```

Everything else is test fixtures: roughly 30 mechanical call sites, mostly in
`BrokerServiceFanOutTest` and `FileSessionStoreTest`.

**`connectionId` is never displayed.** `accountLabel` from `UX-STEP2.md` §Backend-1 is the
user-facing string. That item is now a dependency of this step rather than of Step 2b, since
a raw `10847...219:kite:default` in the UI is unacceptable in a way `kite-default` was not.

---

## Security filter chain

| Path | Access |
|---|---|
| `/`, `/login`, static assets | public |
| `/oauth2/**`, `/login/oauth2/**` | public |
| `/{broker}/callback` | **public** — see below |
| everything else | authenticated + allowlisted |

### Broker callbacks are public, and `state` is why — corrected 3 Aug

The original reasoning here was that callbacks must be authenticated, because the broker
names the brokerage account but never says which MoneyPlant user asked, so only the session
can attribute the connection.

**The conclusion was right and the mechanism was wrong.** Making the callback authenticated
means a third-party redirect has to carry our session cookie across a cross-site hop, which
depends on SameSite behaviour and browser cookie policy. Built that way, it failed
immediately on localhost: Zerodha redirected correctly, the callback hit the sign-in entry
point instead of its controller, the browser landed on Google's account chooser, and Kite's
single-use `request_token` was discarded — so retrying looped forever with no error anywhere.

Callbacks are therefore `permitAll()` again, exactly as before Step 3, and attribution moves
to the OAuth **`state`** parameter in 3b: a nonce minted at connect time, held server-side
against the user, verified and consumed on the way back. That identifies the user without
needing a cookie to survive the redirect at all.

This promotes `state` from "CSRF hardening, nice to have" to **load-bearing**. It is the
only thing standing between a public callback and a correctly attributed connection, and
3c must not deploy without it.

A temporary log line in `KiteSessionController.logCallerIdentity()` records whether the app
session *does* in fact survive Zerodha's redirect. That answers a real design question for
3b — if the cookie arrives, `state` can bind to the current session; if it does not, the
nonce must carry the user identity itself. Delete it once 3b decides.

### The prod-only failure to expect

A broker callback is a cross-site top-level redirect from the broker's domain back to yours.
The app session cookie must survive it, or the callback arrives unauthenticated and the
connection cannot be attributed.

`SameSite=Lax` permits this, because these are top-level GET navigations. Set it
**deliberately** rather than inheriting a container default — this is the single most likely
thing to work locally and fail on the VM, and its symptom (callback 401s, connect button
appears to do nothing) does not point at cookies.

Single origin via Caddy means no CORS, which removes the other half of this class of problem.

### The `state` parameter is missing

None of the three broker callbacks send or verify an OAuth `state` value. Single-user on
localhost this is harmless. With the callbacks public — which they now are — a crafted
callback URL can drive the connect flow unauthenticated, and on a public host with more than
one user it can bind an attacker-controlled broker account to a victim, or the reverse.

Build it in 3b, while all three session controllers are already open: generate a random
`state` at connect time in `/api/session/login-url` (which *is* authenticated, so the user is
known at that moment), store it server-side against that user, then verify and consume it in
the callback. Reject on mismatch with a plain error — never a redirect.

Note that `/api/session/login-url` being authenticated is what makes this work: the user is
identified while minting the nonce, so the callback never has to identify them again.

---

## Build order

Branch names identical in both repos, as always. Merge each pair together.

### 3a — Authentication

Ships and is fully verifiable on localhost. No deploy, no broker registration, no VM.

| Repo | Work |
|---|---|
| tradestack | `spring-boot-starter-oauth2-client`; `SecurityConfig` + filter chain; allowlist; real `/api/me` from the authenticated principal; **`/api/logout`, which does not exist today** (known issue 13); `KiteProperties` placeholder guard |
| frontend | `AuthGuard` becomes real; login page posts to `/oauth2/authorization/google`; `useLogout` works against the new endpoint; not-invited page |

`/api/me` currently returns a hardcoded `{email,name,picture}`, which is why `AuthGuard` has
always passed. After 3a it returns the real principal and 401s when absent — `lib/api.ts`
already maps 401 to a redirect to `/login`, so the guard starts working with no change to
the fetch layer.

**Estimate: ~1 day.**

### 3b — User-scoped connections

| Repo | Work |
|---|---|
| tradestack | `connectionId` format; `ConnectionService.forUser(userId)`; `BrokerService` fan-out scoped to caller; three session controllers; `state` parameter; delete `PaytmDebugController` and `mp-pm-raw`; `accountLabel` on `BrokerSession`; `/api/session/status` reshape per `UX-STEP2.md` §Backend-1 |
| frontend | `SessionStatus` type reshape and its three consumers |

**`FileSessionStore` becomes local-only, permanently.** It was already opt-in and already
must not reach the VM. Multi-user makes it worse rather than differently bad: plaintext
tokens for more than one person's brokerage account in a single file.

**Estimate: ~½ day.**

### 3c — Deploy

OCI VM, reserved static IP, Caddy serving `dist/` and proxying
`/api|/oauth2|/kite|/aliceblue|/paytm` → `:8080`. Single origin. Env values per host.

**Estimate: ~1 day of work**, plus broker approval turnaround (observed: ~1 day).

### Start now, in parallel with 3a

- Kite **prod** app registration against the domain.
- Static IP reserved and registered with the broker (SEBI requirement).
- Domain decided; Cloudflare DNS vs OCI-only settled.

These are approval-bound, not code-bound. They are the only part of Step 3 that cannot be
compressed by writing code faster.

---

## Pre-deploy checklist

Both already in `CLAUDE.md`; restated because 3c is the moment they stop being theoretical.

- [ ] `PaytmDebugController` and `mp-pm-raw` deleted — they expose account data with no
      authentication of their own.
- [ ] `MP_SESSION_STORE` unset on the VM. It writes live broker tokens to
      `~/.moneyplant/sessions.json` **in plaintext**. On a reachable host that file is a
      credential for a real brokerage account.
- [ ] `KiteProperties` fails fast on an unset env var rather than binding `${...}`.
- [ ] Session cookie `SameSite` set explicitly.
- [ ] **Broker callbacks attribute via `state`.** They are `permitAll()` and currently
      attribute nothing — on a reachable host anyone can drive the connect flow. This is the
      one item on this list that is a genuine hole rather than a hygiene check.
- [ ] `KiteSessionController.logCallerIdentity()` deleted.
- [ ] Prod broker credentials present in the VM environment; dev credentials absent from it.

---

## Open questions

1. **Which broker does the second user trade on?** Decides which prod registration goes
   first. Assumed Kite.
2. **Does the OAuth `state` round trip survive Alice Blue's and Paytm's callbacks?** Kite
   documents a `state`-like passthrough. The other two are unverified — if either drops
   unknown query parameters, the CSRF fix needs the HTTP session alone rather than a
   round-tripped nonce.
3. **Domain and DNS.** Cloudflare in front, or OCI only. Cloudflare adds TLS and a hostname
   for free; it also puts a third party between the user and a brokerage session.
4. **Does the Kite Connect monthly fee apply per app registration?** Decides whether prod
   registrations for all three brokers are worth doing at once or one at a time.

---

## Explicitly not in this step

Postgres, `users`, `broker_links`, saved strategies, credential encryption, per-user API
keys, roles or permissions, invitations, password login, account deletion. Two or three
known people on an allowlist need none of it.

Step 7 remains where persistence lives. Nothing here blocks Step 6 or Step 8.
