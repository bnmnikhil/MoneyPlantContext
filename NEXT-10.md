# GoldenBook — the working queue

**Created 10 Oct 2026.** The working queue: ten items, done one at a time, in order. It is
drawn from the 6 Oct handoff in `PUBLIC-LAUNCH.md`, the open P0, L, O and adapter items, and
the owner's request to add Groww. Most items wrap an id that already exists in another
tracker. **When an item is done, flip its marker here and the wrapped ids in their own
tracker**; this file never restates their detail.

Status markers are `P0-LAUNCH.md`'s: `[ ]` not started, `[~]` in progress, `[x]` done and
verified, `[-]` dropped. `[x]` means the verification below was run, not that code exists.

## Summary

| ID | Item | Wraps | Size | Status |
|---|---|---|---|---|
| N1 | Land the pending branches | broker-sim #2, frontend `docs/rewrite-legal-copy`, context `docs/overview-a-plan` | S | `[x]` |
| N2 | Hide the Risk page | owner decision, 10 Oct | S | `[ ]` postponed (owner, 10 Oct) |
| N3 | Upstox live certification | UPSTOX-07, CERT-02, CERT-04 | M | `[ ]` |
| N4 | Dhan live certification and HOLD-PRICE | HOLD-PRICE, Dhan's open facts, CERT-02, CERT-04 | M | `[ ]` |
| N5 | Broker copy that scales past five brokers | L6, L7, E1, E2, E4, E6 | M | `[ ]` under discussion |
| N6 | Off-VM backups | D1, O3 (backup heartbeat) | M | `[ ]` deferred until the first non-owner user registers a broker (owner, 11 Oct) |
| N7 | Frontend failure states | B2, B3, B4, O13 | M | `[ ]` |
| N8 | Cross-user isolation on production | L11 | S–M | `[ ]` |
| N9 | Monitoring floor: health, uptime, alerts | D2, O1, O2 | S–M | `[ ]` |
| N10 | Groww broker support | `BROKER-EXPANSION-PLAN.md` Phase 4 | L | `[-]` on hold (owner, 11 Oct); dossier done |
| N11 | Payoff: "today" curve (projected P&L), then a days slider | owner request, 10 Oct | M | `[x]` all three phases in production, 11 Oct |

**Removed 10 Oct 2026 (owner):** L5, the Google consent screen, because its test-user limit
does not apply to this application; and A1, the frozen risk data, because the Risk page is
hidden until it is defined (`NEXT-STEPS.md` owner idea 4, `memory/risk-page-hidden-until-defined.md`).

**10 Oct 2026, later (owner):** N11 jumps the queue and N2 waits behind it.

**Why this order.** N1 and N2 are small. N3 and N4 come next because real users can already
connect two uncertified brokers (switched on 6 Oct), and Dhan shows zeros for anyone without
its paid data plan. N5 makes the public pages match what is live, in a form that does not need
rewriting for every new broker. N6–N9 close the gaps live users are exposed to. Groww is last
because `BROKER-EXPANSION-PLAN.md` says to review the pilots before copying them: whatever N3
and N4 find out about the shared contract should land before a sixth adapter is built on it.
**Groww's dossier is research only, so it can start any time.**

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

## `[ ]` N2 — Hide the Risk page

The owner has not settled what Risk should show (`NEXT-STEPS.md` owner idea 4). Take the
`Risk` entry out of `components/layout/nav.ts` and the `/app/risk` route out of `App.tsx`, so
the bottom tab bar has four tabs. Leave `RiskPage`, `features/risk/` and the backend in place:
**`/api/risk/summary` must stay**, because the positions table's margin column reads it
(`memory/positions-margin-comes-from-risk.md`). Check nothing else links to `/app/risk`
(Overview's attention band, menus), and that an old bookmark lands somewhere sensible.

**Verify:** `npm test`, `npm run build`; no `/app/risk` link in the built app; positions'
margin column unchanged; desktop and phone nav checked in Chrome.

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
that a new broker does not touch. Still in scope: L6 (setup guide with exact redirect URLs),
L7 (landing copy and its desktop/phone render check), E1/E2/E4/E6 (legal placeholders,
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
  dump), then `app_user` + `broker_credential`, then `raw_capture` (the only history that cannot
  be rebuilt). Not `broker_session`: sessions die daily.
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
restart alerted. Flip the O-items as each is verified.

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

