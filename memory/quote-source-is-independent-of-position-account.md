---
name: quote-source-is-independent-of-position-account
description: "Option-chain market data and the account whose positions are being adjusted are separate choices"
metadata:
  type: decision
  decided: 2026-09-10
---

The Strategy Builder treats the **position account** and **option-chain source**
as separate dimensions.

An existing-position baseline remains scoped to exactly one
`(connectionId, underlying)` pair. Its quantities, entry costs and margin context
are never merged with another broker. The option-chain snapshot used to quote new
hypothetical legs may come from any market-data-capable broker connection owned
by the same user. Today that means an Alice Blue session can quote a strategy
whose baseline positions are held at Kite, Paytm Money or another Alice Blue
account.

**Why.** A position account answers what the user owns and where hedge benefit
can exist. A quote source answers what a listed contract is worth now. Making the
second depend on the first prevents brokers without a chain API from using the
builder even when the user has a valid data connection elsewhere.

Both connection IDs are still resolved through `BrokerService`, so one user
cannot name another user's session. Quote caches remain separated by user,
source connection and session generation. Draft legs are simulations only; this
decision does not authorise cross-broker order routing or reverse the
no-cross-broker position-merging rule.
