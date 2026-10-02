---
name: new-brokers-require-no-static-ip
description: "New broker integrations must support app activation plus positions and holdings without a static IP"
metadata:
  type: decision
  decided: 2026-09-21
---

GoldenBook will add only brokers for which a user can activate the applicable
data-only integration and fetch **both positions and holdings without supplying
or routing through a static IP**. Static-IP enforcement on order endpoints is
irrelevant because GoldenBook remains read-only.

This is deliberately stricter than accepting a broker whose read endpoints do
not validate source IP after its portal has already forced the user to register
one. The product goal is low-friction portfolio aggregation, so mandatory IP
procurement during app creation is itself a disqualifier for a new integration.

The rule applies to future additions. Alice Blue and Paytm Money predate it and
are not removed, but they are not patterns to copy. The initial implementation
queue is Upstox, Kotak Neo, Dhan and FYERS, followed by Groww, Motilal Oswal and
5paisa only after portal and live certification. Angel One, ICICI Direct and HDFC
remain research-only while their onboarding requires or appears to require an IP.

The evidence bar has three parts: current primary documentation, an observed
data-only app-creation flow, and positions/holdings calls from an unregistered
changing IP. Hosted multi-user use must also be allowed; passing the network test
does not override broker terms or a required partner relationship.

If a candidate fails, GoldenBook selects the next broker by current NSE
active-client rank and repeats the same gate. Reaching an arbitrary count is not
a reason to weaken the rule or introduce shared-IP workarounds.

Related: [[brokers-become-user-configured]],
[[credentials-per-user-per-registration]],
`research/BROKER-LAUNCH-SHORTLIST.md`, `BROKER-EXPANSION-PLAN.md`
