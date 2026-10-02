---
name: option-chain-symbol-resolution
description: "Option-chain adapters resolve canonical codes to exact broker catalogue references; M&M remains MM internally"
metadata:
  type: decision
  decided: 2026-10-01
---

**Decision.** Keep the current canonical identity scheme and repair outbound
translation inside the broker adapter. Alice Blue's `getUnderlying` catalogue
owns its exact request names; `UnderlyingRegistry` owns domain identity. The
adapter indexes vendor names by canonical code and requires a typed broker
reference to build both expiry and chain requests. Responses stay canonical.

**Why.** Live diagnostics found M&M correctly in search (`MM`) and the contract
master (100 October contracts, lot size 200). The same Alice Blue session
rejected `MM` and accepted `M&M`: three expiries and 20 chain rows. Expiry loading
failed first, so the builder never enabled its chain query. URL encoding and
contract parsing were not the cause. The missing operation was canonical ->
broker reference, not broker -> canonical.

**Alternative considered.** `M&M` is a valid possible canonical identity; there
is no requirement to strip punctuation. Adopting official exchange symbols
throughout the application would require a coordinated identity-model change,
not an isolated frontend adjustment. It would still not eliminate broker
translation for differently named indices or numeric references. That broader
change is deferred; no instrument identities or frontend API contracts change
in this fix.

**Safeguards.** Missing and ambiguous mappings fail explicitly, without guessing
or choosing the first row. Catalogue data is shared per vendor exchange, loaded
under a per-exchange lock, and refreshed lazily daily in IST. A warm miss may
refresh once per 60 seconds; a cold load already checked the catalogue. Transient
failures have the same backoff. Session failures are never negative cached
across users, and no session/token/quote is stored in the catalogue cache.

**Coverage.** Exact outbound bodies for punctuation-bearing stocks and index
aliases, canonical snapshots and strategy-service contract/lot lookup, unknown
and ambiguous names, malformed catalogues, duplicate rows, daily rollover,
refresh/backoff, concurrent downloads and caller-specific authentication.

See `tradestack/docs/symbol-model.md` and `tradestack/docs/aliceblue-api.md` for
the boundary contract and payload details. An intraday rename of an already
resolved symbol is picked up by the next daily refresh; catalogue-based mapping
does not make live broker availability infallible.
