---
name: an-unmeasured-zero-is-a-claim
description: "A figure nobody could measure must not render as 0 — PositionDto.priceKnown, like MarginBasis.UNAVAILABLE, makes the difference visible to the UI"
metadata:
  type: decision
---

Generalised 20 Aug 2026, on `feat/position-contract-facts`, from a rule that
already existed for margin.

**The rule.** A zero is an assertion about the world. When the stack could not
obtain a number, it must say *unknown*, and every consumer must render that
differently from a measured zero. **A consumer that cannot tell the two apart
will render the claim** — silently, and with full confidence.

**Where it bit.** Paytm's positions endpoint never populates
`last_traded_price`, so its marks come from a separate market-data call that can
come back empty. `PaytmMapper` already guarded *P&L* against this by reporting
realised-only rather than inventing the unrealised half — but the **mark itself
had no guard**, so an unquoted row arrived as `ltp = 0` and everything derived
from it read as a confident zero: market value, and premium left
([[premium-left-is-negated-market-value]]) showing ₹0 on a leg that may be worth
a great deal.

**The fix is a field, not a sentinel.** `PositionDto.priceKnown`, and it is
**required on the gateway constructor rather than defaulted** — a default would
let a mapper silently claim a price it never received. Kite and Alice Blue quote
the position in the same payload as the position, so there is no separate call
that can fail and both pass `true`; **only Paytm can emit `false`**.

**The precedent is `MarginBasis.UNAVAILABLE`** from
[[margin-attribution-model]], which draws the same distinction for a margin
figure nothing could estimate. This is that idea named.

**Rendering it: a leaf dashes, a subtotal marks itself.** A single leg shows an
em dash. A *subtotal* must not — one unquoted leg among five would hide four
real ones behind a dash. It carries `unpricedLegs` and appends `?` to the known
amount. Corrected 6 Sep 2026: option premium is signed, so missing longs subtract
and missing shorts add; a partial premium total is not a floor. When no options
can be valued, the subtotal also dashes. Unresolved instrument types count as
unknown, but known futures and equity are excluded from option premium entirely.

**When it must be derived, derive it cautiously.** `TypedSnapshotRepository`
cannot distinguish a stored mark of zero from a mark never obtained, so it
reports `ltp > 0`. That errs towards a dash where the truth might have been a
genuine zero — **the harmless direction**; the other one prints a number nobody
measured.

**Where the rule is currently unenforceable.** `realisedPnl` from the snapshot
path is 0 with no way to say so, because the table has no column. Anything that
starts reading it there must add the column rather than trust the value.
