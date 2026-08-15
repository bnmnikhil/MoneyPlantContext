---
name: positions-margin-comes-from-risk
description: "The positions table's margin column reads /api/risk/summary for BOTH the per-underlying subtotal and the account total, never /api/margins, so the column foots"
metadata:
  type: decision
---

Decided 15 Aug 2026, adding a per-underlying margin column to `/app/positions`.

**Both numbers come from `/api/risk/summary` — the group subtotals from
`instruments[].marginUsed`, the account total from `margin.accounts[].used`.**
The obvious alternative was to take the account total from the live
`/api/margins` (which the page could get from the existing `useMargins`) and
only the split from risk. That is wrong: the allocated shares are fractions of
the *snapshot's* `used`, so pairing them with a live account total gives a broker
row that does not equal its own children — destroying the single property that
justifies allocating at all. See [[margin-attribution-model]].

**Summing allocated margin per underlying is legitimate, and this is the only
aggregation of margin that is.** Margin is non-additive, so standalone
per-contract figures over-sum. But every figure here is a share of one account's
bill, so adding a group's legs back together is exact arithmetic on fractions of
a known total, not a second heuristic on the first.

**The cost, accepted and disclosed:** the column carries *three* ages — live
rows, the margin bill, and the positions the bill was split across — and the
caption must name the split's age, not the bill's. Measured live 15 Aug 2026:
`margin.asOf` was hours old (SNAPSHOT) while `report.asOf` was four days old
(STALE, 11 Aug), so a caption naming only the bill read as fresh while the split
was stale. The weaker link is named first. One caption under the table, fired
when *either* freshness is not LIVE; never a badge per row. See
[[snapshot-writers-migrate-the-archive]].

**Margin is shown at the underlying subtotal only, never per leg.** The
allocation is least trustworthy at the leg, and an empty leg cell keeps the eye
on the number worth reading. A group whose legs are partly unattributable shows
the sum as a floor with a marker, never a confident total and never `₹0` — the
same "zero is a claim" rule as `MarginBasis.UNAVAILABLE`.

The rendering lives in one shared `components/MarginFigure.tsx` used by both the
positions and risk tables, so the two pages cannot describe the same allocation
differently.

**No sticky column header on any shadcn `Table`.** It was built, and it broke:
`Table` wraps the `<table>` in `<div class="relative w-full overflow-auto">`, and
any `overflow` other than `visible` makes that wrapper the sticky containing
block — so `top-16` offset 64px from the *wrapper*, dropping the header onto the
first broker band and clipping it. Making it work means changing a shared
primitive every other table relies on for horizontal scroll. Not worth it, and
especially not once groups collapse by default.
