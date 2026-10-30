# GoldenBook — the working queue

**Created 10 Oct 2026; re-planned 11 Oct 2026 as stages that end in the announcement.** It is
drawn from the 6 Oct handoff in `PUBLIC-LAUNCH.md`, the open P0, L, O and adapter items, and
the owner's requests. Most items wrap an id that already exists in another tracker. **When an
item is done, flip its marker here and the wrapped ids in their own tracker**; this file never
restates their detail.

Status markers are `P0-LAUNCH.md`'s: `[ ]` not started, `[~]` in progress, `[x]` done and
verified, `[-]` dropped. `[x]` means the verification below was run, not that code exists.

## The launch plan (owner, 11 Oct 2026)

**Launch scope: positions, holdings, payoff graphs and the Strategy Builder, on the user's live
data. Nothing else** (`memory/launch-scope-is-live-data-only.md`). No history is captured before
launch; risk analytics, market history and back-testing come after it and decide then what to
store (end-of-day history can be backfilled).

**The launch is the announcement.** Sign-up has been open since 3 Oct 2026, but nobody has been
told, and production holds only the owner's data. The stages lead to the day it is announced.
Finish a stage before starting the next; only L1's external clock runs alongside.

| Stage | Goal | Items | Done when |
|---|---|---|---|
| **A** | Correct and safe for a stranger who arrives unannounced | N12, N2, N13, N4's HOLD-PRICE, N7, N8, N9, L4, E3 | A new user sees only live, correct figures and nobody else's data; a new sign-up and an outage both alert the owner; terms acceptance is recorded; erasure has been run once |
| **B** | Friends as the first users | N14, N6, then N3 and N4's certification | Backups proven by a restore; 2–3 friends' Upstox and Dhan accounts compared figure by figure |
| **C** | Ready to announce | L1 (review 17–24 Oct), N5 (L7, E1/E2/E4/E6), L12, D4, L16 | `PUBLIC-LAUNCH.md`'s go/no-go checklist ticked; the copy claims only the four launch features. Then announce |
| **D** | After launch | Define Risk; market history; back-testing; N10 if Groww opens a path | — |

**Why this order.** A is what a stranger meets today, since sign-up is open. B before C because
friends both certify Upstox and Dhan (live since 6 Oct, unverified) and fire N6's backup trigger,
one batch of work instead of two. C last because broker answers (L1) and honest public copy should
precede telling anyone.

**Open (owner):** the announcement date (fixed, or "when C is green"); 2–3 friends with Upstox
or Dhan accounts for B.

## Summary

| ID | Item | Wraps | Size | Stage | Status |
|---|---|---|---|---|---|
| N1 | Land the pending branches | broker-sim #2, frontend `docs/rewrite-legal-copy`, context `docs/overview-a-plan` | S | — | `[x]` |
| N2 | Hide the Risk page | owner decision, 10 Oct | S | A | `[x]` in production 30 Oct |
| N3 | Upstox live certification | UPSTOX-07, CERT-02, CERT-04 | M | B | `[ ]` |
| N4 | Dhan live certification and HOLD-PRICE | HOLD-PRICE, Dhan's open facts, CERT-02, CERT-04 | M | A (HOLD-PRICE), B (certification) | `[ ]` |
| N5 | Broker copy that scales past five brokers | L7, E1, E2, E4, E6 (L6 moved to N14) | M | C | `[ ]` under discussion |
| N6 | Off-VM backups | D1, O3 (backup heartbeat) | M | B | `[ ]` deferred until the first non-owner user registers a broker (owner, 11 Oct) |
| N7 | Frontend failure states | B2, B3, B4, O13 | M | A | `[ ]` |
| N8 | Cross-user isolation on production | L11 | S–M | A | `[ ]` |
| N9 | Monitoring floor: health, uptime, alerts, new sign-ups | D2, O1, O2 | S–M | A | `[ ]` |
| N10 | Groww broker support | `BROKER-EXPANSION-PLAN.md` Phase 4 | L | D | `[-]` on hold (owner, 11 Oct); dossier done |
| N11 | Payoff: "today" curve (projected P&L), then a days slider | owner request, 10 Oct | M | — | `[x]` all three phases in production, 11 Oct |
| N12 | Positions margin calculated live | owner, 11 Oct; supersedes the column's risk dependency | S–M | A | `[x]` |
| N13 | Switch off `raw_capture` | owner, 11 Oct; drops L14 | S | A | `[ ]` |
| N14 | Show how to create each broker's API key and secret | owner, 11 Oct; L6 | M | B | `[~]` in production 13 Oct; waits on a friend's walk-through |
| N15 | Release the 13 Oct usability fixes | usability session, 13 Oct | S | A | `[x]` in production 13 Oct |
| N16 | The screen after sign-in | usability session, 13 Oct | M | A | `[~]` in production 13 Oct; owner's look at desktop and phone left |
| N17 | Staging without its password prompt | usability session, 13 Oct | S | — | `[ ]` |
| N18 | Browser smoke pack | `TESTING.md`'s `ui` scope | M | — | `[ ]` |
| N19 | The landing page states GoldenBook's price | usability session, 13 Oct | S | C | `[ ]` |

**Removed 10 Oct 2026 (owner):** L5, the Google consent screen, because its test-user limit
does not apply to this application; and A1, the frozen risk data, because the Risk page is
hidden until it is defined (`NEXT-STEPS.md` owner idea 4, `memory/risk-page-hidden-until-defined.md`).

**10 Oct 2026, later (owner):** N11 jumps the queue and N2 waits behind it.

**11 Oct 2026 (owner):** N11 done; N2 back in, as Risk is outside the launch scope; N12 and N13
added; the queue regrouped into the stages above, replacing the 10 Oct order.

**13 Oct 2026 (owner's usability session on staging):** N15 to N19 added. The session's notes
are kept off git (`usability/`, local); what came out of them is here.

---

## `[x]` N1 — Land the pending branches

- broker-sim **#2** (Dhan profile, 57 tests): staging already runs it from its branch. Merge,
  then point staging at the simulator's `main`.
- frontend `docs/rewrite-legal-copy` (`6fc0651`, 8 Oct): pushed, no PR. Open the PR, run the
  gates on the merged result, merge. Its rendered check moves to N5, which rewrites the same
  pages.
- context `docs/overview-a-plan`: seven tracker commits (6–9 Oct), never pushed. Push, PR, merge.

**Verify:** `gh pr list` is empty in all four repos; staging's simulator unit runs from `main`.

**Done 10 Oct 2026.** broker-sim #2 merged, and #3 with it: staging actually ran
`feature/any-credentials`, which stacks the SIM005 near-expiry spread and the any-credentials
flags on the Dhan profile (both flags default to `true`). Simulator gate 59 passing. Frontend
#41 merged; `npm test` 116 passing, build clean, branch already level with `main`. This
branch went up as a context-repo PR. Staging's simulator was not redeployed: its running build
is the same code as the simulator's new `main`, and the next staging deploy picks up `main` by
default.

## `[x]` N2 — Hide the Risk page

The owner has not settled what Risk should show (`NEXT-STEPS.md` owner idea 4). Take the
`Risk` entry out of `components/layout/nav.ts` and the `/app/risk` route out of `App.tsx`, so
the bottom tab bar has four tabs. Leave `RiskPage`, `features/risk/` and the backend in place:
**`/api/risk/summary` must stay**, because the positions table's margin column reads it
(`memory/positions-margin-comes-from-risk.md`). Check nothing else links to `/app/risk`
(Overview's attention band, menus), and that an old bookmark lands somewhere sensible.

**Verify:** `npm test`, `npm run build`; no `/app/risk` link in the built app; positions'
margin column unchanged; desktop and phone nav checked in Chrome.

**Done 30 Oct 2026** (frontend `n2/hide-risk-page` `4040c2a`, merged as `6daebfd`). The nav has
five items, not four, because Builder joined it after this plan. `/app/risk` redirects to
`/app/positions` rather than 404ing, and Overview's stale-estimates link now reads "Positions →".
Gates: typecheck, `npm test` 154, build. Checked in Chrome locally with dev auth: desktop nav and
a 390 px frame's bottom tab bar show Overview, Positions, Holdings, Payoff, Builder; the old URL
lands on Positions with the margin column filled. **In production 30 Oct, 11:06 IST:** backend
gate 694, `/` and `/app/positions` 200, `/api/me` 401, Google OIDC in the boot log, and the served
bundle has no nav link to `/app/risk`.

## `[ ]` N3 — Upstox live certification (UPSTOX-07)

The method is the handoff's: the laptop in `GB_ENVIRONMENT=local` with dev auth, a real
account (the owner's or a friend's), and a `localhost` redirect registered at Upstox. Settle
the facts `UpstoxRawMapperTest` pins as assumptions: `average_price` as the true entry; whether
`quantity`, `t1_quantity` and `collateral_quantity` are disjoint; that the margin block has no
collateral figure; and the real error bodies (session-expired vs call-failed classification).
CERT-02: does the app form ask for a static IP? CERT-04: what the terms say about hosted
multi-user use.

Fix any mapper or test that turns out wrong, ship it to production, then discard credentials
and personal response data. Record findings in `research/UPSTOX-DOSSIER.md`.

**Verify:** positions, holdings and margins compared figure by figure against Upstox's own app
for one account; expiry and reconnect seen once; UPSTOX-07 flipped in `BROKER-EXPANSION-PLAN.md`.

## `[ ]` N4 — Dhan live certification and HOLD-PRICE

**Split by stage (11 Oct):** HOLD-PRICE is Stage A, the live certification Stage B.

**HOLD-PRICE first.** `HoldingDto` gets `priceKnown`, the same rule as `PositionDto`'s: a
missing price is not zero. The holdings screens and the Overview totals show a dash and
mark totals partial. Dhan without the data plan then shows "price unavailable", not ₹0. This
is the gate that was skipped on 6 Oct; it is also correct for any broker whose quote fails.

Then certify, the same way as N3, against `DhanRawMapperTest`'s pinned assumptions:
`costPrice` as the true entry, `totalQty` vs `collateralQty`, the instrument file's date
format, and the single-pending-connect callback. Record findings in `research/DHAN-DOSSIER.md`.

**Owner decision inside this item:** keep Dhan on for users without a data plan before
HOLD-PRICE ships, or set `GB_ROLLOUT_DHAN` back until it does.

**Verify:** backend and frontend gates green; a Dhan account without a data plan shows dashes
on staging (`SIM001`–`SIM003`) and real figures with one (`SIM004`); the live comparison done.

## `[ ]` N5 — Broker copy that scales past five brokers

**Under discussion with the owner (10 Oct 2026); the approach below is not decided.** The
landing page, the legal pages and the setup guide name brokers one by one, and more brokers are
coming, so every addition means editing prose in several places. Replace that format with one
that a new broker does not touch. Still in scope: L7 (landing copy and its desktop/phone render check), E1/E2/E4/E6 (legal placeholders,
support contact), and N1's deferred render check of the legal rewrite.

**Verify:** to be written once the approach is chosen.

## `[ ]` N6 — Off-VM backups (D1) — deferred until its trigger

**11 Oct 2026 (owner): deferred, with a trigger.** Production holds only the owner's own data (3
`app_user` rows, all the owner's or seeded from the owner's history; 11 MB), all recreatable, so a
loss today costs an evening. **Switch backups on when the first account that is not the owner's
registers a broker, or before any announcement or marketing, whichever comes first.** Sign-up is
open, so that can happen unannounced: watch `/app/admin`'s user count until N9 can alert on it.
The strategy is fixed now so the switch-on is an hour's work, not a design:

- **What, in priority:** `GB_CREDENTIAL_KEY` (already off the VM; never in the same place as a
  dump), then `app_user` + `broker_credential`. Not `broker_session`: sessions die daily. Not
  `raw_capture`: switched off by N13 (11 Oct).
- **How:** nightly `pg_dump`, encrypted before it leaves the VM, to OCI Object Storage (always-free
  tier). Losing at most a day is acceptable for a read-only product.
- **Retention:** 7 daily, 4 weekly.
- **Proof:** a heartbeat alert on a missed run (O3) and a monthly restore drill into staging.

Production holds real users' encrypted credentials and sessions, and the only copies are on the
VM. The scripts already exist (PR #16). Remaining: an off-VM target (OCI Object Storage PAR,
per D1), `backup.env`, enable the timer, a heartbeat to Healthchecks.io (O3), and **a tested
restore** into a scratch database. `GB_CREDENTIAL_KEY` stays backed up separately and never
travels with a dump. Then remove the old rollback copies listed in the handoff.

**Verify:** a scheduled run lands off the VM; a restore of it boots the app against a scratch
database and reads one user's credentials; a missed run raises an alert.

## `[ ]` N7 — Frontend failure states (B2, B3, B4, O13)

- **B2:** a React error boundary, so one bad payload stops being a blank white page.
- **O13:** the boundary reports to `/api/client-errors` (rides on B2).
- **B3:** a fetch timeout in `lib/api.ts`, so a hung call becomes an error, not an endless
  skeleton.
- **B4:** a failed query renders as unavailable, never a confident `₹0`.

**Verify:** `npm test`, `npm run build`; in Chrome, a forced render error shows the fallback
and logs a client error; a blocked API call times out to an error state; no tile reads ₹0
when its query failed.

## `[ ]` N8 — Cross-user isolation on production (L11)

With open sign-up, the one property that cannot fail is that a user never sees another user's
data. Two real Google accounts on production; each connects a broker; every read endpoint
(`positions`, `holdings`, `margins`, `payoff`, `risk`, `session/status`, `broker-credentials`)
and every connection id from one account is tried from the other. L18's spot and chain cache
is in scope.

**Verify:** a written run sheet in `P0-LAUNCH.md`/`PUBLIC-LAUNCH.md` with each request and its
response code; every cross-account request is refused or returns nothing of the other user's.

## `[ ]` N9 — Monitoring floor: health, uptime, alerts

`OBSERVABILITY.md` still shows O1 and O2 as not started, but MoneyPlant #43
(`obs/o1-health-and-host-stats`) is merged and the monitor already alerts to Telegram and
Discord. First reconcile: what of O1 and O2 is deployed and working. Then finish the floor:
a public minimal `/api/health`, an external uptime check that alerts, and the backend's own
restart alerted. Flip the O-items as each is verified. **Added 11 Oct:** an alert when a new
`app_user` row appears (count only, no email in the message), because sign-up is open and N6's
backup trigger is the first non-owner user.

**Verify:** stopping the backend on staging (not production) raises an alert within the
uptime interval; `/api/health` answers without auth and leaks nothing.

## `[-]` N10 — Groww broker support (on hold)

**11 Oct 2026: step 1 done, stopped at step 2's gate.** `research/GROWW-DOSSIER.md`. Groww's retail Trade API
has **no browser-redirect login**: its routes are an API key and secret with a daily approval at Groww, a TOTP
seed, or a pasted daily token. The dossier recommends the first as a Groww-only exception (no login secret passes
through GoldenBook; the user consents daily at Groww) and rules out the TOTP seed. Also open: whether the
static-IP field is mandatory at key creation (CERT-02, a hard stop if so), and the **₹499 a month plus taxes**
every user would pay Groww. **On hold (owner, 11 Oct 2026):** too few Groww users would pay ₹499 a month
to connect a read-only app, against the largest build in the queue. Reopen if Groww offers a partner/OAuth
route for read-only apps (ask in the L1 outreach, 17–24 Oct) or a friend confirms the static-IP field is
optional. Until then no simulator or adapter work.

Groww is rank 1 by NSE active clients and next in the approved order. The vertical slice is
`BROKER-EXPANSION-PLAN.md`'s: **dossier → gate → simulator → auth → adapter → catalogue/UI →
verification → live certification → staging soak → production flag**, each as its own step.

1. **Dossier** (`research/GROWW-DOSSIER.md`, shaped like Upstox's and Dhan's): login type,
   token lifetime, positions/holdings/margins payloads, instrument master, error bodies, rate
   limits, the ₹499-a-month API cost, terms on hosted multi-user use.
2. **Gates, hard stops:** (a) portfolio reads must work without a static IP; this is
   documented only as "IP is for orders" and must be **observed**. (b) The login must be a
   browser redirect: `memory/browser-redirect-brokers-first.md` holds back any broker whose
   login passes the user's secrets through GoldenBook. **If either gate fails, stop and bring
   it to the owner**; do not lower the rule (the plan's own instruction).
3. **broker-sim Groww profile**, synthetic data only, with a `login-url` property from the start
   (`memory/browser-urls-never-share-a-setting-with-server-urls.md`).
4. **Adapter** in `broker/groww/`: gateway, session service, mapper, raw source, capabilities;
   rollout default `internal`. Give the browser login URL its own property.
5. **Catalogue and settings** fields; staging soak; live certification as in N3; then
   `GB_ROLLOUT_GROWW` in production on the owner's word.

**Verify:** the plan's "Definition of done for one broker", item by item; backend gate and
`verify.ps1 -Scope broker -Broker groww` green; connected end to end on staging.

## `[x]` N11 — Payoff: "today" curve, then a days slider

Sensibull-style projected P&L: beside the expiry payoff, the open legs valued **now** at each
spot. On staging's BANKNIFTY condor the page showed Current P/L −₹89 while the expiry curve at
spot read +₹8,785; the today curve is what joins the two.

**Model.** Each option leg is priced with Black-Scholes at the volatility implied by its own
current mark, held as spot moves (sticky strike; no smile dynamics). That makes the curve pass
through Current P/L at spot, which is the built-in check. Futures and shares keep today's basis.
A leg with no usable mark borrows the nearest-the-money volatility (same expiry first) and the
chart says how many did; with no volatility anywhere, the curve is not drawn and the chart says
why. Computed in the browser (`frontend/src/features/payoff/projection.ts`) because the chart
redraws there on every leg toggle and zoom; it mirrors `pricing/BlackScholes` and
`ImpliedVolatility` constant for constant, and both test suites pin the same reference prices.

- **Phase 1** (`payoff/today-curve`; frontend #43, MoneyPlant #45): live Payoff page; Both /
  Today / Expiry toggle, default Both (owner); tooltip shows both; Today-only hides the expiry
  breakevens; title "Payoff". Gates: frontend 127 tests and build; backend 667 on the staging
  build. **Verified on staging 10 Oct** (SIM004 BANKNIFTY condor): Today at spot −₹89 against
  Current P/L −₹89; with one leg unticked, −₹3,507 against −₹3,507. Convergence to the expiry
  curve at expiry is unit-tested.
- **Phase 2** (same branch and PRs; frontend `05f0479`, `90b660d`): a target-date slider, **days
  only** (owner: no volatility control). Day 0 is now; day *n* is that day's 15:30 IST close, up to
  the last open expiry. Volatility stays solved at today's marks; a leg past its own expiry counts at
  intrinsic (mixed-expiry books); a future's basis shrinks to nil at its expiry. Target-date
  breakevens are listed under the slider, found over the auto range so zooming does not move them,
  and drawn in blue in the Projected-only view. The toggle's middle button is now **Projected**; the
  legend and tooltip name the curve "Today" or its date. Max profit/loss stay expiry-based. Gates:
  frontend 135 tests, typecheck, build. **Verified on staging 11 Oct** (SIM004 condor): the T+7
  curve lifts as time value decays; at T+16 (27 Oct, last expiry) it lies on the expiry curve, with
  the expiry breakevens 56,449 · 58,951; Projected-only draws 56,427 · 58,820 for 19 Oct; the
  tooltip shows both curves. Phone width not checked.
- **Phase 3:** the Strategy Builder chart and its compare view; draft legs take volatility from
  the chain's price at their strike.
- **Layout, owner review 11 Oct** (frontend `2846add`, `8389676`): the Both / Projected / Expiry
  selector is gone, both curves always show. Range buttons, reset and legend share one toolbar; the
  range explanation and the model note sit behind ⓘ tips; the axis titles are dropped. The target
  date moved under the chart as one gold slider (owner picked design A from four mocks on the
  canvas `https://claude.ai/artifact/CMCeNzw5T2TFiiLvU1N5Tg`, then gold over blue: controls take the
  theme colour, curves keep data colours; a blue swatch in the thumb's date label ties it to the
  curve). The stepper and the separate Today button are gone; Today is a pill at the track's left end.
- **In production 11 Oct 2026, 11:16 IST:** frontend #43 (`cc15e5b`) and MoneyPlant #45
  (`3611be6`) merged and deployed; backend gate 667 on the host, site 200, `/api/me` 401, served
  bundle identical to the local build. The gold slider and the phone layout were not seen in a
  browser before the deploy (staging had signed out); check both next time Payoff is open.
  **Validated in production 11 Oct** on a live HEROMOTOCO call ratio spread: today at spot +₹2,926
  against Current P/L +₹2,927; at the last expiry the curve lies on the expiry payoff and its
  breakeven (5,412) is the expiry one. Phone width still unchecked.
- **Phase 3** (`payoff/builder-projected`, frontend #44, `7c16a25`, `1e6aa32`): the Strategy Builder
  uses the live chart panel (toolbar, both curves, gold target-date slider). Imported legs project
  from the broker's mark, draft legs from the chain quote they were added at, so a strategy built
  from quotes is flat today at spot (tested). The "If it expires at" spot slider and its three
  figures are removed (owner). Gates: 136 tests, typecheck, build; on staging (simulator 59, backend
  667). **Verified on staging 11 Oct** (ITC bear call spread from chain quotes): today +₹0 at spot,
  T+8 breakeven 429.38, at the last expiry the curve lies on the expiry payoff with breakeven 432.
  Follow-up `c6b479b` drops a focus box the builder drew round the slider. **In production 11 Oct**
  (frontend #44, `522c9f9`): backend 667 on the host, site 200, `/api/me` 401, served bundle identical
  to the local build of `main`.

## `[x]` N12 — Positions margin calculated live

**Owner, 11 Oct 2026: margin has to be calculated live.** The positions table's margin column
reads `/api/risk/summary` (`memory/positions-margin-comes-from-risk.md`), whose positions come
from `position_snapshot`. `SnapshotService.getPositions` fetches live only when a user has **no**
rows, so it seeds them at the first visit and serves them for ever: every new user's margin
column freezes on their first day (captioned stale, but useless). Production's own rows are
frozen at 13–15 Aug.

Run the margin engine (`MarginAllocator` / `HeuristicMarginEngine`) over the **live** positions
the table already shows, and take the subtotal and the account total from that same fetch, so
the column still foots. The column then reads nothing from `snapshot/` or `risk/`; once it does,
nothing on a visible page reads `/api/risk/summary`, and `raw_capture` can stop (N13).

**Verify:** backend and frontend gates; a position opened today gets a margin figure the same
day and no stale caption; on staging the figures equal the engine's on the same positions;
checked in production on the owner's book.

**Done 11 Oct 2026** (tradestack PR #46, `6ef0d26`; ADR 0029 supersedes 0012; docs PR #33).
Built differently from the plan above: rather than moving the engine out of `risk/`, risk's two
inputs are now read live (`portfolio/LivePositionSource`, `LiveMarginSource`), so the column
still comes from `/api/risk/summary` but over the live book. Gates: `mvnw clean test` 670.
Staging: every risk request computed all three simulator accounts from live margins. Production,
deployed 15:28 IST: the owner's Alice Blue estimate is over **6** live positions where the frozen
snapshot holds 11 from 13 Aug; no WARN or ERROR since the deploy.
- **Not checked:** the rendered page by automation (staging's basic auth blocked it; the owner
  viewed production), and "a position opened today" (Sunday; confirm on the next trading day).
- **Engine finding, not N12's:** the estimate is 0.94× Kite's bill but **0.60×** Alice Blue's.
  Alice Blue's `utilizedSpanMargin` 109,991 + `utilizedExposureMargin` 96,678 is exactly its
  `used`, so the shortfall is mostly exposure, which the engine charges at 2% / 3.5% of
  notional. Worth calibrating before friends compare the column with their Alice Blue bill.

## `[ ]` N13 — Switch off `raw_capture`

**Owner, 11 Oct 2026** (`memory/launch-scope-is-live-data-only.md`). Two writers fill it:
`OnFetchCapture` (every user's portfolio, throttled to one row per connection and kind per 15
minutes) and `EodCaptureJob` (15:35 IST, weekdays). No launch feature reads it; its only reader
chain is `MarginBackfillService` → `margin_snapshot` → `/api/risk/summary`, which N12 removes
from view. **Do N12 first.**

Stop both writers; keep the table and the read-side classes for now, and let the Risk redesign
(Stage D) decide whether to drop them in a migration. Then delete production's `raw_capture`
rows, all the owner's (a production change: owner approval at the time). Check that the privacy
page says nothing about keeping portfolio history. L14 is dropped with this.

**Verify:** backend gate; after a trading day on production `select count(*) from raw_capture`
stays 0 and no `capture_run` rows appear; positions, holdings, payoff and builder unchanged.

## `[~]` N14 — Show how to create each broker's API key and secret (L6)

**Owner, 11 Oct 2026: the app has to show the instructions for creating the API key and secret at
each broker.** Today the add-registration form shows the right field names (*API key*, *App
code*, *secret*) and one link, "Open <broker> developer portal" (`CredentialFields.tsx`). It
gives no steps and no redirect URL to paste, so nobody gets through it without the owner on the phone.
This takes over L6 from N5. It sits in Stage B because friends connecting Upstox and Dhan are the
first people who will need it.

**13 Oct 2026: shipped to production** (tradestack PR #47 `2eda115`, frontend PR #45 `6483bf2`;
gates 675 / 141). Owner checked staging; production boots with all five guides and
`GB_FRONTEND_URL=https://goldenbook.in`, so every URL reads `https://goldenbook.in/<id>/callback`.
Owner's wording rules (13 Oct): steps and the activation wait only, no extra detail. Alice Blue
says activation can take some time, usually the same day; the IP field and Paytm's product type
are left out. Alice Blue's portal link moved to `a3.aliceblueonline.com`.
**Left:** a friend connects one broker using only the guide (L6's test), then tick L6; correct
the Upstox and Dhan text after the Stage B walk-through.

### Plan (11 Oct 2026)

**What the user sees.** Choosing a broker in `AddRegistrationPanel` opens a **"How to get these"**
block above the fields:
1. **Numbered steps**, from opening the developer portal (the existing link moves into step 1) to
   copying the key and secret into the boxes below.
2. **The redirect URL** in a read-only box with a **Copy** button. The steps say "paste the URL
   below" rather than spelling it out, so the text stays the same on every host.
3. **Before you start** notes in an amber callout: costs, waits and prerequisites, shown *before*
   step 1 so nobody finds out at the end that Dhan prices cost ₹499 a month.

Open by default when the user has no registration at that broker; collapsed to a one-line
"How to get these" toggle when they already have one (they have done it before). The inline
**Replace** form on `RegistrationRow` gets the same toggle, collapsed. Settings' empty state
says to choose Add broker to see the steps, instead of "register a developer app at your
broker" with nothing to follow.

**Where the content lives: the backend catalogue.** `BrokerCatalog`'s templates already own
each broker's name, fields and portal link, and the catalogue refuses to start for a gateway
with no template. It gains a `SetupGuide(List<String> steps, List<String> notes)` per template
and refuses to start if `steps` is empty, so **no broker can ship without instructions**.
`BrokerDefinition` and `GET /api/brokers` gain `setup` and `redirectUrl`; `types/api.ts` mirrors
them as optional fields, so a frontend deployed against an older backend renders no guide rather than crashing.

**The redirect URL is computed, never typed.** `redirectUrl = app.frontend-url + "/" + id +
"/callback"`, the convention all five session controllers follow (`@GetMapping("/<id>/callback")`).
A test fails if any gateway's id has no controller mapped at that path, and checks that
`UpstoxSessionService.redirectUri()` (the one adapter that sends the URL in its login request)
equals the catalogue's. Production shows `https://goldenbook.in/kite/callback`, staging its own
host, and the laptop `localhost`, each correct where it is shown.

**The text, per broker.** Draft from the vendors' current documentation, then walk each portal
once to correct it. The owner walks Kite, Alice Blue and Paytm (accounts held); Upstox and Dhan
are walked by the Stage B friends, which is also their L6 test. The notes known today:
- **Kite:** the Personal tier costs ₹0 and covers everything GoldenBook reads; leave the
  postback URL empty. Existing apps registered at the old `moneyplant.bonamnikhilbabu.in`
  callback keep working through its redirect until R11, but new apps use the URL shown.
- **Alice Blue:** after creating the app, its admin team must activate it; until then login
  answers "Invalid vendor id". Say how long that took when the owner walks it.
- **Paytm Money:** a KYC'd Paytm Money account is required, and every daily connect asks for
  the password and an OTP (there is no refresh token).
- **Upstox:** a standard OAuth app; the URL must match character for character. Record whether
  the form asks for a static IP (CERT-02) while walking it.
- **Dhan:** TOTP must be on before the key can be made; key and secret come from web.dhan.co →
  Profile → *Access DhanHQ APIs* and **expire after 12 months**; the third box is the Dhan client
  ID; live prices need the **Data API at ₹499 + tax a month**, without which positions show
  Dhan's own P&L but no marks.
- Text only, no screenshots: the vendors' screens move and a stale picture misleads more
  than a stale sentence.

**Order of work** (one branch, `n14/broker-setup-steps`, in both repos):
1. Draft the five guides in the chat for the owner to approve the wording.
2. Backend: `SetupGuide` on the templates, `setup` and `redirectUrl` on `BrokerDefinition`;
   tests for the non-empty rule, the URL convention and the Upstox match. `mvnw clean test`.
3. Frontend: `features/credentials/SetupGuide.tsx` (steps, copy box, notes; the open/collapsed
   rule as a pure function in `model.ts` with a node test), wired into the Add panel, the
   Replace form and the empty state. Typecheck, `npm test`, build.
4. Staging: the owner looks at desktop and phone width (the automation browser cannot pass
   staging's basic auth), every broker's URL is staging's own, and Copy works.
5. Production, with approval; check that every URL reads `https://goldenbook.in/<id>/callback`.
6. The owner walks Kite, Alice Blue and Paytm against the text and corrections ship. Upstox and
   Dhan are corrected after the friends' walk in Stage B.
7. Update `frontend/docs/broker-credential-setup.md` and `docs/product/brokers.md`; tick L6 in
   `PUBLIC-LAUNCH.md` only after a friend has connected using the guide alone.

**Verify:** frontend gates; every listed broker shows steps and its redirect URL on staging and
in production, with the URL matching that host's callback; a person who has never seen the app
connects one broker using only these instructions (L6's test). Friends in Stage B are that test.

## `[x]` N15 — Release the 13 Oct usability fixes

Three fixes found while the owner used staging on 13 Oct 2026, all verified there:
- **Sign in / Sign up.** The landing and login pages gave no hint that this is also how to make
  an account, and there is no username and password to look for.
- **A deploy left a blank page.** Without a Cache-Control header the browser kept an old
  index.html naming a bundle the deploy had deleted, and `try_files` answered that .js with
  HTML. Caddy now revalidates index.html, keeps hashed bundles a year and 404s a missing one.
- **A deploy signed everyone out.** The sign-in session now lives in Postgres
  (`memory/web-sessions-persist-in-postgres.md`).

tradestack PR #48 and frontend PR #46 (`launch/persist-web-sessions` in both), and this repo's
`docs/persist-web-sessions`. **Owner decision open:** the Privacy page gains a retention line for
the sign-in session; bump `details.ts`' version and date or not.

**Verify:** gates (678 / 141); production deploy (it signs users out one last time); copy
`deploy/Caddyfile` to `/etc/caddy/Caddyfile` and reload (the owner runs it); then sign in, deploy
again and stay signed in, and `curl -I` shows `no-cache` on `/` and `immutable` on a bundle.

**Done 13 Oct 2026.** tradestack #48, frontend #46 and context #39 merged and deployed (backend up
20:43:35 IST); the owner reloaded Caddy. From outside: `/` and SPA routes `no-cache`, the bundle
`immutable`, a missing bundle 404, and the `SESSION` cookie Secure, HttpOnly, SameSite=Lax. The
owner signed in, then N16's deploy restarted the backend (21:59:40 IST) and they stayed signed
in. The privacy version was not bumped.

## `[~]` N16 — The screen after sign-in

What a user meets on `/app` before any broker is logged in today (`ConnectBrokerCard`). From the
session: it read as first-time setup, but for a returning user it is a daily step (broker logins
end every night); its buttons wrapped raggedly and Kite alone was highlighted; and the header's
"Offline" read as "the app is down".

**Decided (owner, 13 Oct 2026, from a mockup):**
- **Daily login:** "Log in to your brokers for today", one even row per registration with its own
  Log in button and a line on what to expect (Paytm: password and OTP every day). No broker is
  highlighted.
- **First-time user:** a three-step checklist (signed in, add a broker, log in for today). *Add a
  broker* opens Settings with the add form open (`/app/settings?add=1`), where N14's guide is.
- **Header:** "Not logged in", or "No brokers yet", with a grey dot, instead of an orange
  "Offline". "Partial" and "Live" unchanged.
- **The Overview once any broker is logged in is unchanged, including *To fix*** listing brokers
  not connected. The mockup's "not logged in today" bar was rejected.

**Built** on `n16/daily-login` (frontend; tradestack mirrors `main` for the staging script):
`features/session/dailyLogin.ts` (pure; `tests/daily-login.test.mjs`), `ConnectBrokerCard`,
`Topbar`, `SettingsPage`. Gates: typecheck clean, `npm test` 145, build clean. Checked locally with
dev auth: the owner's seven registrations list as seven rows, the header reads "Not logged in";
as a user with no keys the checklist shows, the header reads "No brokers yet", and *Add a broker*
lands on Settings with the form open. **Not checked:** the look itself, and phone width (the
automation browser could not screenshot localhost).

**Verify:** the owner looks at both states at desktop and phone width (the daily login shows
once no broker is logged in for the day).

**13 Oct 2026: in production** (frontend #47, context #40; backend up 21:59:40 IST), at the
owner's request before their look. The live bundle carries both screens and the new header
wording. **Left:** the owner's look; then `[x]`.

## `[ ]` N17 — Staging without its password prompt

Basic auth on staging stops the automation browser and asks the owner for a password on every
visit. Keep it on `/docs` (internal), take it off the app and the simulator login pages, and set
staging's `GB_SIGNUP_MODE=allowlist` so only listed Google accounts get in. No test-login back
door. Caddy change; the owner runs the reload. Also: the staging deploy warns that a unit file
changed on disk (`systemctl daemon-reload`); find which and fix the deploy script.

**Verify:** staging's app opens without a password prompt, `/docs` still asks, and a Google
account not on the list is refused.

## `[ ]` N18 — Browser smoke pack

Playwright on the laptop against the local app with dev auth and `broker-sim`, so no Google
sign-in is needed: open every page, log in to each simulated broker, check the Overview,
Positions, Payoff and Builder render figures. Becomes `verify.ps1 -Scope ui`, which is a
placeholder today.

**Verify:** `.\scripts\verify.ps1 -Scope ui` passes on a clean run and fails when a page breaks.

## `[ ]` N19 — The landing page states GoldenBook's price

The landing page never says what GoldenBook costs, so a visitor cannot tell whether it is free.
Say it (free, while that is true), and that some brokers charge for API access. Belongs with N5's public copy in Stage C.

**Verify:** the price is on the landing page and matches the terms.

