---
name: groww-on-hold
description: Groww integration on hold since 11 Oct 2026 — no browser-redirect login and a ₹499/month per-user API fee; reopen on a partner/OAuth route
metadata:
  type: project
---

**Decided 11 Oct 2026 (owner): Groww is on hold.** N10 stopped after its dossier (`research/GROWW-DOSSIER.md`).

**Why:** Groww's retail Trade API has no browser-redirect login (key + secret with a daily approval at Groww, a
TOTP seed, or a pasted daily token), so it fails [[browser-redirect-brokers-first]] as written. Every user would
also pay Groww ₹499 a month plus taxes before any call works, so the users GoldenBook would really gain are only
Groww F&O traders already paying for the API — few, against the largest build in the queue (a separate quote feed
too: Groww positions carry no last price). Groww's headline reach (about 29% of NSE active clients) does not
survive the fee.

**How to apply:** do not start a Groww simulator profile or adapter. Reopen only if Groww offers a partner/OAuth
route for read-only apps (ask during L1 outreach, 17–24 Oct) or the per-user fee goes away, and confirm the
static-IP field at key creation is optional (CERT-02) before any build. If reopened without OAuth, the dossier's
route A (daily approval) is the recommended exception; the TOTP-seed route stays ruled out.
Related: [[new-brokers-require-no-static-ip]].
