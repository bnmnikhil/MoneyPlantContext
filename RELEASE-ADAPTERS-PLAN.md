# Release plan: FOUND-03, the Upstox adapter and the Dhan adapter to production

**Written 6 Oct 2026**, after both brokers were tested working on staging. Status markers are
`P0-LAUNCH.md`'s (`[ ]` `[~]` `[x]` `[-]`). This plan owns the release; `PUBLIC-LAUNCH.md` carries the
handoff; `BROKER-EXPANSION-PLAN.md` carries the per-broker work.

**The release is two separate decisions, and this plan keeps them apart.**

1. **Ship the code, dark** (Phase 1). Upstox and Dhan are in the production jar but **not offered to anyone**.
   No user-visible change except the settings form learning about an optional field. One additive migration.
2. **Turn a broker on** (Phase 2). A deliberate, per-broker flip, gated on evidence that cannot come from the
   simulator. Not scheduled here; it has its own checklist.

## What production runs today (read from the VM, 6 Oct 2026, 20:29 IST)

| | |
|---|---|
| Backend | `8b7ed3e` (main, FOUND-06 merged). Started 6 Oct 12:05 IST. |
| Frontend | `03d015e` (main, with the landing-page change LAND-06). |
| Flyway | V1 to V9, all `success`. |
| Boot line | `Broker rollout (environment=production): aliceblue=available, kite=available, paytm=available` |
| Env file | no `GB_ROLLOUT_*`, `GB_ENVIRONMENT`, `GB_UPSTOX_*` or `GB_DHAN_*`: production defaults apply |
| Data | 3 users; credentials: Kite 2, Alice Blue 1, Paytm 1 |
| Backups | **the timer is disabled and there is no `backup.env`**: no off-VM copy of anything (P0 D1) |
| Resources | 6.0 GB free memory, 32 GB free disk; staging runs beside it |

## What goes out

| Change | PRs | Production effect |
|---|---|---|
| **FOUND-03**: optional `client_id` on a registration | MoneyPlant #40, frontend #33 | **V10**: `alter table broker_credential add column client_id text`. Nullable, additive, the 8 existing rows keep null. The list endpoint gains a `clientId` key (null for every current broker). |
| **Upstox adapter** | MoneyPlant #39, frontend #31 | Code present, **rollout state `staging`: not usable in production**. Public `/upstox/callback` exists. |
| **Dhan adapter** | MoneyPlant #41, frontend #34 | Same: state `staging`, not usable in production. Public `/dhan/callback`. |
| `SessionController` | in #41 | `login-url` now cancels the pending flow it minted if building the URL throws. Affects every broker only on a failure path that previously stranded a flow. |
| Caddy | already on the VM | Production's `@backend` already routes `/upstox/*` and `/dhan/*` to `:8080` (installed from the branch on 5 and 6 Oct). **No Caddy change at release.** |

Nothing changes for Kite, Alice Blue or Paytm users. FOUND-06 (already live) is what keeps the two new
brokers invisible: the catalogue, the credential screens, the connect flow and every read of a stored session
consult it.

## Risks, and why each is acceptable

| Risk | Assessment | Mitigation |
|---|---|---|
| **V10 on the live database** | One nullable column, metadata-only in Postgres 16, applies in milliseconds. Flyway ran it on staging and on the laptop's real-shaped database. | Dump first (below). |
| **Rolling back the jar after V10** | Safe: the old code names its columns explicitly in every `select` and `insert`, so an extra nullable column is ignored. The column stays; nothing needs reverting. | Rollback steps below. |
| **A hidden broker leaking** | The one way this release can matter to a user. Checked at three levels in code and tests (catalogue, auth registry, `ConnectionService`). | **Verification step 3**: the settings dropdown must show exactly three brokers. |
| **Restart blip** | The backend is down for the jar swap (seconds). Broker sessions are restored from Postgres; the 10-minute pending-connect state is lost. | Deploy outside market hours. |
| **Build load on 1 OCPU** | `deploy.sh` builds and runs the full test suite on the VM, unthrottled, beside production. Staging's own build caused a brief SSH timeout today. | Stop staging for the window; run late evening. |
| **No off-VM backup** | A failed deploy cannot lose data (the migration is additive), but a bad day on the VM would. D1 is deprioritised by the owner. | Take the pre-release dump; copy it off the VM. |
| **Kite after ST-2** | The Kite REST client has run since 4 Oct but the owner has not confirmed Kite's figures against GoldenBook's, nor the reconnect banner. Not part of this release, but it is the one live-broker check outstanding. | Do it before or alongside; see Preconditions. |

## Phase 1: ship the code, dark

### Preconditions

- [ ] Merge in this order, because the PRs are stacked: MoneyPlant **#39 + frontend #31**, then **#40 + #33**,
  then **#41 + #34**. (Broker-sim #2 and the context PRs are not part of the production build.)
- [ ] On the merged `main` of each repo: `mvnw clean test` (expect 626) and, for the frontend, `npm test`
  (84) and `tsc -b`. A merge that git calls clean is not a merge that compiles.
- [ ] **Staging runs the merged `main`**, not just the feature branch, and Upstox and Dhan still connect there.
  (Both were tested working on the branch on 6 Oct.)
- [ ] The owner has compared Kite's positions, holdings and margins with GoldenBook's (ST-2), and has seen the
  reconnect banner once after a token expired.
- [ ] A window: **outside 09:15-15:30 IST**, on a weekday evening or a weekend, with an hour free to watch it.

### Steps

1. **Free the VM.** `sudo systemctl stop goldenbook-staging goldenbook-staging-sim` (staging is disposable, and
   this returns about 1 GB and most of the CPU to the build).
2. **Pre-release copy**, as root, into `/root/pre-release-<UTC timestamp>/`: `pg_dump` of the `goldenbook`
   database from the container, a copy of `/opt/goldenbook/tradestack.jar`, a copy of `/var/www/goldenbook`, and
   the env file. **Copy the dump off the VM** (`scp` to the laptop). This is the only off-VM copy there is.
3. **Deploy:** `deploy-from-local.ps1` (production, `main`). It refuses any other branch.
4. **Bring staging back:** `sudo systemctl start goldenbook-staging-sim goldenbook-staging`.

### Verification (all must pass; any failure is a rollback trigger)

1. **Boot line** (`journalctl -u goldenbook`, since the new start):
   `Broker rollout (environment=production): aliceblue=available, dhan=staging (not offered here), kite=available,
   paytm=available, upstox=staging (not offered here)`.
2. **Endpoint guard line** shows only vendor hosts, now including `api.upstox.com`, `api.dhan.co` and
   `auth.dhan.co`. (Production refuses a simulator host at boot, so a misconfigured env would have failed to start.)
3. **The settings form** (browser, signed in): the broker dropdown offers **exactly Kite, Alice Blue and Paytm**.
   No Upstox, no Dhan. Existing registrations still list, with their keys.
4. **Flyway**: `select version, success from flyway_schema_history order by installed_rank desc limit 1` is
   `10 | t`.
5. **Sessions survived**: Overview, Positions and Holdings load for a connected broker without a reconnect.
6. **Public paths are inert**: `curl -s -o /dev/null -w '%{http_code}' https://goldenbook.in/upstox/callback` and
   `/dhan/callback` return a redirect to the app (302), not a 5xx, with no code.
7. **Logs**: no `ERROR` since boot; no line mentioning `upstox` or `dhan` other than the two boot lines.
8. `free -m` shows headroom; `https://goldenbook.in` and `/api/me` answer (200 and 401).

### Rollback

Triggers: any verification failure, or an error burst in the first hour. **Rollback is safe because V10 is
backwards compatible**; the column is left in place.

```
sudo systemctl stop goldenbook
sudo cp /root/pre-release-<ts>/tradestack.jar /opt/goldenbook/tradestack.jar
sudo rsync -a --delete /root/pre-release-<ts>/www/ /var/www/goldenbook/
sudo systemctl start goldenbook
```

Then re-run verification steps 1 (no Upstox or Dhan in the line), 5 and 8. Restoring the database dump is **not**
part of a normal rollback and would lose any credentials saved since the dump; it is for corruption only.

### After

- [ ] Watch the journal for a day: nothing new should appear.
- [ ] Record the deploy in `PUBLIC-LAUNCH.md`'s handoff and `P0-LAUNCH.md`.
- [ ] Remove the rollback copies a week later, with the older ones already listed in the handoff.

## Phase 2: turning a broker on (separate decision, per broker)

**The ladder has no "owner only in production" rung.** `GB_ROLLOUT_<BROKER>=available` exposes the broker to
every user, and sign-up is open. So the first real-account test must not be in production.

**Recommended live certification: the laptop, in `local` mode.** `GB_ENVIRONMENT=local` accepts vendor hosts and
shows `staging`-state brokers, and both Upstox and Dhan accept a `localhost` redirect URL. A friend's account (or
the owner's own) connects to the real broker through dev auth, with nothing in production. This is where CERT-02
and CERT-03 happen, and where the open facts are settled.

### Gate to flip `GB_ROLLOUT_UPSTOX=available`

- [ ] CERT-02: creating a data-only Upstox app does not ask for a static IP.
- [ ] CERT-03: positions and holdings fetched from an unregistered IP.
- [ ] CERT-04: Upstox's answer on hosted multi-user use, in writing, or its terms read and judged.
- [ ] The three assumptions settled on a live account and their tests updated: `average_price` is the real entry,
  or the mapper is corrected; `quantity`, `t1_quantity` and `collateral_quantity` are disjoint or overlap; the
  margin block's collateral.
- [ ] The real error body and the token-exchange error code recorded (the adapter does not depend on them, but the
  dossier should).
- [ ] User-facing: the onboarding steps (create an Upstox developer app, redirect URL
  `https://goldenbook.in/upstox/callback`), the broker list on the landing page, and the privacy and terms pages
  updated to name Upstox. The broker guide (L6) gains an Upstox section.

### Gate to flip `GB_ROLLOUT_DHAN=available`

- [ ] Everything above, for Dhan: CERT-02 (does the key form ask for an IP), CERT-03, CERT-04 (**Dhan's written
  answer on hosted use**, or the partner programme), and its own open facts (`costPrice`, `totalQty`,
  `collateralQty`, the instrument file's date format, whether the redirect can carry state).
- [ ] **HOLD-PRICE has landed**: `HoldingDto` can say "price unknown" and the holdings screens show a dash. Until
  it does an unpriced Dhan holding reports zeros.
- [ ] The onboarding guide says plainly that **live prices need Dhan's paid Data API (Rs 499 plus tax a month)**,
  that the user needs TOTP enabled, and that Dhan's API key lasts 12 months.
- [ ] The client-id field's label and help text checked with a real user.

### To flip

Add one line to `/etc/goldenbook/goldenbook.env` (`GB_ROLLOUT_UPSTOX=available`), restart, verify the boot line
shows `upstox=available` and the dropdown shows it, then connect the owner's own account first and watch the
logs. No migration, no redeploy of code. **Reversing is the same line removed and a restart**: stored sessions stay
saved and reappear if it is turned back on.

## Open decisions for the owner

1. **The window** for Phase 1 (tonight after market close, or a weekend).
2. **Whether to wait for the Kite comparison** (ST-2) before releasing, or release in parallel. They are independent.
3. **Live certification on the laptop with a friend's account**: who, and when. This is the long pole for Phase 2.
4. **Hosted-use outreach** (CERT-04) to Upstox and Dhan, currently deferred to the 17-24 Oct review: it is on the
   critical path to turning either broker on, though not to Phase 1.
5. **Off-VM backups (D1)**: the owner deprioritised it; this release is a reason to at least copy the pre-release
   dump off the VM by hand.

## Status

- [ ] PRs merged in order
- [ ] Gates green on merged `main` (backend 626, frontend 84, typecheck)
- [ ] Staging on merged `main`
- [ ] Kite comparison done
- [ ] Phase 1 deployed and verified
- [ ] Phase 2, Upstox: certified, user-facing copy updated, flipped
- [ ] Phase 2, Dhan: certified, HOLD-PRICE landed, copy updated, flipped
