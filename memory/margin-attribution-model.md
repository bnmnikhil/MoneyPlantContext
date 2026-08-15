---
name: margin-attribution-model
description: "Per-instrument margin is an allocation of the broker's real bill, split by each leg's worst loss across the scenario markers; margin is non-additive so the convention must always be stated"
metadata:
  type: decision
---

Decided 15 Aug 2026, building margin at instrument level.

**Margin is non-additive — the same trap as `maxLoss`, one level up.** A hedged
book consumes far less than its legs separately, so there is no single true
per-contract number. Standalone sums to *more* than the real bill, marginal
(leave-one-out) to *less*, allocated to *exactly* it. **Whichever is shown, the
convention has to be on screen.**

**We allocate**, so the column foots to what the broker actually charges — the
one property a reader can check. That makes it the deliberate mirror image of
the `maxLoss` column beside it, which is standalone and does *not* add up. See
[[per-instrument-risk-model]].

**The split key is each contract's worst loss across the ladder's scenarios**,
and it is not arbitrary: SPAN — the dominant component of Indian F&O margin — is
*defined* as the worst loss over a scenario array, so this is structurally the
same idea as the calculation that produced the bill.

**Measured per leg at its own worst scenario, never at one shared worst spot.**
The shared-spot version was written first and a strangle test killed it
immediately: only one side of a strangle loses at any single point, so the other
took nothing while the exchange charges for both. Per-leg also handles hedges
without a special case — a long option's worst outcome is losing the premium it
paid, so it takes a small share and the short takes the rest.

**Known bias, deliberately visible:** only dated F&O with a spot takes part, so
an account also holding margin-consuming equity over-allocates to its options.
Everything else reports `UNAVAILABLE`, never zero — zero is a claim.

**What each broker can actually do** (verified against `raw_capture`, 11 Aug):

| | account `used` | span/exposure split | basket calculator |
|---|---|---|---|
| Kite | yes | yes, sums exactly to `debits` | yes — `getCombinedMarginCalculation`, in the SDK, was unused |
| Alice Blue | yes | yes, sums exactly to `utilizedMargin` | nothing documented |
| Paytm | yes | none | `POST /margin/v1/scrips/calculator`, shape unverified |

**Kite's basket call is built but not wired, and there is no schema for it yet.**
Both deferred until one live call is observed, because the response shape is
unverified and a migration built for it now would likely need a second to
correct — migrations here are append-only, which is why V6 exists. The gateway
logs `initial/final/benefit` on every call so the first connected session
verifies it at a glance. **`considerPositions` is `false`**: the flag means
"margin for these *new* orders given my *existing* positions", and these legs
*are* the existing positions — `true` would price the book twice. That reading
is itself unverified.

`initial − final` is the hedge benefit as the exchange scores it, and no broker
surfaces it in its UI. That is the reason the basket call is worth making at all.

**`margin_snapshot` is written only by migrating `raw_capture`**, never by a
live fallback — see [[snapshot-writers-migrate-the-archive]].
