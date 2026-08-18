---
name: aliceblue-option-chain-verified
description: "Alice Blue's option chain verified live 18 Aug 2026: per-strike ltp/oi, spotLTP, futLTP and lotsize for 181 underlyings, free — Step 8's market-data blocker is answered"
metadata:
  type: state
---

**Verified against a live `userSession` on 18 Aug 2026.** All three
`/obrest/optionChain/*` calls answered HTTP 200 with real data. This closes the
question [[free-market-data-options-researched]] left open and that CLAUDE.md
carried for weeks as "the real prize, still unclaimed". Full payload shapes,
field names and the live sample are in `tradestack/docs/aliceblue-api.md`; only
what a future reader cannot re-derive is here.

**It returns more than was hoped for.** Per strike, `CE` and `PE` each with
`ltp`, `oi`, `pdc`, `pdoi`, `token`, `tradingsymbol` — and on the wrapper,
`spotLTP`, `futLTP`, `lotsize`, `ticksize` and `pcr`. 181 underlyings, real
per-underlying expiry ladders, at no cost beyond the account. **Upstox is no
longer needed as the fallback**, which saves a fourth OAuth integration — but
Upstox remains the only located source of *greeks*, so
[[free-market-data-options-researched]] is still live for that.

**Do not derive spot by put-call parity.** The docs proposed it and it is
subtly wrong: parity recovers the **forward** price, not spot. Measured on
NIFTY 25AUG26 at the 24200 strike, parity gave 24232.30 against a `futLTP` of
24242.00 and a `spotLTP` of 24199.35 — within 10 points of the future, 33 from
spot, the gap being the cost of carry. The error would have been small,
plausible and one-directional, which is the worst possible shape for an input to
a margin estimate. `spotLTP` is in the payload; use it.

**How it was verified matters, and is the reusable part.** The probe ran as a
temporary debug endpoint inside the app
(`broker/aliceblue/AliceBlueOptionChain` + `AliceBlueDebugController`), reading
the session already in `ConnectionService` — *not* by extracting the token to a
file and curling it. The token never left the JVM. Prefer this shape for any
future vendor probe: it is safer, it needs no secret handling, and the class is
the one the real feature will grow from. It deliberately does **not** implement
`BrokerGateway` — partly so a controller may touch it under rule A4, partly
because option chains belong in `marketdata/` behind a canonical-underlying
interface when they graduate, beside `SpotPriceProvider`.

**Report evidence, not parsed results.** The probe returns each call's real HTTP
status, real top-level keys and a verbatim body slice *beside* its
interpretation. That is what caught three of my own parser bugs and two vendor
facts in one round trip, without a redeploy per guess. Vendor docs were wrong
about three things here — `interval` is the strike count either side of the
money and not the strike step, the strikes are nested a level deeper than
`result`, and the spot is present — which is the same lesson Paytm's `pref`
encoding and Kite's SDK field names already taught.

**Open, and blocking a decision rather than the code:** whether Alice Blue's
licence permits using their feed to price *another broker's* positions. That is
a real question for a multi-broker app and should be settled before this becomes
load-bearing. See [[real-product-not-personal-tool]] — the personal-use carve-out
is not ours.
