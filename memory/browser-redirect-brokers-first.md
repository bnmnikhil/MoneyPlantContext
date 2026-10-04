---
name: browser-redirect-brokers-first
description: New brokers are added browser-redirect only (Upstox, Dhan, Groww); server-login brokers held back; friends' accounts for live checks
metadata:
  type: project
---

Decided 4 Oct 2026 (owner). Beyond Kite, Alice Blue and Paytm, GoldenBook adds **brokers whose login is a browser
redirect**: Upstox first, then Dhan, then Groww, one at a time, each through `BROKER-EXPANSION-PLAN.md` (dossier,
simulator profile, adapter merged `hidden`, staging soak, live check, flag).

**Held back: server-login brokers** (Kotak Neo needs the user's TOTP and 6-digit MPIN; Motilal Oswal needs the
trading password, PAN or date of birth, and TOTP). **Why:** the secrets would pass through GoldenBook, and a
Motilal-style trading password can place orders; Motilal's own FAQ tells customers never to share it. Revisit
only with a user-typed, never-stored design and the owner's say-so. Angel One waits on a portal check of whether
its static-IP field can be skipped (it is rank 3, about 14.6% of NSE clients).

**Live checks use friends' accounts**, arranged later; real accounts take time. The simulator and adapters do not
depend on them, only each broker's CERT-02/03 and live comparison do. Hosted multi-user terms (CERT-04) need a
written answer per broker and remain open; L1 broker outreach is deferred to 17-24 Oct.

**How to apply:** do not start Kotak Neo or Motilal Oswal work; do not skip the dossier-then-simulator-first order.
Related: [[new-brokers-require-no-static-ip]].
