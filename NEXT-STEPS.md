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

### 2. Documentation in a clean tool (6 Oct 2026)

> "we have to add documentation on business logics, technical flows, architecture, and
> plan for new items in some clean tool, like jira, confluence or notion, suggest something."

**Not decided; the assistant's recommendation is below and awaits the owner's choice.** The
substance already exists and is current, in git: `CLAUDE.md` (code truth), `SPEC.md`, the ADRs
in `tradestack/docs/adr/`, `memory/` (the reasoning), the per-broker dossiers, the trackers
(`PUBLIC-LAUNCH.md`, `BROKER-EXPANSION-PLAN.md`, `STAGING.md`, `OBSERVABILITY.md`,
`RELEASE-ADAPTERS-PLAN.md`) and the runbook (`tradestack/deploy/README.md`). The gap is
discoverability and presentation for a reader who is not an agent, plus diagrams, not content.

**Recommended:** keep git as the source of truth (docs-as-code) and add a readable layer on
top: a navigable site built from the same Markdown, Mermaid diagrams for the flows and the
architecture, and GitHub Projects (issues linked to PRs) for the plan and backlog. Notion
is the fallback if the owner wants a polished UI more than a single source of truth. Jira
and Confluence are not recommended at this size. The reasoning and the proposed structure
are in the 6 Oct 2026 conversation; carry them into the tracker that takes this on.

### 3. A marketing, distribution, social media and SEO pipeline and strategy (6 Oct 2026)

> "we have to setup pipeline and strategy for marketing, distributing, social media and
> seo items."

**Nothing exists yet beyond landing-page copy.** Constraints already on record, which any
strategy has to start from (the assistant's mapping, not the owner's words):

- **SEO is architecturally limited today.** `frontend/docs/adr/0023-static-spa-no-ssr.md`
  records "no meaningful SEO for the landing page" and accepts it because the product was
  invite-only. Sign-up has been open since 3 Oct, so that ADR needs revisiting. The landing
  page is client-rendered, so crawlers see little. Options to weigh: prerender the landing
  and legal pages at build time, or a separate marketing site (`REBRAND-GOLDENBOOK.md` already
  routes `/`, `/privacy` and `/terms` so a marketing site could replace the landing page).
  Still open from the rebrand: `og:image`, and a rendered check of the social previews.
- **No analytics today, by promise.** The privacy policy says exactly two cookies (session
  and XSRF) and no analytics (`PUBLIC-LAUNCH.md` L7, `OBSERVABILITY.md`: "no analytics script
  and no tracking cookie"). Measuring marketing needs a decision: cookieless and
  self-hosted analytics (for example Plausible or Umami) keeps the promise; Google Analytics
  or an ad pixel would not, and would need the policy and the cookie statement rewritten.
- **Landing copy has standing rules** (`NEXT-STEPS.md`, "Landing page beyond launch"): no
  "bank-grade", "real-time", "secure", "official partner", "all brokers" or an uptime claim
  without a measured basis, and no broker logo without permission. LAND-05 (honest broker
  support), LAND-06 (proof without exposing users) and LAND-08 (quality and social
  previews) are the existing items.
- **Regulatory.** GoldenBook is a read-only viewer. Anything that reads as a recommendation
  may fall under SEBI research-analyst or investment-adviser rules (`research/REGULATORY-API-STATIC-IP.md`,
  "confirm before Step 8"), and SEBI's rules on promotions and on finfluencers apply to
  social media content about F&O. A compliance checklist for every post and page belongs in
  the pipeline. Not legal advice; confirm with a professional before paid promotion.
- **Brokers are both the product and the audience's identity.** Naming Zerodha, Upstox or
  Dhan in marketing touches their trademark and each API's terms (`research/BROKER-API-TERMS-MULTI-USER.md`).
  Broker outreach is deferred to the 17-24 Oct review.

**Pieces a pipeline would need** (to design, in the owner's order of priority): who it is for
(retail F&O traders running more than one broker) and the one-line promise; the channels and
a realistic weekly cadence for one person; a content backlog and calendar kept in the same
tool as the rest of the plan (see item 2); the SEO technical work above plus a keyword and
content plan; a measurement set that respects the privacy promise (sign-ups, connects per
broker, activation); a budget; and the compliance checklist.

**To settle first:** the audience and budget; whether the owner posts under a personal
handle or a product one; whether any paid promotion is in scope (the compliance bar is
higher); and the analytics decision above.

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
