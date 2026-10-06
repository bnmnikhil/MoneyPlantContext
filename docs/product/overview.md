# Product overview

## What it is

A trader who runs positions at more than one broker has no single view of them: each broker shows its own
book, in its own shape, and two of the brokers GoldenBook started with show no useful payoff chart at all.
GoldenBook connects to each broker the user already has, reads (never writes) their portfolio, and shows:

- **Positions and holdings** from every connected account, side by side, grouped by underlying.
- **Margins and capital** per account, with the bill each broker actually charges.
- **A payoff chart** for each strategy (the legs held at one broker on one underlying), with breakevens,
  maximum profit and loss, and the spot price.
- **A strategy builder** that starts from the real legs or from a template and lets the user try an
  adjustment (add, close, change a strike) before doing anything at the broker.
- **A risk view**: exposure, expiry buckets and a margin estimate computed from the positions.

## What it deliberately does not do

- **It places no orders.** There is no order endpoint, no order scope requested from any broker, and no
  workaround for a broker's static-IP rule on orders. This is a product boundary and a regulatory one: the
  broker's static-IP mandate binds order placement, so a read-only app is outside it.
- **It does not merge positions across brokers.** The same strike at two brokers stays two legs, and a
  payoff is drawn per account, because margin benefit exists only inside one account.
- **It does not give advice.** Figures are computed and labelled, not recommended. Whether the strategy
  builder counts as research is an open question in the launch plan.
- **It does not hold a shared broker app.** Each user registers their own developer app at each broker
  (see below).

## Who it is for

Retail NSE F&O traders with accounts at several brokers, who today stitch their positions together by hand.
Sign-up has been open to anyone with a Google account since 3 October 2026, with no invitation and no user
cap. The first user is the owner; three people had accounts on 6 October.

## How a user gets started

1. Sign in with Google.
2. For each broker, **create a developer app in that broker's own portal** and copy its key and secret into
   GoldenBook's settings. GoldenBook encrypts the secret and never shows it again.
3. Press **Connect**; the broker's own login page opens, the user signs in there, and is sent back.
4. Positions, holdings, margins and payoff charts appear.

The per-user app is a deliberate design choice, not an oversight. It means GoldenBook never holds one
shared credential that could serve everyone, never needs a broker's approval to onboard each user, and
sidesteps the rule that most brokers allow one redirect URL per app. The cost is onboarding effort, and for a
few brokers a small fee, which GoldenBook can only soften with a good setup guide.

## Supported brokers

Five are live and two more are planned; see [Brokers](brokers.md). **Upstox and Dhan went live on 6 October
2026 before being checked against a real account**, so their figures are unverified; that is recorded, not
hidden.

## What exists and what does not

| Area | State |
|---|---|
| Multi-broker positions, holdings and margins | Live |
| Payoff charts, with exact strikes, breakevens and range controls | Live |
| Strategy builder with live option-chain quotes | Live (the chain comes from Alice Blue only) |
| Risk view: exposure, expiry buckets, margin estimate | Live, but computed from stored snapshots that can be stale |
| Open Google sign-up with an admission switch | Live |
| Backups, monitoring and alerting | **Not yet** |
| Self-serve broker setup guide, support contact, data erasure | **Not yet** |
| Price history, greeks and decay analysis | Not built |

The honest list of what is missing is in [`NEXT-STEPS.md`](https://github.com/bnmnikhil/MoneyPlantContext/blob/main/NEXT-STEPS.md)
("Gaps review").
