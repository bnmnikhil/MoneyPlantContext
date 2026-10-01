# Read-only broker expansion plan

**Created:** 21 September 2026
**Status:** In progress — capability foundation and verification entry point are complete; simulator is next.
**Research basis:**
[`research/BROKER-LAUNCH-SHORTLIST.md`](research/BROKER-LAUNCH-SHORTLIST.md)
**Release authority:** `P0-LAUNCH.md` remains the production-readiness gate.

## Goal

Grow MoneyPlant from three broker integrations to ten while keeping it strictly
read-only. Every **new** broker must let a user activate a data-only integration
and fetch both positions and holdings without supplying or routing through a
static IP.

The existing Alice Blue and Paytm Money integrations are not removed by this
rule. They predate it and currently have static-IP onboarding friction. The rule
governs which brokers MoneyPlant adds next.

## Hard eligibility gate

A new broker is eligible only when all of these are evidenced:

1. A user can create and activate the relevant data-only app or API key without
   entering a static IP.
2. Login, token exchange and renewal do not require requests from a whitelisted
   IP.
3. Both positions and holdings work from a normal changing source IP.
4. Static-IP enforcement, if present, is limited to order placement, modification
   and cancellation endpoints that MoneyPlant does not call.
5. The broker permits the applicable hosted use model. If a retail key is only
   for the account owner's personal scripts, MoneyPlant has the required partner
   approval before integration work starts.
6. The evidence comes from current broker documentation plus a portal observation,
   support confirmation or a controlled real-account test. Marketing pages alone
   are insufficient.

Do not work around a failed gate with a fake IP, shared proxy or one MoneyPlant IP
registered against multiple users. Mark that broker `deferred` and evaluate the
next candidate instead.

## Expansion roster

The planned path to ten brokers is the current three plus seven candidates. Four
have sufficiently clear public evidence to enter planning; three require the
gate to be completed before implementation.

| Order | Broker | NSE rank | Planning state | Reason / remaining gate |
|---:|---|---:|---|---|
| 1 | Upstox | 5 | First pilot | Standard OAuth holdings and positions are explicitly outside static-IP restrictions |
| 2 | Kotak Neo | 6 | Planned | Portfolio, report and login APIs are explicitly outside IP validation; IP is added separately for orders |
| 3 | Dhan | 8 | Planned after partner check | Documentation limits IP validation to order APIs; confirm MoneyPlant's hosted multi-user onboarding model |
| 4 | FYERS | 21 | Planned | FYERS explicitly leaves apps in data-only mode for positions and holdings without trading activation |
| 5 | Groww | 1 | Certification required | Documentation scopes IP to orders but does not explicitly guarantee no-IP portfolio access and activation |
| 6 | Motilal Oswal | 10 | Certification required | Documentation has both endpoints and scopes IP language to orders; portal behavior needs proof |
| 7 | 5paisa | 16 | Certification required | Non-order APIs are documented as exempt, but current dashboard guidance asks users to submit IP against the key |

If Groww, Motilal Oswal or 5paisa fails the hard gate, do not lower the rule merely
to reach ten. Select the next broker by the current NSE active-client ranking that
has a public positions-and-holdings API, then repeat the same gate.

### Deliberately not in this implementation queue

- **Angel One:** non-order calls may be exempt, but the current Add App flow asks
  for a static IP.
- **ICICI Direct:** documentation describes the IP as registered while procuring
  the API key.
- **HDFC Securities / HDFC Sky:** the app remains deactivated until an IP is
  mapped.
- **SBI Securities:** no current public self-service retail portfolio API and
  developer reference was found.

Keep their research records, but create no adapters until the documented or
observed onboarding behavior changes.

## Current architecture constraints

The existing three integrations establish useful boundaries, but three parts will
not scale cleanly to seven more brokers:

- `BrokerGateway` requires positions, holdings, margins and instruments from every
  broker. New read-only portfolio support must not invent margins or contract
  masters when a broker does not supply them.
- `BrokerCredentials` and `broker_credential` assume every broker needs exactly an
  API key and API secret. The new brokers use different names and may require
  additional identifiers.
- The frontend hardcodes `kite`, `aliceblue` and `paytm` in credential labels,
  links, badges, warnings and error handling.

The foundation phase removes these assumptions before the second new adapter is
added. The Upstox pilot proves the design before it is repeated.

## Phase 0 — certify candidates before coding

- [ ] **CERT-01 — Create one dated dossier per candidate.** Record positions and
  holdings endpoints, auth flow, token lifetime, rate limits, pricing, callback
  rules, supported segments and documentation versions.
- [ ] **CERT-02 — Observe app creation.** Create a data-only app without entering
  an IP and capture a redacted screenshot or dated notes. Never store credentials.
- [ ] **CERT-03 — Test from changing IPs.** Fetch empty and non-empty positions
  and holdings from two unregistered egress IPs. Record status and response shape,
  not personal portfolio data.
- [ ] **CERT-04 — Confirm hosted use.** Obtain written confirmation or applicable
  partner terms for MoneyPlant's multi-user model.
- [ ] **CERT-05 — Decide the candidate.** Mark `eligible`, `deferred` or `rejected`
  with evidence. Only `eligible` brokers enter an implementation branch.
- [ ] **CERT-06 — Freeze contract samples.** Derive sanitized synthetic examples
  for success, empty portfolio, expired token, permission failure, rate limit and
  vendor error cases.

Run certification for Groww, Dhan, Motilal Oswal and 5paisa early. Upstox, Kotak
Neo and FYERS still receive portal checks—the clear public documentation reduces
risk but does not replace a real setup observation.

## Phase 1 — make broker support capability-driven

- [x] **FOUND-01 — Add a broker catalogue.** Define one backend-owned
  `BrokerDefinition` per broker with display name, developer-console URL,
  credential fields, auth type, capabilities and availability state. Expose it to
  the frontend so broker IDs and labels are not copied across components.
- [x] **FOUND-02 — Split required and optional capabilities.** Make positions and
  holdings the required portfolio contract. Model margins, instruments, quotes,
  option chains and basket margins as independent optional providers. Unsupported
  must be explicit; it must never become an empty list or zero by accident.
- [ ] **FOUND-03 — Generalise credential fields safely.** Replace the fixed
  key/secret UI assumption with definition-driven fields. Keep identifiers in
  cleartext only when required for login; encrypt every secret value; keep all
  secrets write-only in API responses and logs.
- [ ] **FOUND-04 — Preserve stateless adapters.** Every gateway and auth provider
  continues to receive the user's session or credentials per call. No broker SDK,
  token or client instance may become shared mutable state.
- [ ] **FOUND-05 — Standardise session outcomes.** Use common errors for expired
  login, permission denied, throttling, vendor outage and malformed data while
  preserving the broker's safe diagnostic code.
- [ ] **FOUND-06 — Add broker rollout states.** Support `hidden`, `internal`,
  `staging` and `available` so an unfinished adapter cannot appear in production
  merely because its Spring bean exists.
- [ ] **FOUND-07 — Pin canonical mapping rules.** Document quantity, average
  price, realised/unrealised P&L, product, exchange, instrument type, settled/T1
  and pledged-quantity behavior. Missing vendor facts remain missing rather than
  becoming zero.

### Foundation acceptance criteria

- Existing Kite, Alice Blue and Paytm behavior remains unchanged.
- The UI renders broker setup from catalogue data rather than broker-specific
  conditionals.
- A portfolio-only fake broker can supply positions and holdings while clearly
  reporting margins and instruments as unsupported.
- Two users with different registrations and two accounts under one registration
  remain isolated.
- Architecture, credential and session regression tests pass.

## Phase 2 — build the broker simulator and test entry point

- [ ] **SIM-01 — Create one development-only simulator service.** Use isolated
  profiles per broker and documented paths, status codes, headers and JSON shapes.
  It may run as one process locally but each profile must be independently
  selectable in tests and staging.
- [ ] **SIM-02 — Record fixture provenance.** Every synthetic fixture names the
  broker documentation URL, access date and transformation notes. No live user
  payload or secret may enter the repository.
- [ ] **SIM-03 — Implement deterministic auth.** Simulate redirects, code/token
  exchange, daily expiry, invalid state and forced re-login with an injected clock.
- [ ] **SIM-04 — Implement common portfolio scenarios.** At minimum: empty,
  equity-only, mixed futures/options, T1 and pledged holdings, partial/missing
  fields, pagination, expired token, 403, 429, 500, timeout and malformed JSON.
- [ ] **SIM-05 — Add reset and health endpoints.** Tests must select a scenario and
  reset it without sharing state across users. Administrative controls must be
  impossible to enable in production.
- [x] **TEST-01 — Add one verification command.** Target interface:
  `./scripts/verify.ps1 -Scope broker -Broker <id>`. It prints prerequisites,
  chosen checks, pass/fail/skip summaries and exact reproduction commands.
- [ ] **TEST-02 — Create a shared broker contract suite.** Run identical positions,
  holdings, account-isolation, missing-data and error-mapping assertions against
  every adapter and its simulator profile.

## Phase 3 — Upstox pilot

- [ ] **UPSTOX-01 — Accept the completed eligibility dossier.** Use standard OAuth;
  do not use the one-year Analytics Token because its portfolio access has a
  different static-IP rule.
- [ ] **UPSTOX-02 — Add synthetic simulator fixtures** for authentication,
  positions and holdings before writing the production HTTP adapter.
- [ ] **UPSTOX-03 — Implement auth and session handling** through
  `BrokerAuthProvider`, including state validation and expiry.
- [ ] **UPSTOX-04 — Implement the portfolio adapter** and map vendor responses into
  canonical DTOs without leaking vendor types outside `broker/upstox`.
- [ ] **UPSTOX-05 — Add catalogue and Settings UI metadata** with honest capability
  labels and setup instructions.
- [ ] **UPSTOX-06 — Run unit, shared contract, Postgres integration and browser
  smoke tests** entirely against synthetic data.
- [ ] **UPSTOX-07 — Perform a controlled live certification** from a non-whitelisted
  IP, compare response shape with fixtures, then discard credentials and personal
  response data.
- [ ] **UPSTOX-08 — Soak in staging** through token expiry, reconnect, empty
  portfolio and vendor-error scenarios before enabling production availability.

Review the pilot before copying it. Amend the common contracts, simulator and
onboarding template wherever Upstox exposed a shared assumption.

## Phase 4 — add the remaining eligible brokers one at a time

Use the same vertical slice for each broker: accepted dossier → simulator → auth
→ adapter → catalogue/UI → automated verification → live certification → staging
soak → production flag.

1. **Kotak Neo** — highest-confidence second adapter and a check that the pilot
   did not accidentally encode Upstox OAuth details.
2. **Dhan** — only after the partner/use-model gate passes.
3. **FYERS** — exercise its explicit data-only app mode and daily authentication.
4. **Groww** — only after no-IP activation and portfolio calls are observed.
5. **Motilal Oswal** — only after portal and hosted-use confirmation.
6. **5paisa** — last because current dashboard guidance is the most ambiguous.

Do not develop two new adapters concurrently until the Upstox review is complete.
After the common contract is stable, batches of two are acceptable, but each
broker retains an independent rollout flag and acceptance report.

## Definition of done for one broker

- The broker has passed every hard eligibility gate with dated evidence.
- Both empty and non-empty positions and holdings map correctly, including
  intraday/carry-forward positions and settled/T1/pledged quantities where the
  broker exposes them.
- Login, expiry, reconnect and multiple-account ownership are tested.
- The simulator matches the documented wire contract and contains only synthetic
  data.
- Unit, shared contract, integration and browser smoke checks pass through the
  single verification command.
- Dev and staging need no live broker account.
- A controlled live comparison was performed from an unregistered dynamic IP.
- Settings and status UI show only verified capabilities and setup requirements.
- Documentation, support notes and the landing-page capability matrix are dated.
- The broker remains disabled in production until its staging soak and explicit
  rollout decision are recorded.

## Required verification layers

| Layer | Required assertion | External dependency |
|---|---|---|
| Unit | Mapping, quantities, P&L and error translation | None |
| Contract | Documented request/response shapes for every scenario | Simulator only |
| Integration | Credential encryption, Postgres sessions, user/account isolation | Local Postgres + simulator |
| Browser smoke | Save credentials, connect, reconnect, positions, holdings and visible errors | Local stack + simulator |
| Live certification | Auth and both portfolio endpoints from an unregistered IP | Explicit test account only |
| Staging soak | Expiry, reconnect, timeout, rate limit and vendor outage behavior | Staging simulator; brief controlled live check |

The normal local and CI paths must never require broker credentials, a static IP
or internet access.

## Production sequencing

1. Complete the applicable `P0-LAUNCH.md` safety work before exposing new brokers
   to users.
2. Release the capability-driven foundation with existing brokers only.
3. Release the simulator and verification entry point without production routes.
4. Enable Upstox internally, then in staging, then for a small production cohort.
5. Review metrics and support findings before enabling the next broker.
6. Repeat one broker at a time until the eligible roster reaches ten total.

At every stage, MoneyPlant remains read-only. Order endpoints, order scopes and
static-IP workarounds are explicitly outside this plan.
