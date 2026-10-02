# Strategy Builder preserves signed imported position bases

Type: decision
Date: 2026-10-01

## Failure and evidence

M&M's option chain resolved correctly, but `/api/payoff/compare` returned HTTP
400 for the imported five-leg baseline. The 2900 PE leg had an effective basis
of -50.80, while the comparison validator required every entry price to be
nonnegative. The live payoff and chart arithmetic already accepted that value.

The captured Alice Blue row had 400 overnight units at 28.00, 200 units sold
today at 106.80, and 200 net units. The existing mapper computes
`(400 * 28.00 - 200 * 106.80) / 200 = -50.80`. This is the application's
net-cash basis after a partial sale, not a negative market quote. The broker's
separate `netAveragePrice` was 54.65; these fields are not interchangeable.

## Contract decision

Allow a finite signed `entryPrice` only in `baselineLegs` when both
`origin == EXISTING_POSITION` and `priceBasis == POSITION_AVERAGE`.
All draft execution prices, quote/manual bases and existing-holding costs stay
nonnegative. Required prices still cannot be null; all supplied prices must be
finite. A draft cannot gain the exception by claiming imported provenance.

Keep the imported value unchanged. Do not take its absolute value, clamp it to
zero, omit the leg, or introduce an M&M-specific exception. The rule applies to
any instrument with this imported position provenance.

## Scope and verification

The comparison validator changes; canonical symbols, broker mapping and payoff
arithmetic do not. Regression coverage includes the five-leg M&M baseline,
closing a signed-basis position at a nonnegative execution price, invalid
provenance, non-finite prices, the JSON API contract, frontend import and chart
arithmetic. The baseline-only comparison must match the existing live expiry
payoff.

This is not an accounting-policy rewrite. Alice Blue's mapper also exposes
realised P&L separately; whether that should be combined with a net-cash basis
in portfolio totals needs a separate accounting review. Allowing the chart to
preserve today's imported basis does not certify those totals or change how
realised P&L is attributed.
