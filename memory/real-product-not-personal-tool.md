---
name: real-product-not-personal-tool
description: "MoneyPlant is a real product for a limited number of real users on deliberately minimal infrastructure — not a personal script, and not a startup chasing scale"
metadata:
  type: decision
  decided: 2026-07-29
---

MoneyPlant serves **a limited number of real users, run safely, on deliberately
minimal infrastructure cost.**

**Why it matters.** It settles a whole class of arguments at once, in both
directions:

- *"Real users"* is why credentials are per-user and encrypted, why sessions key
  off the Google `sub` rather than the email, and why a `connectionId` reaching
  the browser inside a warning was worth designing around.
- *"Minimal cost"* is why the stack is the OCI always-free tier with Postgres on
  the same VM rather than managed services, and why the next service added will
  be another block in the existing `docker-compose.yml` rather than a second
  deployment style.
- *"Limited number"* is what keeps `MP_ALLOWED_EMAILS` an acceptable substitute
  for a `users` table.

**How to apply.** Price every proposal against the free tier first — a managed
queue, a hosted database or a paid data feed needs an argument, not just a
benefit. Assume more than one user and more than one account per broker in any
contract you design. But do not build for scale that is not coming: tens of
users, not thousands.

Related: [[brokers-become-user-configured]], [[credentials-per-user-per-registration]]
