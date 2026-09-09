---
name: payoff-ranges-and-limits
description: "Futures need price anchors, and payoff limits come from quantities and the spot-zero boundary"
metadata:
  type: decision
  decided: 2026-09-06
---

Futures and equity carry strike zero as a contract convention. That is not a
chart price. PayoffEngine's API sample window still uses their entry prices,
option strikes and a known current spot. The UI now owns the visible window:
indices start at spot +/-10%, stocks at +/-15%, classified by UnderlyingRegistry
through the response's `isIndex` field. Auto widens for strikes and breakevens
outside that interval, adding 2% of the anchor as padding. Historical entry cost
alone does not widen it. Missing spot falls back to the midpoint of active option
strikes, then average linear entry prices, with an explicit caption.

The shared live/builder chart offers +/-5%, +/-10%, +/-15%, Custom and Reset.
Explicit presets/custom bounds can crop landmarks; Reset restores Auto. Custom
bounds must be finite, nonnegative and increasing. The chart recalculates expiry
P&L from returned legs within the requested interval, including exact strikes,
breakevens and endpoints, instead of stretching or extrapolating rounded samples.
It rescales the P&L axis from visible values (including zero), and never changes
the API's profit/loss limits. Closed legs do not set the range.

The real Paytm NIFTY future plus put exposed this: strike zero stretched the
window from 0 to 38,160 while spot was 23,897.70. A futures-only book collapsed
to 201 identical spot-zero points.

Unlimited profit/loss is determined by net signed call + future + equity units
beyond all strikes. Inferring it from differences between sampled P&Ls turned
floating-point cancellation noise into unlimited risk: the live AUBANK iron
condor and ITC put spread were both affected. The lower boundary is spot zero,
which is finite. Evaluate it for extrema without forcing it into the viewport.
Include exact option strikes for peaks and corners, deduplicate zero crossings,
and round output P&L to paise after calculating crossings from unrounded values.

Mixed expiries remain a limitation. The observed NIFTY put expires on 8 Sep and
the future on 27 Oct. Their combined terminal-price scenario does not value the
October future at September expiry. The live page must state that assumption
and qualify the loss rather than implying a guaranteed hedge through October.
Breakevens are now solved over the complete nonnegative spot domain, including
the linear tail beyond the last strike, independently of the sample window.
Full valuation across expiries remains separate work; no market-data or
futures-basis model was added here.
