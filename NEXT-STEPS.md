# GoldenBook next steps — discussion draft

**Captured:** 21 September 2026
**Status:** Draft backlog for discussion; not yet an implementation commitment.
**Current release authority:** `P0-LAUNCH.md` remains the source of truth for
production-readiness work. Nothing in this draft marks a P0 item complete or
changes the read-only product constraint.

## Outcomes we want

1. Support the ten most-used relevant Indian retail brokers, subject to API,
   legal, security and operational feasibility.
2. Prefer brokers that let a user read positions and holdings without requiring
   the user's API application to be tied to a static IP.
3. Reproduce supported broker APIs with synthetic data in development and
   staging, so normal testing does not depend on live broker accounts.
4. Make the public landing page credible, transparent and useful to a new user.
5. Give an implementation agent one obvious, low-cognitive-cost way to select
   and run the right verification for any change.

## Important questions to settle in the next discussion

- **Settled for this roadmap:** ten brokers in total, including Zerodha/Kite,
  Alice Blue and Paytm Money.
- **Settled baseline:** NSE active clients, using the latest available snapshot.
  The dated ranking, provisional shortlist and fallback rule are recorded in
  [`research/BROKER-LAUNCH-SHORTLIST.md`](research/BROKER-LAUNCH-SHORTLIST.md).
- **Settled capability gate:** every new broker must support both positions and
  holdings. Other capabilities may be partial and must be labelled explicitly.
- **Settled static-IP gate:** mandatory IP entry during data-app activation or
  IP validation on positions/holdings disqualifies a new broker. Order-only IP
  enforcement does not. The executable roster and delivery phases are in
  [`BROKER-EXPANSION-PLAN.md`](BROKER-EXPANSION-PLAN.md).
- How much P0 production-readiness work must be completed before broker
  expansion begins? At minimum, stale risk data and unverified backups should
  not disappear behind expansion work.
- Should simulators run as one multi-broker service with isolated profiles, or
  as independently deployable services? A one-service prototype is the default
  to test before multiplying infrastructure.

## Workstream A — broker ranking and feasibility research

The examples currently discussed—Kite as a potentially read-only-friendly API,
and Alice Blue/Paytm Money as portals that request a static IP—are hypotheses to
verify, not conclusions to copy into product claims.

- [x] **BR-01 — Define the ranking rule.** Select an authoritative usage
  dataset, snapshot its date, document exclusions, and decide how ties or
  brokers without usable APIs are handled.
- [x] **BR-02 — Produce the top-ten candidate list.** Show whether the three
  existing integrations fall inside or outside the selected ten. Keep a reserve
  list so an unusable candidate can be replaced without changing the method.
- [ ] **BR-03 — Create one evidence dossier per broker.** Use current primary
  broker documentation, the broker's developer portal, published terms and, if
  needed, a written response from broker support. Date every finding.
- [ ] **BR-04 — Verify positions and holdings capabilities.** Record endpoint,
  segments covered, intraday/delivery treatment, pagination, freshness, realised
  and unrealised P&L fields, instrument identifiers and known data gaps.
- [ ] **BR-05 — Verify authentication and application registration.** Record
  app types, OAuth or login flow, redirect-URI constraints, token lifetime,
  refresh/re-login behavior, multi-account support, pricing and approval steps.
- [ ] **BR-06 — Separate the three static-IP questions.** For every broker,
  answer independently: is an IP mandatory to create the API app, is it checked
  on positions/holdings calls, and is it checked only on order calls? Record
  IPv4/IPv6, allowlist count and change process where relevant.
- [ ] **BR-07 — Verify permitted use.** Check whether read data may be displayed
  in GoldenBook, retained as snapshots, or combined with market data from another
  broker. Record restrictions on caching, redistribution, logos and naming.
- [ ] **BR-08 — Portal-check ambiguous claims.** Documentation alone is not
  enough when the actual developer portal imposes extra fields. Capture a
  redacted screenshot or dated observation without storing credentials.
- [ ] **BR-09 — Score and select.** Score usage, positions, holdings, static-IP
  friction, auth stability, documentation quality, sandbox availability, price,
  terms and maintenance risk. Mark each candidate `integrate`, `defer` or
  `reject`, with a short reason.
- [ ] **BR-10 — Publish the accepted capability matrix.** Product copy and
  implementation work may cite only accepted, dated findings.

### Research matrix to complete

| Field | Required evidence |
|---|---|
| Rank and usage | Metric, count/share, reporting month, primary source |
| Positions | Endpoint, supported segments, fields, pagination, freshness |
| Holdings | Endpoint, settled/unsettled/pledged treatment and fields |
| App creation | Required fields, price, approval, callback constraints |
| Static IP: registration | Required, optional or absent; portal evidence |
| Static IP: read-only calls | Enforced or not enforced for positions/holdings |
| Static IP: orders | Recorded separately; GoldenBook remains read-only |
| Authentication | Flow, token lifetime, refresh/re-login, multi-account model |
| Instruments | Contract master availability and identifier stability |
| Terms | Display, retention, cross-broker data, branding restrictions |
| Test support | Official sandbox, sample payloads, or documentation only |
| Confidence | Verified, documented-only, ambiguous, or support-confirmed |
| Last checked | Date, researcher and direct evidence links |

## Workstream B — broker integration foundation

- [ ] **ARCH-01 — Define explicit broker capabilities.** Model positions,
  holdings, margins, instruments, quotes and option chains independently. The UI
  must not assume every broker implements every capability.
- [ ] **ARCH-02 — Review the registration/account/session model for ten
  brokers.** Preserve the existing distinction between a developer app and an
  authorised account, including multiple accounts per registration.
- [ ] **ARCH-03 — Standardise adapter boundaries.** Keep vendor DTOs and SDKs
  inside each broker adapter; map into GoldenBook's canonical position, holding,
  margin and instrument contracts at the boundary.
- [ ] **ARCH-04 — Standardise failure semantics.** Define common behavior for
  expired sessions, partial responses, missing quotes, throttling, vendor
  outages, malformed data and unsupported capabilities.
- [ ] **ARCH-05 — Create a broker onboarding checklist/template.** Every new
  broker receives the same research file, fixture layout, adapter tests,
  simulator profile, configuration docs, UI capability labels and rollout gate.
- [ ] **ARCH-06 — Pilot before scaling.** Validate the template against the
  existing three integrations, then add one new broker. Do not implement the
  remaining candidates until the pilot exposes and resolves shared-contract
  gaps.
- [ ] **ARCH-07 — Deliver remaining brokers in small batches.** Suggested batch
  size is two or three, with a reviewed capability matrix and green verification
  gate after every batch.

### Definition of done for one broker

A broker is not “supported” until all applicable items are complete:

- The dated research dossier and static-IP findings have accepted evidence.
- Positions and holdings map correctly into canonical GoldenBook data, including
  missing/partial values and broker-specific quantity rules.
- Authentication, expiry, reconnect and account ownership are tested.
- Synthetic happy-path and failure fixtures exist and contain no user data or
  secrets.
- The simulator passes the same adapter contract tests used by the application.
- Dev and staging can run without a live broker account.
- The Settings and session UI expose only capabilities the broker actually has.
- Unit, contract, integration and browser smoke tests pass.
- Operational and user-facing documentation is updated without implying an
  official partnership.

## Workstream C — broker simulators for development and staging

The simulators should reproduce documented wire contracts, not broker business
systems. They must use synthetic portfolios and must never replay a user's live
payload without explicit sanitisation and review.

- [ ] **SIM-01 — Choose the simulator shape.** Prototype one multi-broker
  simulator application with isolated route/profile modules and the ability to
  deploy one profile per container if isolation is later needed. Compare a
  fixture-driven HTTP tool with a small stateful service for OAuth/session flows.
- [ ] **SIM-02 — Define fixture provenance.** Each request/response fixture names
  the documentation URL, documentation version or access date, transformation
  notes and the synthetic-data generator version.
- [ ] **SIM-03 — Define a common scenario catalogue.** At minimum: successful
  login, positions and holdings; empty portfolio; mixed equity/futures/options;
  partial or missing fields; expired and invalid token; permission failure;
  rate limit; server error; timeout; malformed response; duplicate rows; and
  pagination where the broker supports it.
- [ ] **SIM-04 — Make time and identity deterministic.** Inject the clock, stable
  user/account identifiers, instruments and prices. Tests must not drift at
  midnight, expiry or market open/close.
- [ ] **SIM-05 — Support stateful auth behavior.** Simulate redirect, token
  exchange, refresh or forced re-login, token expiry, reconnect, and isolation
  between two users and two accounts.
- [ ] **SIM-06 — Add contract drift checks.** Adapter contract tests run against
  both stored fixtures and the simulator. A documented broker schema change must
  produce a focused failure rather than silently turning values into zero.
- [ ] **SIM-07 — Package for local development.** One documented command starts
  database, backend, frontend and selected broker profiles with seeded users.
- [ ] **SIM-08 — Package for staging.** Staging uses synthetic credentials and
  isolated simulator endpoints; it must be impossible to confuse a simulator
  with a real broker or route production traffic to it.
- [ ] **SIM-09 — Add health and reset controls.** Provide readiness checks and a
  deterministic state reset for tests. Administrative scenario controls must not
  be exposed on the production network.
- [ ] **SIM-10 — Validate against real APIs carefully.** Where accounts are
  available, run a redacted comparison of documented and real response shapes.
  Store only the derived contract observations, not credentials or raw personal
  portfolio data.

## Workstream D — low-cognitive-cost testing for agents

The target experience is: read one page, run one command, receive a clear list of
what passed, failed or was skipped, and paste the same result into the handoff.

- [x] **TEST-01 — Create `TESTING.md` as the single entry point.** It should list
  prerequisites, supported scopes, expected duration, external dependencies,
  pass criteria and troubleshooting. Other docs link to it rather than copying
  commands.
- [x] **TEST-02 — Add a root verification command.** Implemented interface:
  `./scripts/verify.ps1 -Scope changed|fast|frontend|backend|broker|integration|ui|all`
  with `-Broker <id>` for broker work. It orchestrates the existing `npm test`,
  `npm run typecheck`, `npm run build` and Maven commands without hiding their
  real summaries.
- [x] **TEST-03 — Define `changed` deterministically.** Map changed paths to the
  minimum safe checks and print the mapping before running. Financial
  calculations, API contracts, authentication and migrations always expand to
  their required regression suites.
- [x] **TEST-04 — Keep a fast inner loop.** Unit and mapping tests should require
  no network, broker credentials, browser or wall-clock date. Reserve container
  and browser tests for explicit scopes.
- [ ] **TEST-05 — Standardise broker contract tests.** A shared abstract contract
  verifies positions, holdings, account isolation, missing values, error mapping
  and session expiry for every adapter. Broker-specific tests cover vendor quirks.
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
  empty, loading, error and expired-session states.
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

## Workstream E — public landing page and user confidence

- [ ] **LAND-01 — Define the audience and trust questions.** A visitor should
  quickly understand what GoldenBook does, who it is for, what data it reads,
  what it never does, what setup is required and where estimates may differ from
  a broker.
- [ ] **LAND-02 — Redesign the information hierarchy.** Proposed order: clear
  value statement; real product preview; how connecting works; supported broker
  capabilities; security/privacy facts; read-only and risk limitations; FAQ;
  support/grievance contact; sign-in action.
- [ ] **LAND-03 — Use precise confidence signals.** State that GoldenBook is
  read-only and places no orders, users provide their own broker API app, secrets
  are write-only in the UI and encrypted at rest, and the broker remains the
  source of truth. Cite privacy, terms and risk-disclosure pages once they exist.
- [ ] **LAND-04 — Avoid unsupported claims.** Do not say “bank-grade”, “real-time”,
  “secure”, “official partner”, “all brokers” or quote uptime unless there is a
  defined, measured basis. Confirm trademark/logo permission before using broker
  marks.
- [ ] **LAND-05 — Show honest broker support.** Present a capability matrix rather
  than a row of logos: positions, holdings, margins, option chain, setup cost,
  static-IP requirement and current support status.
- [ ] **LAND-06 — Add proof without exposing users.** Use synthetic screenshots
  or explicitly consented/redacted captures, explain calculation limitations,
  and link to a dated changelog or status page when those exist.
- [ ] **LAND-07 — Complete public trust pages.** Privacy notice, terms, risk
  disclosure, data-deletion route/process and monitored support/grievance contact
  are prerequisites for inviting non-family users.
- [ ] **LAND-08 — Verify quality.** Test responsive layout, keyboard navigation,
  contrast, reduced motion, link integrity, metadata/social previews, page weight
  and signed-out access. Run short comprehension checks with people who have not
  seen the application.

## Recommended execution order

1. **Confirm scope and priority:** settle the discussion questions and decide how
   this roadmap interleaves with `P0-LAUNCH.md`.
2. **Build the testing entry point and research template:** start TEST-01 through
   TEST-04 and BR-01 through BR-03 together. This lowers the cost of every later
   broker change.
3. **Complete and accept the top-ten matrix:** do not select by brand recognition
   or an undocumented portal observation.
4. **Prototype the integration template and simulator on existing brokers:** use
   the three known integrations to expose common-contract gaps cheaply.
5. **Integrate one new pilot broker end to end:** research, simulator, adapter,
   UI, browser test and staging soak.
6. **Review the pilot before batching:** revise architecture and test contracts,
   then add the remaining accepted brokers in groups of two or three.
7. **Develop landing-page structure in parallel, but publish capability claims
   only after evidence is accepted.** Finish legal/trust pages before expanding
   access.
8. **Run staging and production gates:** multi-user isolation, session expiry,
   failure states, observability, backups and rollback must be measured before a
   wider rollout.

## Suggested next discussion agenda

1. Ten total brokers or ten additional brokers.
2. Ranking metric and replacement rule.
3. Static-IP acceptance rule for read-only use.
4. Required versus optional broker capabilities.
5. P0 work that must precede expansion.
6. Simulator architecture and first pilot broker.
7. Landing-page audience, claims and visual direction.
8. Verification command names, runtime targets and CI expectations.
