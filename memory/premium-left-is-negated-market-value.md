---
name: premium-left-is-negated-market-value
description: "Premium left on the positions table is -(qty x LTP) computed from LIVE positions, not the risk report, and it is additive at every level unlike margin"
metadata:
  type: decision
---

Decided 15 Aug 2026, adding a Premium column to `/app/positions` alongside the
margin column from [[positions-margin-comes-from-risk]].

**"Premium left" is `-(qty x ltp)`, summed.** Positive is a net credit — what you
keep if every leg expires worthless; negative is a net debit. `qty` is signed and
**already includes the lot** (a two-lot short of a 75-lot contract arrives as
-150), so there is no lot size to multiply by and doing so would overstate every
figure by that lot size. The column shows it beside the same figure at entry
(`-(qty x avgPrice)`); the gap between the two is exactly the lifetime P&L, in
the direction **entry - left**, because a credit decaying towards zero is the
profit. Verified live: Alice Blue `24,360 - 62,928 = -38,568`, matching its P&L
cell to the rupee.

**It is computed from the live `/api/positions` rows, not from the risk report,**
even though the risk report carries `marketValue` which is the same quantity
negated. Measured 15 Aug: the risk snapshot's LTPs differ from live on **all 31
rows** (`HDFCBANK25AUG26P730` live 11.35, snapshot 12.40), because
`position_snapshot` is frozen at 11 Aug. A subtotal sourced from there would not
equal `qty x LTP` of the rows printed directly beneath it — arithmetic the reader
can check in their head and will. Margin can survive being stale because it is an
allocation with a caption; premium cannot, because it is visibly derivable.

**Premium is additive at every level; margin is not.** This is the reason the two
adjacent columns behave differently and it should stay commented in the code:
premium appears on the leg rows, where margin is deliberately blank, because it
is plain arithmetic on the row itself rather than a share of a bill. The one
place premium is *not* split is CE/PE margin — the allocation divides a bill per
contract, and re-splitting it by right would be inventing a number.

**Never colour premium with `pnlColor`.** A net debit is not a loss. Live proof
from the same page: HEROMOTOCO's long C6200 shows premium `-3,180` in neutral
while its P&L cell is red for a different reason, and a group can carry a
negative premium while being in profit.

**CE/PE comes from a new `PositionDto.instrumentType`, not from parsing symbols
in the browser.** One nullable `InstrumentType`, stamped in
`BrokerService.resolveInstrument` from the contract master lookup that was
already happening. Deliberately not the whole `InstrumentKey`: the key carries
its own, differently-normalised spelling of the underlying, and reconciling the
two is [[app-owns-its-symbols]] Step 3, a bigger job than this column needed.
A null right gets its own `OTHER` bucket — never folded into CE, which would make
a subtotal quietly wrong instead of visibly incomplete.

That change also required dropping the early return in `resolveInstrument`: it
used to skip the lookup entirely when a gateway had already set an underlying,
which is how Paytm keeps its own, and would have left every Paytm row untyped.
Underlying and type now obey separate rules in the same method.
