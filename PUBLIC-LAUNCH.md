# Public launch — the plan and tracker

**Created 2 Oct 2026. Target: sign-up opens Fri 9 Oct 2026, after the 15:30 IST market
close.** This file owns the **launch schedule** and the new **L-items** that open sign-up
creates. The existing A–F items keep their detail and their status in `P0-LAUNCH.md`. This
file only says *which of them gate launch* and *on which day*. `CLAUDE.md` points here;
the monitoring plan is `OBSERVABILITY.md` (O-items, same status rules); the rename and domain move is `REBRAND-GOLDENBOOK.md` (R-items); reasoning lives in `memory/public-launch-is-open-signup.md`; outside-world facts live in
`research/BROKER-API-TERMS-MULTI-USER.md`.

Status markers are `P0-LAUNCH.md`'s (`[ ]` `[~]` `[x]` `[-]`), with the same rule: **`[x]`
only after the verification line has actually been run.** Branch names carry the id
(`launch/l3-open-signup`).

## Decisions taken 2 Oct 2026 (owner)

1. **"Public" means open sign-up**: anyone with a Google account can sign in. It does
   not mean open-sourcing the repos. This supersedes P0's "small invited group" framing.
2. **The Strategy Builder ships; the index-spread Screener does not.** P0 item A6 (hide
   the builder) is dropped. The builder's preconditions (A2, A4's input fix, B5, C4)
   become launch blockers instead.
3. **Read-only stays a product constraint.** Nothing here adds order placement.

## The honest read on the timeline

The code work is large but parallelisable, and most items are hours, not days. **The
critical path is external**, and none of it can be made faster by working harder:

| External dependency | Lead time | Starts |
|---|---|---|
| **Zerodha compliance answer on multi-user Kite Connect use** (L1) | unknown, days to weeks | **today** |
| Alice Blue and Paytm Money answers (L1) | unknown | today |
| Google OAuth brand verification, so the consent screen shows the name and logo (L5) | a few business days; needs the privacy page **live** first | Sat 3 Oct |

**If L1 has no Zerodha answer by go/no-go (Thu 8 Oct), do not open sign-up.** Deploy
everything else and run as a wider allowlisted beta until it arrives. See the fallback
ladder in the research doc. Launching anyway puts the risk of a revoked API app on users
who cannot see it.

---

## Summary

**Tier 1: blocks opening sign-up.** Tier 2: launch week, but not a hard gate. Tier 3: the
week after.

### New items (status owned here)

| ID | Item | Tier | Status |
|---|---|---|---|
| L1 | Written broker answers on multi-user API use | 1 · external | `[~]` |
| L2 | Final domain decision: it is baked into every user's broker app | 1 · decision | `[~]` |
| L3 | Open sign-up mode, `app_user` table, kill switch | 1 · auth | `[ ]` |
| L4 | Terms acceptance recorded at first sign-in | 1 · legal | `[ ]` |
| L5 | Google OAuth consent screen → Production + brand verification | 1 · external | `[ ]` |
| L6 | Self-serve broker setup guide (exact redirect URLs per broker) | 1 · onboarding | `[ ]` |
| L7 | Landing + login copy rewritten for strangers | 1 · onboarding | `[~]` |
| L8 | Screener kept out of the launch build | 1 · scope | `[~]` |
| L9 | Builder is honest without an Alice Blue quote source | 1 · numbers | `[ ]` |
| L10 | Release integration: merge, deploy `main`, verify Flyway V5–V8 in prod | 1 · release | `[ ]` |
| L11 | Cross-user data isolation test on production | 1 · security | `[ ]` |
| L12 | Security review of the launch diff + dependency audit | 1 · security | `[ ]` |
| L18 | Spot cache shared across users: one user's broker quote served to another | 1 · terms | `[ ]` |
| L13 | Capacity: resize the VM to the free 4 OCPU / 24 GB, set JVM heap, smoke-load | 2 · ops | `[ ]` |
| L14 | `raw_capture` growth: measure per user/day, add retention | 2 · ops | `[ ]` |
| L15 | Incident runbook: breach, key rotation, disabling sign-up | 2 · ops | `[ ]` |
| L16 | Launch comms + feedback channel | 2 · comms | `[ ]` |
| L17 | SEBI RA: lawyer's read on the builder's recipes | 3 · legal | `[ ]` |

### Existing P0 items, re-tiered for open sign-up (status stays in `P0-LAUNCH.md`)

| Tier | Items | Why this tier |
|---|---|---|
| **1** | **A1** risk page frozen in prod · **A2** NIFTY lot size (verify: `origin/main` no longer has the literal) · **A4** `₹NaN` + builder input noise · **B2** error boundary · **B3** fetch timeout · **B4** confident `₹0` · **B5** failed simulation · **B6** generic exception handler · **C1** security headers · **C3** debug endpoints · **C4** validation / rate limit / body cap · **C5** disconnect · **C6** prove dev auth off · **D1** backups (PAR + restore-verify) · **D2** → **O1–O8 + O13** in `OBSERVABILITY.md` (health, uptime + Telegram, heartbeats, 30-day log retention, request ids, structured logs, JVM flags, audit events) · **D3** deploy check · **D4** rollback · **E1 E2 E4 E6** legal pages, disclosure, contact · **E3** erasure (manual, tested procedure is enough) | Strangers, their money, a public URL, and hotfix deploys during launch week |
| 2 | **C2** Caddy query-string logging · **C7** stale comment (5 min, do with C3) · **A7** estimate labels · **A3** Paytm master silent failure · **D5** runbook step | Cheap; do in launch week if time allows |
| 3 | **B7** Kite client per call · **A5** payoff engine edge cases · **D6** snapshot backfill (owner-deferred) · **F2** → absorbed by L6 | Real, but not public-exposure risks |
| — | **A6** `[-]` dropped (builder ships) · **E5** → absorbed by L1 · **F1** → absorbed by L3 | Superseded |

---

## Day-by-day

Each day ends with the gate green on what was merged: `mvnw clean test`, `npm test`,
`npm run build`. **Market hours are 09:15–15:30 IST. Deploy only outside them.**

**Fri 2 – Sun 4 Oct: start the slow clocks** (Fri 2 Oct is a market holiday)
- L1: send the three emails. They are on the critical path; nothing else today matters as much.
- L2: settle the domain.
- E1/E2/E4/E6: write the privacy, terms and disclosure text, then deploy it as static
  pages (Caddy can serve them before the SPA routes exist) so that L5 can start.
- L5: switch the consent screen to Production, add the privacy/terms URLs, submit brand verification.
- D1: mint the PAR, enable the timer, **restore-verify from Object Storage**. VM work, so
  the weekend suits it.
- L13: resize the VM (stop, change shape, start). Do it now, not on launch day.

**Mon 5 Oct: backend blockers**
- A1 (one condition), C3 + C7, C6, B6, C4 (validation starter, body cap, leg cap,
  NaN/Infinity rejection, per-user token bucket on `simulate` / `compare` / `margin-estimate`).
- L8: confirm the screener classes are not on the launch branch.

**Tue 6 Oct: sign-up and user control**
- L3 + L4 (one migration, `V9`), C5 disconnect (backend + the badge button), E3's erasure
  procedure written and **run against a test user**.

**Wed 7 Oct: frontend blockers, then deploy dark**
- B2, B3, B4, A4, B5, L9, the E1 routes + footer, L6, L7.
- **Deploy to production with sign-up still allowlisted** (L10). Read the Flyway history,
  read the boot log for C6, and run the runbook's nine verification steps.

**Thu 8 Oct: ops, review, rehearse**
- C1 (+ external header scan), O1–O8 + O13 (`OBSERVABILITY.md`; O1 also fixes D3's probe), D3, D4 (**rehearse a rollback on the real VM**), L14,
  L12, L11 with a second Google account.
- **Go/no-go 20:00 IST**, against the checklist below.

**Fri 9 Oct: open**
- No code deploy. After 15:30, flip sign-up to open (L3's switch is config only), sign
  up as a fresh account end to end, then post L16's announcement.

**Mon 12 – Fri 16 Oct: watch**
- Read the logs and the uptime monitor daily, and answer the support inbox the same day.
  Then work through Tier 2 leftovers and Tier 3.

---

## Go/no-go checklist (Thu 8 Oct, 20:00 IST)

All must be true. Anything false means **stay allowlisted**, not "launch and fix".

- [ ] `frontend/src/features/legal/details.ts` has no `[placeholder]` left (the legal pages show no draft notice).
- [ ] **Every claim in the privacy policy is true on production**, in particular:
  - server logs kept ≤ 30 days (the logrotate under D2, plus journald limits);
  - backups expire at 30 days (D1's lifecycle rule; already applied);
  - erasure from the live DB within 7 days of a request (E3's procedure exists and has been run);
  - email address stored (L3);
  - exactly two cookies (session + `XSRF-TOKEN`) and no analytics;
  - Google Fonts disclosed, **or** self-hosted, with that line deleted (also simplifies C1's CSP).
- [ ] The landing page makes no claim the terms contradict (L7). The copy is fixed on `launch/e1-legal-pages`; this box is ticked once that branch is what is deployed. Today it advertises "Telegram alerts", "Risk-guarded execution … before it reaches the exchange" and "Live Greeks & IV", and none of the three exists.
- [ ] L1: Zerodha has answered and does not object (or the owner has consciously chosen a fallback from the research doc).
- [ ] Every Tier 1 item is `[x]` in its tracker.
- [ ] D1: a backup **downloaded from Object Storage** restored and decrypted a credential, this week.
- [ ] D4: a rollback was rehearsed on the VM.
- [ ] D2: stopping the service paged the owner's phone.
- [ ] L11: a second account saw none of the first account's data on production.
- [ ] Sign-up kill switch tested: off → a new Google account is refused, existing users unaffected.
- [ ] `GB_CREDENTIAL_KEY` and `GB_BACKUP_PASSPHRASE` are both in the password manager and current.

---

## Tier 1: new items

### `[~]` L1 — Written broker answers on multi-user API use

**2 Oct 2026: drafted, not sent.** The drafts and a send log are in `research/BROKER-CONSENT-EMAILS.md`.

Kite Connect §4(b): credentials "are intended to be used only by you". Staff: "personal use
only … speak to compliance for multi-user access". Alice Blue's terms have the same clause
and a separate admin-reviewed vendor route. Paytm publishes no terms. Full quotes are in
`research/BROKER-API-TERMS-MULTI-USER.md`.

**Do:** email `kiteconnect@zerodha.com`, Alice Blue API support and
`openapi.care@paytmmoney.com` with the same factual description: read-only, no orders;
each user's own developer app; the secret encrypted with AES-256-GCM under a key held
outside the database; each user sees only their own data; nothing shown publicly. Ask the
direct question: *is this permitted, and is approval needed?*

**Verify:** each answer saved verbatim into the research doc, and a memory written if an
answer changes a decision.

### `[~]` L2 — Final domain decision

**2 Oct 2026: `goldenbook.in` bought, and the product is renamed GoldenBook.** The move is
carried out as R-items in `REBRAND-GOLDENBOOK.md`, which owns its status. This item turns
`[x]` when R2's verification has run.

Every user's broker app registers `https://<domain>/kite/callback` (and the Alice Blue and
Paytm equivalents) **in their own broker account**. Changing the domain after launch breaks
every user's connect flow until each of them edits their broker app. Today's domain is
`moneyplant.bonamnikhilbabu.in`.

**Do:** keep it, or buy and move **before** L5 and L6, since both print the domain.

**Verify:** the Google OAuth redirect URI, Caddy, `app.frontend-url` and L6's guide all
name the same host.

### `[ ]` L3 — Open sign-up mode, `app_user` table, kill switch

`AllowedEmails` refuses to start on an empty list, by design ("never 'allow everyone'").
Open sign-up must be **an explicit mode, never an empty list**. Keep that property.

**Do:** `V9` creates `app_user (user_id = Google sub, email, created_at, last_seen_at,
disabled_at, terms_version, terms_accepted_at)`. Add `goldenbook.signup = allowlist | open
| closed`: `closed` admits existing `app_user` rows only, which is the kill switch. Add a
`disabled_at` check at sign-in so one abusive account can be cut off. Keep rejection inside
the token exchange, as `SecurityConfig` does now, so there is no half-logged-in state. Log
the active mode at startup, next to C6's auth-mode line. This absorbs F1, and gives E3's
erasure a row to start from.

**Verify:** in each of the three modes, test a new address, an existing address and a
disabled address, with no restart required to disable a user.

### `[ ]` L4 — Terms acceptance recorded at first sign-in

**Do:** after first sign-in, a one-screen interstitial shows the read-only / not-advice /
estimates disclosure (E4) and links the terms and privacy pages. Accepting writes
`terms_version` + `terms_accepted_at`. Bumping the version re-prompts.

**Verify:** a new user cannot reach `/app` without accepting, and the row records the version.

### `[ ]` L5 — Google OAuth to Production, brand verification

`openid email profile` are non-sensitive scopes, so Production status lifts the 100-test-user
cap without a security review. Brand verification (name and logo on the consent screen)
needs a verified domain, a live privacy-policy URL on it, and a support email. It takes days.

**Verify:** a Google account not on any test-user list completes sign-in, and the consent
screen shows GoldenBook's name.

### `[ ]` L6 — Self-serve broker setup guide

A stranger cannot use GoldenBook until they create a developer app at each broker, a step
no one will walk them through in person. Kite Connect's Personal tier costs ₹0. Alice Blue
needs its admin team to activate the app, otherwise login answers `"Invalid vendor id"`.
Paytm needs a KYC'd account. This absorbs F2.

**Do:** one page per broker, linked from the Settings empty state and from each
registration form. It names the exact redirect URL to paste, which fields map to *API key*
/ *App code* / *secret*, the activation wait, and the cost.

**Verify:** a person who has never seen the app connects one broker using only the guide.

### `[~]` L7 — Landing and login copy for strangers

**2 Oct 2026: rewritten, not yet seen rendered.** On `launch/e1-legal-pages` (with the legal pages, which cannot ship without it). Removed three false claims: Telegram alerts, risk-guarded order execution, and live Greeks & IV. Added four true features, a "Read-only, by design" block, the three setup steps (L6's friction stated up front), a "Good to know" limits list, the shared footer, page title, meta description and Open Graph tags. `og:url` and `og:image` wait for L2. `npm test` 63 passing, build clean. The Chrome extension did not respond, so **desktop and phone rendering are still to be checked**.

`LandingPage.tsx:90` says "Private system", and `LoginPage.tsx:93` says "Private system.
Access restricted."

**Do:** what it does, which brokers it supports, that it is read-only and places no
orders, what setup it needs (L6), the E4 disclosure, footer links (E1/E6), page title and
Open Graph tags.

**Verify:** read it signed out on a phone.

### `[~]` L8 — Screener out of the launch build

**2 Oct 2026: split and merged** (frontend #22 settings; the screener stays on its own
unpushed branch). Was: split, committed locally, not pushed. Settings redesign is
`launch/l8-settings-redesign` in `frontend` (`cc01727` Sidebar removal, `698beb5` the
redesign; 71 tests, build clean). The screener is `feat/index-spread-screener` in both
repos (`frontend abb378e`, `tradestack 650e8c7`), each cut from `origin/main` and
independent of the Settings branch. The screener's frontend commit also carries the nav
breakpoint move from `lg` to `xl`, which a sixth nav item forced. Settings and
`launch/e1-legal-pages` merge cleanly. Verification waits for the production deploy.

The screener ranks specific credit spreads, which is the RA-exposed end (see the research
doc). It used to be uncommitted local work in both repos, mixed with the Settings
redesign in the frontend's `App.tsx` / `nav.ts`.

**Do:** split the Settings redesign into its own PR (it ships). Keep the screener on its
own branch, or ship it behind a flag that is off. No `/app/screener` route and no nav item
in the launch build.

**Verify:** on production, `GET /api/screener` returns 404 and `/app/screener` hits `NotFoundPage`.

### `[ ]` L9 — Builder is honest without an Alice Blue quote source

Option-chain quotes come only from `AliceBlueOptionChainProvider`. Most public users will
connect Kite only.

**Do:** walk the builder as a Kite-only user. It must say that no quote source is connected
and what to connect. It must never fall back to invented premiums, and never produce
figures from a missing quote. Confirm A2's lot size comes from the contract master for that
user.

**Verify:** a Kite-only account sees a clear "needs a quote source" state; an Alice Blue
account sees live premiums; `GET /api/payoff/metadata` returns 65 for NIFTY.

### `[ ]` L10 — Release integration and the dark deploy

The last **recorded** production deploy is 6 Sep (`tradestack 0b95e40`, `frontend
c8ab2ae`). Every later status note says "no production change", so assume backend PRs
up to #23 and frontend PRs up to #21 are not live. **Confirm by reading the VM's checked-out
commits first.** **V5–V8 have never been confirmed in prod.**

**Do:** merge the Settings redesign PR (L8 split) and every Tier 1 branch, run the gates
**on a clean worktree of merged `main`**, then `deploy.sh` with sign-up still allowlisted.
Run `select version, success from flyway_schema_history`.

**Verify:** Flyway lists V1–V9 all `success`; the runbook's nine steps pass with all three
brokers connected.

### `[ ]` L11 — Cross-user isolation on production

**Do:** sign in as a second Google account with its own broker. Check every page and
every `connectionId`-taking endpoint (`/api/payoff/{u}?connectionId=`, `DELETE
/api/session/{id}`, credentials) by **substituting the first user's ids**.

**Verify:** every substituted call returns 404/403, and no page shows the other user's data.

### `[ ]` L12 — Security review and dependency audit

**Do:** run `/security-review` over the merged launch diff, plus `npm audit --omit=dev`
and an OWASP dependency check (or `mvn versions:display-dependency-updates`) on the
backend. Confirm `GB_COOKIE_SECURE=true` on the VM. Re-read CSRF and session-fixation
settings with open sign-up in mind.

**Verify:** findings fixed, or recorded here with a reason.

### `[ ]` L18 — The spot cache crosses users

Found 2 Oct while drafting L1. `SpotPriceService` fetches over the **caller's own**
session, but its 5 s cache is keyed by underlying alone, deliberately shared ("one quote
should serve everyone"). With open sign-up, a user with no Paytm connection can be shown
a spot that was fetched under **another user's** Paytm credentials. That is market data
obtained on one account and displayed to someone else, which is exactly what the
redistribution clauses prohibit. `OptionChainService`'s cache is already keyed by
`userId` + `connectionId` and is fine.

**Do:** key the spot cache by `(userId, underlying)`. The upstream cost is one call per
user per 5 s burst, which is negligible.

**Verify:** a unit test with two users, where only the first has a Paytm session: the
second gets 0 (no spot), never the first user's cached price.

## Tier 2: new items

### `[ ]` L13 — Capacity

The VM is 1 OCPU / 8 GB. The always-free Ampere allowance is **4 OCPU / 24 GB**, so the
extra capacity costs nothing. Every signed-in tab refetches positions and margins every
30 s, across up to three brokers.

**Do:** resize, set an explicit `-Xmx`, and smoke-load ~20 concurrent sessions against
dev auth locally. Watch heap, threads (B7's per-call `KiteConnect` matters here) and
Postgres connections.

**Verify:** p95 for `/api/positions` and memory stay flat across 15 minutes of load.

### `[ ]` L14 — `raw_capture` growth

`OnFetchCapture` is throttled, but no retention exists anywhere, so the table grows per
user per day forever on a single VM disk, and inside every nightly backup.

**Do:** measure rows and bytes per user per day locally, project for 100 users, then add
a retention job (e.g. 90 days), or a documented decision that it isn't needed yet.

**Verify:** the projection is recorded here, and the job deletes only rows past the window.

### `[ ]` L15 — Incident runbook

**Do:** add a short section to `tradestack/deploy/README.md` covering: switch sign-up to
`closed`; disable one user; rotate `GB_CREDENTIAL_KEY` (the `key_version` backfill, never
an in-place edit); force-expire all broker sessions; and the DPDP breach notice (users plus
the Data Protection Board; legally due from May 2027, but state the commitment now in E2).

**Verify:** the kill switch and single-user disable have been run once, for real.

### `[ ]` L16 — Launch comms and feedback

**Do:** an announcement post that leads with the setup cost (L6) and the read-only scope.
Point it at the E6 support address as the one feedback channel, and pin a "known
limitations" list: mixed-expiry payoff, the SPAN estimate running under the broker's
figure, no history yet.

## Tier 3

### `[ ]` L17 — SEBI RA read on the builder

The builder computes payoffs over legs the user chose. That is the defensible end. Its
one-click **recipes** (Bull Call Spread, Iron Condor, …) are generic, but they are named
strategies. Comparable Indian platforms are registered RAs.

**Do:** a short opinion from a securities lawyer before adding any ranking, scoring or
"suggested" language, and certainly before the screener ships. Until then the recipe list
carries "educational templates, not recommendations".
