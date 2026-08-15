---
name: brokers-become-user-configured
description: "Long-term direction — users will configure their own brokers and accounts, so the \"three known brokers\" assumption is temporary"
metadata:
  type: state
  decided: 2026-08-05
---

MoneyPlant's broker list is currently a global assumption: `BrokerRegistry`
enumerates every broker the *build* knows about (kite, aliceblue, paytm). **The
long-term model is the opposite** — each user configures which brokers they use
and how many accounts they hold at each. Stated by the owner on **5 Aug 2026**
while deciding the `/api/session/status` shape, with the scale sketched as "tens
of brokers".

**Why it matters.** It changes what "disconnected" means. Today that is "a
registered broker this user has no session for", which is only sensible while the
registry is small and every user plausibly wants all of it. At tens of brokers,
showing every user every broker is noise, and the answer has to come from that
user's own configuration rather than from the bean registry.

**How to apply — directional, not scheduled.** The owner put the priority as
"very far". Do not build toward it now. Do let it break ties in present-day
design: prefer contracts that can express *this user's* brokers and *per-account*
identity over ones that hardcode a global list.

**What it has already shaped:** `/api/session/status` returns `brokers` and
`connections` as two arrays rather than one array with synthetic rows;
`accountLabel` falls back to the connectionId's label segment — the segment a
user will eventually name themselves — rather than to the brokerId. The first
half then landed in Step 3d: that endpoint's `brokers` is now *this user's*
brokers, and `/app/settings` is where configuration happens.

Related: [[real-product-not-personal-tool]], [[credentials-per-user-per-registration]]
