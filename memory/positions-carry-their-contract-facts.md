---
name: positions-carry-their-contract-facts
description: "PositionDto carries strike, expiry and lot size as one nullable Contract object, filled from the lookup resolveInstrument was already doing"
metadata:
  type: decision
---

Decided 20 Aug 2026, on `feat/position-contract-facts`, as groundwork for the
intrinsic/extrinsic premium split and for feeding the real option chain into the
strategy builder ([[aliceblue-option-chain-verified]]).

**`PositionDto.Contract(double strike, LocalDate expiry, int lotSize)`, nullable.**

**Why it travels at all.** Anything reasoning about a position as a *structure*
rather than as a mark needs these three: splitting a premium into intrinsic and
extrinsic needs the strike, pricing time value needs the expiry, and locating a
group on its own payoff curve needs the strike of every leg. **None of it can be
derived downstream.** The only other route is parsing the vendor symbol, which
[[app-owns-its-symbols]] refuses on exactly the grounds that the contract master
exists to make it unnecessary — and which would put that parsing in the browser.

**It costs no extra lookup.** `BrokerService.resolveInstrument` has always called
`InstrumentService.find` on every row to fill in the underlying and the option
right, received a whole `OptionInstrument`, and kept two fields of it. This
carries the rest of what it already had. That is the whole reason this was cheap
enough to do speculatively: **nothing reads `contract` yet.**

**One nullable object, not three nullable fields**, so a consumer asks "did the
contract master resolve this row?" once. Same both-or-neither discipline as
`underlying`/`underlyingLabel`, and for the same reason — three independently
null fields invite a consumer to check one and assume the others.

**`strike` is 0 for futures and equity and `expiry` is null for equity**, copied
straight off `InstrumentKey` rather than inventing a second convention.

**What the snapshot path cannot do.** `position_snapshot` has no column for any
of the three, so `TypedSnapshotRepository` reads them back as null. Rows from
there are re-resolved through the contract master by `SnapshotPositionSource`,
which is where risk gets its key from — so the snapshot path is not blocked, but
it does mean **the table is not the source of truth for contract facts** and a
consumer wanting them from a snapshot must add the columns.

See also [[an-unmeasured-zero-is-a-claim]], the other half of the same commit.
