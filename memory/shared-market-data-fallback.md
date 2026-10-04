---
name: shared-market-data-fallback
description: Spot and option-chain data come from the user's own brokers first, then an admin account's feed (off by default), until a paid data subscription; the terms risk is accepted by the owner up to about 50 users.
metadata:
  type: decision
  decided: 2026-10-03
---

**Decided 3 Oct 2026 (owner)**, while planning L18. Resolution order for **spot**: the
user's own Paytm live price, then the user's own Alice Blue chain `spotLTP`, then the
user's own Kite LTP (only with paid market data), then the **admin feed** (the admin's
Paytm, then the admin's Alice Blue), otherwise none. For the **option chain**: the
user's own Alice Blue, then the admin's. A level is never invented:
`PayoffService.defaultSpotFor` goes.

**Why.** Kite's free Personal tier returns no quotes, and most new users will be
Kite-only, so "own data only" means most users see no spot and a builder that cannot
price. The owner wants momentum for the first ~50 users and will buy a data subscription
later.

**The risk was stated and accepted.** Kite's terms say live market data "cannot be
displayed to the public at large". Alice Blue's terms forbid sublicensing, and the
research doc lists "market data shown to anyone but the account holder" as one of the
risks. NSE licenses redistribution separately. The likely penalty is revoked API access
on the account that runs the feed, which is why the feed should run on a separate,
unfunded broker account. Sources: `research/BROKER-API-TERMS-MULTI-USER.md`.

**This is not a reversal of L18.** L18 was data from **another user's** session
reaching someone silently. That stays forbidden: a user's own connections are cached per
user. Only the admin's designated feed is shared, and only under the guard rails in
`PUBLIC-LAUNCH.md` L18: off by default (`GB_ADMIN_MARKET_DATA`); a narrow market-data-only
access path that can never read positions; the admin's connection id never in a
response; every spot labelled with its source; daily usage counts.

**How to apply.** Never fall back to another *user's* session, whatever the shortage.
When the subscription arrives, it plugs in where the admin feed sits, as one more
provider behind the same interface. Exit at about 50 users, on a broker objection, or
once there is revenue. Revisit at the 17–24 Oct L1 review using the usage counts.
Supersedes the "owned by the same user" clause of
[[quote-source-is-independent-of-position-account]] for the chain fallback only. See
also [[free-market-data-options-researched]].
