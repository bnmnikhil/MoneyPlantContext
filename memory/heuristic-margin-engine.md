# Decision: Bottom-up margin engine, and what a real bill taught it

**Date:** 15 Aug 2026, rewritten 17 Aug 2026 after calibration
**Status:** Shipped, and the default per-instrument figure
**Affects:** `risk/HeuristicMarginEngine`, `risk/MarginAllocator`, `analytics/PayoffService`

---

## Why bottom-up at all

Two cases the top-down allocation could not serve: a strategy in the builder has
no bill to divide, and an account whose margin snapshot is missing had to report
zero. See [[margin-attribution-model]] for the allocation it replaced and why
that was demoted.

## The model, and the evidence

Calibrated against **one real Zerodha account, twice** — 15 and 17 Aug 2026, on
two different books. `KiteMarginCalibrationTest` holds the second as a fixture
and is the thing to re-run before touching any rate.

**`utilised.debits` is not the number to calibrate against.** Measured exactly on
17 Aug: `debits 236,271.825 = span 83,215.50 + exposure 145,648.825 +
optionPremium 1,936.50 + delivery 5,471.00`, where the delivery figure is 20 ITC
shares at their 273.55 average — a CNC equity holding, charged at full value, not
at a margin percentage. The target for an F&O margin model is `span + exposure`.
`CLAUDE.md`'s claim that `span + exposure + optionPremium = debits` holds exactly
is therefore true only for a book with no delivery obligation.

**The first version came out 54% under the real bill.** Three errors, each
corrected and each now pinned by a test:

1. **Premium is not margin.** Kite's span + exposure equal the bill exactly, and
   option premium is billed separately. A long option therefore blocks *no*
   margin — its premium is cash already spent. The old model added premium into
   the charge, and `PayoffService` then added the net debit again on top when it
   computed `totalFundsRequired`, so a debit spread was double-counted.
2. **Hedging reduces SPAN and leaves exposure untouched.** Every leg in the
   calibration book is hedged, and per-leg exposure summed to **within 0.5%** of
   what the exchange charged. The old model discounted the short leg's whole
   standalone charge down to the spread's max loss, which wiped the exposure
   component — that alone was most of the 54%.
3. **SPAN is a portfolio scan, not a catalogue of named strategies.** The old
   code pattern-matched pairs of legs into "bull call spread" and "strangle" and
   applied a rule per shape. It could only ever price shapes someone had already
   thought of, and double-counted legs matched into more than one pair. Now the
   whole `(account, underlying, expiry)` group is revalued at each scan point
   and the worst total loss is the charge.

**Scan points are the strikes inside the range plus its endpoints.** Under
intrinsic valuation that was provably sufficient — the payoff is piecewise
linear with kinks only at strikes. It still matters after the change below: a
ratio spread's loss can sit entirely *between* the endpoints, both of which show
a profit. The ITC 255/272.5 backspread in the 17 Aug book is exactly that.

## The fourth error, found by the owner (17 Aug 2026)

**Legs must be priced, not settled.** The corrected model above still valued each
leg at *expiry intrinsic* at the scan point, and that was worse than all three
errors it replaced. The owner reported AUBANK showing **₹1.25L in the app against
₹95,000 in Kite**. The whole of that structure's SPAN came from one scan point —
1180, where it holds 2,000 **long** 1180 calls. Intrinsic prices an option at its
own strike at zero, so the covered short read as naked and the group was charged
its full undefended loss. Those calls were at the money with nine days to run and
really worth about ₹26 each.

The fix: value legs with Black-Scholes at each scan point, using a volatility
solved from that leg's own mark — so the model reproduces the mark at the base
point by construction and the scan starts from zero loss. Legs whose mark yields
no volatility inherit the group's nearest-the-money solve; a group where nothing
solves falls back to intrinsic. **`ImpliedVolatility` and `BlackScholes` already
existed** for `ScenarioLadder`'s sigma band; nothing new was needed.

**Volatility is scanned too**, because SPAN scans both axes and a book long
options is hurt by vol falling even where the price move alone is harmless.
AUBANK is net long options, so its worst case is a vol-down scenario a
price-only scan never visits.

**The grid is SPAN's own sixteen scenarios**: seven price moves — nothing, and a
third, two thirds and all of the scan range either way — each paired with
volatility up and down, plus two extreme moves at twice the range carrying 35%
weight.

**Only those points are evaluated, and that is a reversal.** The version before
this one added every strike inside the range, reasoning that the payoff's kinks
live there and a worst case can hide between grid points. True — and true of
SPAN as well, which does not look at those points either. Charging for them made
the estimate *stricter than the thing it estimates*. A ratio spread's real
interior peak is now deliberately not charged; true worst case is the `maxLoss`
column's job, and that column is standalone and already says so.

**Result on the 17 Aug book:** AUBANK **98,887 against 95,000 (+4.1%)**, from
129,904 (+36.7%). Account total 208,216 against 228,864 (−9.0%); exposure
−0.68%; SPAN −23.6%.

**The account total is under and the per-underlying figure is close.** That is
the deliberate priority — the per-underlying number is the one on screen with no
broker equivalent beside it, whereas the account's real bill is always shown
unaltered. The SPAN shortfall is the price-scan floor above.

**Erring high is the tolerable direction** for the per-instrument figure. A
margin estimate that reads low tells someone they have room they do not have.

## Rates: NSE Clearing's published parameters, not invented ones

Looked up 17 Aug 2026 after the AUBANK report, and the rates were changed to
match. Sources in the "Reference" section of [[MEMORY]] — Zerodha's own support
article and NSE Clearing's SPAN pages.

| | had been | NSE Clearing's published value |
|---|---|---|
| Price scan range, index | 10% | 6σ×√2, **min 9.3%** |
| Price scan range, stock | 15% | 6σ×√2, **min 14.2%** |
| Exposure, index | 2% | **2%** of contract value — confirmed |
| Exposure, stock | 3.5% | **3.5%**, or 1.5σ of six-month log returns if higher |
| Volatility scan range | ±30% relative, invented | **25% of the contract's volatility, floored at 3 absolute points** |

**We use the published minimums for the scan range**, because the 6σ that would
widen them needs a volatility history the stack does not have. So the scan sits
at its floor on a volatile name and the estimate runs light there by exactly
however far the exchange widened it. That is most of the remaining gap.

**The volatility scan being *relative* was the lucky guess** — ±30% invented
against NSE's 25%-of-vol. Had it been coded as an absolute point shift it would
have been badly wrong for low- and high-vol legs in opposite directions.

**Margin = SPAN + Exposure** is Zerodha's own formula, stated as
`SPAN + Exposure − spread benefit`; the spread benefit is presentational, being
the difference between summing legs standalone and the portfolio SPAN, which is
exactly what `initialMargin` minus `withBenefitMargin` reports.

**The Short Option Minimum floor applies only to short quantity no long of the
same right covers.** On gross shorts it was measurably wrong: the calibration
book is eight short legs, all covered, and its entire SPAN bill across four
underlyings is less than a gross-short floor on one of them.

## Architecture

Pure domain in `risk/`: no Spring, no broker imports, ArchUnit A2 clean.
`MarginAllocator` feeds it from `ScenarioGroup.spot()` rather than a separate
spot map, so the estimate and the scenario markers describe the same world.
