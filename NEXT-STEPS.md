# GoldenBook next steps — residual backlog

**Captured:** 21 September 2026. **Trimmed:** 3 October 2026.
**Status:** Backlog, not an implementation commitment.
**Authorities:** `PUBLIC-LAUNCH.md` for what is being worked on now,
`P0-LAUNCH.md` for production readiness, `BROKER-EXPANSION-PLAN.md` for broker
research, the capability foundation, simulators and per-broker delivery.

This file holds only the open items that no other tracker owns. The broker
ranking, feasibility research, integration foundation and simulator workstreams
that used to live here were absorbed by `BROKER-EXPANSION-PLAN.md` (CERT, FOUND,
SIM and pilot phases) and `research/BROKER-LAUNCH-SHORTLIST.md`; the original
draft is in git history. When an item below is picked up, move it into the
tracker that will own it and delete it here.

## Owner ideas, to triage

Captured as the owner states them, dated. Each is moved into the tracker that will own it
(and deleted here) when it is picked up. Notes under an item are the assistant's mapping to
existing work, not the owner's words.

### 1. An application dashboard (6 Oct 2026)

> "we have to add dashboard where i can check our application status, stats, health,
> resource utilisation and several other parameters."

**Mostly planned already, none of it started.** `OBSERVABILITY.md` has the stack decided
(2 Oct): O1 the health endpoint, O9 the metrics catalogue (Actuator and Micrometer),
O10 Prometheus, Grafana and `node_exporter` on the VM (loopback only, reached through an
SSH tunnel), O11 the dashboards as provisioned JSON (Overview, Brokers, Host: up/down,
request rate, p95 latency, 5xx and ERROR rate, sign-ins, live sessions, CPU, memory,
disk and its forecast, JVM heap, Hikari pool, DB size), O12 alert rules to Telegram.

**To settle when this is picked up** (the owner said "several other parameters" without
listing them):
- Which parameters beyond O11's list. Candidates the assistant would raise, since the
  product has changed since 2 Oct: **per-broker connect success and failure counts**
  (there are now five brokers, two uncertified, and a failed connect is what to watch
  first), live sessions per broker, how many users and sign-ups, token-expiry and
  reconnect rates, the Alice Blue and Dhan "more than one pending connect" refusals, and
  how stale the contract masters are.
- **Staging shares the VM**, so the Host dashboard must show production and staging
  separately (memory, CPU), or a staging build will look like a production incident.
- Who can see it: the existing design is loopback plus an SSH tunnel. A public or
  team-visible dashboard would need an authenticated route and is a different decision.
- Sequence: O1 and O2 (health endpoint, external uptime and Telegram) are the cheap start
  and the launch floor; the dashboard proper is O9 to O11.

## Testing for agents

`TESTING.md` and `scripts/verify.ps1` are the entry point (old TEST-01 to
TEST-04, done). The shared broker contract suite is `BROKER-EXPANSION-PLAN.md`
TEST-02. Still open:

- [ ] **TEST-06 — Centralise broker fixtures.** Proposed location:
  `tradestack/src/test/resources/brokers/<broker>/<endpoint>/<scenario>.json`,
  with provenance metadata beside each scenario and a secret/PII scan.
- [ ] **TEST-07 — Add deterministic test-data builders.** Reuse named portfolios
  such as empty, equity-only, options spread, multi-account, expired session and
  partial quote. Avoid one-off magic JSON embedded across tests.
- [ ] **TEST-08 — Add real integration boundaries.** Test database migrations and
  persistence against Postgres; test broker HTTP behavior against simulators;
  test the frontend against the same backend contracts. Do not mock the layer
  whose contract the test claims to verify.
- [ ] **TEST-09 — Add a small browser smoke pack.** Sign in through dev auth,
  connect a simulated broker, and verify Overview, Positions, Holdings, Payoff,
  Risk and Settings at desktop and phone widths. Include keyboard navigation,
  empty, loading, error and expired-session states. This is what turns
  `verify.ps1 -Scope ui` from an explicit skip into a real check.
- [ ] **TEST-10 — Make failures self-explanatory.** Print the failed layer,
  broker/scenario, command to reproduce, relevant artifact path and whether a
  failure may be environmental. Avoid requiring agents to inspect stale report
  directories or infer the real Maven test count.
- [ ] **TEST-11 — Add CI only after local commands are stable.** CI calls the same
  verification entry point, uploads browser screenshots/logs and blocks merges
  on the agreed scope. Local and CI behavior must not diverge.
- [ ] **TEST-12 — Standardise the handoff report.** Every implementation reports
  branches, changed behavior, exact verification commands and results, skipped
  checks with reasons, and whether anything was committed, pushed or deployed.

### Proposed verification levels

| Level | Purpose | Must be independent of |
|---|---|---|
| Unit | Calculations, parsing, mapping, UI helpers | Network, database, browser, current date |
| Contract | Canonical API and each broker's HTTP shapes | Live broker accounts |
| Integration | Postgres, migrations, sessions, simulator-backed adapters | Production services |
| Browser smoke | Critical user journeys and visible failure states | Real broker credentials |
| Live certification | Small, explicit comparison with a real broker | Normal local/CI runs |
| Production smoke | Deployment reachability and safe read-only checks | Destructive actions |

## Simulator packaging

**3 Oct 2026: SIM-07 and SIM-08 moved to `STAGING.md`** (ST-11 and ST-7 to ST-9).

`BROKER-EXPANSION-PLAN.md` SIM-01 to SIM-05 build the simulator. Not covered
there:

- [ ] **SIM-07 — Package for local development.** One documented command starts
  database, backend, frontend and selected broker profiles with seeded users.
- [ ] **SIM-08 — Package for staging.** Staging uses synthetic credentials and
  isolated simulator endpoints; it must be impossible to confuse a simulator
  with a real broker or route production traffic to it.
- [ ] **SIM-10 — Validate against real APIs carefully.** Where accounts are
  available, run a redacted comparison of documented and real response shapes.
  Store only the derived contract observations, not credentials or raw personal
  portfolio data.

## Landing page beyond launch

The launch copy rewrite and legal pages are `PUBLIC-LAUNCH.md` L7 and
`P0-LAUNCH.md` E1. These go further:

- [ ] **LAND-05 — Show honest broker support.** Present a capability matrix rather
  than a row of logos: positions, holdings, margins, option chain, setup cost,
  static-IP requirement and current support status. Cite only accepted, dated
  findings from `BROKER-EXPANSION-PLAN.md`.
- [ ] **LAND-06 — Add proof without exposing users.** Use synthetic screenshots
  or explicitly consented/redacted captures, explain calculation limitations,
  and link to a dated changelog or status page when those exist.
- [ ] **LAND-08 — Verify quality.** Test responsive layout, keyboard navigation,
  contrast, reduced motion, link integrity, metadata/social previews, page weight
  and signed-out access. Run short comprehension checks with people who have not
  seen the application.

Standing rule for all landing copy: do not say "bank-grade", "real-time",
"secure", "official partner", "all brokers" or quote uptime without a defined,
measured basis, and confirm trademark/logo permission before using broker marks.
